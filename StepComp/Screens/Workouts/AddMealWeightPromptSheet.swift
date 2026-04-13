//
//  AddMealWeightPromptSheet.swift
//  FitComp
//

import SwiftUI
import UIKit

enum AddMealWeightInputUnit: String, CaseIterable, Identifiable {
    case grams
    case ounces
    case serving

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grams: return "Grams"
        case .ounces: return "Ounces"
        case .serving: return "Serving"
        }
    }

    var shortLabel: String {
        switch self {
        case .grams: return "g"
        case .ounces: return "oz"
        case .serving: return "srv"
        }
    }
}

struct AddMealWeightPromptSheet: View {
    @Binding var pendingWeightItem: NutritionItem?
    @Binding var pendingBackgroundURL: URL?
    @Binding var pendingWeightText: String
    @Binding var weightInputUnit: AddMealWeightInputUnit
    var onConfirm: () -> Void
    var onCancel: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let preview = currentPreviewValues()
        VStack(spacing: 0) {
            HStack {
                Button {
                    onCancel()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(FitCompColors.textSecondary)
                        .padding(10)
                        .background(FitCompColors.textSecondary.opacity(0.08))
                        .clipShape(Circle())
                }
                Spacer()
                Text("Add to Log")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(FitCompColors.textPrimary)
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            ZStack {
                backgroundForWeightPrompt

                ScrollView {
                    VStack(spacing: 20) {
                        if let item = pendingWeightItem {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(FitCompColors.primary.opacity(0.2))
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(FitCompColors.textPrimary)
                                }
                                .frame(width: 62, height: 62)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name.capitalized)
                                        .font(.system(size: 28, weight: .black))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                        .foregroundColor(FitCompColors.textPrimary)
                                    Text("\(Int(item.caloriesPer100G.rounded())) kcal per 100g")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(FitCompColors.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(16)
                            .background(colorScheme == .dark ? Color(hex: "1a1a1a").opacity(0.85) : Color.white.opacity(0.92))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
                            )
                        }

                        VStack(spacing: 10) {
                            Text("AMOUNT")
                                .font(.system(size: 14, weight: .black))
                                .tracking(1)
                                .foregroundColor(FitCompColors.textSecondary)

                            HStack(alignment: .lastTextBaseline, spacing: 8) {
                                TextField("0", text: $pendingWeightText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 72, weight: .black))
                                    .frame(maxWidth: 220)
                                    .foregroundColor(FitCompColors.textPrimary)
                                Text(weightInputUnit.shortLabel)
                                    .font(.system(size: 44, weight: .bold))
                                    .foregroundColor(FitCompColors.textSecondary.opacity(0.55))
                            }
                        }

                        HStack(spacing: 8) {
                            ForEach(AddMealWeightInputUnit.allCases) { unit in
                                Button {
                                    switchUnit(to: unit)
                                } label: {
                                    Text(unit.title)
                                        .font(.system(size: 16, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(weightInputUnit == unit ? FitCompColors.primary : Color.clear)
                                        .foregroundColor(weightInputUnit == unit ? FitCompColors.textPrimary : FitCompColors.textSecondary)
                                        .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(6)
                        .background(FitCompColors.textSecondary.opacity(0.08))
                        .cornerRadius(14)

                        HStack(spacing: 10) {
                            previewChip("Protein", value: preview.protein)
                            previewChip("Carbs", value: preview.carbs)
                            previewChip("Fat", value: preview.fat)
                        }

                        Button {
                            onConfirm()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Add to Log")
                                    .font(.system(size: 20, weight: .black))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(FitCompColors.primary)
                            .foregroundColor(FitCompColors.textPrimary)
                            .cornerRadius(14)
                        }

                        Button("Cancel") {
                            onCancel()
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : FitCompColors.textSecondary)
                        .padding(.top, 2)
                    }
                    .padding(20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(FitCompColors.background.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .simultaneousGesture(
            TapGesture().onEnded {
                dismissKeyboard()
            }
        )
    }

    private var backgroundForWeightPrompt: some View {
        ZStack {
            if let url = pendingBackgroundURL {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                } placeholder: {
                    LinearGradient(
                        colors: [FitCompColors.primary.opacity(0.3), FitCompColors.background],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            } else {
                LinearGradient(
                    colors: [FitCompColors.primary.opacity(0.25), FitCompColors.background],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(colorScheme == .dark ? 0.45 : 0.15),
                    FitCompColors.background.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private func switchUnit(to newUnit: AddMealWeightInputUnit) {
        guard let item = pendingWeightItem, newUnit != weightInputUnit else {
            weightInputUnit = newUnit
            return
        }

        let grams = currentWeightInGrams(item: item)
        let convertedAmount: Double
        switch newUnit {
        case .grams:
            convertedAmount = grams
        case .ounces:
            convertedAmount = grams / 28.3495
        case .serving:
            convertedAmount = grams / max(item.servingSizeG, 1)
        }

        pendingWeightText = formatAmount(convertedAmount)
        weightInputUnit = newUnit
    }

    private func currentWeightInGrams(item: NutritionItem) -> Double {
        let numeric = Double(pendingWeightText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "."))
        let amount = max(numeric ?? defaultAmountForUnit(item: item, unit: weightInputUnit), 0.1)
        let grams: Double
        switch weightInputUnit {
        case .grams:
            grams = amount
        case .ounces:
            grams = amount * 28.3495
        case .serving:
            grams = amount * max(item.servingSizeG, 1)
        }
        return min(max(grams, 1), 2000)
    }

    private func defaultAmountForUnit(item: NutritionItem, unit: AddMealWeightInputUnit) -> Double {
        switch unit {
        case .grams:
            return max(item.servingSizeG, 1)
        case .ounces:
            return max(item.servingSizeG, 1) / 28.3495
        case .serving:
            return 1
        }
    }

    private func currentPreviewValues() -> (protein: Double, carbs: Double, fat: Double) {
        guard let item = pendingWeightItem else {
            return (0, 0, 0)
        }
        let grams = currentWeightInGrams(item: item)
        let baseServing = max(item.servingSizeG, 1)
        let scale = grams / baseServing
        return (
            item.proteinG * scale,
            item.carbohydratesTotalG * scale,
            item.fatTotalG * scale
        )
    }

    private func previewChip(_ title: String, value: Double) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(FitCompColors.textSecondary)
            Text("\(formatMacro(value))g")
                .font(.system(size: 30, weight: .black))
                .foregroundColor(FitCompColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(colorScheme == .dark ? Color(hex: "1a1a1a") : Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
        )
    }

    private func formatMacro(_ value: Double) -> String {
        if value >= 10 {
            return String(format: "%.1f", value)
        }
        return String(format: "%.2f", value)
    }

    private func formatAmount(_ value: Double) -> String {
        if abs(value.rounded() - value) < 0.01 {
            return "\(Int(value.rounded()))"
        }
        return String(format: "%.1f", value)
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private extension NutritionItem {
    var caloriesPer100G: Double {
        let serving = max(servingSizeG, 1)
        return calories * (100.0 / serving)
    }
}
