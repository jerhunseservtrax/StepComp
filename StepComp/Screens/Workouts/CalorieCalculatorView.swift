//
//  CalorieCalculatorView.swift
//  FitComp
//

import SwiftUI

struct CalorieTargetCard: View {
    @ObservedObject var foodLogViewModel: FoodLogViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingCalculator = false
    @State private var showingManualEdit = false
    @State private var refreshID = UUID()

    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "1a1a1a") : FitCompColors.primary.opacity(0.95)
    }

    private var titleColor: Color {
        FitCompColors.primary
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? FitCompColors.textPrimary : .black
    }

    private var calorieTarget: Int {
        CalorieCalculator.currentDailyGoal()
    }

    private var consumed: Int {
        Int(foodLogViewModel.todaySummary.totalCalories.rounded())
    }

    private var progress: Double {
        guard calorieTarget > 0 else { return 0 }
        return min(Double(consumed) / Double(calorieTarget), 1.0)
    }

    var body: some View {
        Button {
            showingCalculator = true
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("DAILY TARGET")
                        .font(.system(size: 13, weight: .black))
                        .tracking(1.5)
                        .foregroundColor(titleColor)
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "fork.knife")
                        Text("Nutrition")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(primaryTextColor.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(colorScheme == .dark ? 0.2 : 0.08))
                    .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Remaining")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(titleColor)
                    Text("\(max(calorieTarget - consumed, 0))")
                        .font(.system(size: 50, weight: .black))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("of \(calorieTarget) kcal")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(primaryTextColor.opacity(0.65))
                }

                VStack(spacing: 10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.black.opacity(colorScheme == .dark ? 0.25 : 0.1))
                            Capsule()
                                .fill(colorScheme == .dark ? Color.white : FitCompColors.primary)
                                .frame(width: max(6, geo.size.width * CGFloat(progress)))
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        macroMetric(label: "GOAL", value: calorieTarget)
                        Spacer()
                        macroMetric(label: "FOOD", value: consumed)
                        Spacer()
                        macroMetric(label: "LEFT", value: max(calorieTarget - consumed, 0))
                    }
                }

                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                    Text(CalorieCalculator.isManualGoal() ? "Manual daily goal enabled" : "Calculated from your profile")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(primaryTextColor.opacity(0.45))
                }
                .foregroundColor(primaryTextColor)
        }
        .padding(20)
        .background(cardBackground)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
        )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                showingManualEdit = true
            }
        )
        .id(refreshID)
        .sheet(isPresented: $showingCalculator, onDismiss: {
            refreshID = UUID()
        }) {
            CalorieCalculatorSheet()
        }
        .sheet(isPresented: $showingManualEdit, onDismiss: {
            refreshID = UUID()
        }) {
            ManualCalorieGoalSheet()
        }
    }

    private func macroMetric(label: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .black))
                .tracking(1)
                .foregroundColor(titleColor)
            Text("\(value)")
                .font(.system(size: 24, weight: .black))
                .foregroundColor(primaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

struct CalorieCalculatorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var unitManager = UnitPreferenceManager.shared
    @State private var goal: WeightGoal = .maintain
    @State private var aggressiveness: GoalAggressiveness = .moderate
    @State private var workoutDaysPerWeek: Int = 3
    @State private var ageYears: Int = 28
    @State private var sex: BiologicalSex = .male
    @State private var heightCmValue: Int = 178
    @State private var weightKgValue: Double = 76.5

    private struct CalorieResultOption: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let calories: Int
        let percent: Int
        let aggressiveness: GoalAggressiveness?
    }

    private var heightFeetInches: (feet: Int, inches: Int) {
        cmToFeetInches(heightCmValue)
    }

    private var weightLbsValue: Double {
        kgToLbs(weightKgValue)
    }

    private var heightDisplayValue: String {
        if unitManager.unitSystem == .metric {
            return "\(heightCmValue)"
        }
        return "\(heightFeetInches.feet)'\(heightFeetInches.inches)\""
    }

    private var heightDisplayUnit: String {
        unitManager.unitSystem == .metric ? "cm" : "ft/in"
    }

    private var weightDisplayValue: String {
        if unitManager.unitSystem == .metric {
            return String(format: "%.1f", weightKgValue)
        }
        return String(format: "%.1f", weightLbsValue)
    }

    private var weightDisplayUnit: String {
        unitManager.unitSystem == .metric ? "kg" : "lbs"
    }

    private var derivedActivityLevel: ActivityLevel {
        switch workoutDaysPerWeek {
        case 0:
            return .sedentary
        case 1...3:
            return .lightlyActive
        case 4...5:
            return .moderatelyActive
        case 6:
            return .veryActive
        default:
            return .extraActive
        }
    }

    private var calculatedTDEE: Int {
        CalorieCalculator.calculateTDEE(
            weightKg: Int(weightKgValue.rounded()),
            heightCm: heightCmValue,
            ageYears: ageYears,
            sex: sex,
            activityLevel: derivedActivityLevel
        )
    }

    private var calculatedTarget: Int {
        CalorieCalculator.dailyTarget(
            tdee: calculatedTDEE,
            goal: goal,
            aggressiveness: aggressiveness
        )
    }

    private var resultOptions: [CalorieResultOption] {
        if goal == .maintain {
            return [
                CalorieResultOption(
                    id: "maintain",
                    title: "Maintain weight",
                    subtitle: "Baseline daily intake",
                    calories: calculatedTDEE,
                    percent: 100,
                    aggressiveness: nil
                )
            ]
        }

        let options: [(GoalAggressiveness, String, String)] = goal == .lose
            ? [
                (.mild, "Mild weight loss", "0.5 lb/week"),
                (.moderate, "Weight loss", "1 lb/week"),
                (.aggressive, "Extreme weight loss", "2 lb/week")
            ]
            : [
                (.mild, "Mild weight gain", "0.5 lb/week"),
                (.moderate, "Weight gain", "1 lb/week"),
                (.aggressive, "Extreme weight gain", "2 lb/week")
            ]

        return options.map { level, title, subtitle in
            let calories = CalorieCalculator.dailyTarget(
                tdee: calculatedTDEE,
                goal: goal,
                aggressiveness: level
            )
            let percent = max(0, Int((Double(calories) / Double(max(calculatedTDEE, 1)) * 100).rounded()))
            return CalorieResultOption(
                id: "\(goal.rawValue)-\(level.rawValue)",
                title: title,
                subtitle: subtitle,
                calories: calories,
                percent: percent,
                aggressiveness: level
            )
        }
    }

    var body: some View {
        NavigationStack {            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(FitCompColors.primary)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "plusminus.circle.fill")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(Color.black.opacity(0.85))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Calorie Calculator")
                                    .font(.system(size: 20, weight: .black))
                                    .foregroundColor(.white)
                                Text("Recalculate your daily needs")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }

                        HStack(spacing: 12) {
                            fieldCard(title: "Age", value: "\(ageYears)", unit: "yrs")
                            genderField
                        }

                        HStack(spacing: 12) {
                            fieldCard(
                                title: "Height",
                                value: heightDisplayValue,
                                unit: heightDisplayUnit
                            )
                            fieldCard(title: "Weight", value: weightDisplayValue, unit: weightDisplayUnit)
                        }

                        workoutDaysField

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Goal")
                                .font(.system(size: 10, weight: .black))
                                .textCase(.uppercase)
                                .tracking(1)
                                .foregroundColor(.white.opacity(0.5))

                            Picker("Weight Goal", selection: $goal) {
                                ForEach(WeightGoal.allCases) { value in
                                    Text(value.title).tag(value)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(FitCompColors.primary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Result")
                                .font(.system(size: 10, weight: .black))
                                .textCase(.uppercase)
                                .tracking(1)
                                .foregroundColor(.white.opacity(0.5))

                            VStack(spacing: 8) {
                                ForEach(resultOptions) { option in
                                    resultOptionRow(option)
                                }
                            }
                        }

                        Button {
                            save()
                            dismiss()
                        } label: {
                            Text("Update Plan")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(Color.black.opacity(0.85))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(FitCompColors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(20)
                    .background(Color(hex: "111827"))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .navigationTitle("Calorie Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .background(FitCompColors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear(perform: loadSavedData)
    }

    private var genderField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Gender")
                .font(.system(size: 10, weight: .black))
                .textCase(.uppercase)
                .tracking(1)
                .foregroundColor(.white.opacity(0.5))
            Menu {
                ForEach(BiologicalSex.allCases) { value in
                    Button(value.title) { sex = value }
                }
            } label: {
                HStack {
                    Text(sex.title)
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var workoutDaysField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Activity Level")
                .font(.system(size: 10, weight: .black))
                .textCase(.uppercase)
                .tracking(1)
                .foregroundColor(.white.opacity(0.5))
            HStack {
                Text("\(workoutDaysPerWeek) day\(workoutDaysPerWeek == 1 ? "" : "s") / week")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(derivedActivityLevel.title)
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(FitCompColors.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 8) {
                Button {
                    workoutDaysPerWeek = max(workoutDaysPerWeek - 1, 0)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                Button {
                    workoutDaysPerWeek = min(workoutDaysPerWeek + 1, 7)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
            }
            .foregroundColor(.white)
        }
    }

    private func fieldCard(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .textCase(.uppercase)
                .tracking(1)
                .foregroundColor(.white.opacity(0.5))
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                Text(unit)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }
            HStack(spacing: 8) {
                Button(action: { decrementValue(for: title) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                Button(action: { incrementValue(for: title) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
            }
            .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func resultOptionRow(_ option: CalorieResultOption) -> some View {
        let isSelected = goal == .maintain
            ? option.aggressiveness == nil
            : option.aggressiveness == aggressiveness

        return Button {
            if let selectedAggressiveness = option.aggressiveness {
                aggressiveness = selectedAggressiveness
            }
        } label: {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(isSelected ? FitCompColors.primary : Color.clear)
                    .frame(width: 4, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text(option.subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(option.calories) kcal/day")
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(.white)
                    Text("\(option.percent)% Calories/day")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            .padding(12)
            .background(isSelected ? FitCompColors.primary.opacity(0.15) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(goal == .maintain)
    }

    private func incrementValue(for field: String) {
        switch field {
        case "Age":
            ageYears = min(ageYears + 1, 90)
        case "Height":
            if unitManager.unitSystem == .metric {
                heightCmValue = min(max(heightCmValue + 1, 120), 241)
            } else {
                let totalInches = (heightFeetInches.feet * 12) + heightFeetInches.inches + 1
                let clamped = min(max(totalInches, 48), 95)
                heightCmValue = feetInchesToCm(feet: clamped / 12, inches: clamped % 12)
            }
        case "Weight":
            if unitManager.unitSystem == .metric {
                weightKgValue = min(max(weightKgValue + 0.5, 35.0), 250.0)
            } else {
                let increasedLbs = min(max(weightLbsValue + 1.0, 80.0), 550.0)
                weightKgValue = lbsToKg(increasedLbs)
            }
        default:
            break
        }
    }

    private func decrementValue(for field: String) {
        switch field {
        case "Age":
            ageYears = max(ageYears - 1, 13)
        case "Height":
            if unitManager.unitSystem == .metric {
                heightCmValue = min(max(heightCmValue - 1, 120), 241)
            } else {
                let totalInches = (heightFeetInches.feet * 12) + heightFeetInches.inches - 1
                let clamped = min(max(totalInches, 48), 95)
                heightCmValue = feetInchesToCm(feet: clamped / 12, inches: clamped % 12)
            }
        case "Weight":
            if unitManager.unitSystem == .metric {
                weightKgValue = min(max(weightKgValue - 0.5, 35.0), 250.0)
            } else {
                let decreasedLbs = min(max(weightLbsValue - 1.0, 80.0), 550.0)
                weightKgValue = lbsToKg(decreasedLbs)
            }
        default:
            break
        }
    }

    private func cmToFeetInches(_ cm: Int) -> (feet: Int, inches: Int) {
        let raw = unitManager.heightComponents(fromCm: cm)
        let totalInches = (raw.feet * 12) + raw.inches
        let clampedInches = min(max(totalInches, 48), 95)
        return (clampedInches / 12, clampedInches % 12)
    }

    private func feetInchesToCm(feet: Int, inches: Int) -> Int {
        let totalInches = min(max((feet * 12) + inches, 48), 95)
        return unitManager.heightToStorage(feet: totalInches / 12, inches: totalInches % 12)
    }

    private func kgToLbs(_ kg: Double) -> Double {
        unitManager.convertWeightFromStorage(kg).rounded(toPlaces: 1)
    }

    private func lbsToKg(_ lbs: Double) -> Double {
        unitManager.convertWeightToStorage(lbs).rounded(toPlaces: 2)
    }

    private func defaultWorkoutDays(for level: ActivityLevel) -> Int {
        switch level {
        case .sedentary:
            return 0
        case .lightlyActive:
            return 2
        case .moderatelyActive:
            return 4
        case .veryActive:
            return 6
        case .extraActive:
            return 7
        }
    }

    private func loadSavedData() {
        if let saved = CalorieCalculator.loadSavedInputs() {
            ageYears = saved.ageYears
            sex = saved.sex
            workoutDaysPerWeek = defaultWorkoutDays(for: saved.activityLevel)
            goal = saved.goal
            aggressiveness = saved.aggressiveness
        }

        let defaults = UserDefaults.standard
        let storedHeight = defaults.integer(forKey: "userHeight")
        let storedWeight = defaults.integer(forKey: "userWeight")
        if storedHeight > 0 {
            heightCmValue = storedHeight
        }
        if storedWeight > 0 {
            weightKgValue = Double(storedWeight)
        }
        let storedWorkoutDays = defaults.integer(forKey: "calorie_workout_days_per_week")
        if (0...7).contains(storedWorkoutDays) {
            workoutDaysPerWeek = storedWorkoutDays
        }
    }

    private func save() {
        let savedHeightCm = heightCmValue
        let savedWeightKg = Int(weightKgValue.rounded())
        let inputs = CalorieInputs(
            ageYears: ageYears,
            sex: sex,
            activityLevel: derivedActivityLevel,
            goal: goal,
            aggressiveness: aggressiveness
        )
        CalorieCalculator.saveInputs(inputs)
        CalorieCalculator.saveGoal(calories: calculatedTarget, isManual: false)
        UserDefaults.standard.set(workoutDaysPerWeek, forKey: "calorie_workout_days_per_week")

        UserDefaults.standard.set(savedHeightCm, forKey: "userHeight")
        UserDefaults.standard.set(savedWeightKg, forKey: "userWeight")

        Task {
            let auth = AuthService.shared
            await auth.updateUserHeightWeight(
                height: savedHeightCm,
                weight: savedWeightKg
            )
        }
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

struct ManualCalorieGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var calorieGoalText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Calorie Goal") {
                    TextField("Calories per day", text: $calorieGoalText)
                        .keyboardType(.numberPad)
                    Text("Range: 1200 - 5000")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(FitCompColors.textSecondary)
                }
            }
            .navigationTitle("Edit Calorie Goal")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if let value = Int(calorieGoalText) {
                            CalorieCalculator.saveGoal(calories: value, isManual: true)
                        }
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .onAppear {
            calorieGoalText = "\(CalorieCalculator.currentDailyGoal())"
        }
    }
}
