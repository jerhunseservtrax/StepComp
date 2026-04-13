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
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityLabel("Weekly performance report")
                    HStack(spacing: 10) {
                        metric(
                            key: "insights-weekly-strength",
                            title: "Strength",
                            value: signedPercent(report.strengthChangePercent),
                            detail: MetricBreakdownDetail(
                                title: "Weekly Strength Change",
                                trackedValues: [
                                    "Weekly strength change: \(signedPercent(report.strengthChangePercent))",
                                    "Compared lifts: \(report.comparedLiftCount)"
                                ],
                                formula: "Compares recent strength indicators to the prior period and expresses the delta as a percent.",
                                interpretation: "Positive changes suggest your current programming and recovery are translating to better output."
                            )
                        )
                        metric(
                            key: "insights-weekly-workouts",
                            title: "Workouts",
                            value: "\(report.workoutsCompleted)",
                            detail: MetricBreakdownDetail(
                                title: "Workouts Completed",
                                trackedValues: [
                                    "Completed workouts: \(report.workoutsCompleted)",
                                    "Compared lifts: \(report.comparedLiftCount)"
                                ],
                                formula: "Counts the total logged workout sessions included in the active metrics period.",
                                interpretation: "Higher counts generally improve confidence in trend metrics and progress signals."
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(insight.title) \(insight.message) Confidence \(insight.confidence) percent.")
        .accessibilityHint("Automated insight based on your recent training data.")
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
        .accessibilityValue(value)
    }

    private func signedPercent(_ value: Double?) -> String {
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
