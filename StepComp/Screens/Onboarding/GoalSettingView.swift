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
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
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
                        .fill(primaryYellow.opacity(0.2))
                        .frame(width: 160, height: 160)
                    
                    Image(systemName: "target")
                        .font(.system(size: 80, weight: .medium))
                        .foregroundColor(primaryYellow)
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
                            primaryYellow: primaryYellow
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
                                .fill(showingCustomInput ? primaryYellow : Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(showingCustomInput ? primaryYellow : Color.clear, lineWidth: 2)
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
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(primaryYellow)
                        .cornerRadius(999)
                        .shadow(color: primaryYellow.opacity(0.3), radius: 16, x: 0, y: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func saveGoalAndContinue() {
        // Save goal to UserDefaults
        UserDefaults.standard.set(selectedGoal, forKey: "dailyStepGoal")
        print("✅ Daily step goal set to: \(selectedGoal)")
        
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
    let primaryYellow: Color
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
                    .foregroundColor(isSelected ? primaryYellow : Color(.systemGray4))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical: 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? primaryYellow.opacity(0.15) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? primaryYellow : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

