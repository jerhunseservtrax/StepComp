//
//  WorkoutWidgetProvider.swift
//  StepCompWorkoutWidget
//

import WidgetKit

enum WorkoutWidgetStore {
    static let appGroupID = "group.JE.StepComp"

    static var suite: UserDefaults? {
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

    static func readEntry(date: Date) -> WorkoutWidgetEntry {
        guard let suite = suite else {
            return WorkoutWidgetEntry(date: date, isActive: false, sessionStartTime: nil, totalPausedTime: 0, isPaused: false, workoutName: nil, currentExerciseName: nil)
        }
        let active = suite.bool(forKey: Key.workoutActive)
        let startTimestamp = suite.double(forKey: Key.sessionStartTime)
        let sessionStartTime = startTimestamp > 0 ? Date(timeIntervalSince1970: startTimestamp) : nil
        let totalPausedTime = suite.double(forKey: Key.totalPausedTime)
        let isPaused = suite.bool(forKey: Key.isPaused)
        let workoutName = suite.string(forKey: Key.workoutName)
        let currentExerciseName = suite.string(forKey: Key.currentExerciseName)

        return WorkoutWidgetEntry(
            date: date,
            isActive: active,
            sessionStartTime: sessionStartTime,
            totalPausedTime: totalPausedTime,
            isPaused: isPaused,
            workoutName: workoutName,
            currentExerciseName: currentExerciseName
        )
    }
}

struct WorkoutWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WorkoutWidgetEntry {
        WorkoutWidgetEntry(
            date: Date(),
            isActive: true,
            sessionStartTime: Date(),
            totalPausedTime: 0,
            isPaused: false,
            workoutName: "Upper Body",
            currentExerciseName: "Bench Press"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WorkoutWidgetEntry) -> Void) {
        let entry = WorkoutWidgetStore.readEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkoutWidgetEntry>) -> Void) {
        let now = Date()
        let entry = WorkoutWidgetStore.readEntry(date: now)

        // Real-time updates are handled by the Live Activity.
        // The static widget only needs periodic refreshes for state consistency.
        let nextUpdate: Date
        if entry.isActive {
            nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: now) ?? now
        } else {
            nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now
        }

        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
