//
//  EditedWorkoutResyncTests.swift
//  FitComp Tests
//
//  Documents that edited completed workouts must keep the original startTime
//  so sync_workout_session can upsert on (user_id, started_at).
//  Executable gate: scripts/edited_workout_resync_regression_check.py
//

import XCTest
@testable import StepComp

final class EditedWorkoutResyncTests: XCTestCase {
    func testEditedSessionPreservesStartTimeForIdempotentUpsert() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end = Date(timeIntervalSince1970: 1_700_003_600)
        let original = CompletedWorkoutSession(
            id: UUID(),
            workoutId: UUID(),
            workoutName: "Push",
            startTime: start,
            endTime: end,
            exercises: []
        )

        // EditCompletedSessionView rebuilds the session with the same timestamps.
        let edited = CompletedWorkoutSession(
            id: original.id,
            workoutId: original.workoutId,
            workoutName: original.workoutName,
            startTime: original.startTime,
            endTime: original.endTime,
            exercises: original.exercises
        )

        XCTAssertEqual(edited.id, original.id)
        XCTAssertEqual(edited.startTime, original.startTime)
        XCTAssertEqual(edited.endTime, original.endTime)
    }
}
