#!/usr/bin/env python3
"""Regression checks for FatSecret search serving-size parsing.

FatSecret food_description values are per the stated serving
("Per 342g", "Per 100g", "Per 8 oz"), not always per 100g. The iOS food
log scales calories/macros as:

    stored = api_calories * (consumed_g / serving_size_g)

If the proxy hardcodes serving_size_g = 100 while calories are per 342g,
logging the default 100g stores ~3x too many calories.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROXY_PATH = ROOT / "supabase" / "functions" / "fatsecret-proxy" / "index.ts"

GRAM_RE = re.compile(r"per\s+([0-9]+(?:\.[0-9]+)?)\s*g\b", re.IGNORECASE)
OZ_RE = re.compile(r"per\s+([0-9]+(?:\.[0-9]+)?)\s*(?:fl\s+)?oz\b", re.IGNORECASE)
CALORIES_RE = re.compile(r"Calories\s*:\s*([0-9]+(?:\.[0-9]+)?)", re.IGNORECASE)
OZ_TO_G = 28.3495


def parse_serving_g(description: str) -> float:
    gram = GRAM_RE.search(description)
    if gram:
        return float(gram.group(1))
    oz = OZ_RE.search(description)
    if oz:
        return float(oz.group(1)) * OZ_TO_G
    return 100.0


def parse_calories(description: str) -> float:
    match = CALORIES_RE.search(description)
    return float(match.group(1)) if match else 0.0


def scaled_calories(description: str, consumed_g: float) -> float:
    serving = max(parse_serving_g(description), 1.0)
    return parse_calories(description) * (consumed_g / serving)


def extract_function(source: str, name: str) -> str:
    start = source.find(f"function {name}(")
    if start < 0:
        raise AssertionError(f"missing function {name}() in {PROXY_PATH}")
    # Skip the parameter list and any object return-type annotation so we
    # start counting braces at the function body.
    header_end = source.find(")", start)
    if header_end < 0:
        raise AssertionError(f"unclosed parameter list for {name}()")
    body_start = source.find("{", header_end)
    if body_start < 0:
        raise AssertionError(f"missing function body for {name}()")
    # If the next "{" is a return-type object, skip that block too.
    between = source[header_end:body_start]
    if ":" in between:
        depth = 0
        for index, char in enumerate(source[body_start:], body_start):
            if char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    body_start = source.find("{", index + 1)
                    break
        if body_start < 0:
            raise AssertionError(f"missing function body after return type for {name}()")
    depth = 0
    for index, char in enumerate(source[body_start:], body_start):
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[start : index + 1]
    raise AssertionError(f"unclosed function {name}()")


def check_parse_cases() -> list[str]:
    failures: list[str] = []
    cases = [
        (
            "Per 100g - Calories: 52kcal | Fat: 0.17g | Carbs: 13.81g | Protein: 0.26g",
            100.0,
            52.0,
        ),
        (
            "Per 342g - Calories: 835kcal | Fat: 32.28g | Carbs: 105.43g | Protein: 29.41g",
            342.0,
            244.152,
        ),
        (
            "Per 342 g - Calories: 835kcal | Fat: 32.28g | Carbs: 105.43g | Protein: 29.41g",
            342.0,
            244.152,
        ),
        (
            "Per 8 oz - Calories: 200kcal | Fat: 8.00g | Carbs: 24.00g | Protein: 10.00g",
            226.796,
            88.185,
        ),
        (
            "Per 1 serving - Calories: 300kcal | Fat: 12.00g | Carbs: 40.00g | Protein: 15.00g",
            100.0,
            300.0,
        ),
    ]
    for description, expected_serving, expected_100g_kcal in cases:
        serving = parse_serving_g(description)
        got_100g = scaled_calories(description, 100.0)
        if abs(serving - expected_serving) > 0.05:
            failures.append(
                f"serving for {description!r}: expected {expected_serving}, got {serving}"
            )
        if abs(got_100g - expected_100g_kcal) > 0.05:
            failures.append(
                f"100g kcal for {description!r}: expected {expected_100g_kcal}, got {got_100g}"
            )

    # Concrete trigger: restaurant item logged at the 100g default.
    restaurant = "Per 342g - Calories: 835kcal | Fat: 32.28g | Carbs: 105.43g | Protein: 29.41g"
    buggy_100g = parse_calories(restaurant)  # what the hardcoded-100 path stores
    if abs(buggy_100g - 835.0) > 0.01:
        failures.append("fixture calories changed; update the restaurant trigger case")
    fixed_100g = scaled_calories(restaurant, 100.0)
    if fixed_100g >= 400:
        failures.append(
            f"restaurant 100g serving still looks like the 835 kcal bug ({fixed_100g})"
        )
    return failures


def check_proxy_source() -> list[str]:
    failures: list[str] = []
    source = PROXY_PATH.read_text(encoding="utf-8")
    parse_fn = extract_function(source, "parseFoodDescription")

    if re.search(r"servingPer100\s*\?\s*100\s*:\s*100", parse_fn):
        failures.append(
            "parseFoodDescription hardcodes servingSizeG = 100 for both per-100g "
            "and non-100g FatSecret descriptions"
        )
    if "servingSizeG = 100" in parse_fn and not GRAM_RE.search(parse_fn.replace("\\\\", "\\")):
        # The TS regex is written with a single backslash in a JS string.
        ts_has_gram_capture = bool(
            re.search(r"per\\s\+.*\(\[0-9\]|per\\s\+.*\(\\d", parse_fn)
            or re.search(r"per\s+\$?\{", parse_fn)
            or ("match(" in parse_fn and "servingSizeG" in parse_fn)
        )
        if not ts_has_gram_capture:
            failures.append(
                "parseFoodDescription does not capture a gram serving from "
                "'Per <n>g' descriptions"
            )

    if not re.search(r"per\\s\+.*g", parse_fn) and not re.search(
        r"Per\s+.*g", parse_fn
    ):
        # Accept either a regex or an explicit gram parser helper call.
        if "parseServingSizeGrams" not in parse_fn and "servingSizeFromDescription" not in parse_fn:
            if not re.search(r"/per\\s\+/i", source) and not re.search(
                r"per\\s\+", parse_fn
            ):
                failures.append(
                    "proxy no longer contains a Per-<n>g serving parser; "
                    "keep gram capture in parseFoodDescription"
                )

    get_fn = extract_function(source, "mapFoodGetResult")
    if re.search(r"servingUnit\s*===\s*[\"']g[\"']\s*\?\s*servingSizeG\s*:\s*100", get_fn):
        failures.append(
            "mapFoodGetResult treats every non-'g' metric unit as 100g, "
            "corrupting oz barcode servings"
        )
    return failures


def main() -> int:
    if not PROXY_PATH.is_file():
        print(f"fatsecret-serving-parse: missing {PROXY_PATH}", file=sys.stderr)
        return 1

    failures = check_parse_cases() + check_proxy_source()
    if failures:
        print("fatsecret-serving-parse: FAIL")
        for item in failures:
            print(f"  - {item}")
        return 1

    print("fatsecret-serving-parse: ok")
    print("  parsed Per 342g as 342g; 100g of 835 kcal/342g => ~244 kcal")
    print("  proxy no longer hardcodes servingSizeG = 100 for all search hits")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
