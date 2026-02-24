//
//  WorkoutLiveActivity.swift
//  StepCompWorkoutWidget
//
//  Live Activity configuration for active workouts. Uses system-driven
//  timer rendering so the widget extension is never woken every second.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutAttributes.self) { context in
            // Lock Screen / banner presentation
            LockScreenWorkoutView(context: context)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title3)
                        Text(context.attributes.workoutName)
                            .font(.headline)
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerView(state: context.state)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if let exercise = context.state.currentExerciseName, !exercise.isEmpty {
                            Label(exercise, systemImage: "dumbbell.fill")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                        if context.state.isPaused {
                            Label("Paused", systemImage: "pause.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.white)
            } compactTrailing: {
                TimerView(state: context.state)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            } minimal: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Lock Screen View

private struct LockScreenWorkoutView: View {
    let context: ActivityViewContext<WorkoutAttributes>

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title3)
                    Text(context.attributes.workoutName)
                        .font(.headline)
                        .lineLimit(1)
                }
                .foregroundStyle(.white.opacity(0.8))

                TimerView(state: context.state)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                if context.state.isPaused {
                    Label("Paused", systemImage: "pause.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            if let exercise = context.state.currentExerciseName, !exercise.isEmpty {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("CURRENT")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                    Text(exercise)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding()
    }
}

// MARK: - Timer View

/// Uses `Text(timerInterval:)` so the system drives the count-up natively
/// without waking the widget extension process.
private struct TimerView: View {
    let state: WorkoutAttributes.ContentState

    var body: some View {
        if state.isPaused {
            let elapsed = state.sessionStartTime.distance(to: Date()) - state.totalPausedTime
            let total = Int(max(0, elapsed))
            let minutes = total / 60
            let seconds = total % 60
            Text(String(format: "%d:%02d", minutes, seconds))
        } else {
            let adjustedStart = state.sessionStartTime.addingTimeInterval(state.totalPausedTime)
            Text(timerInterval: adjustedStart...Date.distantFuture, countsDown: false)
        }
    }
}
