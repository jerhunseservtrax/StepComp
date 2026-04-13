//
//  FoodLogMealSectionView.swift
//  FitComp
//

import SwiftUI

struct FoodLogMealSectionView: View {
    let mealType: MealType
    let mealEntries: [FoodLogEntry]
    @ObservedObject var viewModel: FoodLogViewModel
    var onAddMeal: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: mealType.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(FitCompColors.primary)
                Text(mealType.title.uppercased())
                    .font(.system(size: 13, weight: .black))
                    .tracking(1)
                    .foregroundColor(FitCompColors.textSecondary)
                Spacer()
                if !mealEntries.isEmpty {
                    let totalCal = mealEntries.reduce(0.0) { $0 + $1.totalCalories }
                    Text("\(Int(totalCal)) cal")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(FitCompColors.textSecondary)
                }
            }

            if mealEntries.isEmpty {
                Button(action: onAddMeal) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add \(mealType.title)")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(FitCompColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(FitCompColors.textSecondary.opacity(0.06))
                    .cornerRadius(12)
                }
            } else {
                ForEach(mealEntries) { entry in
                    MealEntryRow(entry: entry, viewModel: viewModel)
                }
            }
        }
        .padding(14)
        .background(colorScheme == .dark ? Color(hex: "1a1a1a") : Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}
