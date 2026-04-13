//
//  MuscleBalanceCardView.swift
//  StepComp
//

import SwiftUI

struct MuscleBalanceCardView: View {
    let title: String
    let subtitle: String
    let data: [MuscleGroupVolume]

    @Environment(\.colorScheme) private var colorScheme

    private var topMuscles: [MuscleGroupVolume] {
        Array(data.sorted(by: { $0.volume > $1.volume }).prefix(8))
    }

    private var totalVolume: Double {
        topMuscles.reduce(0.0) { $0 + $1.volume }
    }

    private var normalized: [(id: String, label: String, percentage: Double, volume: Double)] {
        topMuscles.map { point in
            let percentage = totalVolume > 0 ? (point.volume / totalVolume) * 100.0 : 0
            return (id: point.id, label: point.muscleGroup, percentage: percentage, volume: point.volume)
        }
    }

    private var topShare: Double { normalized.first?.percentage ?? 0 }
    private var bottomShare: Double { normalized.last?.percentage ?? 0 }
    private var spread: Double { max(0, topShare - bottomShare) }

    private var muscleBalanceAccessibilitySummary: String {
        let breakdown = normalized
            .map { "\($0.label) \(String(format: "%.1f", $0.percentage)) percent" }
            .joined(separator: ", ")
        return "\(title). \(subtitle) Summary: highest share \(String(format: "%.1f", topShare)) percent, lowest \(String(format: "%.1f", bottomShare)) percent, spread \(String(format: "%.1f", spread)) percent. Top eight muscle groups by volume share: \(breakdown). Includes a radar chart of relative shares."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.stepCaptionBold())
                    .foregroundStyle(FitCompColors.textSecondary)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FitCompColors.textSecondary.opacity(0.9))
            }

            HStack(spacing: 10) {
                statChip(title: "Highest", value: String(format: "%.1f%%", topShare))
                statChip(title: "Lowest", value: String(format: "%.1f%%", bottomShare))
                statChip(title: "Spread", value: String(format: "%.1f%%", spread))
            }

            RadarChartView(
                data: normalized.map { point in
                    RadarChartDataPoint(
                        id: point.id,
                        label: point.label,
                        value: point.percentage
                    )
                },
                levels: 5,
                maxReferenceValue: 100,
                fillColor: heatColor(for: max(topShare, 20)).opacity(0.28),
                strokeColor: heatColor(for: topShare),
                pointColors: normalized.map { heatColor(for: $0.percentage) }
            )
            .frame(height: 300)
            .padding(.horizontal, 4)

            heatLegend

            VStack(spacing: 10) {
                ForEach(normalized, id: \.id) { point in
                    VStack(spacing: 4) {
                        HStack {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(heatColor(for: point.percentage))
                                    .frame(width: 8, height: 8)
                                Text(point.label)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(FitCompColors.textPrimary)
                            }
                            Spacer()
                            Text(String(format: "%.1f%%", point.percentage))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(heatColor(for: point.percentage))
                        }

                        ProgressView(value: point.percentage, total: 100)
                            .tint(heatColor(for: point.percentage))

                        HStack {
                            Spacer()
                            Text(String(format: "%.0f total volume", point.volume))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(FitCompColors.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(FitCompColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FitCompColors.cardBorder, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(muscleBalanceAccessibilitySummary)
        .accessibilityHint("Describes how much of your recent training volume each muscle group received.")
    }

    private func statChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(FitCompColors.textSecondary)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(FitCompColors.textPrimary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FitCompColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(FitCompColors.cardBorder, lineWidth: 1))
    }

    private func heatColor(for percentage: Double) -> Color {
        let t = max(0, min(1, percentage / 100.0))
        let start: (Double, Double, Double)
        let end: (Double, Double, Double)

        if colorScheme == .dark {
            start = (0.96, 0.82, 0.36)
            end = (1.00, 0.38, 0.05)
        } else {
            start = (1.00, 0.92, 0.70)
            end = (0.98, 0.47, 0.02)
        }

        let r = start.0 + (end.0 - start.0) * t
        let g = start.1 + (end.1 - start.1) * t
        let b = start.2 + (end.2 - start.2) * t
        return Color(red: r, green: g, blue: b)
    }

    private var heatLegend: some View {
        HStack(spacing: 8) {
            Text("Low")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(FitCompColors.textSecondary)

            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [heatColor(for: 8), heatColor(for: 92)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 110, height: 10)

            Text("High")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(FitCompColors.textSecondary)

            Spacer()
        }
        .padding(.top, 2)
    }
}
