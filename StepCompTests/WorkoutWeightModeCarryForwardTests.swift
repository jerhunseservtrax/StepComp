//
//  WorkoutWeightModeCarryForwardTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class WorkoutWeightModeCarryForwardTests: XCTestCase {
    @MainActor
    func testStartWorkoutPreservesHistoricalPerSideMode() {
        let viewModel = WorkoutViewModel.shared
        viewModel.cancelWorkout()
        viewModel.completedSessions = []
        defer {
            viewModel.cancelWorkout()
            viewModel.completedSessions = []
        }

        let workoutId = UUID()
        let exercise = Exercise(name: "Dumbbell Bench Press", targetMuscles: "Chest")
        let historicalSet = WorkoutSet(
            setNumber: 1,
            weight: 30,
            reps: 8,
            isCompleted: true,
            weightInputMode: .perSide
        )
        let historicalExercise = WorkoutExercise(exercise: exercise, sets: [historicalSet])
        viewModel.completedSessions = [
            CompletedWorkoutSession(
                workoutId: workoutId,
                workoutName: "Push",
                startTime: Date().addingTimeInterval(-3600),
                endTime: Date(),
                exercises: [historicalExercise]
            )
        ]
        let workout = Workout(
            id: workoutId,
            name: "Push",
            exercises: [
                WorkoutExercise(
                    exercise: exercise,
                    sets: [WorkoutSet(setNumber: 1)]
                )
            ],
            assignedDays: []
        )

        viewModel.startWorkout(workout)

        let carriedSet = viewModel.currentSession?.exercises.first?.sets.first
        XCTAssertEqual(carriedSet?.weight, 30)
        XCTAssertEqual(carriedSet?.weightInputMode, .perSide)
        XCTAssertEqual(carriedSet?.effectiveWeightForVolume, 60)
        XCTAssertEqual(carriedSet?.suggestedWeight, 30)
    }

    @MainActor
    func testAddSetInheritsExerciseWeightInputMode() {
        let viewModel = WorkoutViewModel.shared
        viewModel.cancelWorkout()
        defer { viewModel.cancelWorkout() }

        let exercise = Exercise(name: "Dumbbell Bench Press", targetMuscles: "Chest")
        let workoutExercise = WorkoutExercise(
            exercise: exercise,
            sets: [
                WorkoutSet(
                    setNumber: 1,
                    weight: 30,
                    reps: 8,
                    weightInputMode: .perSide
                ),
                WorkoutSet(
                    setNumber: 2,
                    weight: 60,
                    reps: 8,
                    weightInputMode: .total
                )
            ]
        )
        viewModel.currentSession = WorkoutSession(
            workoutId: UUID(),
            workoutName: "Push",
            exercises: [workoutExercise]
        )

        viewModel.addSet(exerciseId: workoutExercise.id)

        let addedSet = viewModel.currentSession?.exercises.first?.sets.last
        XCTAssertEqual(addedSet?.setNumber, 3)
        XCTAssertEqual(addedSet?.weightInputMode, .perSide)
    }
}
