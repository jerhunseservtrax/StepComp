#!/usr/bin/env python3
"""Regression check: Total/Per Side toggle must not reinterpret an uncommitted weight.

Trigger:
  1. Start a workout on an exercise that shows Total / Per Side.
  2. Tap a set weight field. activateField() resets editBuffer to "".
  3. Type a weight (for example 50) meaning the CURRENT mode (Total).
  4. Before Done, tap Per Side in the exercise header.
  5. Tap Done / checkmark / dismiss.

Bug: updateExerciseWeightInputMode() converted already-persisted weights only.
The still-open editBuffer was later committed under the NEW mode, so 50 Total
became 50 Per Side (100 kg effective volume). The reverse halved the load.

Correct policy: commit a valid pending buffer under the current mode, convert
that stored value into the new mode, then dismiss the editor so Done cannot
re-write the old digits under the new mode. An empty buffer must not wipe the
auto-populated weight (same rule as empty-dismiss).
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ACTIVE_WORKOUT = ROOT / "StepComp" / "Screens" / "Workouts" / "ActiveWorkoutView.swift"
VIEW_MODEL = ROOT / "StepComp" / "ViewModels" / "WorkoutViewModel.swift"

PER_SIDE_MULTIPLIER = 2.0


def extract_swift_func(source: str, name: str) -> str:
    marker = f"func {name}("
    start = source.find(marker)
    if start < 0:
        raise SystemExit(f"FAIL: {name}() not found in source")
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


def convert_storage_weight(weight: float | None, from_mode: str, to_mode: str) -> float | None:
    if weight is None:
        return None
    if from_mode == to_mode:
        return weight
    if from_mode == "total" and to_mode == "perSide":
        return weight / PER_SIDE_MULTIPLIER
    if from_mode == "perSide" and to_mode == "total":
        return weight * PER_SIDE_MULTIPLIER
    return weight


def apply_mode_change(
    stored_kg: float | None,
    current_mode: str,
    new_mode: str,
    pending_kg: float | None,
) -> float | None:
    """Commit pending digits under the current mode, then convert."""
    source = pending_kg if pending_kg is not None else stored_kg
    return convert_storage_weight(source, current_mode, new_mode)


def effective_volume_kg(stored_kg: float | None, mode: str) -> float | None:
    if stored_kg is None:
        return None
    return stored_kg * PER_SIDE_MULTIPLIER if mode == "perSide" else stored_kg


def simulate_toggle_policy() -> None:
    # Type 50 as Total, then switch to Per Side: keep 50 kg total load.
    stored = apply_mode_change(50.0, "total", "perSide", 50.0)
    if stored != 25.0:
        raise SystemExit(f"FAIL: 50 Total then Per Side must store 25 per side, got {stored}")
    if effective_volume_kg(stored, "perSide") != 50.0:
        raise SystemExit("FAIL: 50 Total then Per Side must keep 50 kg effective volume")

    # Type 25 as Per Side, then switch to Total: keep 50 kg total load.
    stored = apply_mode_change(25.0, "perSide", "total", 25.0)
    if stored != 50.0:
        raise SystemExit(f"FAIL: 25 Per Side then Total must store 50 total, got {stored}")
    if effective_volume_kg(stored, "total") != 50.0:
        raise SystemExit("FAIL: 25 Per Side then Total must keep 50 kg effective volume")

    # Empty buffer: convert the already-populated last-session weight only.
    stored = apply_mode_change(50.0, "total", "perSide", None)
    if stored != 25.0:
        raise SystemExit("FAIL: empty buffer must convert the persisted weight, not wipe it")

    # Buggy convert-then-commit path (what the UI used to do) doubles volume.
    buggy_stored = 50.0  # pending digits written after mode is already perSide
    if effective_volume_kg(buggy_stored, "perSide") != 100.0:
        raise SystemExit("FAIL: sanity check of the 2x corruption scenario")


def check_mode_button_commits_then_dismisses() -> None:
    source = ACTIVE_WORKOUT.read_text()
    body = extract_swift_func(source, "exerciseModeButton")

    if "updateExerciseWeightInputMode" not in body and "applyExerciseWeightInputMode" not in body:
        raise SystemExit(
            "FAIL: exerciseModeButton() must still change the exercise weight input mode."
        )

    commits_pending = (
        "commitActive" in body
        or "commitPending" in body
        or "applyExerciseWeightInputMode" in body
    )
    if not commits_pending:
        raise SystemExit(
            "FAIL: exerciseModeButton() toggles mode without committing the open number-pad "
            "buffer under the current mode. Typing 50 Total then tapping Per Side stores 50 "
            "as per-side (2x volume) when Done is pressed."
        )

    apply_source = source
    if "func applyExerciseWeightInputMode" in source:
        apply_source = extract_swift_func(source, "applyExerciseWeightInputMode")
    elif "func commitActive" in source:
        apply_source = body

    dismisses_editor = (
        "activeField = nil" in apply_source
        or "activeField = nil" in body
        or "dismissActive" in apply_source
        or "dismissActive" in body
    )
    if not dismisses_editor:
        raise SystemExit(
            "FAIL: after a Total/Per Side toggle the number pad must be dismissed. "
            "Leaving editBuffer as the old digits lets Done commit them under the new mode."
        )

    combined = body + apply_source
    if re.search(r"weight:\s*nil", combined):
        raise SystemExit(
            "FAIL: mode toggle must not write weight: nil for an empty editBuffer."
        )


def check_view_model_converts_after_pending_commit() -> None:
    source = VIEW_MODEL.read_text()
    body = extract_swift_func(source, "updateExerciseWeightInputMode")
    if "perSide" not in body or "multiplier" not in body:
        raise SystemExit(
            "FAIL: updateExerciseWeightInputMode() must still convert persisted weights."
        )


def main() -> int:
    simulate_toggle_policy()
    check_mode_button_commits_then_dismisses()
    check_view_model_converts_after_pending_commit()
    print("OK: Total/Per Side toggle commits pending weight under the old mode")
    return 0


if __name__ == "__main__":
    sys.exit(main())
