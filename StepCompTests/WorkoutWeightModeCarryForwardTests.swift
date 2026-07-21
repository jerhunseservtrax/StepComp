//
//  WorkoutWeightModeCarryForwardTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

@MainActor
final class WorkoutWeightModeCarryForwardTests: XCTestCase {
    private let viewModel = WorkoutViewModel.shared

    override func setUp() {
        super.setUp()
        viewModel.cancelWorkout()
        viewModel.completedSessions = []
    }

    override func tearDown() {
        viewModel.cancelWorkout()
        viewModel.completedSessions = []
        super.tearDown()
    }

    func testStartWorkoutPreservesHistoricalPerSideMode() {
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
    }

    func testAddSetInheritsExerciseWeightInputMode() {
        let exercise = Exercise(name: "Dumbbell Bench Press", targetMuscles: "Chest")
        let workoutExercise = WorkoutExercise(
            exercise: exercise,
            sets: [
                WorkoutSet(
                    setNumber: 1,
                    weight: 30,
                    reps: 8,
                    weightInputMode: .perSide
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
        XCTAssertEqual(addedSet?.setNumber, 2)
        XCTAssertEqual(addedSet?.weightInputMode, .perSide)
    }
}
