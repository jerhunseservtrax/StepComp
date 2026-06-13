//
//  WorkoutViewModelStateTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

@MainActor
final class WorkoutViewModelStateTests: XCTestCase {
    func testStartWorkoutDoesNotOverwriteExistingActiveSession() {
        let viewModel = resetSharedViewModel()
        defer { viewModel.cancelWorkout() }

        let firstWorkout = makeWorkout(name: "Push")
        let secondWorkout = makeWorkout(name: "Pull")

        viewModel.startWorkout(firstWorkout)
        let originalSessionId = viewModel.currentSession?.id

        viewModel.startWorkout(secondWorkout)

        XCTAssertEqual(viewModel.currentSession?.id, originalSessionId)
        XCTAssertEqual(viewModel.currentSession?.workoutId, firstWorkout.id)
        XCTAssertEqual(viewModel.currentSession?.workoutName, "Push")
    }

    func testClearAllActiveWorkoutStateClearsInMemorySession() {
        let viewModel = resetSharedViewModel()
        defer { viewModel.cancelWorkout() }

        viewModel.startWorkout(makeWorkout(name: "Legs"))
        XCTAssertNotNil(viewModel.currentSession)

        WorkoutViewModel.clearAllActiveWorkoutState()

        XCTAssertNil(viewModel.currentSession)
        XCTAssertNil(viewModel.sessionStartTime)
        XCTAssertFalse(viewModel.isPaused)
        XCTAssertEqual(viewModel.elapsedTime, 0)
    }

    private func resetSharedViewModel() -> WorkoutViewModel {
        let viewModel = WorkoutViewModel.shared
        viewModel.cancelWorkout()
        return viewModel
    }

    private func makeWorkout(name: String) -> Workout {
        Workout(
            name: name,
            exercises: [
                WorkoutExercise(
                    exercise: Exercise(name: "\(name) Exercise", targetMuscles: "Test"),
                    sets: [WorkoutSet(setNumber: 1)]
                )
            ],
            assignedDays: [.monday]
        )
    }
}
