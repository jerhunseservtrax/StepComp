//
//  WorkoutViewModelDataSafetyTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

@MainActor
final class WorkoutViewModelDataSafetyTests: XCTestCase {
    private let persistedWorkoutKeys = [
        "saved_workouts",
        "completed_workout_sessions",
        "active_workout_draft",
        "weights_migrated_to_kg_v1",
        "set_weight_mode_per_side_backfill_v1"
    ]

    func testLaunchPreservesKgStoredWeightsAndSignOutCleanupClearsLiveSession() throws {
        for key in persistedWorkoutKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        let workoutId = UUID()
        let exercise = Exercise(name: "Dumbbell Bench Press", targetMuscles: "Chest")
        let storedKgWeight = 40.0
        let completedSession = CompletedWorkoutSession(
            workoutId: workoutId,
            workoutName: "Push",
            startTime: Date(timeIntervalSince1970: 1_000),
            endTime: Date(timeIntervalSince1970: 1_600),
            exercises: [
                WorkoutExercise(
                    exercise: exercise,
                    sets: [
                        WorkoutSet(
                            setNumber: 1,
                            previousWeight: storedKgWeight,
                            previousReps: 8,
                            weight: storedKgWeight,
                            reps: 8,
                            isCompleted: true,
                            suggestedWeight: storedKgWeight
                        )
                    ]
                )
            ]
        )
        let encoded = try JSONEncoder().encode([completedSession])
        UserDefaults.standard.set(encoded, forKey: "completed_workout_sessions")

        let viewModel = WorkoutViewModel.shared

        let restoredSet = try XCTUnwrap(viewModel.completedSessions.first?.exercises.first?.sets.first)
        XCTAssertEqual(try XCTUnwrap(restoredSet.weight), storedKgWeight, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(restoredSet.previousWeight), storedKgWeight, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(restoredSet.suggestedWeight), storedKgWeight, accuracy: 0.001)
        XCTAssertEqual(restoredSet.weightInputMode, .total)
        XCTAssertEqual(try XCTUnwrap(restoredSet.effectiveWeightForVolume), storedKgWeight, accuracy: 0.001)

        let workout = Workout(
            id: workoutId,
            name: "Push",
            exercises: [WorkoutExercise(exercise: exercise, sets: [WorkoutSet(setNumber: 1)])],
            assignedDays: []
        )
        viewModel.startWorkout(workout)
        XCTAssertNotNil(viewModel.currentSession)

        WorkoutViewModel.clearAllActiveWorkoutState()

        XCTAssertNil(viewModel.currentSession)
        XCTAssertNil(viewModel.sessionStartTime)
        XCTAssertEqual(viewModel.elapsedTime, 0)
    }
}
