//
//  RecoveryPillarSection.swift
//  StepComp
//

import SwiftUI

struct RecoveryPillarSection: View {
    @ObservedObject var viewModel: MetricsViewModel
    @State private var expandedCards: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PillarHeader(
                title: "RECOVERY",
                subtitle: "Can my body absorb training?",
                icon: "heart.fill"
            )

            if let recovery = viewModel.recovery {
                HStack(spacing: 10) {
                    metric(
                        key: "recovery-sleep-quality",
                        title: "Sleep Quality",
                        value: "\(recovery.sleepQualityScore)",
                        detail: MetricBreakdownDetail(
                            title: "Sleep Quality",
                            trackedValues: [
                                "Sleep quality score: \(recovery.sleepQualityScore)",
                                "Stress load score: \(recovery.stressLoadScore)"
                            ],
                            formula: "Sleep quality scales average sleep hours against an 8-hour nightly target and maps to 0-100.",
                            interpretation: "Higher sleep quality supports better HRV response and lower overtraining risk."
                        )
                    )
                    metric(
                        key: "recovery-stress-load",
                        title: "Stress Load",
                        value: "\(recovery.stressLoadScore)",
                        detail: MetricBreakdownDetail(
                            title: "Stress Load",
                            trackedValues: [
                                "Stress load: \(recovery.stressLoadScore)",
                                "Sleep quality: \(recovery.sleepQualityScore)",
                                "Recovery efficiency: \(recovery.recoveryEfficiency)"
                            ],
                            formula: "Stress load blends low sleep quality and poor training-load balance into a single 0-100 strain score.",
                            interpretation: "Lower scores generally reflect better recovery capacity and training tolerance."
                        )
                    )
                }

                HStack(spacing: 10) {
                    trendCard(
                        title: "HRV Trend",
                        value: percent(recovery.hrvTrendPercent),
                        direction: recovery.hrvDirection
                    )
                    trendCard(
                        title: "RHR Trend",
                        value: percent(recovery.rhrTrendPercent),
                        direction: recovery.rhrDirection
                    )
                }

                HStack(spacing: 10) {
                    metric(
                        key: "recovery-efficiency",
                        title: "Recovery Efficiency",
                        value: "\(recovery.recoveryEfficiency)",
                        detail: MetricBreakdownDetail(
                            title: "Recovery Efficiency",
                            trackedValues: [
                                "Recovery efficiency: \(recovery.recoveryEfficiency)",
                                "HRV trend: \(percent(recovery.hrvTrendPercent))",
                                "RHR trend: \(percent(recovery.rhrTrendPercent))"
                            ],
                            formula: "Recovery efficiency is derived from how stable/improving autonomic trends are across the latest history window.",
                            interpretation: "Higher efficiency means your body is rebounding better between sessions."
                        )
                    )
                    ExpandableMetricCard(
                        isExpanded: binding(for: "recovery-overtraining-risk"),
                        detail: MetricBreakdownDetail(
                            title: "Overtraining Risk",
                            trackedValues: [
                                "Risk score: \(recovery.overtrainingRiskScore)",
                                "Risk status: \(recovery.overtrainingRiskStatus.label)",
                                "Stress load: \(recovery.stressLoadScore)",
                                "Recovery efficiency: \(recovery.recoveryEfficiency)"
                            ],
                            formula: "Risk score combines stress load (50%), low recovery efficiency (35%), and sleep deficit pressure (15%), clamped to 0-100.",
                            interpretation: "Use this to decide when to deload or reduce intensity to avoid accumulated fatigue."
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Overtraining Risk")
                                .font(.stepCaptionBold())
                                .foregroundStyle(FitCompColors.textSecondary)
                            Text("\(recovery.overtrainingRiskScore)")
                                .font(.stepBody())
                                .foregroundStyle(FitCompColors.textPrimary)
                            MetricStatusBadge(status: recovery.overtrainingRiskStatus)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(FitCompColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(FitCompColors.cardBorder, lineWidth: 1))
                    }
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

    private func trendCard(title: String, value: String, direction: TrendDirection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.stepCaptionBold())
                .foregroundStyle(FitCompColors.textSecondary)
            Text(value)
                .font(.stepBody())
                .foregroundStyle(FitCompColors.textPrimary)
            MetricTrendIndicator(direction: direction, text: direction.rawValue.capitalized)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FitCompColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(FitCompColors.cardBorder, lineWidth: 1))
    }

    private func percent(_ value: Double?) -> String {
        guard let value else { return "N/A" }
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(Int(value.rounded()))%"
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
