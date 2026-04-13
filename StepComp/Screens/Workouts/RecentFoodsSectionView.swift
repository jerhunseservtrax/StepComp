//
//  RecentFoodsSectionView.swift
//  FitComp
//

import SwiftUI

struct RecentFoodsSectionView: View {
    @ObservedObject var viewModel: FoodLogViewModel
    let selectedResultKeys: Set<String>
    var selectionKey: (FoodItem) -> String
    var onToggle: (FoodItem) -> Void

    var body: some View {
        if !viewModel.cachedFoods.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("RECENT FOODS")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1)
                        .foregroundColor(FitCompColors.textSecondary)
                    Spacer()
                    Text("Tap to reuse")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(FitCompColors.textTertiary)
                }

                ForEach(viewModel.cachedFoods.prefix(15)) { item in
                    let key = selectionKey(item)
                    let isSelected = selectedResultKeys.contains(key)
                    Button(action: { onToggle(item) }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(FitCompColors.textPrimary)
                                Text("\(Int(item.servingSizeG))g • P:\(Int(item.proteinG)) C:\(Int(item.carbsG)) F:\(Int(item.fatG))")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(FitCompColors.textSecondary)
                            }
                            Spacer()
                            Text("\(Int(item.calories)) cal")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(FitCompColors.textPrimary)
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(isSelected ? FitCompColors.primary : FitCompColors.textSecondary.opacity(0.55))
                                .padding(.leading, 6)
                        }
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
