//
//  WorkoutLiveActivityManager.swift
//  FitComp
//
//  Manages the Live Activity for active workouts. Replaces the old
//  1-second widget timeline approach which caused memory crashes.
//

import ActivityKit
import Foundation

enum WorkoutLiveActivityManager {

    private(set) static var currentActivity: Activity<WorkoutAttributes>?

    /// Ensures manager has a reference to a currently running workout activity.
    /// Helpful after app relaunch when `currentActivity` in memory is nil.
    private static func adoptExistingActivityIfNeeded() {
        guard currentActivity == nil else { return }
        currentActivity = Activity<WorkoutAttributes>.activities.first
    }

    static func start(
        workoutName: String,
        sessionStartTime: Date,
        currentExerciseName: String?
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        adoptExistingActivityIfNeeded()

        // If one already exists, update it instead of creating duplicate activities.
        if let existing = currentActivity {
            let state = WorkoutAttributes.ContentState(
                sessionStartTime: sessionStartTime,
                totalPausedTime: 0,
                isPaused: false,
                currentExerciseName: currentExerciseName
            )
            Task {
                let content = ActivityContent(state: state, staleDate: nil)
                await existing.update(content)
            }
            return
        }

        let attributes = WorkoutAttributes(workoutName: workoutName)
        let state = WorkoutAttributes.ContentState(
            sessionStartTime: sessionStartTime,
            totalPausedTime: 0,
            isPaused: false,
            currentExerciseName: currentExerciseName
        )

        do {
            let content = ActivityContent(state: state, staleDate: nil)
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            currentActivity = activity
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    static func update(
        sessionStartTime: Date,
        totalPausedTime: TimeInterval,
        isPaused: Bool,
        currentExerciseName: String?
    ) {
        adoptExistingActivityIfNeeded()
        guard let activity = currentActivity else { return }

        let state = WorkoutAttributes.ContentState(
            sessionStartTime: sessionStartTime,
            totalPausedTime: totalPausedTime,
            isPaused: isPaused,
            currentExerciseName: currentExerciseName
        )

        Task {
            let content = ActivityContent(state: state, staleDate: nil)
            await activity.update(content)
        }
    }

    static func end() {
        let activities = Activity<WorkoutAttributes>.activities
        Task {
            for activity in activities {
                let finalState = WorkoutAttributes.ContentState(
                    sessionStartTime: Date(),
                    totalPausedTime: 0,
                    isPaused: true,
                    currentExerciseName: nil
                )
                let content = ActivityContent(state: finalState, staleDate: nil)
                await activity.end(content, dismissalPolicy: .immediate)
            }

            // Also end any in-memory reference if it wasn't included in activities for any reason.
            if let activity = currentActivity,
               !activities.contains(where: { $0.id == activity.id }) {
                let finalState = WorkoutAttributes.ContentState(
                    sessionStartTime: Date(),
                    totalPausedTime: 0,
                    isPaused: true,
                    currentExerciseName: nil
                )
                let content = ActivityContent(state: finalState, staleDate: nil)
                await activity.end(content, dismissalPolicy: .immediate)
            }
        }
        currentActivity = nil
    }
}
