//
//  FoodLogEntry.swift
//  FitComp
//

import Foundation

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack

    var id: String { rawValue }

    var title: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch:     return "Lunch"
        case .dinner:    return "Dinner"
        case .snack:     return "Snack"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch:     return "sun.max.fill"
        case .dinner:    return "moon.stars.fill"
        case .snack:     return "leaf.fill"
        }
    }
}

struct FoodLogEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let mealType: MealType
    let description: String
    let items: [FoodItem]
    let photoFileName: String?
    let loggedAt: Date

    var totalCalories: Double {
        items.reduce(0) { $0 + $1.calories }
    }

    var totalProteinG: Double {
        items.reduce(0) { $0 + $1.proteinG }
    }

    var totalCarbsG: Double {
        items.reduce(0) { $0 + $1.carbsG }
    }

    var totalFatG: Double {
        items.reduce(0) { $0 + $1.fatG }
    }
}

struct FoodItem: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let sourceKey: String?
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let servingSizeG: Double
    let consumedWeightG: Double?
    let fiberG: Double
    let sugarG: Double
}

extension FoodItem {
    init(from nutritionItem: NutritionItem) {
        self.init(from: nutritionItem, consumedWeightG: nutritionItem.servingSizeG)
    }

    init(from nutritionItem: NutritionItem, consumedWeightG: Double) {
        let baseServing = max(nutritionItem.servingSizeG, 1)
        let clampedWeight = max(consumedWeightG, 1)
        let scale = clampedWeight / baseServing

        self.id = UUID()
        self.name = nutritionItem.name.capitalized
        self.sourceKey = Self.makeSourceKey(for: nutritionItem)
        self.calories = nutritionItem.calories * scale
        self.proteinG = nutritionItem.proteinG * scale
        self.carbsG = nutritionItem.carbohydratesTotalG * scale
        self.fatG = nutritionItem.fatTotalG * scale
        self.servingSizeG = clampedWeight
        self.consumedWeightG = clampedWeight
        self.fiberG = nutritionItem.fiberG * scale
        self.sugarG = nutritionItem.sugarG * scale
    }

    static func makeSourceKey(for nutritionItem: NutritionItem) -> String {
        [
            nutritionItem.name.lowercased(),
            String(format: "%.3f", nutritionItem.calories),
            String(format: "%.3f", nutritionItem.servingSizeG),
            String(format: "%.3f", nutritionItem.proteinG),
            String(format: "%.3f", nutritionItem.carbohydratesTotalG),
            String(format: "%.3f", nutritionItem.fatTotalG)
        ].joined(separator: "|")
    }
}

struct DailyNutritionSummary {
    let date: Date
    let totalCalories: Double
    let totalProteinG: Double
    let totalCarbsG: Double
    let totalFatG: Double
    let mealCount: Int

    var calorieGoal: Int {
        UserDefaults.standard.integer(forKey: "daily_calorie_goal").clamped(to: 1200...5000,
                                                                             default: 2000)
    }

    var proteinGoalG: Int {
        UserDefaults.standard.integer(forKey: "daily_protein_goal_g").clamped(to: 30...400,
                                                                               default: 150)
    }

    var calorieProgress: Double {
        guard calorieGoal > 0 else { return 0 }
        return min(totalCalories / Double(calorieGoal), 1.0)
    }

    var proteinProgress: Double {
        guard proteinGoalG > 0 else { return 0 }
        return min(totalProteinG / Double(proteinGoalG), 1.0)
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>, default fallback: Int) -> Int {
        if self == 0 { return fallback }
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
