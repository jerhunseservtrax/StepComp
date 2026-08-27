#!/usr/bin/env python3
"""Regression check: dismissing the workout number pad must not wipe set data.

Trigger:
  1. Start a workout (sets are auto-populated from the last session).
  2. Tap a weight or reps field. activateField() resets editBuffer to "".
  3. Tap Done, tap the scroll padding, or trigger auto-finish without typing.

Bug: commitAndDismiss() → commitValue() treated an empty buffer as an explicit
clear and wrote weight/reps = nil into the draft. commitCurrentField() already
keeps the existing value when the buffer is empty; dismiss must match that.

This script:
1. Locks the commit policy (empty/invalid buffer keeps the stored value).
2. Asserts ActiveWorkoutView.commitValue no longer nils out on empty text.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ACTIVE_WORKOUT = ROOT / "StepComp" / "Screens" / "Workouts" / "ActiveWorkoutView.swift"


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


def committed_weight_kg(buffer: str, existing_kg: float | None) -> float | None:
    """Mirrors the intended commitValue weight policy (identity storage)."""
    try:
        display_val = float(buffer)
    except ValueError:
        return existing_kg
    if display_val > 0:
        return display_val
    return existing_kg


def committed_reps(buffer: str, existing: int | None) -> int | None:
    """Mirrors the intended commitValue reps policy."""
    if buffer.isdigit() or (buffer.startswith("-") and buffer[1:].isdigit()):
        reps = int(buffer)
        if reps > 0:
            return reps
    return existing


def simulate_empty_dismiss_keeps_values() -> None:
    if committed_weight_kg("", 80.0) != 80.0:
        raise SystemExit("FAIL: empty weight buffer must keep the stored kg value")
    if committed_weight_kg("   ", 80.0) != 80.0:
        raise SystemExit("FAIL: invalid weight buffer must keep the stored kg value")
    if committed_weight_kg("0", 80.0) != 80.0:
        raise SystemExit("FAIL: zero weight buffer must keep the stored kg value")
    if committed_weight_kg("185", 80.0) != 185.0:
        raise SystemExit("FAIL: positive weight buffer must replace the stored value")
    if committed_weight_kg("", None) is not None:
        raise SystemExit("FAIL: empty weight buffer with no stored value stays nil")

    if committed_reps("", 8) != 8:
        raise SystemExit("FAIL: empty reps buffer must keep the stored reps")
    if committed_reps("12", 8) != 12:
        raise SystemExit("FAIL: positive reps buffer must replace the stored reps")
    if committed_reps("", None) is not None:
        raise SystemExit("FAIL: empty reps buffer with no stored value stays nil")


def check_commit_value_does_not_nil_on_empty() -> None:
    source = ACTIVE_WORKOUT.read_text()
    body = extract_swift_func(source, "commitValue")

    empty_weight_clear = re.search(
        r"text\.isEmpty[\s\S]{0,160}weight:\s*nil",
        body,
    )
    empty_reps_clear = re.search(
        r"text\.isEmpty[\s\S]{0,160}reps:\s*nil",
        body,
    )
    if empty_weight_clear:
        raise SystemExit(
            "FAIL: commitValue() writes weight: nil when the number-pad buffer is empty. "
            "activateField() starts with editBuffer == \"\", so Done / scroll-dismiss / "
            "auto-finish wipes an already-populated set weight."
        )
    if empty_reps_clear:
        raise SystemExit(
            "FAIL: commitValue() writes reps: nil when the number-pad buffer is empty. "
            "Dismissing without typing must keep the auto-populated reps."
        )

    current_field = extract_swift_func(source, "commitCurrentField")
    if re.search(r"weight:\s*nil|reps:\s*nil", current_field):
        raise SystemExit(
            "FAIL: commitCurrentField() must keep existing values when the buffer is empty."
        )


def main() -> int:
    simulate_empty_dismiss_keeps_values()
    check_commit_value_does_not_nil_on_empty()
    print("OK: empty number-pad dismiss keeps stored weight/reps")
    return 0


if __name__ == "__main__":
    sys.exit(main())
