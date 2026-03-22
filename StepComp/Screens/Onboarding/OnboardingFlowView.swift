//
//  OnboardingFlowView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

struct OnboardingFlowView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @State private var currentStep: OnboardingStep = .welcome
    
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case healthPermission = 1
        case goalSetting = 2
        case avatarSelection = 3
        case firstWin = 4
        case signIn = 5
        
        var stepIndex: Int { rawValue }
        
        static var totalSteps: Int { 6 }
    }
    
    var body: some View {
        ZStack {
            FitCompColors.background
                .ignoresSafeArea()
            
            Group {
                switch currentStep {
                case .welcome:
                    WelcomeOnboardingView(currentStep: $currentStep)
                case .healthPermission:
                    HealthPermissionOnboardingView(
                        sessionViewModel: sessionViewModel,
                        currentStep: $currentStep
                    )
                case .goalSetting:
                    GoalSettingOnboardingView(
                        sessionViewModel: sessionViewModel,
                        currentStep: $currentStep
                    )
                case .avatarSelection:
                    AvatarSelectionOnboardingView(
                        sessionViewModel: sessionViewModel,
                        currentStep: $currentStep
                    )
                case .firstWin:
                    FirstWinOnboardingView(
                        sessionViewModel: sessionViewModel,
                        currentStep: $currentStep
                    )
                case .signIn:
                    SignInOnboardingView(
                        sessionViewModel: sessionViewModel,
                        currentStep: $currentStep
                    )
                }
            }
            .overlay(alignment: .topLeading) {
                // Back button (hidden on welcome screen)
                if currentStep != .welcome {
                    Button(action: {
                        goBack()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(FitCompColors.surfaceElevated)
                        .cornerRadius(20)
                    }
                    .padding(.leading, 24)
                    .padding(.top, 60) // Increased from 16 to 60 to clear status bar
                }
            }
        }
    }
    
    private func goBack() {
        guard let previousStep = OnboardingStep(rawValue: currentStep.rawValue - 1) else {
            return
        }
        withAnimation {
            currentStep = previousStep
        }
    }
}

// MARK: - Step Indicator

struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int = 6
    
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                if index == currentStep {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(FitCompColors.primary)
                        .frame(width: 32, height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
                } else if index < currentStep {
                    Circle()
                        .fill(FitCompColors.primary.opacity(0.3))
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(FitCompColors.textTertiary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
}

// MARK: - Onboarding Screen Base

struct OnboardingScreenBase<Content: View>: View {
    let currentStep: Int
    let content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            // Step Indicator
            StepIndicator(currentStep: currentStep)
                .padding(.top, 32)
                .padding(.bottom, 16)
            
            // Content
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FitCompColors.background)
    }
}
