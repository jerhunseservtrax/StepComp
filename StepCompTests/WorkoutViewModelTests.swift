//
//  WorkoutViewModelTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class WorkoutViewModelTests: XCTestCase {
    override func tearDown() async throws {
        await MainActor.run {
            WorkoutViewModel.clearAllActiveWorkoutState()
        }
        try await super.tearDown()
    }

    @MainActor
    func testClearAllActiveWorkoutStateClearsInMemorySession() {
        let viewModel = WorkoutViewModel.shared
        let workout = makeWorkout()

        viewModel.startWorkout(workout)
        XCTAssertNotNil(viewModel.currentSession)

        WorkoutViewModel.clearAllActiveWorkoutState()

        XCTAssertNil(viewModel.currentSession)
        XCTAssertNil(viewModel.sessionStartTime)
        XCTAssertEqual(viewModel.elapsedTime, 0)
        XCTAssertFalse(viewModel.isPaused)
        XCTAssertNil(viewModel.workoutTargetDate)
        XCTAssertFalse(viewModel.isAutoFinishing)
    }

    func testWeightMigrationConvertsSessionWeightsFromPoundsToKilograms() {
        let session = WorkoutSession(
            workoutId: UUID(),
            workoutName: "Upper",
            exercises: [
                WorkoutExercise(
                    exercise: Exercise(name: "Bench Press", targetMuscles: "Chest"),
                    sets: [
                        WorkoutSet(
                            setNumber: 1,
                            previousWeight: 110.231,
                            weight: 220.462,
                            suggestedWeight: 242.5082,
                            isCompleted: true
                        )
                    ]
                )
            ]
        )

        let result = WorkoutWeightStorageMigration.sessionByConvertingPoundsToKilograms(session)
        let migratedSet = result.session.exercises[0].sets[0]

        XCTAssertTrue(result.didMigrate)
        XCTAssertEqual(migratedSet.previousWeight ?? 0, 50, accuracy: 0.001)
        XCTAssertEqual(migratedSet.weight ?? 0, 100, accuracy: 0.001)
        XCTAssertEqual(migratedSet.suggestedWeight ?? 0, 110, accuracy: 0.001)
    }

    func testWeightMigrationOnlyRunsForImperialLegacyStorage() {
        XCTAssertTrue(WorkoutWeightStorageMigration.shouldMigrate(unitSystem: .imperial))
        XCTAssertFalse(WorkoutWeightStorageMigration.shouldMigrate(unitSystem: .metric))
    }

    private func makeWorkout() -> Workout {
        Workout(
            name: "Upper",
            exercises: [
                WorkoutExercise(
                    exercise: Exercise(name: "Bench Press", targetMuscles: "Chest"),
                    sets: [WorkoutSet(setNumber: 1)]
                )
            ],
            assignedDays: [.monday]
        )
    }
}
