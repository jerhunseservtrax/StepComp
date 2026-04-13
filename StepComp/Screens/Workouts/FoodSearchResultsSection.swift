//
//  FoodSearchResultsSection.swift
//  FitComp
//

import SwiftUI

struct FoodSearchResultsSection: View {
    @ObservedObject var viewModel: FoodLogViewModel
    let selectedResultKeys: Set<String>
    var selectionKey: (NutritionItem) -> String
    var onToggle: (NutritionItem) -> Void

    var body: some View {
        if !viewModel.searchResults.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("RESULTS")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1)
                    .foregroundColor(FitCompColors.textSecondary)

                ForEach(Array(viewModel.searchResults.enumerated()), id: \.offset) { _, item in
                    let key = selectionKey(item)
                    let isSelected = selectedResultKeys.contains(key)
                    Button(action: { onToggle(item) }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name.capitalized)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(FitCompColors.textPrimary)
                                Text("Tap to set weight (\(Int(item.servingSizeG))g default)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(FitCompColors.textSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                Text("\(Int(item.calories)) cal")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(FitCompColors.textPrimary)
                                Text("P:\(Int(item.proteinG)) C:\(Int(item.carbohydratesTotalG)) F:\(Int(item.fatTotalG))")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(FitCompColors.textSecondary)
                            }
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(isSelected ? FitCompColors.primary : FitCompColors.textSecondary.opacity(0.3))
                                .padding(.leading, 6)
                        }
                        .padding(12)
                        .background(isSelected ? FitCompColors.primary.opacity(0.08) : FitCompColors.textSecondary.opacity(0.04))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? FitCompColors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}
