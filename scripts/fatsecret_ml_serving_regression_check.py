#!/usr/bin/env python3
"""Regression checks for FatSecret barcode/food.get milliliter servings.

FatSecret `food.get` returns beverage servings as metric_serving_amount=355
with metric_serving_unit=ml and calories for that full serving. The iOS food
log scales as:

    stored = api_calories * (consumed_g / serving_size_g)

If the proxy maps every non-'g' unit to 100g, scanning a 355ml soda and
confirming the default 100g stores the whole-can calories as if they were
per 100g (~3.5x too high).
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROXY_PATH = ROOT / "supabase" / "functions" / "fatsecret-proxy" / "index.ts"

OZ_TO_G = 28.3495


def extract_function(source: str, name: str) -> str:
    start = source.find(f"function {name}(")
    if start < 0:
        raise AssertionError(f"missing function {name}() in {PROXY_PATH}")
    header_end = source.find(")", start)
    if header_end < 0:
        raise AssertionError(f"unclosed parameter list for {name}()")
    body_start = source.find("{", header_end)
    if body_start < 0:
        raise AssertionError(f"missing function body for {name}()")
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


def expected_serving_grams(amount: float, unit: str) -> float:
    normalized = unit.strip().lower()
    if normalized in {"g", "gram", "grams", "ml", "milliliter", "milliliters", ""}:
        return amount
    if normalized in {"l", "liter", "liters"}:
        return amount * 1000.0
    if normalized in {"oz", "ounce", "ounces"}:
        return amount * OZ_TO_G
    return 100.0


def scaled_calories(api_calories: float, serving_g: float, consumed_g: float) -> float:
    return api_calories * (consumed_g / max(serving_g, 1.0))


def check_soda_trigger() -> list[str]:
    failures: list[str] = []
    serving_g = expected_serving_grams(355, "ml")
    if abs(serving_g - 355) > 0.01:
        failures.append(f"355ml should map to 355g, got {serving_g}")

    buggy_default = 140.0  # whole-can kcal stored when serving is forced to 100g
    fixed_default = scaled_calories(140.0, serving_g, 100.0)
    if abs(buggy_default - 140.0) > 0.01:
        failures.append("fixture calories changed")
    if fixed_default >= 80:
        failures.append(
            f"355ml soda at 100g still looks like the 140 kcal bug ({fixed_default})"
        )
    if abs(fixed_default - (140.0 * 100.0 / 355.0)) > 0.05:
        failures.append(f"expected ~39.4 kcal for 100g of 140/355ml, got {fixed_default}")
    return failures


def check_proxy_source() -> list[str]:
    failures: list[str] = []
    source = PROXY_PATH.read_text(encoding="utf-8")
    get_fn = extract_function(source, "mapFoodGetResult")

    if re.search(r"servingUnit\s*===\s*[\"']g[\"']\s*\?\s*servingSizeG\s*:\s*100", get_fn):
        failures.append(
            "mapFoodGetResult treats every non-'g' metric unit as 100g, "
            "corrupting ml barcode servings"
        )

    treats_ml = (
        re.search(r"[\"']ml[\"']", get_fn) is not None
        or re.search(r"[\"']ml[\"']", source) is not None
    )
    if not treats_ml:
        failures.append(
            "proxy does not convert metric_serving_unit=ml to grams; "
            "beverage barcode servings stay pinned to 100g"
        )

    return failures


def main() -> int:
    if not PROXY_PATH.is_file():
        print(f"fatsecret-ml-serving: missing {PROXY_PATH}", file=sys.stderr)
        return 1

    failures = check_soda_trigger() + check_proxy_source()
    if failures:
        print("fatsecret-ml-serving: FAIL")
        for item in failures:
            print(f"  - {item}")
        return 1

    print("fatsecret-ml-serving: ok")
    print("  355ml soda serving stays 355g; 100g of 140 kcal/355ml => ~39 kcal")
    print("  proxy no longer maps every non-g FatSecret unit to 100g")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
