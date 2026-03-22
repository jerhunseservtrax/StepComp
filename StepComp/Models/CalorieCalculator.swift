//
//  CalorieCalculator.swift
//  FitComp
//

import Foundation

enum WeightGoal: String, CaseIterable, Codable, Identifiable {
    case lose
    case maintain
    case gain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lose: return "Lose Weight"
        case .maintain: return "Maintain Weight"
        case .gain: return "Gain Weight"
        }
    }
}

enum GoalAggressiveness: String, CaseIterable, Codable, Identifiable {
    case mild
    case moderate
    case aggressive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .aggressive: return "Aggressive"
        }
    }

    var calorieDelta: Int {
        switch self {
        case .mild: return 250
        case .moderate: return 500
        case .aggressive: return 1000
        }
    }
}

enum ActivityLevel: String, CaseIterable, Codable, Identifiable {
    case sedentary
    case lightlyActive
    case moderatelyActive
    case veryActive
    case extraActive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .lightlyActive: return "Lightly Active"
        case .moderatelyActive: return "Moderately Active"
        case .veryActive: return "Very Active"
        case .extraActive: return "Extra Active"
        }
    }

    var subtitle: String {
        switch self {
        case .sedentary: return "Little to no exercise"
        case .lightlyActive: return "Light exercise 1-3 days/week"
        case .moderatelyActive: return "Moderate exercise 3-5 days/week"
        case .veryActive: return "Hard exercise 6-7 days/week"
        case .extraActive: return "Athlete-level daily training"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .moderatelyActive: return 1.465
        case .veryActive: return 1.55
        case .extraActive: return 1.725
        }
    }
}

enum BiologicalSex: String, CaseIterable, Codable, Identifiable {
    case male
    case female

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

struct CalorieInputs: Codable {
    var ageYears: Int
    var sex: BiologicalSex
    var activityLevel: ActivityLevel
    var goal: WeightGoal
    var aggressiveness: GoalAggressiveness
}

enum CalorieCalculator {
    private enum Keys {
        static let userAge = "user_age"
        static let userBiologicalSex = "user_biological_sex"
        static let userActivityLevel = "user_activity_level"
        static let userWeightGoal = "user_weight_goal"
        static let userGoalAggressiveness = "user_goal_aggressiveness"
        static let dailyCalorieGoal = "daily_calorie_goal"
        static let calorieGoalIsManual = "calorie_goal_is_manual"
    }

    static func calculateTDEE(
        weightKg: Int,
        heightCm: Int,
        ageYears: Int,
        sex: BiologicalSex,
        activityLevel: ActivityLevel
    ) -> Int {
        let weight = Double(max(weightKg, 30))
        let height = Double(max(heightCm, 120))
        let age = Double(max(ageYears, 13))
        let bmr: Double

        switch sex {
        case .male:
            bmr = (10.0 * weight) + (6.25 * height) - (5.0 * age) + 5.0
        case .female:
            bmr = (10.0 * weight) + (6.25 * height) - (5.0 * age) - 161.0
        }

        return Int((bmr * activityLevel.multiplier).rounded())
    }

    static func dailyTarget(
        tdee: Int,
        goal: WeightGoal,
        aggressiveness: GoalAggressiveness
    ) -> Int {
        let delta = aggressiveness.calorieDelta
        let target: Int
        switch goal {
        case .lose:
            target = tdee - delta
        case .maintain:
            target = tdee
        case .gain:
            target = tdee + delta
        }
        return max(1200, min(target, 5000))
    }

    static func saveGoal(calories: Int, isManual: Bool) {
        UserDefaults.standard.set(max(1200, min(calories, 5000)), forKey: Keys.dailyCalorieGoal)
        UserDefaults.standard.set(isManual, forKey: Keys.calorieGoalIsManual)
    }

    static func saveInputs(_ inputs: CalorieInputs) {
        UserDefaults.standard.set(inputs.ageYears, forKey: Keys.userAge)
        UserDefaults.standard.set(inputs.sex.rawValue, forKey: Keys.userBiologicalSex)
        UserDefaults.standard.set(inputs.activityLevel.rawValue, forKey: Keys.userActivityLevel)
        UserDefaults.standard.set(inputs.goal.rawValue, forKey: Keys.userWeightGoal)
        UserDefaults.standard.set(inputs.aggressiveness.rawValue, forKey: Keys.userGoalAggressiveness)
    }

    static func loadSavedInputs() -> CalorieInputs? {
        let defaults = UserDefaults.standard
        let age = defaults.integer(forKey: Keys.userAge)
        guard age > 0 else { return nil }

        let sex = BiologicalSex(rawValue: defaults.string(forKey: Keys.userBiologicalSex) ?? "") ?? .male
        let activity = ActivityLevel(rawValue: defaults.string(forKey: Keys.userActivityLevel) ?? "") ?? .moderatelyActive
        let goal = WeightGoal(rawValue: defaults.string(forKey: Keys.userWeightGoal) ?? "") ?? .maintain
        let aggressiveness = GoalAggressiveness(rawValue: defaults.string(forKey: Keys.userGoalAggressiveness) ?? "") ?? .moderate

        return CalorieInputs(
            ageYears: age,
            sex: sex,
            activityLevel: activity,
            goal: goal,
            aggressiveness: aggressiveness
        )
    }

    static func currentDailyGoal() -> Int {
        let value = UserDefaults.standard.integer(forKey: Keys.dailyCalorieGoal)
        if value == 0 { return 2000 }
        return max(1200, min(value, 5000))
    }

    static func isManualGoal() -> Bool {
        UserDefaults.standard.bool(forKey: Keys.calorieGoalIsManual)
    }
}
