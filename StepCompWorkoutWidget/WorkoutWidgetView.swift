//
//  WorkoutWidgetView.swift
//  FitCompWorkoutWidget
//

import SwiftUI
import WidgetKit

struct WorkoutWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: WorkoutWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SystemSmallView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color.black, Color(white: 0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        case .systemMedium:
            SystemMediumView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color.black, Color(white: 0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        default:
            AccessoryRectangularView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
    }
}

private struct AccessoryRectangularView: View {
    let entry: WorkoutWidgetEntry

    var body: some View {
        if entry.isActive {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "figure.strengthtraining.traditional")
                    Text(entry.workoutName ?? "Workout")
                        .font(.headline)
                        .lineLimit(1)
                }
                .foregroundStyle(.secondary)

                Text(entry.timerText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                if let exercise = entry.currentExerciseName, !exercise.isEmpty {
                    Text(exercise)
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }

                if entry.isPaused {
                    Text("Paused")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                Text("No active workout")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

private struct AccessoryInlineView: View {
    let entry: WorkoutWidgetEntry

    var body: some View {
        if entry.isActive {
            Label("\(entry.timerText) · \(entry.currentExerciseName ?? "Workout")", systemImage: "figure.strengthtraining.traditional")
                .lineLimit(1)
        } else {
            Label("No active workout", systemImage: "figure.strengthtraining.traditional")
        }
    }
}

private struct SystemSmallView: View {
    let entry: WorkoutWidgetEntry

    var body: some View {
        if entry.isActive {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title2)
                        .foregroundStyle(.white)
                    Spacer()
                    if entry.isPaused {
                        Image(systemName: "pause.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                    }
                }
                
                Spacer()
                
                Text(entry.timerText)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                
                if let exercise = entry.currentExerciseName, !exercise.isEmpty {
                    Text(exercise)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }
                
                Text(entry.workoutName ?? "Workout")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .padding()
        } else {
            VStack(spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 40))
                    .foregroundStyle(.white.opacity(0.5))
                Text("No active\nworkout")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct SystemMediumView: View {
    let entry: WorkoutWidgetEntry

    var body: some View {
        if entry.isActive {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title3)
                        Text(entry.workoutName ?? "Workout")
                            .font(.headline)
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(entry.timerText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                    
                    if entry.isPaused {
                        HStack(spacing: 4) {
                            Image(systemName: "pause.circle.fill")
                            Text("Paused")
                                .font(.caption)
                        }
                        .foregroundStyle(.orange)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    if let exercise = entry.currentExerciseName, !exercise.isEmpty {
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
                    
                    Spacer()
                }
            }
            .padding()
        } else {
            HStack(spacing: 16) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 50))
                    .foregroundStyle(.white.opacity(0.5))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("No active workout")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Start a workout to see it here")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
