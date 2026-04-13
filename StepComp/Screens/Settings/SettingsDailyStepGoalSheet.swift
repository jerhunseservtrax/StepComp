//
//  SettingsDailyStepGoalSheet.swift
//  FitComp
//
//  Daily step goal editor sheet extracted from SettingsView.swift.
//

import SwiftUI

struct EditDailyStepGoalSheet: View {
    let user: User
    let currentGoal: Int
    let onSave: (Int) -> Void
    
    @State private var sliderValue: Double = 10000
    @State private var selectedPreset: GoalPreset? = .tenThousand
    @Environment(\.dismiss) var dismiss
    
    
    enum GoalPreset: Int, CaseIterable {
        case fiveThousand = 5000
        case sevenThousand = 7500
        case tenThousand = 10000
        case fifteenThousand = 15000
        
        var displayName: String {
            switch self {
            case .fiveThousand: return "5,000"
            case .sevenThousand: return "7,500"
            case .tenThousand: return "10,000"
            case .fifteenThousand: return "15,000"
            }
        }
        
        var label: String {
            switch self {
            case .fiveThousand: return "Casual"
            case .sevenThousand: return "Active"
            case .tenThousand: return "Standard"
            case .fifteenThousand: return "Athlete"
            }
        }
        
        var icon: String {
            switch self {
            case .fiveThousand: return "figure.walk"
            case .sevenThousand: return "figure.hiking"
            case .tenThousand: return "figure.strengthtraining.traditional"
            case .fifteenThousand: return "trophy.fill"
            }
        }
    }
    
    var currentGoalFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: Int(sliderValue))) ?? "\(Int(sliderValue))"
    }
    
    var progressPercentage: Double {
        // Calculate progress for the ring (0-360 degrees)
        return (sliderValue - 2000) / (25000 - 2000)
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .foregroundColor(FitCompColors.primary)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Text("Daily Step Goal")
                        .font(.system(size: 18, weight: .bold))
                    
                    Spacer()
                    
                    Button(action: {
                        onSave(Int(sliderValue))
                        dismiss()
                    }) {
                        Text("Save")
                            .foregroundColor(.black)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(FitCompColors.primary)
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Target Setup Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("TARGET SETUP")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .tracking(1)
                            
                            VStack(spacing: 32) {
                                // Circular Progress
                                ZStack {
                                    // Background circle
                                    Circle()
                                        .stroke(FitCompColors.cardBorder, lineWidth: 12)
                                        .frame(width: 192, height: 192)
                                    
                                    // Progress arc
                                    Circle()
                                        .trim(from: 0, to: progressPercentage)
                                        .stroke(FitCompColors.primary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                        .frame(width: 192, height: 192)
                                        .rotationEffect(.degrees(-90))
                                        .animation(.spring(response: 0.3), value: progressPercentage)
                                    
                                    // Center text
                                    VStack(spacing: 4) {
                                        Text(currentGoalFormatted)
                                            .font(.system(size: 44, weight: .bold))
                                        
                                        Text("STEPS/DAY")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .tracking(0.5)
                                    }
                                }
                                .padding(.vertical, 20)
                                
                                // Custom Goal Slider
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Custom Goal")
                                            .font(.system(size: 18, weight: .semibold))
                                        
                                        Spacer()
                                        
                                        Text("Recommended")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(FitCompColors.primary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(FitCompColors.primary.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                    
                                    // Slider
                                    Slider(value: $sliderValue, in: 2000...25000, step: 500)
                                        .tint(FitCompColors.primary)
                                        .onChange(of: sliderValue) { _, newValue in
                                            // Deselect preset if manually adjusted
                                            if let preset = selectedPreset, Double(preset.rawValue) != newValue {
                                                selectedPreset = nil
                                            }
                                        }
                                    
                                    HStack {
                                        Text("2,000")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Text("25,000")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(24)
                            .background(FitCompColors.surfaceElevated)
                            .cornerRadius(24)
                        }
                        
                        // Quick Select
                        VStack(alignment: .leading, spacing: 16) {
                            Text("QUICK SELECT")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .tracking(1)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(GoalPreset.allCases, id: \.self) { preset in
                                    QuickSelectButton(
                                        preset: preset,
                                        isSelected: selectedPreset == preset,
                                        primaryColor: FitCompColors.primary
                                    ) {
                                        selectedPreset = preset
                                        sliderValue = Double(preset.rawValue)
                                    }
                                }
                            }
                        }
                        
                        // Footer text
                        Text("Set your daily step goal to track your progress and stay motivated. The default is 10,000 steps per day, recommended by health experts.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 32)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            sliderValue = Double(currentGoal > 0 ? currentGoal : 10000)
            if let matchingPreset = GoalPreset.allCases.first(where: { $0.rawValue == currentGoal }) {
                selectedPreset = matchingPreset
            }
        }
    }
}

// MARK: - Quick Select Button

struct QuickSelectButton: View {
    let preset: EditDailyStepGoalSheet.GoalPreset
    let isSelected: Bool
    let primaryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: preset.icon)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .black : primaryColor)
                
                Text(preset.displayName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isSelected ? .black : .primary)
                
                Text(preset.label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isSelected ? .black.opacity(0.7) : .secondary)
                    .tracking(0.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? primaryColor : Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? primaryColor : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? primaryColor.opacity(0.3) : Color.clear, radius: 8)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
