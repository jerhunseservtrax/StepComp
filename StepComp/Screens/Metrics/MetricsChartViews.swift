//
//  MetricsChartViews.swift
//  FitComp
//

import SwiftUI
import Charts

struct RadarChartDataPoint: Identifiable, Hashable {
    let id: String
    let label: String
    let value: Double
}

struct RadarChartShape: Shape {
    let normalizedValues: [Double]

    func path(in rect: CGRect) -> Path {
        guard normalizedValues.count >= 3 else { return Path() }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.42
        let angleStep = (2 * Double.pi) / Double(normalizedValues.count)

        var path = Path()
        for (index, value) in normalizedValues.enumerated() {
            let clamped = max(0.0, min(1.0, value))
            let angle = (Double(index) * angleStep) - (Double.pi / 2)
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle) * Double(radius) * clamped),
                y: center.y + CGFloat(sin(angle) * Double(radius) * clamped)
            )

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct RadarChartView: View {
    let data: [RadarChartDataPoint]
    var levels: Int = 4
    var fillColor: Color = FitCompColors.accent.opacity(0.30)
    var strokeColor: Color = FitCompColors.accent
    var axisColor: Color = FitCompColors.textSecondary.opacity(0.30)
    var labelColor: Color = FitCompColors.textSecondary

    private var normalizedValues: [Double] {
        let maxValue = data.map(\.value).max() ?? 1
        let safeMax = max(maxValue, 1)
        return data.map { $0.value / safeMax }
    }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size * 0.42
            let angleStep = (2 * Double.pi) / Double(max(data.count, 1))

            ZStack {
                ForEach(1...max(levels, 1), id: \.self) { level in
                    let scale = Double(level) / Double(max(levels, 1))
                    RadarChartShape(normalizedValues: Array(repeating: scale, count: data.count))
                        .stroke(axisColor, lineWidth: 1)
                }

                ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
                    Path { path in
                        let angle = (Double(index) * angleStep) - (Double.pi / 2)
                        let axisPoint = CGPoint(
                            x: center.x + CGFloat(cos(angle) * Double(radius)),
                            y: center.y + CGFloat(sin(angle) * Double(radius))
                        )
                        path.move(to: center)
                        path.addLine(to: axisPoint)
                    }
                    .stroke(axisColor, lineWidth: 1)

                    let labelRadius = radius + 18
                    let labelAngle = (Double(index) * angleStep) - (Double.pi / 2)
                    let labelPoint = CGPoint(
                        x: center.x + CGFloat(cos(labelAngle) * Double(labelRadius)),
                        y: center.y + CGFloat(sin(labelAngle) * Double(labelRadius))
                    )

                    Text(point.label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(labelColor)
                        .position(labelPoint)
                }

                RadarChartShape(normalizedValues: normalizedValues)
                    .fill(fillColor)

                RadarChartShape(normalizedValues: normalizedValues)
                    .stroke(strokeColor, lineWidth: 2.5)

                ForEach(Array(normalizedValues.enumerated()), id: \.offset) { index, value in
                    let angle = (Double(index) * angleStep) - (Double.pi / 2)
                    let point = CGPoint(
                        x: center.x + CGFloat(cos(angle) * Double(radius) * value),
                        y: center.y + CGFloat(sin(angle) * Double(radius) * value)
                    )

                    Circle()
                        .fill(strokeColor)
                        .frame(width: 8, height: 8)
                        .position(point)
                }
            }
        }
    }
}

struct StepBarChart: View {
    let data: [MetricBarPoint]

    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Period", point.label),
                y: .value("Steps", point.value)
            )
            .foregroundStyle(FitCompColors.primary.gradient)
            .cornerRadius(4)
        }
        .frame(height: 180)
    }
}

struct WorkoutBarChart: View {
    let data: [MetricBarPoint]

    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Period", point.label),
                y: .value("Sessions", point.value)
            )
            .foregroundStyle(FitCompColors.cyan.gradient)
            .cornerRadius(4)
        }
        .frame(height: 180)
    }
}

struct WeightTrendChart: View {
    let points: [WeightHistoryPoint]
    @ObservedObject private var unitManager = UnitPreferenceManager.shared
    @State private var selectedIndex: Int?

