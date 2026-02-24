//
//  WorkoutAttributes.swift
//  StepComp
//
//  ActivityAttributes for the workout Live Activity.
//  This file must be included in BOTH the main app target and the widget extension target.
//

import ActivityKit
import Foundation

struct WorkoutAttributes: ActivityAttributes {
    /// Fixed context set when the Live Activity starts.
    let workoutName: String

    /// Dynamic state pushed via ActivityKit updates.
    struct ContentState: Codable, Hashable {
        let sessionStartTime: Date
        let totalPausedTime: TimeInterval
        let isPaused: Bool
        let currentExerciseName: String?
    }
}
