//
//  WorkoutViewModelSessionTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

@MainActor
final class WorkoutViewModelSessionTests: XCTestCase {
    func testClearAllActiveWorkoutStateClearsInMemorySession() {
        let viewModel = WorkoutViewModel.shared
        viewModel.cancelWorkout()
        defer { viewModel.cancelWorkout() }

        let workout = makeWorkout(name: "Owner A Workout")
        XCTAssertTrue(viewModel.startWorkout(workout))
        XCTAssertNotNil(viewModel.currentSession)

        WorkoutViewModel.clearAllActiveWorkoutState()

        XCTAssertNil(viewModel.currentSession)
        XCTAssertNil(viewModel.sessionStartTime)
        XCTAssertEqual(viewModel.elapsedTime, 0)
        XCTAssertFalse(viewModel.isPaused)
        XCTAssertFalse(viewModel.isAutoFinishing)
    }

    func testStartWorkoutDoesNotOverwriteExistingActiveSession() {
        let viewModel = WorkoutViewModel.shared
        viewModel.cancelWorkout()
        defer { viewModel.cancelWorkout() }

        let firstWorkout = makeWorkout(name: "In Progress")
        let secondWorkout = makeWorkout(name: "Accidental Tap")

        XCTAssertTrue(viewModel.startWorkout(firstWorkout))
        let originalSessionId = viewModel.currentSession?.id

        XCTAssertFalse(viewModel.startWorkout(secondWorkout))

        XCTAssertEqual(viewModel.currentSession?.id, originalSessionId)
        XCTAssertEqual(viewModel.currentSession?.workoutName, "In Progress")
    }

    private func makeWorkout(name: String) -> Workout {
        Workout(
            name: name,
            exercises: [
                WorkoutExercise(
                    exercise: Exercise(name: "Bench Press", targetMuscles: "Chest"),
                    sets: [WorkoutSet(setNumber: 1, weight: 100, reps: 5)]
                )
            ],
            assignedDays: []
        )
    }
}
