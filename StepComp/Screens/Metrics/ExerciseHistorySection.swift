//
//  ExerciseHistorySection.swift
//  StepComp
//

import SwiftUI
import Charts

struct ExerciseHistorySection: View {
    @ObservedObject var viewModel: MetricsViewModel
    @ObservedObject private var unitManager = UnitPreferenceManager.shared
    @State private var isExpanded = false

    private var topExercises: [ExerciseHistoryStat] {
        Array(viewModel.exerciseHistoryStats.prefix(5))
    }

    private var remainingExercises: [ExerciseHistoryStat] {
        Array(viewModel.exerciseHistoryStats.dropFirst(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PillarHeader(
                title: "EXERCISE HISTORY",
                subtitle: "Volume trends for every exercise",
                icon: "clock.arrow.circlepath"
            )

            if viewModel.exerciseHistoryStats.isEmpty {
                emptyState
            } else {
                ForEach(topExercises) { stat in
                    exerciseCard(stat)
                }

                if !remainingExercises.isEmpty {
                    expandToggle

                    if isExpanded {
                        ForEach(remainingExercises) { stat in
                            exerciseCard(stat)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        Text("Complete workouts to see exercise history")
            .font(.stepCaption())
            .foregroundStyle(FitCompColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
            .accessibilityLabel("No exercise history yet. Complete workouts to see volume trends here.")
    }

    // MARK: - Exercise Card

    private func exerciseCard(_ stat: ExerciseHistoryStat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(stat.exerciseName)
                .font(.stepCaptionBold())
                .foregroundStyle(FitCompColors.textPrimary)
                .lineLimit(1)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(exerciseSummaryLabel(stat))

            HStack(spacing: 14) {
                statPill(
                    icon: "scalemass",
                    value: formattedVolume(stat.totalVolume),
                    label: "volume"
                )
                statPill(
                    icon: "flame",
                    value: "\(stat.sessionCount)",
                    label: stat.sessionCount == 1 ? "session" : "sessions"
                )
                statPill(
                    icon: "arrow.up",
                    value: formattedWeight(stat.maxWeight),
                    label: "best"
                )
            }
            .accessibilityHidden(true)

            if stat.sparklineValues.count >= 2 {
                SparklineView(
                    values: stat.sparklineValues,
                    color: FitCompColors.cyan
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(sparklineAccessibilityLabel(stat))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FitCompColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(FitCompColors.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - Stat Pill

    private func statPill(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(FitCompColors.textSecondary)
            Text(value)
                .font(.stepNumberSmall())
                .foregroundStyle(FitCompColors.textPrimary)
            Text(label)
                .font(.stepCaption())
                .foregroundStyle(FitCompColors.textSecondary)
        }
    }

    // MARK: - Expand / Collapse Toggle

    private var expandToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Text(isExpanded ? "Show Less" : "Show All (\(remainingExercises.count) more)")
                    .font(.stepCaptionBold())
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(FitCompColors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(FitCompColors.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded ? "Show fewer exercises" : "Show all exercises, \(remainingExercises.count) more")
        .accessibilityHint(isExpanded ? "Collapses the list to the top five exercises." : "Expands the list to show every exercise tracked in this period.")
    }

    // MARK: - Formatting

    private func formattedVolume(_ volume: Double) -> String {
        let converted = unitManager.convertWeight(kg: volume)
        if converted >= 1_000_000 {
            return String(format: "%.1fM", converted / 1_000_000)
        } else if converted >= 1_000 {
            return String(format: "%.1fk", converted / 1_000)
        }
        return String(format: "%.0f", converted)
    }

    private func formattedWeight(_ kg: Double) -> String {
        let converted = unitManager.convertWeight(kg: kg)
        return "\(String(format: "%.0f", converted)) \(unitManager.weightUnit)"
    }

    private func exerciseSummaryLabel(_ stat: ExerciseHistoryStat) -> String {
        let sessions = stat.sessionCount == 1 ? "1 session" : "\(stat.sessionCount) sessions"
        let vol = formattedVolume(stat.totalVolume)
        let best = formattedWeight(stat.maxWeight)
        return "\(stat.exerciseName), \(sessions), total volume \(vol) \(unitManager.weightUnit) equivalent, best weight \(best)."
    }

    private func sparklineAccessibilityLabel(_ stat: ExerciseHistoryStat) -> String {
        let vals = stat.sparklineValues
        guard vals.count >= 2 else { return "Volume trend chart for \(stat.exerciseName)" }
        let minK = vals.min() ?? 0
        let maxK = vals.max() ?? 0
        let low = formattedVolume(minK)
        let high = formattedVolume(maxK)
        let first = vals.first ?? 0
        let last = vals.last ?? 0
        let trendWord: String
        if last > first * 1.02 {
            trendWord = "trending up"
        } else if last < first * 0.98 {
            trendWord = "trending down"
        } else {
            trendWord = "mostly flat"
        }
        return "\(stat.exerciseName) volume sparkline, \(vals.count) points, \(trendWord), low \(low), high \(high), in \(unitManager.weightUnit) equivalent units."
    }
}
