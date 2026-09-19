//
//  ActiveWorkoutStartPolicy.swift
//  FitComp
//
//  A second "Start Workout" tap (Home upcoming-workout card, suggested
//  workouts, workout detail) must not replace an in-progress session.
//

import Foundation

enum ActiveWorkoutStartPolicy {
    /// Returns false when a live session already exists so callers cannot
    /// overwrite logged sets or the persisted active-workout draft.
    static func canStartNewWorkout(hasActiveSession: Bool) -> Bool {
        !hasActiveSession
    }
}
