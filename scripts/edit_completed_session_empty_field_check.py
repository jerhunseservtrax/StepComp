#!/usr/bin/env python3
"""Regression check: editing a completed session must not wipe set data.

Trigger:
1. User opens a completed workout and taps Edit.
2. They tap a weight or reps field (tap-to-clear empties the display).
3. They tap the other field, or tap Save without retyping (iOS decimalPad
   has no Done key).

Bug: onTapGesture set displayWeight/displayReps to "". onChange then wrote
set.weight = nil or set.reps = Int("") == nil into editedExercises. Save
persisted that wipe into completed history.

This script:
1. Locks the commit policy (empty/invalid display keeps the stored value).
2. Asserts EditCompletedSessionView no longer nils history on empty text.
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VIEW = ROOT / "StepComp/Screens/Workouts/EditCompletedSessionView.swift"


def committed_weight_kg(display: str, existing_kg: float | None) -> float | None:
    """Mirrors the intended EditSetRow weight onChange policy (identity storage)."""
    try:
        display_val = float(display)
    except ValueError:
        return existing_kg
    if display_val > 0:
        return display_val
    return existing_kg


def committed_reps(display: str, existing: int | None) -> int | None:
    """Mirrors the intended EditSetRow reps onChange policy."""
    if display.isdigit() or (display.startswith("-") and display[1:].isdigit()):
        reps = int(display)
        if reps > 0:
            return reps
    return existing


def simulate_tap_then_save_keeps_values() -> None:
    if committed_weight_kg("", 80.0) != 80.0:
        raise SystemExit("FAIL: empty weight display must keep the stored kg value")
    if committed_weight_kg("   ", 80.0) != 80.0:
        raise SystemExit("FAIL: invalid weight display must keep the stored kg value")
    if committed_weight_kg("0", 80.0) != 80.0:
        raise SystemExit("FAIL: zero weight display must keep the stored kg value")
    if committed_weight_kg("82.5", 80.0) != 82.5:
        raise SystemExit("FAIL: positive weight display must replace the stored value")
    if committed_weight_kg("", None) is not None:
        raise SystemExit("FAIL: empty weight display with no stored value stays nil")

    if committed_reps("", 8) != 8:
        raise SystemExit("FAIL: empty reps display must keep the stored reps")
    if committed_reps("abc", 8) != 8:
        raise SystemExit("FAIL: invalid reps display must keep the stored reps")
    if committed_reps("0", 8) != 8:
        raise SystemExit("FAIL: zero reps display must keep the stored reps")
    if committed_reps("10", 8) != 10:
        raise SystemExit("FAIL: positive reps display must replace the stored value")
    if committed_reps("", None) is not None:
        raise SystemExit("FAIL: empty reps display with no stored value stays nil")


def assert_view_does_not_nil_on_empty() -> None:
    source = VIEW.read_text()

    if re.search(r"set\.weight\s*=\s*nil", source):
        raise SystemExit(
            "FAIL: EditCompletedSessionView still writes set.weight = nil "
            "from an empty display (tap-then-Save wipes history)"
        )

    # Int("") is nil; assigning that on every keystroke wipes reps on tap-to-clear.
    if re.search(r"set\.reps\s*=\s*Int\(newValue\)", source):
        raise SystemExit(
            "FAIL: EditCompletedSessionView still assigns set.reps = Int(newValue), "
            "which is nil for the empty tap-to-clear display"
        )

    if "if let display = Double(newValue), display > 0" not in source:
        raise SystemExit(
            "FAIL: weight onChange must apply a value only for a positive parsed display"
        )

    if "if let reps = Int(newValue), reps > 0" not in source:
        raise SystemExit(
            "FAIL: reps onChange must apply a value only for a positive parsed display"
        )


def main() -> None:
    if not VIEW.is_file():
        raise SystemExit(f"FAIL: missing {VIEW}")
    simulate_tap_then_save_keeps_values()
    assert_view_does_not_nil_on_empty()
    print("PASS: completed-session edit no longer wipes weight/reps on empty display")


if __name__ == "__main__":
    main()
