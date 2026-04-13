//
//  FoodLogSummaryCard.swift
//  FitComp
//

import SwiftUI

// MARK: - Summary Card (embedded in WorkoutsView)

struct FoodLogSummaryCard: View {
    @ObservedObject var viewModel: FoodLogViewModel
    @Binding var showingFoodLog: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var summary: DailyNutritionSummary { viewModel.todaySummary }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1a1a1a") : Color(hex: "f8f8f5")
    }

    var body: some View {
        Button(action: { showingFoodLog = true }) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("FOOD LOG")
                        .font(.system(size: 13, weight: .black))
                        .tracking(1.5)
                        .foregroundColor(FitCompColors.textSecondary)

                    Spacer()

                    Text(Date.now, style: .date)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(FitCompColors.textSecondary)
                }

                HStack(spacing: 0) {
                    calorieRing
                        .frame(width: 80, height: 80)

                    Spacer().frame(width: 20)

                    VStack(alignment: .leading, spacing: 10) {
                        macroRow(label: "Protein", value: summary.totalProteinG, goal: Double(summary.proteinGoalG), color: FitCompColors.cyan)
                        macroRow(label: "Carbs", value: summary.totalCarbsG, goal: nil, color: FitCompColors.accent)
                        macroRow(label: "Fat", value: summary.totalFatG, goal: nil, color: FitCompColors.purple)
                    }
                    .frame(maxWidth: .infinity)
                }

                if !viewModel.todayEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DAILY LOG")
                            .font(.system(size: 11, weight: .black))
                            .tracking(1)
                            .foregroundColor(FitCompColors.textSecondary)
                        ForEach(viewModel.todayEntries.prefix(2)) { entry in
                            mealPreviewRow(entry)
                        }
                    }
                }

                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Log a Meal")
                        .font(.system(size: 14, weight: .bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(FitCompColors.textSecondary.opacity(0.5))
                }
                .foregroundColor(FitCompColors.primary)
            }
            .padding(20)
            .background(cardBackground)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var calorieRing: some View {
        ZStack {
            Circle()
                .stroke(FitCompColors.textSecondary.opacity(0.15), lineWidth: 8)

            Circle()
                .trim(from: 0, to: summary.calorieProgress)
                .stroke(FitCompColors.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(Int(summary.totalCalories))")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(FitCompColors.textPrimary)
                Text("/ \(summary.calorieGoal)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(FitCompColors.textSecondary)
                Text("cal")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(FitCompColors.textSecondary)
            }
        }
    }

    private func macroRow(label: String, value: Double, goal: Double?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(FitCompColors.textSecondary)
                Spacer()
                if let goal {
                    Text("\(Int(value))/\(Int(goal))g")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(FitCompColors.textPrimary)
                } else {
                    Text("\(Int(value))g")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(FitCompColors.textPrimary)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.15))
                    Capsule()
                        .fill(color)
                        .frame(width: barWidth(value: value, goal: goal, totalWidth: geo.size.width))
                }
            }
            .frame(height: 5)
        }
    }

    private func barWidth(value: Double, goal: Double?, totalWidth: CGFloat) -> CGFloat {
        let target = goal ?? 200.0
        guard target > 0 else { return 0 }
        return min(CGFloat(value / target), 1.0) * totalWidth
    }

    private func mealPreviewRow(_ entry: FoodLogEntry) -> some View {
        HStack(spacing: 8) {
            Image(systemName: entry.mealType.icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(FitCompColors.primary)
                .frame(width: 22, height: 22)
                .background(FitCompColors.primary.opacity(0.12))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.mealType.title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(FitCompColors.textSecondary)
                Text(entry.description)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(FitCompColors.textPrimary)
                    .lineLimit(1)
            }
            Spacer()
            Text("\(Int(entry.totalCalories)) kcal")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(FitCompColors.textPrimary)
        }
        .padding(10)
        .background(FitCompColors.textSecondary.opacity(0.06))
        .cornerRadius(12)
    }
}
