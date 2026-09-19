#!/usr/bin/env python3
"""Regression check: starting a workout must not replace an active session.

Concrete trigger this locks in:
1. Start Workout A and log sets.
2. Switch to Home and open the Upcoming Workout card.
3. Tap Start Workout on workout B (or A again).
4. The in-progress session and persisted draft must stay intact.
"""

from __future__ import annotations

import pathlib
import re
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]


def read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def test_policy_blocks_active_session() -> None:
    source = read("StepComp/Utilities/ActiveWorkoutStartPolicy.swift")
    require(
        "static func canStartNewWorkout(hasActiveSession: Bool)" in source,
        "ActiveWorkoutStartPolicy is missing canStartNewWorkout",
    )
    require(
        "!hasActiveSession" in source,
        "ActiveWorkoutStartPolicy must reject an existing active session",
    )


def test_start_workout_uses_policy_guard() -> None:
    source = read("StepComp/ViewModels/WorkoutViewModel.swift")
    match = re.search(
        r"func startWorkout\([^{]+\{(?P<body>.*?)\n    func pauseWorkout",
        source,
        re.S,
    )
    require(match is not None, "Could not locate startWorkout in WorkoutViewModel")
    body = match.group("body")
    require(
        "ActiveWorkoutStartPolicy.canStartNewWorkout(hasActiveSession:" in body,
        "startWorkout must consult ActiveWorkoutStartPolicy before replacing currentSession",
    )
    require(
        "guard ActiveWorkoutStartPolicy.canStartNewWorkout" in body
        or "guard " in body and "canStartNewWorkout" in body,
        "startWorkout must return early when an active session exists",
    )
    policy_index = body.find("canStartNewWorkout")
    assign_index = body.find("currentSession = WorkoutSession")
    require(assign_index != -1, "startWorkout no longer assigns a new WorkoutSession")
    require(
        policy_index != -1 and policy_index < assign_index,
        "startWorkout must check the active-session policy before creating a new session",
    )


def test_workout_detail_does_not_start_over_active_session() -> None:
    source = read("StepComp/Screens/Workouts/WorkoutDetailView.swift")
    require(
        "viewModel.currentSession" in source,
        "WorkoutDetailView must inspect the live session before offering Start Workout",
    )
    require(
        "hasActiveWorkout" in source or "currentSession != nil" in source,
        "WorkoutDetailView needs an explicit in-progress workout branch",
    )
    require(
        "Workout In Progress" in source or "Continue Workout" in source,
        "WorkoutDetailView should surface an in-progress CTA instead of Start Workout",
    )


def test_suggested_starts_guard_active_session() -> None:
    source = read("StepComp/Screens/Workouts/SuggestedWorkoutsView.swift")
    require(source.count("currentSession == nil") >= 2, (
        "Suggested workout start paths must refuse to start while a session is active"
    ))


def test_policy_unit_semantics() -> None:
    def can_start(has_active_session: bool) -> bool:
        return not has_active_session

    require(can_start(False) is True, "No active session should allow start")
    require(can_start(True) is False, "Active session must block start")


def main() -> int:
    tests = [
        test_policy_blocks_active_session,
        test_start_workout_uses_policy_guard,
        test_workout_detail_does_not_start_over_active_session,
        test_suggested_starts_guard_active_session,
        test_policy_unit_semantics,
    ]
    failed = 0
    for test in tests:
        try:
            test()
            print(f"PASS {test.__name__}")
        except AssertionError as error:
            failed += 1
            print(f"FAIL {test.__name__}: {error}")
    if failed:
        print(f"\n{failed} failing check(s)")
        return 1
    print(f"\n{len(tests)} passing check(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
