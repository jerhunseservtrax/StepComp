//
//  ConsistencyPillarSection.swift
//  StepComp
//

import SwiftUI

struct ConsistencyPillarSection: View {
    @ObservedObject var viewModel: MetricsViewModel
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var expandedCards: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PillarHeader(
                title: "CONSISTENCY",
                subtitle: "Am I showing up every week?",
                icon: "calendar.badge.clock"
            )

            if let consistency = viewModel.consistency {
                HStack(spacing: 10) {
                    ExpandableMetricCard(
                        isExpanded: binding(for: "consistency-momentum"),
                        detail: MetricBreakdownDetail(
                            title: "Momentum",
                            trackedValues: [
                                "Momentum score: \(consistency.momentumScore.score)",
                                "Consistency score: \(consistency.consistencyScore)",
                                "Workout frequency: \(String(format: "%.1f / week", consistency.workoutFrequencyPerWeek))",
                                "Step consistency: \(consistency.stepConsistencyDaysHit) / 7 days"
                            ],
                            formula: "Momentum blends consistency score, PR frequency score, and recent volume trend into a 0-100 readiness-to-progress signal.",
                            interpretation: "Higher momentum means your habits and performance trend are aligned for faster progress."
                        )
                    ) {
                        MetricStatusCard(
                            title: "Momentum",
                            score: consistency.momentumScore.score,
                            status: consistency.momentumScore.status,
                            action: "Protect your training rhythm",
                            icon: "flame.fill"
                        )
                    }
                }

                HStack(spacing: 10) {
                    metric(
                        key: "consistency-score",
                        title: "Consistency Score",
                        value: "\(consistency.consistencyScore)",
                        detail: MetricBreakdownDetail(
                            title: "Consistency Score",
                            trackedValues: [
                                "Consistency score: \(consistency.consistencyScore)",
                                "Habit adherence: \(consistency.habitAdherencePercent)%",
                                "Step consistency: \(consistency.stepConsistencyDaysHit) / 7"
                            ],
                            formula: "Weighted blend of workout adherence, goal completion, nutrition logging, and step consistency.",
                            interpretation: "This score reflects repeatability of core health behaviors, not just one strong day."
                        )
                    )
                    metric(
                        key: "consistency-habit-adherence",
                        title: "Habit Adherence",
                        value: "\(consistency.habitAdherencePercent)%",
                        detail: MetricBreakdownDetail(
                            title: "Habit Adherence",
                            trackedValues: [
                                "Habit adherence: \(consistency.habitAdherencePercent)%",
                                "Workout frequency: \(String(format: "%.1f / week", consistency.workoutFrequencyPerWeek))"
                            ],
                            formula: "Represents how often recent workouts and step-goal targets are met over rolling windows.",
                            interpretation: "Higher adherence means routines are becoming automatic and easier to sustain."
                        )
                    )
                }

                HStack(spacing: 10) {
                    metric(
                        key: "consistency-workout-frequency",
                        title: "Workout Frequency",
                        value: String(format: "%.1f / week", consistency.workoutFrequencyPerWeek),
                        detail: MetricBreakdownDetail(
                            title: "Workout Frequency",
                            trackedValues: [
                                "Frequency: \(String(format: "%.1f / week", consistency.workoutFrequencyPerWeek))",
                                "Completed workouts loaded: \(viewModel.completedWorkoutsCount)"
                            ],
                            formula: "Computed from workouts completed in the last 28 days divided by 4 weeks.",
                            interpretation: "Shows the practical weekly training cadence your body is currently adapting to."
                        )
                    )
                    metric(
                        key: "consistency-step-consistency",
                        title: "Step Consistency",
                        value: "\(consistency.stepConsistencyDaysHit) / 7 days",
                        detail: MetricBreakdownDetail(
                            title: "Step Consistency",
                            trackedValues: [
                                "Days hit in last week: \(consistency.stepConsistencyDaysHit) / 7",
                                "Habit adherence: \(consistency.habitAdherencePercent)%"
                            ],
                            formula: "Counts last 7 days where your step goal was met and converts that to a consistency component score.",
                            interpretation: "More goal-hit days indicates dependable baseline activity and recovery support."
                        )
                    )
                }

                metric(
                    key: "consistency-streak-strength",
                    title: "Streak Strength",
                    value: "\(consistency.streakStrengthScore)",
                    detail: MetricBreakdownDetail(
                        title: "Streak Strength",
                        trackedValues: [
                            "Streak strength: \(consistency.streakStrengthScore)",
                            "Workout frequency: \(String(format: "%.1f / week", consistency.workoutFrequencyPerWeek))"
                        ],
                        formula: "Combines current workout streak depth with recent weekly training volume into a capped 0-100 score.",
                        interpretation: "Higher values suggest your routine is durable even when schedule variability increases."
                    )
                )
            }

            workoutHeatmapCard
        }
        .onAppear {
            if let first = viewModel.heatmapYears.first {
                selectedYear = first
            }
        }
    }

    private var workoutHeatmapCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Workout Heatmap")
                    .font(.stepCaptionBold())
                    .foregroundStyle(FitCompColors.textSecondary)
                Spacer()
                if !viewModel.heatmapYears.isEmpty {
                    Picker("Year", selection: $selectedYear) {
                        ForEach(viewModel.heatmapYears, id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            let volumeByDay = viewModel.workoutVolumeByDay(forYear: selectedYear)
            HeatmapGrid(volumeByDay: volumeByDay)
        }
        .padding(14)
        .background(FitCompColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FitCompColors.cardBorder, lineWidth: 1))
    }

    private func metric(key: String, title: String, value: String, detail: MetricBreakdownDetail) -> some View {
        ExpandableMetricCard(isExpanded: binding(for: key), detail: detail) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.stepCaptionBold())
                    .foregroundStyle(FitCompColors.textSecondary)
                Text(value)
                    .font(.stepBody())
                    .foregroundStyle(FitCompColors.textPrimary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FitCompColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(FitCompColors.cardBorder, lineWidth: 1))
        }
    }

    private func binding(for key: String) -> Binding<Bool> {
        Binding(
            get: { expandedCards.contains(key) },
            set: { isExpanded in
                if isExpanded {
                    expandedCards.insert(key)
                } else {
                    expandedCards.remove(key)
                }
            }
        )
    }
}

private struct HeatmapGrid: View {
    let volumeByDay: [Date: Double]
    private let columns = Array(repeating: GridItem(.flexible(minimum: 10, maximum: 14), spacing: 3), count: 21)
    private let calendar = Calendar.current

    var body: some View {
        LazyVGrid(columns: columns, spacing: 3) {
            ForEach(dayBuckets, id: \.self) { day in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color(for: day))
                    .frame(height: 10)
            }
        }
    }

    private var dayBuckets: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<147).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }.reversed()
    }

    private func color(for day: Date) -> Color {
        let volume = volumeByDay[calendar.startOfDay(for: day)] ?? 0
        switch volume {
        case 0:
            return FitCompColors.surfaceElevated
        case ..<1000:
            return FitCompColors.primary.opacity(0.25)
        case ..<2500:
            return FitCompColors.primary.opacity(0.45)
        case ..<4000:
            return FitCompColors.primary.opacity(0.7)
        default:
            return FitCompColors.primary
        }
    }
}
