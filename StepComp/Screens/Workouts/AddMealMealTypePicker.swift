//
//  AddMealMealTypePicker.swift
//  FitComp
//

import SwiftUI

struct AddMealMealTypePicker: View {
    @Binding var selectedMealType: MealType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MEAL TYPE")
                .font(.system(size: 11, weight: .black))
                .tracking(1)
                .foregroundColor(FitCompColors.textSecondary)

            HStack(spacing: 8) {
                ForEach(MealType.allCases) { meal in
                    Button(action: { selectedMealType = meal }) {
                        VStack(spacing: 4) {
                            Image(systemName: meal.icon)
                                .font(.system(size: 16, weight: .bold))
                            Text(meal.title)
                                .font(.system(size: 10, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedMealType == meal ? FitCompColors.primary : FitCompColors.textSecondary.opacity(0.08))
                        .foregroundColor(selectedMealType == meal ? FitCompColors.buttonTextOnPrimary : FitCompColors.textSecondary)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
}
