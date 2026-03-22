//
//  TodayPillarSection.swift
//  StepComp
//

import SwiftUI

struct TodayPillarSection: View {
    @ObservedObject var viewModel: MetricsViewModel
    @State private var expandedCards: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PillarHeader(
                title: "TODAY",
                subtitle: "Can I train today?",
                icon: "sun.max.fill"
            )

            if let readiness = viewModel.readiness {
                ExpandableMetricCard(
                    isExpanded: binding(for: "today-readiness"),
                    detail: readinessDetail(readiness)
                ) {
                    MetricStatusCard(
                        title: "Readiness Score",
                        score: readiness.score,
                        status: readiness.status,
                        action: readiness.recommendation.title,
                        icon: "figure.strengthtraining.traditional"
                    )
                }

                HStack(spacing: 10) {
                    ExpandableMetricCard(
                        isExpanded: binding(for: "today-recovery-status"),
                        detail: recoveryStatusDetail(readiness)
                    ) {
                        card(title: "Recovery Status", value: readiness.recoveryStatus.title)
                    }
                    ExpandableMetricCard(
                        isExpanded: binding(for: "today-recovery-debt"),
                        detail: recoveryDebtDetail(readiness)
                    ) {
                        card(title: "Recovery Debt", value: "\(Int(readiness.recoveryDebtHours.rounded())) hrs")
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Training Readiness Trend")
                        .font(.stepCaptionBold())
                        .foregroundStyle(FitCompColors.textSecondary)

                    SparklineView(values: readiness.trend.values.map(Double.init), color: FitCompColors.primary)

                    MetricTrendIndicator(
                        direction: readiness.trend.direction,
                        text: "Improving \(readiness.trend.daysImproving) days"
                    )
                }
                .padding(14)
                .background(FitCompColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FitCompColors.cardBorder, lineWidth: 1)
                )
            } else {
                Text("Readiness data unavailable. Connect HealthKit to unlock daily coaching.")
                    .font(.stepBodySmall())
                    .foregroundStyle(FitCompColors.textSecondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FitCompColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func card(title: String, value: String) -> some View {
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
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(FitCompColors.cardBorder, lineWidth: 1)
        )
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

    private func readinessDetail(_ readiness: ReadinessResult) -> MetricBreakdownDetail {
        let missing = readiness.missingInputs.isEmpty ? "none" : readiness.missingInputs.joined(separator: ", ")
        return MetricBreakdownDetail(
            title: "Readiness Score",
            trackedValues: [
                "Readiness score: \(readiness.score)",
                "Recovery status: \(readiness.recoveryStatus.title)",
                "Missing inputs: \(missing)"
            ],
            formula: "Weighted blend of sleep quality (35%), HRV vs baseline (25%), RHR vs baseline (15%), and training-load balance (25%). Missing HRV/RHR are re-normalized.",
            interpretation: "Higher scores mean your recovery systems are ready for higher intensity training."
        )
    }

    private func recoveryStatusDetail(_ readiness: ReadinessResult) -> MetricBreakdownDetail {
        MetricBreakdownDetail(
            title: "Recovery Status",
            trackedValues: [
                "Current status: \(readiness.recoveryStatus.title)",
                "Readiness score: \(readiness.score)"
            ],
            formula: "Status thresholds map from readiness score: 90+ recovered, 75-89 maintaining, 60-74 fatigued, below 60 overreached.",
            interpretation: "Use this to match daily training intensity to current readiness."
        )
    }

    private func recoveryDebtDetail(_ readiness: ReadinessResult) -> MetricBreakdownDetail {
        MetricBreakdownDetail(
            title: "Recovery Debt",
            trackedValues: [
                "Estimated debt: \(Int(readiness.recoveryDebtHours.rounded())) hours",
                "Current recommendation: \(readiness.recommendation.title)"
            ],
            formula: "Recovery debt = max(0, ideal weekly sleep (49h) - actual weekly sleep estimate).",
            interpretation: "Higher debt indicates accumulated sleep shortfall and reduced recovery capacity."
        )
    }
}
