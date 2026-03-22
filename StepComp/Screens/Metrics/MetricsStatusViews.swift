//
//  MetricsStatusViews.swift
//  StepComp
//

import SwiftUI

struct MetricBreakdownDetail: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let trackedValues: [String]
    let formula: String
    let interpretation: String
}

struct ExpandableMetricCard<Content: View>: View {
    @Binding var isExpanded: Bool
    let detail: MetricBreakdownDetail
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                content()
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(FitCompColors.textSecondary)
                            .padding(8)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Metric details for \(detail.title)")
            .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand") calculation details.")

            if isExpanded {
                MetricBreakdownDetailView(detail: detail)
                    .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
            }
        }
    }
}

struct MetricBreakdownDetailView: View {
    let detail: MetricBreakdownDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tracked Numbers")
                .font(.stepCaptionBold())
                .foregroundStyle(FitCompColors.textSecondary)

            ForEach(detail.trackedValues, id: \.self) { value in
                Text("• \(value)")
                    .font(.stepBodySmall())
                    .foregroundStyle(FitCompColors.textPrimary)
            }

            Text("Calculation")
                .font(.stepCaptionBold())
                .foregroundStyle(FitCompColors.textSecondary)
                .padding(.top, 4)

            Text(detail.formula)
                .font(.stepBodySmall())
                .foregroundStyle(FitCompColors.textPrimary)

            Text("Interpretation")
                .font(.stepCaptionBold())
                .foregroundStyle(FitCompColors.textSecondary)
                .padding(.top, 4)

            Text(detail.interpretation)
                .font(.stepBodySmall())
                .foregroundStyle(FitCompColors.textPrimary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FitCompColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(FitCompColors.cardBorder, lineWidth: 1)
        )
    }
}

struct PillarHeader: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(FitCompColors.primary)
                .frame(width: 34, height: 34)
                .background(FitCompColors.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.stepTitleMedium())
                    .foregroundStyle(FitCompColors.textPrimary)
                Text(subtitle)
                    .font(.stepBodySmall())
                    .foregroundStyle(FitCompColors.textSecondary)
            }
            Spacer()
        }
    }
}

struct MetricStatusBadge: View {
    let status: MetricStatus

    var body: some View {
        Text(status.label)
            .font(.stepCaptionBold())
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .excellent, .optimal:
            return FitCompColors.green
        case .good:
            return FitCompColors.cyan
        case .moderate:
            return FitCompColors.orange
        case .low, .atRisk:
            return FitCompColors.coral
        }
    }
}

struct MetricTrendIndicator: View {
    let direction: TrendDirection
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .bold))
            Text(text)
                .font(.stepBodySmall())
        }
        .foregroundStyle(color)
    }

    private var iconName: String {
        switch direction {
        case .improving:
            return "arrow.up.right"
        case .stable:
            return "minus"
        case .declining:
            return "arrow.down.right"
        }
    }

    private var color: Color {
        switch direction {
        case .improving:
            return FitCompColors.green
        case .stable:
            return FitCompColors.textSecondary
        case .declining:
            return FitCompColors.coral
        }
    }
}

struct ScoreRing: View {
    let score: Int
    var size: CGFloat = 80
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(FitCompColors.surfaceElevated, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(.stepNumberMedium())
                    .foregroundStyle(FitCompColors.textPrimary)
                Text("/100")
                    .font(.stepCaption())
                    .foregroundStyle(FitCompColors.textSecondary)
            }
        }
        .frame(width: size, height: size)
    }

    private var progress: CGFloat {
        CGFloat(max(0, min(score, 100))) / 100.0
    }

    private var ringColor: Color {
        if score >= 90 { return FitCompColors.green }
        if score >= 75 { return FitCompColors.cyan }
        if score >= 60 { return FitCompColors.orange }
        return FitCompColors.coral
    }
}

struct MetricStatusCard: View {
    let title: String
    let score: Int
    let status: MetricStatus
    let action: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.stepBody())
                    .foregroundStyle(FitCompColors.textPrimary)
                Spacer()
                MetricStatusBadge(status: status)
            }
            HStack(alignment: .center, spacing: 12) {
                ScoreRing(score: score, size: 62, lineWidth: 7)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Action")
                        .font(.stepCaption())
                        .foregroundStyle(FitCompColors.textSecondary)
                    Text(action)
                        .font(.stepBody())
                        .foregroundStyle(FitCompColors.textPrimary)
                }
                Spacer()
            }
        }
        .padding(14)
        .background(FitCompColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(FitCompColors.cardBorder, lineWidth: 1)
        )
    }
}

struct KillerScoreBar: View {
    let title: String
    let score: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.stepCaptionBold())
                    .foregroundStyle(FitCompColors.textSecondary)
                Spacer()
                Text("\(score)")
                    .font(.stepBody())
                    .foregroundStyle(FitCompColors.textPrimary)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(FitCompColors.surfaceElevated)
                    Capsule()
                        .fill(FitCompColors.primaryGradient(for: .light))
                        .frame(width: proxy.size.width * CGFloat(max(0, min(score, 100))) / 100.0)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(FitCompColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(FitCompColors.cardBorder, lineWidth: 1)
        )
    }
}
