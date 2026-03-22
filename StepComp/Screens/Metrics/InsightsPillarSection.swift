//
//  InsightsPillarSection.swift
//  StepComp
//

import SwiftUI

struct InsightsPillarSection: View {
    @ObservedObject var viewModel: MetricsViewModel
    @State private var expandedCards: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PillarHeader(
                title: "INSIGHTS",
                subtitle: "What should I do next?",
                icon: "sparkles"
            )

            if let insights = viewModel.insightsPillar {
                if let daily = insights.dailyInsights.first {
                    insightCard(title: "Daily Insight", insight: daily, accent: FitCompColors.primary)
                }

                ForEach(insights.weeklyInsights.prefix(5)) { item in
                    insightCard(title: "Weekly Insight", insight: item, accent: FitCompColors.cyan)
                }

                if let monthly = insights.monthlyInsights.first {
                    insightCard(title: "Monthly Insight", insight: monthly, accent: FitCompColors.purple)
                }
            }

            if let report = viewModel.weeklyReport {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Weekly Performance Report")
                        .font(.stepCaptionBold())
                        .foregroundStyle(FitCompColors.textSecondary)
                    HStack(spacing: 10) {
                        metric(
                            key: "insights-weekly-strength",
                            title: "Strength",
                            value: signedPercent(report.strengthChangePercent),
                            detail: MetricBreakdownDetail(
                                title: "Weekly Strength Change",
                                trackedValues: [
                                    "Weekly strength change: \(signedPercent(report.strengthChangePercent))",
                                    "Recovery trend: \(report.recoveryTrend.rawValue.capitalized)"
                                ],
                                formula: "Compares recent strength indicators to the prior period and expresses the delta as a percent.",
                                interpretation: "Positive changes suggest your current programming and recovery are translating to better output."
                            )
                        )
                        metric(
                            key: "insights-weekly-consistency",
                            title: "Consistency",
                            value: "\(report.consistencyPercent)%",
                            detail: MetricBreakdownDetail(
                                title: "Weekly Consistency",
                                trackedValues: [
                                    "Consistency percent: \(report.consistencyPercent)%",
                                    "Fat loss status: \(report.fatLossStatus)"
                                ],
                                formula: "Rolls up completion and adherence behavior into a weekly consistency percentage.",
                                interpretation: "Higher consistency usually predicts steadier long-term progress."
                            )
                        )
                    }
                    HStack(spacing: 10) {
                        metric(
                            key: "insights-weekly-recovery",
                            title: "Recovery",
                            value: report.recoveryTrend.rawValue.capitalized,
                            detail: MetricBreakdownDetail(
                                title: "Weekly Recovery Trend",
                                trackedValues: [
                                    "Recovery trend: \(report.recoveryTrend.rawValue.capitalized)",
                                    "Strength change: \(signedPercent(report.strengthChangePercent))"
                                ],
                                formula: "Recovery trend is inferred from sleep/stress/autonomic signals and trend direction logic across the week.",
                                interpretation: "Improving recovery trend supports safer progression in workload."
                            )
                        )
                        metric(
                            key: "insights-weekly-fatloss",
                            title: "Fat Loss",
                            value: report.fatLossStatus,
                            detail: MetricBreakdownDetail(
                                title: "Weekly Fat Loss Status",
                                trackedValues: [
                                    "Fat loss status: \(report.fatLossStatus)",
                                    "Consistency percent: \(report.consistencyPercent)%"
                                ],
                                formula: "Status is derived from body-composition trend signals and current consistency context.",
                                interpretation: "Use this as a weekly directional check rather than a day-to-day scale signal."
                            )
                        )
                    }
                }
                .padding(14)
                .background(FitCompColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(FitCompColors.cardBorder, lineWidth: 1))
            }
        }
    }

    private func insightCard(title: String, insight: InsightItem, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.stepCaptionBold())
                .foregroundStyle(FitCompColors.textSecondary)
            Text(insight.title)
                .font(.stepBody())
                .foregroundStyle(FitCompColors.textPrimary)
            Text(insight.message)
                .font(.stepBodySmall())
                .foregroundStyle(FitCompColors.textSecondary)
            Text("Confidence \(insight.confidence)%")
                .font(.stepCaption())
                .foregroundStyle(accent)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FitCompColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(FitCompColors.cardBorder, lineWidth: 1))
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

    private func signedPercent(_ value: Double) -> String {
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
