//
//  WorkoutCompletionPolicyTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class WorkoutCompletionPolicyTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)
    private lazy var today: Date = {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: 11, hour: 12))!
    }()

    func testEmptyFinishDoesNotCountAsCompleted() {
        let workout = makeWorkout(name: "Push Day")
        let session = makeSession(
            workout: workout,
            endTime: today,
            setsCompleted: [false, false, false]
        )

        XCTAssertFalse(
            WorkoutCompletionPolicy.sessionCompletesWorkout(session, workout: workout, on: today, calendar: calendar)
        )
    }

    func testUncheckedSetsDoNotLockTheDay() {
        let workout = makeWorkout(name: "Push Day")
        let session = makeSession(
            workout: workout,
            endTime: today,
            setsCompleted: [false]
        )

        XCTAssertFalse(
            WorkoutCompletionPolicy.hasCompletedWork(exercises: session.exercises)
        )
        XCTAssertFalse(
            WorkoutCompletionPolicy.sessionCompletesWorkout(session, workout: workout, on: today, calendar: calendar)
        )
    }

    func testCompletedSetLocksTheDay() {
        let workout = makeWorkout(name: "Push Day")
        let session = makeSession(
            workout: workout,
            endTime: today,
            setsCompleted: [true]
        )

        XCTAssertTrue(
            WorkoutCompletionPolicy.sessionCompletesWorkout(session, workout: workout, on: today, calendar: calendar)
        )
    }

    func testNameFallbackStillRequiresCompletedSet() {
        let workout = makeWorkout(id: UUID(), name: "Push Day")
        let session = CompletedWorkoutSession(
            workoutId: UUID(),
            workoutName: "Push Day",
            startTime: today.addingTimeInterval(-1800),
            endTime: today,
            exercises: [makeExercise(setsCompleted: [false])]
        )

        XCTAssertFalse(
            WorkoutCompletionPolicy.sessionCompletesWorkout(session, workout: workout, on: today, calendar: calendar)
        )
    }

    private func makeWorkout(id: UUID = UUID(), name: String) -> Workout {
        Workout(id: id, name: name, exercises: [], assignedDays: [.monday])
    }

    private func makeSession(
        workout: Workout,
        endTime: Date,
        setsCompleted: [Bool]
    ) -> CompletedWorkoutSession {
        CompletedWorkoutSession(
            workoutId: workout.id,
            workoutName: workout.name,
            startTime: endTime.addingTimeInterval(-1800),
            endTime: endTime,
            exercises: [makeExercise(setsCompleted: setsCompleted)]
        )
    }

    private func makeExercise(setsCompleted: [Bool]) -> WorkoutExercise {
        let sets = setsCompleted.enumerated().map { index, completed in
            WorkoutSet(setNumber: index + 1, isCompleted: completed)
        }
        return WorkoutExercise(
            exercise: Exercise(name: "Bench Press", targetMuscles: "chest"),
            sets: sets
        )
    }
}
