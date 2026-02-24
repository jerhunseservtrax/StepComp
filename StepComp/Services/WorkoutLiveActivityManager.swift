//
//  WorkoutLiveActivityManager.swift
//  StepComp
//
//  Manages the Live Activity for active workouts. Replaces the old
//  1-second widget timeline approach which caused memory crashes.
//

import ActivityKit
import Foundation

enum WorkoutLiveActivityManager {

    private(set) static var currentActivity: Activity<WorkoutAttributes>?

    static func start(
        workoutName: String,
        sessionStartTime: Date,
        currentExerciseName: String?
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

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
        guard let activity = currentActivity else { return }

        let finalState = WorkoutAttributes.ContentState(
            sessionStartTime: Date(),
            totalPausedTime: 0,
            isPaused: true,
            currentExerciseName: nil
        )

        Task {
            let content = ActivityContent(state: finalState, staleDate: nil)
            await activity.end(content, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }
}
