#!/usr/bin/env python3
"""Regression check: empty / unchecked finish must not lock a workout for the day.

Mirrors WorkoutCompletionPolicy and scans WorkoutViewModel for the wiring.
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
POLICY_SWIFT = REPO / "StepComp/Utilities/WorkoutCompletionPolicy.swift"
VIEW_MODEL_SWIFT = REPO / "StepComp/ViewModels/WorkoutViewModel.swift"


@dataclass
class WorkoutSet:
    is_completed: bool = False


@dataclass
class WorkoutExercise:
    sets: list[WorkoutSet] = field(default_factory=list)


@dataclass
class CompletedSession:
    workout_id: str
    workout_name: str
    end_time: datetime
    exercises: list[WorkoutExercise]


@dataclass
class Workout:
    workout_id: str
    name: str


def has_completed_work(exercises: list[WorkoutExercise]) -> bool:
    return any(s.is_completed for ex in exercises for s in ex.sets)


def session_completes_workout(
    session: CompletedSession,
    workout: Workout,
    on_day: date,
) -> bool:
    if not has_completed_work(session.exercises):
        return False
    same_day = session.end_time.date() == on_day
    same_workout = (
        session.workout_id == workout.workout_id or session.workout_name == workout.name
    )
    return same_day and same_workout


def was_workout_completed(
    workout: Workout,
    on_day: date,
    sessions: list[CompletedSession],
) -> bool:
    return any(session_completes_workout(s, workout, on_day) for s in sessions)


def assert_true(condition: bool, message: str) -> bool:
    if not condition:
        print(f"FAIL: {message}", file=sys.stderr)
        return False
    return True


def run_policy_suite() -> bool:
    today = date(2026, 9, 11)
    noon = datetime(2026, 9, 11, 12, 0, 0)
    push = Workout(workout_id="push", name="Push Day")

    empty = CompletedSession(
        workout_id="push",
        workout_name="Push Day",
        end_time=noon,
        exercises=[WorkoutExercise(sets=[WorkoutSet(is_completed=False)] * 3)],
    )
    unchecked_with_weight = CompletedSession(
        workout_id="push",
        workout_name="Push Day",
        end_time=noon,
        exercises=[WorkoutExercise(sets=[WorkoutSet(is_completed=False)])],
    )
    real = CompletedSession(
        workout_id="push",
        workout_name="Push Day",
        end_time=noon,
        exercises=[WorkoutExercise(sets=[WorkoutSet(is_completed=True)])],
    )
    other_day = CompletedSession(
        workout_id="push",
        workout_name="Push Day",
        end_time=noon - timedelta(days=1),
        exercises=[WorkoutExercise(sets=[WorkoutSet(is_completed=True)])],
    )
    other_workout = CompletedSession(
        workout_id="pull",
        workout_name="Pull Day",
        end_time=noon,
        exercises=[WorkoutExercise(sets=[WorkoutSet(is_completed=True)])],
    )
    name_only_match = CompletedSession(
        workout_id="legacy",
        workout_name="Push Day",
        end_time=noon,
        exercises=[WorkoutExercise(sets=[WorkoutSet(is_completed=True)])],
    )

    passed = True
    passed = assert_true(
        not was_workout_completed(push, today, [empty]),
        "Empty finish (0 completed sets) must not lock the day",
    ) and passed
    passed = assert_true(
        not was_workout_completed(push, today, [unchecked_with_weight]),
        "Unchecked sets must not lock the day",
    ) and passed
    passed = assert_true(
        was_workout_completed(push, today, [real]),
        "A session with a completed set must lock the day",
    ) and passed
    passed = assert_true(
        not was_workout_completed(push, today, [other_day]),
        "Yesterday's completed session must not lock today",
    ) and passed
    passed = assert_true(
        not was_workout_completed(push, today, [other_workout]),
        "A different workout must not lock Push Day",
    ) and passed
    passed = assert_true(
        was_workout_completed(push, today, [name_only_match]),
        "Name fallback must still count a real completed session",
    ) and passed
    passed = assert_true(
        was_workout_completed(push, today, [empty, real]),
        "A later real session must still lock even if an empty one exists",
    ) and passed
    return passed


def run_source_wiring_suite() -> bool:
    policy = POLICY_SWIFT.read_text()
    view_model = VIEW_MODEL_SWIFT.read_text()

    passed = True
    passed = assert_true(
        POLICY_SWIFT.exists(),
        f"Missing {POLICY_SWIFT}",
    ) and passed
    passed = assert_true(
        "enum WorkoutCompletionPolicy" in policy,
        "Policy type must exist",
    ) and passed
    passed = assert_true(
        "static func hasCompletedWork" in policy,
        "Policy must expose hasCompletedWork",
    ) and passed
    passed = assert_true(
        "sets.contains(where: \\.isCompleted)" in policy
        or "sets.contains { $0.isCompleted }" in policy,
        "Policy must require at least one isCompleted set",
    ) and passed
    passed = assert_true(
        "WorkoutCompletionPolicy.sessionCompletesWorkout" in view_model,
        "wasWorkoutCompleted must delegate to WorkoutCompletionPolicy",
    ) and passed
    passed = assert_true(
        "WorkoutCompletionPolicy.hasCompletedWork" in view_model,
        "Weekly progress must ignore sessions with no completed sets",
    ) and passed

    stale = re.search(
        r"func wasWorkoutCompleted.*?return completedSessions.contains",
        view_model,
        flags=re.S,
    )
    passed = assert_true(
        stale is None,
        "wasWorkoutCompleted must not use the old any-session lockout",
    ) and passed
    return passed


def main() -> int:
    ok = run_policy_suite() and run_source_wiring_suite()
    if ok:
        print("Empty-finish day-lockout regression suite passed.")
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
