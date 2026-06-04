//
//  WorkoutViewModelLogoutCleanupTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class WorkoutViewModelLogoutCleanupTests: XCTestCase {
    @MainActor
    func testClearAllActiveWorkoutStateRemovesInMemorySession() {
        WorkoutViewModel.clearAllActiveWorkoutState()
        defer { WorkoutViewModel.clearAllActiveWorkoutState() }

        let workout = Workout(
            name: "Private Session",
            exercises: [
                WorkoutExercise(
                    exercise: Exercise(name: "Bench Press", targetMuscles: "Chest"),
                    sets: [WorkoutSet(setNumber: 1)]
                )
            ],
            assignedDays: [.monday]
        )

        WorkoutViewModel.shared.startWorkout(workout)
        XCTAssertNotNil(WorkoutViewModel.shared.currentSession)

        WorkoutViewModel.clearAllActiveWorkoutState()

        XCTAssertNil(
            WorkoutViewModel.shared.currentSession,
            "Logout cleanup must not leave the previous user's active workout in shared memory."
        )
    }

    @MainActor
    func testClearAllLocalUserStateRemovesWorkoutListsFromMemory() {
        WorkoutViewModel.clearAllLocalUserState()
        defer { WorkoutViewModel.clearAllLocalUserState() }

        let workout = Workout(
            name: "Private Template",
            exercises: [
                WorkoutExercise(
                    exercise: Exercise(name: "Bench Press", targetMuscles: "Chest"),
                    sets: [WorkoutSet(setNumber: 1)]
                )
            ],
            assignedDays: [.monday]
        )

        WorkoutViewModel.shared.addWorkout(workout)
        XCTAssertFalse(WorkoutViewModel.shared.workouts.isEmpty)

        WorkoutViewModel.clearAllLocalUserState()

        XCTAssertTrue(
            WorkoutViewModel.shared.workouts.isEmpty,
            "Logout cleanup must not retain the previous user's workout templates in memory."
        )
    }
}
