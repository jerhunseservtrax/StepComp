#!/usr/bin/env python3
"""Regression check: barcode lookups must not be overwritten by live text search.

Trigger: Log Meal → scan (or manually look up) a barcode.
Current bug: handleScannedBarcode assigns foodQuery, which fires onChange and
schedules searchFood() 300ms later. That text search writes the same
searchResults array and can replace a correct barcode hit with empty/wrong foods.

This script:
1. Asserts AddMealView.swift suppresses live text search for barcode fills.
2. Asserts FoodLogViewModel.swift ignores stale search writes via a generation token.
3. Simulates the race to lock the intended dispatch rules.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADD_MEAL = ROOT / "StepComp" / "Screens" / "Workouts" / "AddMealView.swift"
FOOD_VM = ROOT / "StepComp" / "ViewModels" / "FoodLogViewModel.swift"


def extract_swift_func(source: str, name: str) -> str:
    marker = f"func {name}("
    start = source.find(marker)
    if start < 0:
        raise SystemExit(f"FAIL: {name}() not found")
    brace = source.find("{", start)
    depth = 0
    for i, ch in enumerate(source[brace:], brace):
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return source[start : i + 1]
    raise SystemExit(f"FAIL: could not parse {name}()")


def check_add_meal_suppresses_barcode_live_search() -> None:
    source = ADD_MEAL.read_text()
    handle = extract_swift_func(source, "handleScannedBarcode")
    on_change = source[source.find(".onChange(of: foodQuery") :]

    assigns_query = bool(re.search(r"foodQuery\s*=", handle))
    sets_suppress = (
        "suppressNextLiveSearch" in handle
        or "FoodSearchDispatch" in handle
        or "ignoreNextFoodQueryChange" in handle
    )
    on_change_guards = (
        "suppressNextLiveSearch" in on_change
        or "shouldScheduleLiveTextSearch" in on_change
        or "FoodSearchDispatch" in on_change
    )

    if assigns_query and not sets_suppress:
        raise SystemExit(
            "FAIL: handleScannedBarcode assigns foodQuery without suppressing "
            "the live text-search onChange. Scanning a UPC then races searchFood() "
            "against searchFoodByBarcode() on the same searchResults."
        )
    if not on_change_guards:
        raise SystemExit(
            "FAIL: foodQuery onChange still always schedules live text search. "
            "Barcode fills must be ignored by scheduleLiveSearch."
        )


def check_view_model_has_generation_guard() -> None:
    source = FOOD_VM.read_text()
    for name in ("searchFood", "searchFoodByBarcode"):
        body = extract_swift_func(source, name)
        if "searchGeneration" not in body and "isCurrentSearch" not in body:
            raise SystemExit(
                f"FAIL: {name}() writes searchResults without a generation token. "
                "A late text-search response can overwrite a newer barcode result."
            )
        writes = len(re.findall(r"searchResults\s*=", body))
        guards = len(re.findall(r"isCurrentSearch\(|searchGeneration\.isCurrent", body))
        if writes and guards < 1:
            raise SystemExit(
                f"FAIL: {name}() assigns searchResults but never checks the current search token."
            )


class FoodSearchDispatch:
    """Mirrors the Swift generation + source policy."""

    def __init__(self) -> None:
        self.generation = 0

    @staticmethod
    def should_schedule_live_text_search(source: str) -> bool:
        return source == "user_typing"

    def begin(self) -> int:
        self.generation += 1
        return self.generation

    def is_current(self, token: int) -> bool:
        return token == self.generation


def simulate_barcode_then_stale_text() -> None:
    dispatch = FoodSearchDispatch()
    results = ["barcode-hit"]

    if dispatch.should_schedule_live_text_search("barcode_fill"):
        raise SystemExit("FAIL: barcode_fill must not schedule live text search")
    if not dispatch.should_schedule_live_text_search("user_typing"):
        raise SystemExit("FAIL: user typing must still schedule live text search")

    barcode_token = dispatch.begin()
    # A live text search that started after a barcode fill (the old bug).
    stale_text_token = dispatch.begin()

    # Barcode response arrives later; it must be ignored because text started after it.
    if dispatch.is_current(barcode_token):
        results = ["barcode-hit"]
        raise SystemExit("FAIL: older barcode token should not still be current after a newer search began")

    # Correct ordering: barcode search begins last and stale text cannot clobber it.
    dispatch = FoodSearchDispatch()
    results = []
    text_token = dispatch.begin()
    barcode_token = dispatch.begin()
    if dispatch.is_current(text_token):
        results = []
        raise SystemExit("FAIL: stale text search wrote after barcode search began")
    if dispatch.is_current(barcode_token):
        results = ["barcode-hit"]
    if results != ["barcode-hit"]:
        raise SystemExit("FAIL: barcode result was lost")


def main() -> int:
    check_add_meal_suppresses_barcode_live_search()
    check_view_model_has_generation_guard()
    simulate_barcode_then_stale_text()
    print("OK: barcode scans do not schedule competing text search; stale writes are ignored")
    return 0


if __name__ == "__main__":
    sys.exit(main())
