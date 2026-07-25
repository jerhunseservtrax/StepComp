#!/usr/bin/env python3
"""
Regression check: editing a completed workout must re-sync to Supabase.

Bug: EditCompletedSessionView.saveChanges() updated local UserDefaults only.
Because MetricsService.syncAllLocalData() skips IDs already marked synced,
edited sets/reps never reached workout_sessions / metrics RPCs.

This script statically verifies the save path still re-syncs.
"""

from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
EDIT_VIEW = ROOT / "StepComp/Screens/Workouts/EditCompletedSessionView.swift"
VIEW_MODEL = ROOT / "StepComp/ViewModels/WorkoutViewModel.swift"


def fail(msg: str) -> None:
    print(f"edited-workout-resync: FAIL — {msg}", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    edit_src = EDIT_VIEW.read_text(encoding="utf-8")
    vm_src = VIEW_MODEL.read_text(encoding="utf-8")

    save_match = re.search(
        r"private func saveChanges\(\)\s*\{(?P<body>.*?)\n    \}",
        edit_src,
        flags=re.DOTALL,
    )
    if not save_match:
        fail("could not locate EditCompletedSessionView.saveChanges()")

    save_body = save_match.group("body")

    # Must not only mutate completedSessions + saveCompletedSessions without sync.
    if "updateCompletedSession" not in save_body and "syncWorkoutSession" not in save_body:
        fail(
            "saveChanges() does not re-sync the edited session "
            "(expected updateCompletedSession(...) or syncWorkoutSession(...))"
        )

    # Prefer the ViewModel helper so future edit call sites stay consistent.
    if "func updateCompletedSession" not in vm_src:
        fail("WorkoutViewModel.updateCompletedSession(_:) is missing")

    helper_match = re.search(
        r"func updateCompletedSession\([^\)]*\)\s*\{(?P<body>.*?)\n    \}",
        vm_src,
        flags=re.DOTALL,
    )
    if not helper_match:
        fail("could not parse WorkoutViewModel.updateCompletedSession(_:) body")

    helper_body = helper_match.group("body")
    if "saveCompletedSessions" not in helper_body:
        fail("updateCompletedSession must persist local completed sessions")
    if "syncWorkoutSession" not in helper_body:
        fail("updateCompletedSession must call MetricsService.syncWorkoutSession")

    print("edited-workout-resync: ok")


if __name__ == "__main__":
    main()