    private static let dateParser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var parsedPoints: [(date: Date, weight: Double)] {
        points.compactMap { point in
            guard let date = Self.dateParser.date(from: point.recordedOn) else { return nil }
            return (date, unitManager.convertWeight(kg: point.weightKg))
        }
        .sorted(by: { $0.date < $1.date })
    }

    private var weightUnit: String { unitManager.weightUnit }

    private var yDomain: ClosedRange<Double> {
        let weights = parsedPoints.map(\.weight)
        guard let minW = weights.min(), let maxW = weights.max() else { return 0...100 }
        let step: Double = 5
        let lower = (minW / step).rounded(.down) * step - step
        let upper = (maxW / step).rounded(.up) * step + step
        return lower...upper
    }

    private var yTickValues: [Double] {
        let step: Double = 5
        let domain = yDomain
        var ticks: [Double] = []
        var v = domain.lowerBound
        while v <= domain.upperBound {
            ticks.append(v)
            v += step
        }
        return ticks
    }

    private var selectedPoint: (date: Date, weight: Double)? {
        guard let idx = selectedIndex, parsedPoints.indices.contains(idx) else { return nil }
        return parsedPoints[idx]
    }

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    private let startColor = Color(red: 0.35, green: 0.55, blue: 0.95)
    private let endColor = Color(red: 1.0, green: 0.55, blue: 0.25)

    var body: some View {
        chartSection
    }

    // MARK: - Chart

    @ViewBuilder
    private var chartSection: some View {
        let sorted = parsedPoints

        if sorted.count >= 2 {
            ZStack(alignment: .topLeading) {
                Chart(Array(sorted.enumerated()), id: \.offset) { index, point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [startColor, endColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [startColor.opacity(0.25), endColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    if index == 0 {
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(startColor)
                        .symbolSize(50)
                        .annotation(position: .top, alignment: .leading, spacing: 6) {
                            endpointLabel(
                                weight: point.weight,
                                date: point.date,
                                color: startColor
                            )
                        }
                    }

                    if index == sorted.count - 1 {
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(endColor)
                        .symbolSize(50)
                        .annotation(position: .top, alignment: .trailing, spacing: 6) {
                            endpointLabel(
                                weight: point.weight,
                                date: point.date,
                                color: endColor
                            )
                        }
                    }

                    if let sel = selectedIndex, sel == index {
                        RuleMark(x: .value("Date", point.date))
                            .foregroundStyle(FitCompColors.textSecondary.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(.white)
                        .symbolSize(80)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(endColor)
                        .symbolSize(40)
                    }
                }
                .chartYScale(domain: yDomain)
                .chartYAxis {
                    AxisMarks(values: yTickValues) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(FitCompColors.textSecondary.opacity(0.15))
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))")
                                    .font(.system(size: 10))
                                    .foregroundStyle(FitCompColors.textSecondary.opacity(0.6))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(FitCompColors.textSecondary.opacity(0.1))
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                                    .font(.system(size: 10))
                                    .foregroundStyle(FitCompColors.textSecondary.opacity(0.6))
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let origin = geo[proxy.plotFrame!].origin
                                        let locationX = value.location.x - origin.x
                                        guard let date: Date = proxy.value(atX: locationX) else { return }
                                        let closest = sorted.enumerated().min(by: {
                                            abs($0.element.date.timeIntervalSince(date)) <
                                            abs($1.element.date.timeIntervalSince(date))
                                        })
                                        selectedIndex = closest?.offset
                                    }
                                    .onEnded { _ in
                                        selectedIndex = nil
                                    }
                            )
                    }
                }
                .frame(height: 220)

                if let sel = selectedPoint {
                    scrubTooltip(weight: sel.weight, date: sel.date)
                        .padding(.leading, 8)
                        .padding(.top, 4)
                        .transition(.opacity)
                        .animation(.easeOut(duration: 0.15), value: selectedIndex)
                }
            }
        } else {
            Text("Log at least 2 weights to see your trend")
                .font(.stepCaption())
                .foregroundStyle(FitCompColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(height: 180)
        }
    }

    // MARK: - Helper Views

    private func endpointLabel(weight: Double, date: Date, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(String(format: "%.1f", weight))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color) +
            Text(weightUnit)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(color.opacity(0.8))

            Text(Self.shortDateFormatter.string(from: date))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(FitCompColors.textSecondary.opacity(0.7))
        }
    }

    private func scrubTooltip(weight: Double, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(String(format: "%.1f %@", weight, weightUnit))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(FitCompColors.textPrimary)
            Text(Self.shortDateFormatter.string(from: date))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(FitCompColors.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(FitCompColors.surface.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 2)
    }

}

