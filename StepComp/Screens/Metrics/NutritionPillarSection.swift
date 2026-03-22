//
//  NutritionPillarSection.swift
//  FitComp
//

import SwiftUI
import Charts

struct NutritionPillarSection: View {
    @ObservedObject var viewModel: MetricsViewModel

    private var logs: [NutritionLog] {
        viewModel.nutritionLogs(forLast: viewModel.selectedTimePeriod.lookbackDays)
    }

    private var dailyGroups: [(date: Date, calories: Int, protein: Int, carbs: Int, fat: Int)] {
        let grouped = Dictionary(grouping: logs) { Calendar.current.startOfDay(for: $0.loggedAt) }
        return grouped
            .map { day, entries in
                (
                    date: day,
                    calories: entries.reduce(0) { $0 + $1.calories },
                    protein: entries.reduce(0) { $0 + $1.proteinG },
                    carbs: entries.reduce(0) { $0 + $1.carbsG },
                    fat: entries.reduce(0) { $0 + $1.fatG }
                )
            }
            .sorted { $0.date < $1.date }
    }

    private var avgCalories: Int {
        guard !dailyGroups.isEmpty else { return 0 }
        let total = dailyGroups.reduce(0) { $0 + $1.calories }
        return Int((Double(total) / Double(dailyGroups.count)).rounded())
    }

    private var calorieGoal: Int {
        viewModel.calorieTarget
    }

    private var adherencePercent: Int {
        guard !dailyGroups.isEmpty else { return 0 }
        let tolerance = Double(calorieGoal) * 0.1
        let adherentDays = dailyGroups.filter { abs(Double($0.calories - calorieGoal)) <= tolerance }.count
        return Int((Double(adherentDays) / Double(dailyGroups.count) * 100.0).rounded())
    }

    private var macroTotals: (protein: Int, carbs: Int, fat: Int) {
        (
            protein: dailyGroups.reduce(0) { $0 + $1.protein },
            carbs: dailyGroups.reduce(0) { $0 + $1.carbs },
            fat: dailyGroups.reduce(0) { $0 + $1.fat }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PillarHeader(
                title: "NUTRITION",
                subtitle: "Are calorie intake and macros aligned?",
                icon: "fork.knife.circle"
            )

            if dailyGroups.isEmpty {
                Text("No nutrition logs for this period yet. Log meals from Food Log to see trends.")
                    .font(.stepBodySmall())
                    .foregroundStyle(FitCompColors.textSecondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FitCompColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(FitCompColors.cardBorder, lineWidth: 1))
            } else {
                calorieTrendCard

                HStack(spacing: 10) {
                    nutritionMetric(title: "Avg Calories", value: "\(avgCalories)")
                    nutritionMetric(title: "Target", value: "\(calorieGoal)")
                }

                HStack(spacing: 10) {
                    nutritionMetric(title: "Adherence", value: "\(adherencePercent)%")
                    nutritionMetric(title: "Logged Days", value: "\(dailyGroups.count)")
                }

                macroCard
            }
        }
    }

    private var calorieTrendCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calorie Trend")
                .font(.stepCaptionBold())
                .foregroundStyle(FitCompColors.textSecondary)

            Chart(dailyGroups, id: \.date) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Calories", point.calories)
                )
                .foregroundStyle(FitCompColors.primary)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Calories", point.calories)
                )
                .foregroundStyle(FitCompColors.primary)

                RuleMark(y: .value("Target", calorieGoal))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .foregroundStyle(FitCompColors.cyan.opacity(0.8))
            }
            .frame(height: 180)
        }
        .padding(14)
        .background(FitCompColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FitCompColors.cardBorder, lineWidth: 1))
    }

    private var macroCard: some View {
        let totals = macroTotals
        let macroTotal = max(totals.protein + totals.carbs + totals.fat, 1)
        let proteinPct = Int((Double(totals.protein) / Double(macroTotal) * 100.0).rounded())
        let carbsPct = Int((Double(totals.carbs) / Double(macroTotal) * 100.0).rounded())
        let fatPct = Int((Double(totals.fat) / Double(macroTotal) * 100.0).rounded())

        return VStack(alignment: .leading, spacing: 10) {
            Text("Macro Breakdown")
                .font(.stepCaptionBold())
                .foregroundStyle(FitCompColors.textSecondary)

            macroRow(name: "Protein", grams: totals.protein, percent: proteinPct, color: FitCompColors.cyan)
            macroRow(name: "Carbs", grams: totals.carbs, percent: carbsPct, color: FitCompColors.accent)
            macroRow(name: "Fat", grams: totals.fat, percent: fatPct, color: FitCompColors.purple)
        }
        .padding(14)
        .background(FitCompColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(FitCompColors.cardBorder, lineWidth: 1))
    }

    private func macroRow(name: String, grams: Int, percent: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.stepBodySmall())
                    .foregroundStyle(FitCompColors.textSecondary)
                Spacer()
                Text("\(grams)g (\(percent)%)")
                    .font(.stepCaptionBold())
                    .foregroundStyle(FitCompColors.textPrimary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.2))
                    Capsule().fill(color).frame(width: geo.size.width * CGFloat(percent) / 100.0)
                }
            }
            .frame(height: 7)
        }
    }

    private func nutritionMetric(title: String, value: String) -> some View {
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
