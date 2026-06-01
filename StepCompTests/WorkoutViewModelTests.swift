//
//  WorkoutViewModelTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

@MainActor
final class WorkoutViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        WorkoutViewModel.clearAllActiveWorkoutState()
        UserDefaults.standard.removeObject(forKey: "active_workout_draft")
    }

    override func tearDown() {
        WorkoutViewModel.clearAllActiveWorkoutState()
        UserDefaults.standard.removeObject(forKey: "active_workout_draft")
        super.tearDown()
    }

    func testClearAllActiveWorkoutStateCancelsInMemorySession() {
        let viewModel = WorkoutViewModel.shared
        let exercise = Exercise(name: "Bench Press", targetMuscles: "Chest")
        let workout = Workout(
            name: "Regression Workout",
            exercises: [
                WorkoutExercise(
                    exercise: exercise,
                    sets: [WorkoutSet(setNumber: 1, weight: 100, reps: 5)]
                )
            ],
            assignedDays: [.monday]
        )

        viewModel.startWorkout(workout)
        XCTAssertNotNil(viewModel.currentSession)
        XCTAssertNotNil(UserDefaults.standard.data(forKey: "active_workout_draft"))

        WorkoutViewModel.clearAllActiveWorkoutState()

        XCTAssertNil(viewModel.currentSession)
        XCTAssertNil(viewModel.sessionStartTime)
        XCTAssertEqual(viewModel.elapsedTime, 0)
        XCTAssertFalse(viewModel.isPaused)
        XCTAssertNil(UserDefaults.standard.data(forKey: "active_workout_draft"))
    }
}
