//
//  PerformancePillarSection.swift
//  StepComp
//

import SwiftUI

struct PerformancePillarSection: View {
    @ObservedObject var viewModel: MetricsViewModel
    @State private var expandedCards: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PillarHeader(
                title: "PERFORMANCE",
                subtitle: "Am I improving?",
                icon: "bolt.fill"
            )

            if let performance = viewModel.performance {
                HStack(spacing: 10) {
                    metric(
                        key: "performance-strength-trend",
                        title: "Strength Trend",
                        value: strengthTrendDisplay(performance.strengthTrendPercent),
                        detail: MetricBreakdownDetail(
                            title: "Strength Trend",
                            trackedValues: [
                                "Trend: \(strengthTrendDisplay(performance.strengthTrendPercent))",
                                "Compared lifts: \(comparedLiftsDisplay(performance.comparedLiftCount, trend: performance.strengthTrendPercent))",
                                "Strength score: \(performance.strengthScore)"
                            ],
                            formula: "Compares each lift's best estimated 1RM in the most recent period against the prior equal-length period, then reports the median percent change.",
                            interpretation: "Positive values mean your overlapping lifts improved versus the prior block. N/A means there were not enough comparable lifts across both windows."
                        )
                    )
                    metric(
                        key: "performance-overload-score",
                        title: "Overload Score",
                        value: overloadDisplay(performance.overloadScore),
                        detail: MetricBreakdownDetail(
                            title: "Overload Score",
                            trackedValues: [
                                "Overload score: \(overloadDisplay(performance.overloadScore))",
                                "PR velocity status: \(performance.prVelocity.status.label)",
                                "Load balance ratio: \(loadBalanceDisplay(performance.trainingLoadBalance))"
                            ],
                            formula: "Progressive overload success is scored from recent session progress and constrained to a 0-100 scale.",
                            interpretation: "A higher score means you are applying progressive overload consistently."
                        )
                    )
                }

                HStack(spacing: 10) {
                    metric(
                        key: "performance-pr-velocity",
                        title: "PR Velocity",
                        value: prVelocityDisplay(performance.prVelocity),
                        detail: MetricBreakdownDetail(
                            title: "PR Velocity",
                            trackedValues: [
                                "Workouts per PR: \(prVelocityDetails(performance.prVelocity))",
                                "Velocity status: \(performance.prVelocity.status.label)",
                                "Plateau detected: \(performance.plateauDetection.isDetected ? "Yes" : "No")"
                            ],
                            formula: "PR velocity tracks how frequently PRs occur over completed sessions.",
                            interpretation: "Lower workouts-per-PR means faster strength progression."
                        )
                    )
                    ExpandableMetricCard(
                        isExpanded: binding(for: "performance-load-balance"),
                        detail: MetricBreakdownDetail(
                            title: "Load Balance",
                            trackedValues: [
                                "Balance ratio: \(loadBalanceDisplay(performance.trainingLoadBalance))",
                                "Status: \(performance.trainingLoadBalance.status.label)",
                                "Optimal range: \(performance.trainingLoadBalance.isOptimalRange ? "Yes" : "No")"
                            ],
                            formula: "Training load balance ratio compares recent workload to chronic workload and maps to a status zone.",
                            interpretation: "Ratios near the optimal range support performance gains while limiting overload risk."
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Load Balance")
                                .font(.stepCaptionBold())
                                .foregroundStyle(FitCompColors.textSecondary)
                            Text(loadBalanceDisplay(performance.trainingLoadBalance))
                                .font(.stepBody())
                                .foregroundStyle(FitCompColors.textPrimary)
                            if performance.trainingLoadBalance.hasData {
                                MetricStatusBadge(status: performance.trainingLoadBalance.status)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(FitCompColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(FitCompColors.cardBorder, lineWidth: 1))
                    }
                }

                if performance.plateauDetection.isDetected {
                    Text(performance.plateauDetection.message ?? "Plateau detected")
                        .font(.stepBodySmall())
                        .foregroundStyle(FitCompColors.coral)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(FitCompColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(FitCompColors.coral.opacity(0.4), lineWidth: 1))
                }

                if !performance.muscleBalance.isEmpty {
                    let topMuscles = Array(performance.muscleBalance.prefix(8))
                    let totalVolume = topMuscles.reduce(0.0) { $0 + $1.volume }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Muscle Group Balance")
                            .font(.stepCaptionBold())
                            .foregroundStyle(FitCompColors.textSecondary)
                        RadarChartView(
                            data: topMuscles.map { point in
                                RadarChartDataPoint(
                                    id: point.id,
                                    label: point.muscleGroup,
                                    value: totalVolume > 0 ? (point.volume / totalVolume) * 100.0 : 0
                                )
                            },
                            levels: 4,
                            maxReferenceValue: 100
                        )
                        .frame(height: 220)
                    }
                    .padding(14)
                    .background(FitCompColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(FitCompColors.cardBorder, lineWidth: 1))
                }
            }
        }
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

    private func strengthTrendDisplay(_ value: Double?) -> String {
        guard let value else { return "N/A" }
        let sign = value >= 0 ? "+" : ""
        if abs(value) < 10 {
            return "\(sign)\(String(format: "%.1f", value))%"
        }
        return "\(sign)\(Int(value.rounded()))%"
    }

    private func comparedLiftsDisplay(_ count: Int?, trend: Double?) -> String {
        guard trend != nil else { return "N/A" }
        return "\(count ?? 0)"
    }

    private func overloadDisplay(_ value: Int?) -> String {
        guard let value else { return "N/A" }
        return "\(value)%"
    }

    private func prVelocityDisplay(_ velocity: PRVelocity) -> String {
        guard velocity.hasRecordedPRs else { return "N/A" }
        return "1 PR / \(Int(velocity.workoutsPerPR.rounded())) workouts"
    }

    private func prVelocityDetails(_ velocity: PRVelocity) -> String {
        guard velocity.hasRecordedPRs else { return "N/A (no recorded PRs in this period)" }
        return String(format: "%.1f", velocity.workoutsPerPR)
    }

    private func loadBalanceDisplay(_ balance: TrainingLoadBalance) -> String {
        guard balance.hasData else { return "N/A" }
        return String(format: "%.2f", balance.ratio)
    }
}
