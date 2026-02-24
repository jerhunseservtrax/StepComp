//
//  WorkoutWidgetStore.swift
//  StepComp
//
//  Shared state for the lock screen workout widget. Writes to App Group UserDefaults
//  so the widget extension can read timer and current exercise.
//

import Foundation
import WidgetKit

enum WorkoutWidgetStore {
    static let appGroupID = "group.JE.StepComp"

    private static var suite: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    enum Key {
        static let workoutActive = "workout_widget_active"
        static let sessionStartTime = "workout_widget_session_start"
        static let totalPausedTime = "workout_widget_total_paused"
        static let isPaused = "workout_widget_is_paused"
        static let workoutName = "workout_widget_workout_name"
        static let currentExerciseName = "workout_widget_current_exercise"
    }

    /// Call when a workout starts, pauses, resumes, ends, or when current exercise changes.
    static func update(
        active: Bool,
        sessionStartTime: Date?,
        totalPausedTime: TimeInterval,
        isPaused: Bool,
        workoutName: String?,
        currentExerciseName: String?
    ) {
        guard let suite = suite else { return }
        suite.set(active, forKey: Key.workoutActive)
        suite.set(sessionStartTime?.timeIntervalSince1970, forKey: Key.sessionStartTime)
        suite.set(totalPausedTime, forKey: Key.totalPausedTime)
        suite.set(isPaused, forKey: Key.isPaused)
        suite.set(workoutName, forKey: Key.workoutName)
        suite.set(currentExerciseName, forKey: Key.currentExerciseName)
        suite.synchronize()
        WidgetCenter.shared.reloadTimelines(ofKind: "WorkoutWidget")
    }

    /// Clear widget state when workout ends or is cancelled.
    static func clear() {
        update(
            active: false,
            sessionStartTime: nil,
            totalPausedTime: 0,
            isPaused: false,
            workoutName: nil,
            currentExerciseName: nil
        )
    }
}
