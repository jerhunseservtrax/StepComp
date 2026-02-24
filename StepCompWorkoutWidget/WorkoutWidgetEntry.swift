//
//  WorkoutWidgetEntry.swift
//  StepCompWorkoutWidget
//
//  Lock screen widget: timer + current exercise when a workout is active.
//

import WidgetKit

struct WorkoutWidgetEntry: TimelineEntry {
    let date: Date
    let isActive: Bool
    let sessionStartTime: Date?
    let totalPausedTime: TimeInterval
    let isPaused: Bool
    let workoutName: String?
    let currentExerciseName: String?

    var elapsedTime: TimeInterval {
        guard isActive, let start = sessionStartTime else { return 0 }
        if isPaused {
            return start.distance(to: date) - totalPausedTime
        }
        return start.distance(to: date) - totalPausedTime
    }

    var timerText: String {
        let total = Int(elapsedTime)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
