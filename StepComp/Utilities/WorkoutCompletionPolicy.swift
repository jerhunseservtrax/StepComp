//
//  WorkoutCompletionPolicy.swift
//  FitComp
//
//  A workout only counts as completed for a calendar day when at least one
//  set was explicitly checked off. Finishing with zero completed sets must
//  not hide Start Workout for the rest of the day.
//

import Foundation

enum WorkoutCompletionPolicy {
    static func hasCompletedWork(exercises: [WorkoutExercise]) -> Bool {
        exercises.contains { exercise in
            exercise.sets.contains(where: \.isCompleted)
        }
    }

    static func sessionCompletesWorkout(
        _ session: CompletedWorkoutSession,
        workout: Workout,
        on date: Date,
        calendar: Calendar = .current
    ) -> Bool {
        guard hasCompletedWork(exercises: session.exercises) else { return false }
        let sameDay = calendar.isDate(session.endTime, inSameDayAs: date)
        let sameWorkout = session.workoutId == workout.id || session.workoutName == workout.name
        return sameDay && sameWorkout
    }
}
