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
                        value: signedPercent(performance.strengthTrendPercent),
                        detail: MetricBreakdownDetail(
                            title: "Strength Trend",
                            trackedValues: [
                                "Trend: \(signedPercent(performance.strengthTrendPercent))",
                                "Strength score: \(performance.strengthScore)",
                                "Recent volume points: \(performance.volumeTrend.count)"
                            ],
                            formula: "Compares average estimated 1RM from recent 30-day sessions versus the prior 30-day window.",
                            interpretation: "Positive percentages indicate your recent strength trend is improving over the previous block."
                        )
                    )
                    metric(
                        key: "performance-overload-score",
                        title: "Overload Score",
                        value: "\(performance.overloadScore)%",
                        detail: MetricBreakdownDetail(
                            title: "Overload Score",
                            trackedValues: [
                                "Overload score: \(performance.overloadScore)",
                                "PR velocity status: \(performance.prVelocity.status.label)",
                                "Load balance ratio: \(String(format: "%.2f", performance.trainingLoadBalance.ratio))"
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
                        value: "1 PR / \(Int(performance.prVelocity.workoutsPerPR.rounded())) workouts",
                        detail: MetricBreakdownDetail(
                            title: "PR Velocity",
                            trackedValues: [
                                "Workouts per PR: \(String(format: "%.1f", performance.prVelocity.workoutsPerPR))",
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
                                "Balance ratio: \(String(format: "%.2f", performance.trainingLoadBalance.ratio))",
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
                            Text(String(format: "%.2f", performance.trainingLoadBalance.ratio))
                                .font(.stepBody())
                                .foregroundStyle(FitCompColors.textPrimary)
                            MetricStatusBadge(status: performance.trainingLoadBalance.status)
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

                if !performance.volumeTrend.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Volume Trend")
                            .font(.stepCaptionBold())
                            .foregroundStyle(FitCompColors.textSecondary)
                        SparklineView(values: performance.volumeTrend, color: FitCompColors.cyan)
                    }
                    .padding(14)
                    .background(FitCompColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(FitCompColors.cardBorder, lineWidth: 1))
                }

                if !performance.muscleBalance.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Muscle Group Balance")
                            .font(.stepCaptionBold())
                            .foregroundStyle(FitCompColors.textSecondary)
                        RadarChartView(
                            data: performance.muscleBalance.prefix(8).map { point in
                                RadarChartDataPoint(
                                    id: point.id,
                                    label: point.muscleGroup,
                                    value: point.volume
                                )
                            },
                            levels: 4
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

    private func signedPercent(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(Int(value.rounded()))%"
    }
}
