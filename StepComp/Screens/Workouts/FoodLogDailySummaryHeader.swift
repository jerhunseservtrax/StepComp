//
//  FoodLogDailySummaryHeader.swift
//  FitComp
//

import SwiftUI

struct FoodLogDailySummaryHeader: View {
    let summary: DailyNutritionSummary
    var onEditCalorieGoal: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(FitCompColors.textSecondary.opacity(0.15), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    Circle()
                        .trim(from: 0, to: summary.calorieProgress)
                        .stroke(FitCompColors.primary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 2) {
                        Text("\(Int(summary.totalCalories))")
                            .font(.system(size: 24, weight: .black))
                        Button {
                            onEditCalorieGoal()
                        } label: {
                            HStack(spacing: 4) {
                                Text("/ \(summary.calorieGoal) cal")
                                    .font(.system(size: 11, weight: .bold))
                                Image(systemName: "pencil")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(FitCompColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    macroStat("Protein", value: summary.totalProteinG, goal: Double(summary.proteinGoalG), color: FitCompColors.cyan)
                    macroStat("Carbs", value: summary.totalCarbsG, goal: nil, color: FitCompColors.accent)
                    macroStat("Fat", value: summary.totalFatG, goal: nil, color: FitCompColors.purple)
                }
            }
        }
        .padding(20)
        .background(colorScheme == .dark ? Color(hex: "1a1a1a") : Color.white)
        .cornerRadius(24)
    }

    private func macroStat(_ label: String, value: Double, goal: Double?, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(FitCompColors.textSecondary)
            Spacer()
            if let goal {
                Text("\(Int(value))/\(Int(goal))g")
                    .font(.system(size: 13, weight: .black))
            } else {
                Text("\(Int(value))g")
                    .font(.system(size: 13, weight: .black))
            }
        }
    }
}
