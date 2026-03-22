//
//  BodyPillarSection.swift
//  StepComp
//

import SwiftUI

struct BodyPillarSection: View {
    @ObservedObject var viewModel: MetricsViewModel
    @State private var expandedCards: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PillarHeader(
                title: "BODY",
                subtitle: "Is composition moving the right way?",
                icon: "figure.arms.open"
            )

            if let body = viewModel.body {
                if !viewModel.weightHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weight Trend")
                            .font(.stepCaptionBold())
                            .foregroundStyle(FitCompColors.textSecondary)
                        WeightTrendChart(points: viewModel.weightHistory)
                    }
                    .padding(16)
                    .background(FitCompColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(FitCompColors.cardBorder, lineWidth: 1))

                    if viewModel.weightHistory.count >= 2 {
                        WeightLossSummaryCard(points: viewModel.weightHistory)
                    }
                }

                HStack(spacing: 10) {
                    metric(
                        key: "body-fat-loss-velocity",
                        title: "Fat Loss Velocity",
                        value: formatVelocity(body.fatLossVelocityPerWeek),
                        detail: MetricBreakdownDetail(
                            title: "Fat Loss Velocity",
                            trackedValues: [
                                "Velocity: \(formatVelocity(body.fatLossVelocityPerWeek))",
                                "Recomposition score: \(body.recompositionScore)",
                                "Body trend: \(body.bodyTrendScore.title)"
                            ],
                            formula: "Based on weight change across recent check-ins, normalized by elapsed weeks in the recent analysis window.",
                            interpretation: "A steady, moderate rate is usually more sustainable than aggressive drops."
                        )
                    )
                    metric(
                        key: "body-lean-mass-trend",
                        title: "Lean Mass Trend",
                        value: formatKg(body.leanMassTrendKg60d),
                        detail: MetricBreakdownDetail(
                            title: "Lean Mass Trend",
                            trackedValues: [
                                "Lean mass trend: \(formatKg(body.leanMassTrendKg60d))",
                                "Recomposition score: \(body.recompositionScore)"
                            ],
                            formula: "Projects weekly lean-mass change across a longer trend window to estimate direction and pace.",
                            interpretation: "Positive trend indicates lean mass is being maintained or improved while progressing body goals."
                        )
                    )
                }

                HStack(spacing: 10) {
                    metric(
                        key: "body-recomposition-score",
                        title: "Recomposition Score",
                        value: "\(body.recompositionScore)",
                        detail: MetricBreakdownDetail(
                            title: "Recomposition Score",
                            trackedValues: [
                                "Recomposition score: \(body.recompositionScore)",
                                "Fat loss velocity: \(formatVelocity(body.fatLossVelocityPerWeek))",
                                "Lean mass trend: \(formatKg(body.leanMassTrendKg60d))"
                            ],
                            formula: "Score rewards simultaneous fat-mass reduction and lean-mass improvement, then clamps to a 0-100 range.",
                            interpretation: "Higher values indicate better quality body-composition change, not just scale movement."
                        )
                    )
                    metric(
                        key: "body-body-trend",
                        title: "Body Trend",
                        value: body.bodyTrendScore.title,
                        detail: MetricBreakdownDetail(
                            title: "Body Trend",
                            trackedValues: [
                                "Body trend: \(body.bodyTrendScore.title)",
                                "Measurement consistency: \(body.measurementConsistency)%"
                            ],
                            formula: "Trend classification comes from weekly weight-change direction thresholds (improving/maintaining/regressing).",
                            interpretation: "This summarizes whether overall body trajectory aligns with your current objective."
                        )
                    )
                }

                metric(
                    key: "body-measurement-consistency",
                    title: "Measurement Consistency",
                    value: "\(body.measurementConsistency)%",
                    detail: MetricBreakdownDetail(
                        title: "Measurement Consistency",
                        trackedValues: [
                            "Consistency: \(body.measurementConsistency)%",
                            "Weight entries loaded: \(viewModel.weightHistory.count)"
                        ],
                        formula: "Consistency score reflects frequency of recent logged body measurements against a daily tracking target.",
                        interpretation: "Higher consistency improves confidence and stability of trend calculations."
                    )
                )
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

    private func formatVelocity(_ value: Double?) -> String {
        guard let value else { return "N/A" }
        let poundsPerWeek = value * 2.20462
        return String(format: "%.1f lbs/week", poundsPerWeek)
    }

    private func formatKg(_ value: Double?) -> String {
        guard let value else { return "N/A" }
        let sign = value >= 0 ? "+" : ""
        return String(format: "\(sign)%.1f kg", value)
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