struct WeightLossSummaryCard: View {
    let points: [WeightHistoryPoint]
    @ObservedObject private var unitManager = UnitPreferenceManager.shared

    private static let dateParser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var parsedPoints: [(date: Date, weight: Double)] {
        points.compactMap { point in
            guard let date = Self.dateParser.date(from: point.recordedOn) else { return nil }
            return (date, unitManager.convertWeight(kg: point.weightKg))
        }
        .sorted(by: { $0.date < $1.date })
    }

    private var weightUnit: String { unitManager.weightUnit }
    private var firstPoint: (date: Date, weight: Double)? { parsedPoints.first }
    private var lastPoint: (date: Date, weight: Double)? { parsedPoints.last }

    private var totalChange: Double? {
        guard let first = firstPoint, let last = lastPoint else { return nil }
        return last.weight - first.weight
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Weight Loss Summary")
                .font(.stepTitleSmall())
                .foregroundStyle(FitCompColors.textPrimary)

            VStack(spacing: 0) {
                if let first = firstPoint {
                    summaryRow(
                        title: "Initial Weight",
                        value: String(format: "%.1f %@", first.weight, weightUnit)
                    )
                }

                if let last = lastPoint {
                    Divider()
                        .overlay(FitCompColors.cardBorder)
                    summaryRow(
                        title: "Current Weight",
                        value: String(format: "%.1f %@", last.weight, weightUnit)
                    )
                }

                if let change = totalChange {
                    Divider()
                        .overlay(FitCompColors.cardBorder)
                    summaryRow(
                        title: "Total Change",
                        value: String(format: "%@%.1f %@", change >= 0 ? "+" : "", change, weightUnit)
                    )
                }
            }

            if let change = totalChange {
                Text(change < 0
                     ? "Great work! Share your progress to keep the momentum going."
                     : "Stay consistent and your trend will move in the right direction.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(FitCompColors.textSecondary)
                    .padding(.top, 2)
            }
        }
        .padding(16)
        .background(FitCompColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FitCompColors.cardBorder, lineWidth: 1))
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(FitCompColors.textPrimary)
            Spacer()
            Text(value.uppercased())
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(FitCompColors.textPrimary)
        }
        .padding(.vertical, 10)
    }
}

struct YearComparisonChart: View {
    let data: [YearMetricPoint]

    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Total Steps", point.value),
                y: .value("Year", "\(point.year)")
            )
            .foregroundStyle(FitCompColors.primary.gradient)
            .cornerRadius(4)
        }
        .frame(height: 180)
    }
}

struct SparklineView: View {
    let values: [Double]
    let color: Color

    init(values: [Double], color: Color = FitCompColors.primary) {
        self.values = values
        self.color = color
    }

    var body: some View {
        Chart(Array(values.enumerated()), id: \.offset) { index, value in
            LineMark(
                x: .value("Index", index),
                y: .value("Value", value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(color)
            if index == values.count - 1 {
                PointMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(color)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 52)
    }
}

struct ScoreRingView: View {
    let score: Int
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(FitCompColors.surfaceElevated, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(score, 100))) / 100.0)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(.stepNumberMedium())
                .foregroundStyle(FitCompColors.textPrimary)
        }
        .frame(width: 74, height: 74)
    }

    private var ringColor: Color {
        if score >= 90 { return FitCompColors.green }
        if score >= 75 { return FitCompColors.cyan }
        if score >= 60 { return FitCompColors.orange }
        return FitCompColors.coral
    }
}

struct KillerScoresBarView: View {
    let scores: KillerScores

    private var items: [(String, Int)] {
        [
            ("Momentum", scores.momentum),
            ("Fitness", scores.fitness),
            ("Recovery", scores.recovery),
            ("Training", scores.trainingBalance),
            ("Discipline", scores.discipline)
        ]
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(items, id: \.0) { item in
                KillerScoreBar(title: item.0, score: item.1)
            }
        }
    }
}
