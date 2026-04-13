//
//  RecentMealsSectionView.swift
//  FitComp
//

import SwiftUI

struct RecentMealsSectionView: View {
    @ObservedObject var viewModel: FoodLogViewModel
    var isMealSelected: (FoodLogEntry) -> Bool
    var onTapMeal: (FoodLogEntry) -> Void

    var body: some View {
        if !viewModel.recentMealEntries.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("RECENT MEALS")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1)
                        .foregroundColor(FitCompColors.textSecondary)
                    Spacer()
                    Text("Tap to reuse full meal")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(FitCompColors.textTertiary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(viewModel.recentMealEntries) { entry in
                            let isSelected = isMealSelected(entry)
                            Button(action: { onTapMeal(entry) }) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 8) {
                                        Image(systemName: entry.mealType.icon)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(FitCompColors.primary)
                                            .frame(width: 28, height: 28)
                                            .background(FitCompColors.primary.opacity(0.12))
                                            .clipShape(Circle())
                                        Text(entry.mealType.title.uppercased())
                                            .font(.system(size: 10, weight: .black))
                                            .tracking(0.8)
                                            .foregroundColor(FitCompColors.textSecondary)
                                        Spacer(minLength: 0)
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(isSelected ? FitCompColors.primary : FitCompColors.textSecondary.opacity(0.55))
                                    }

                                    Text(entry.description)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(FitCompColors.textPrimary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)

                                    HStack(spacing: 6) {
                                        Text("\(entry.items.count) item(s)")
                                        Text("•")
                                        Text("\(Int(entry.totalCalories)) cal")
                                    }
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(FitCompColors.textSecondary)
                                }
                                .frame(width: 220, alignment: .leading)
                                .padding(12)
                                .background(isSelected ? FitCompColors.primary.opacity(0.08) : FitCompColors.textSecondary.opacity(0.04))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }
}
