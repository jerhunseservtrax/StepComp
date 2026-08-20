#!/usr/bin/env python3
"""Regression checks for stale-workout silent auto-finish.

Draft persistence (6b21b36) restores in-progress sessions after kill/background.
The 1s timer then treated wall-clock time minus explicit pauses as "active"
duration and called finishWorkout() at 6 hours — including overnight sleep.

Concrete trigger:
  1. Start a workout at 8:00 PM and log a few sets (do not pause).
  2. Lock or force-quit the phone.
  3. Reopen the app after 6+ hours.
  4. Draft restore restarts the timer; the next tick silently finishes and
     syncs a partial session with an inflated duration.

Expected behavior:
  Pause the stale session once so the user can resume or finish manually.
  Never persist/sync a completed session from the 6-hour guard.

Usage:
  python3 scripts/abandoned_workout_autofinish_regression_check.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POLICY_SWIFT = ROOT / "StepComp/Utilities/AbandonedWorkoutPolicy.swift"
WORKOUT_VM = ROOT / "StepComp/ViewModels/WorkoutViewModel.swift"

THRESHOLD = 6 * 3600


def fail(msg: str) -> None:
    print(f"abandoned-workout-autofinish: FAIL — {msg}", file=sys.stderr)
    sys.exit(1)


def should_auto_pause(
    elapsed: float,
    is_paused: bool,
    already_auto_paused: bool,
    threshold: float = THRESHOLD,
) -> bool:
    return (not is_paused) and (not already_auto_paused) and elapsed >= threshold


def check_algorithm() -> None:
    if should_auto_pause(THRESHOLD, False, False) is not True:
        fail("exactly 6h of wall-clock active time must auto-pause")
    if should_auto_pause(THRESHOLD + 1, False, False) is not True:
        fail("overnight / 6h+ sessions must auto-pause")
    if should_auto_pause(THRESHOLD - 1, False, False) is not False:
        fail("sessions under 6h must keep running")
    if should_auto_pause(12 * 3600, True, False) is not False:
        fail("already-paused sessions must not be re-paused")
    if should_auto_pause(12 * 3600, False, True) is not False:
        fail("explicit resume after auto-pause must be allowed to continue")
    if should_auto_pause(45 * 60, False, False) is not False:
        fail("normal gym session must not trip the stale-session guard")


def extract_function(text: str, name: str) -> str:
    marker = f"func {name}"
    idx = text.find(marker)
    if idx == -1:
        fail(f"WorkoutViewModel missing {name}()")
    body = text[idx:]
    nxt = re.search(r"\n    (func |private func |/// )", body[len(marker) :])
    if nxt:
        body = body[: len(marker) + nxt.start()]
    return body


def check_static() -> None:
    if not POLICY_SWIFT.exists():
        fail(f"missing {POLICY_SWIFT.relative_to(ROOT)}")
    if not WORKOUT_VM.exists():
        fail(f"missing {WORKOUT_VM.relative_to(ROOT)}")

    policy = POLICY_SWIFT.read_text()
    vm = WORKOUT_VM.read_text()

    if "enum AbandonedWorkoutPolicy" not in policy:
        fail("AbandonedWorkoutPolicy.swift missing AbandonedWorkoutPolicy")
    if "6 * 3600" not in policy and "21600" not in policy:
        fail("AbandonedWorkoutPolicy must keep the 6-hour threshold")
    if "shouldAutoPause" not in policy:
        fail("AbandonedWorkoutPolicy missing shouldAutoPause")

    start_timer = extract_function(vm, "startTimer")
    if "finishWorkout()" in start_timer:
        fail("startTimer still silently finishWorkout()s at the 6-hour threshold")
    if "applyStaleSessionGuard" not in start_timer and "shouldAutoPause" not in start_timer:
        fail("startTimer does not consult the stale-session pause guard")

    restore = extract_function(vm, "loadActiveWorkoutDraftIfAny")
    if "finishWorkout()" in restore:
        fail("draft restore still silently finishes stale workouts")
    if "applyStaleSessionGuard" not in restore:
        fail("draft restore must pause stale sessions before restarting the timer")

    reconcile = extract_function(vm, "reconcileActiveWorkoutState")
    if "finishWorkout()" in reconcile:
        fail("lifecycle reconcile still silently finishes stale workouts")
    if "applyStaleSessionGuard" not in reconcile:
        fail("lifecycle reconcile must apply the stale-session pause guard")

    if "didAutoPauseStaleSession" not in vm:
        fail("WorkoutViewModel must one-shot auto-pause so resume can continue")


def main() -> int:
    check_algorithm()
    check_static()
    print("abandoned-workout-autofinish: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
