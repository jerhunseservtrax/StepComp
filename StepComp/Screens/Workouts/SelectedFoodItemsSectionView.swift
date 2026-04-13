//
//  SelectedFoodItemsSectionView.swift
//  FitComp
//

import SwiftUI

struct SelectedFoodItemsSectionView: View {
    @Binding var selectedItems: [FoodItem]
    @Binding var selectedResultKeys: Set<String>
    var selectionKey: (FoodItem) -> String

    var body: some View {
        if !selectedItems.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("SELECTED (\(selectedItems.count))")
                        .font(.system(size: 11, weight: .black))
                        .tracking(1)
                        .foregroundColor(FitCompColors.textSecondary)
                    Spacer()
                    let totalCal = selectedItems.reduce(0.0) { $0 + $1.calories }
                    Text("\(Int(totalCal)) cal total")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(FitCompColors.primary)
                }

                ForEach(selectedItems) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(FitCompColors.textPrimary)
                            Text("\(Int(item.consumedWeightG ?? item.servingSizeG))g")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(FitCompColors.textSecondary)
                        }
                        Spacer()
                        Text("\(Int(item.calories)) cal")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FitCompColors.textSecondary)
                        Button(action: {
                            let key = selectionKey(item)
                            selectedResultKeys.remove(key)
                            selectedItems.removeAll { $0.id == item.id }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(FitCompColors.textSecondary.opacity(0.5))
                        }
                    }
                    .padding(10)
                    .background(FitCompColors.textSecondary.opacity(0.06))
                    .cornerRadius(10)
                }
            }
        }
    }
}
