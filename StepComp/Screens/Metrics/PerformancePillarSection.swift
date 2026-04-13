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
                                    .accessibilityLabel("Load balance status: \(performance.trainingLoadBalance.status.label)")
                                    .accessibilityHint("Summarizes whether recent training load is balanced versus chronic workload.")
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(FitCompColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(FitCompColors.cardBorder, lineWidth: 1))
                    }
                    .accessibilityValue(loadBalanceDisplay(performance.trainingLoadBalance))
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
                        .accessibilityLabel(performance.plateauDetection.message ?? "Plateau detected")
                        .accessibilityHint("Indicates strength progress may have slowed; consider adjusting volume or intensity.")
                }

                if performance.movementPatternBalance.hasData {
                    MovementPatternBalanceCard(balance: performance.movementPatternBalance)
                }

                if !performance.muscleBalance.isEmpty {
                    MuscleBalanceCardView(
                        title: "Muscle Group Balance",
                        subtitle: "Top-8 share of volume (%) · primary 1×, secondary 0.5× per tag",
                        data: performance.muscleBalance
                    )
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
        .accessibilityValue(value)
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

// MARK: - Push/pull & lower-chain ratios

private struct MovementPatternBalanceCard: View {
    let balance: MovementPatternBalance

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MOVEMENT BALANCE")
                    .font(.stepCaptionBold())
                    .foregroundStyle(FitCompColors.textSecondary)
                Text("Volume ratios from weighted muscle totals (same rules as the radar chart).")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FitCompColors.textSecondary.opacity(0.9))
            }

            VStack(spacing: 10) {
                ratioRow(
                    title: "Push / pull",
                    caption: "Chest, shoulders, triceps vs back & biceps. Near 1.0 is balanced; slightly higher pull (≈1.1) often supports shoulders.",
                    ratio: balance.pushPullRatio,
                    leftLabel: "push",
                    rightLabel: "pull",
                    leftVolume: balance.pushVolume,
                    rightVolume: balance.pullVolume
                )

                ratioRow(
                    title: "Posterior / quad (legs)",
                    caption: "Hamstrings + glutes vs quads. Near 1.0 is even lower-chain volume.",
                    ratio: balance.posteriorToQuadRatio,
                    leftLabel: "post.",
                    rightLabel: "quad",
                    leftVolume: balance.posteriorLegVolume,
                    rightVolume: balance.quadVolume
                )
            }
        }
        .padding(14)
        .background(FitCompColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FitCompColors.cardBorder, lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Movement pattern balance")
        .accessibilityHint("Swipe to hear push versus pull and posterior versus quad volume ratios.")
    }

    private func ratioRow(
        title: String,
        caption: String,
        ratio: Double?,
        leftLabel: String,
        rightLabel: String,
        leftVolume: Double,
        rightVolume: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(FitCompColors.textPrimary)

            Text(caption)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(FitCompColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if leftVolume == 0 && rightVolume == 0 {
                    Text("No volume in this period")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FitCompColors.textSecondary)
                } else if let ratio {
                    Text(String(format: "%.2f", ratio))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(FitCompColors.textPrimary)
                    Text("(\(leftLabel) / \(rightLabel))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(FitCompColors.textSecondary)
                } else {
                    Text("—")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FitCompColors.textSecondary)
                    Text("(not enough \(rightLabel) volume)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(FitCompColors.textTertiary)
                }
                Spacer()
            }

            HStack {
                Text(String(format: "%.0f \(leftLabel)", leftVolume))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(FitCompColors.textSecondary)
                Spacer()
                Text(String(format: "%.0f \(rightLabel)", rightVolume))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(FitCompColors.textSecondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FitCompColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(FitCompColors.cardBorder, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ratioAccessibilityLabel(
            title: title,
            caption: caption,
            ratio: ratio,
            leftLabel: leftLabel,
            rightLabel: rightLabel,
            leftVolume: leftVolume,
            rightVolume: rightVolume
        ))
    }

    private func ratioAccessibilityLabel(
        title: String,
        caption: String,
        ratio: Double?,
        leftLabel: String,
        rightLabel: String,
        leftVolume: Double,
        rightVolume: Double
    ) -> String {
        if leftVolume == 0 && rightVolume == 0 {
            return "\(title). No training volume in this period. \(caption)"
        }
        if let ratio {
            return "\(title). Ratio \(String(format: "%.2f", ratio)), \(Int(leftVolume)) \(leftLabel) volume, \(Int(rightVolume)) \(rightLabel) volume. \(caption)"
        }
        return "\(title). Not enough \(rightLabel) volume to compute a ratio. \(Int(leftVolume)) \(leftLabel) volume, \(Int(rightVolume)) \(rightLabel) volume. \(caption)"
    }
}
