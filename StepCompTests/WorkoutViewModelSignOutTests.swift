//
//  WorkoutViewModelSignOutTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

@MainActor
final class WorkoutViewModelSignOutTests: XCTestCase {
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

    func testClearAllActiveWorkoutStateClearsInMemorySessionAndPreventsDraftResurrection() {
        let viewModel = WorkoutViewModel.shared
        viewModel.finishedSession = nil
        let completedSessionCount = viewModel.completedSessions.count

        let workout = Workout(
            name: "Sign Out Regression",
            exercises: [
                WorkoutExercise(
                    exercise: Exercise(name: "Bench Press", targetMuscles: "Chest"),
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
        XCTAssertNil(viewModel.workoutTargetDate)
        XCTAssertFalse(viewModel.isPaused)
        XCTAssertNil(viewModel.finishedSession)
        XCTAssertEqual(viewModel.completedSessions.count, completedSessionCount)
        XCTAssertNil(UserDefaults.standard.data(forKey: "active_workout_draft"))

        viewModel.reconcileActiveWorkoutState()

        XCTAssertNil(viewModel.currentSession)
        XCTAssertNil(UserDefaults.standard.data(forKey: "active_workout_draft"))
    }
}
