//
//  GoalSettingView.swift
//  StepComp
//
//  Industry-standard goal setting during onboarding
//

import SwiftUI

struct GoalSettingOnboardingView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @Binding var currentStep: OnboardingFlowView.OnboardingStep
    @EnvironmentObject var authService: AuthService
    
    @State private var selectedGoal: Int = 10000
    @State private var customGoal: String = ""
    @State private var showingCustomInput = false
    
    
    // Preset goals
    private let presetGoals = [
        (value: 5000, label: "5,000", description: "Light & Easy"),
        (value: 7500, label: "7,500", description: "Moderate"),
        (value: 10000, label: "10,000", description: "Recommended"),
        (value: 12500, label: "12,500", description: "Challenging")
    ]
    
    var body: some View {
        OnboardingScreenBase(currentStep: currentStep.stepIndex) {
            VStack(spacing: 0) {
                Spacer()
                
                // Goal Icon
                ZStack {
                    Circle()
                        .fill(StepCompColors.primary.opacity(0.2))
                        .frame(width: 160, height: 160)
                    
                    Image(systemName: "target")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundColor(StepCompColors.primary)
                        .symbolEffect(.pulse)
                }
                .padding(.bottom, 32)
                
                // Title
                VStack(spacing: 12) {
                    Text("Set your daily goal")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("We'll help you stay on track")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 32)
                
                // Goal Options
                VStack(spacing: 12) {
                    ForEach(presetGoals, id: \.value) { goal in
                        GoalOptionButton(
                            value: goal.value,
                            label: goal.label,
                            description: goal.description,
                            isSelected: selectedGoal == goal.value && !showingCustomInput,
                            primaryColor: StepCompColors.primary
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedGoal = goal.value
                                showingCustomInput = false
                            }
                        }
                    }
                    
                    // Custom Goal
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            showingCustomInput = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 24))
                            
                            if showingCustomInput {
                                TextField("Enter goal", text: $customGoal)
                                    .keyboardType(.numberPad)
                                    .font(.system(size: 18, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .onChange(of: customGoal) { _, newValue in
                                        if let goal = Int(newValue), goal > 0 {
                                            selectedGoal = goal
                                        }
                                    }
                            } else {
                                Text("Custom")
                                    .font(.system(size: 18, weight: .bold))
                                Spacer()
                            }
                            
                            if showingCustomInput {
                                Text("steps")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(showingCustomInput ? .black : .primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(showingCustomInput ? StepCompColors.primary : Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(showingCustomInput ? StepCompColors.primary : Color.clear, lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                // Reassurance
                Text("You can change this anytime in settings")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 32)
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    saveGoalAndContinue()
                }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(StepCompColors.buttonTextOnPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(StepCompColors.primary)
                        .cornerRadius(999)
                        .shadow(color: StepCompColors.primary.opacity(0.3), radius: 16, x: 0, y: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func saveGoalAndContinue() {
        // Save goal to UserDefaults (temporary storage during onboarding)
        UserDefaults.standard.set(selectedGoal, forKey: "dailyStepGoal")
        print("✅ Daily step goal set to: \(selectedGoal)")
        
        // If user is already authenticated, also save to database immediately
        // This handles cases where user goes back to goal setting or signs in before completing onboarding
        if sessionViewModel.isAuthenticated {
            Task {
                await authService.updateDailyStepGoal(selectedGoal)
                print("✅ Daily step goal synced to database: \(selectedGoal)")
            }
        }
        
        // Continue to next step
        withAnimation {
            currentStep = .avatarSelection
        }
    }
}

// MARK: - Goal Option Button

struct GoalOptionButton: View {
    let value: Int
    let label: String
    let description: String
    let isSelected: Bool
    let primaryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(label) steps")
                        .font(.system(size: 18, weight: .bold))
                    Text(description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? primaryColor : Color(.systemGray4))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? primaryColor.opacity(0.15) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? primaryColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

