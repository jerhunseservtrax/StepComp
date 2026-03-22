//
//  FirstWinView.swift
//  FitComp
//
//  Celebration screen after onboarding completion
//

import SwiftUI

struct FirstWinOnboardingView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @Binding var currentStep: OnboardingFlowView.OnboardingStep
    @State private var showConfetti = false
    @State private var bounceAnimation = false
    
    
    var body: some View {
        OnboardingScreenBase(currentStep: currentStep.stepIndex) {
            VStack(spacing: 0) {
                Spacer()
                
                // Success Animation
                ZStack {
                    // Pulsing background circles
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(FitCompColors.primary.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                            .frame(width: 200 + CGFloat(index * 50), height: 200 + CGFloat(index * 50))
                            .scaleEffect(showConfetti ? 1.2 : 1.0)
                            .opacity(showConfetti ? 0 : 1)
                            .animation(
                                Animation.easeOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.2),
                                value: showConfetti
                            )
                    }
                    
                    // Main success icon
                    ZStack {
                        Circle()
                            .fill(FitCompColors.primary)
                            .frame(width: 160, height: 160)
                            .shadow(color: FitCompColors.primary.opacity(0.5), radius: 30, x: 0, y: 10)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundColor(FitCompColors.buttonTextOnPrimary)
                            .scaleEffect(bounceAnimation ? 1.0 : 0.5)
                            .animation(.spring(response: 0.6, dampingFraction: 0.5), value: bounceAnimation)
                    }
                }
                .padding(.bottom, 48)
                
                // Success Message
                VStack(spacing: 16) {
                    Text("You're all set! 🎉")
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    Text("Your steps will start syncing automatically. Time to start walking!")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)
                
                // Feature Highlights
                VStack(spacing: 16) {
                    FeatureHighlight(
                        icon: "figure.walk",
                        text: "Track your daily steps automatically",
                        primaryColor: FitCompColors.primary
                    )
                    
                    FeatureHighlight(
                        icon: "trophy.fill",
                        text: "Create challenges with friends",
                        primaryColor: FitCompColors.primary
                    )
                    
                    FeatureHighlight(
                        icon: "chart.line.uptrend.xyaxis",
                        text: "Watch your progress grow",
                        primaryColor: FitCompColors.primary
                    )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                
                Spacer()
                
                // Start Button
                Button(action: {
                    continueToSignIn()
                }) {
                    HStack(spacing: 8) {
                        Text("Start Walking")
                            .font(.system(size: 18, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(FitCompColors.buttonTextOnPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(FitCompColors.primary)
                    .cornerRadius(999)
                    .shadow(color: FitCompColors.primary.opacity(0.3), radius: 16, x: 0, y: 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            showConfetti = true
            bounceAnimation = true
        }
    }
    
    private func continueToSignIn() {
        // Navigate to Sign In step
        // completeOnboarding() will be called after successful authentication in SignInView
        withAnimation {
            currentStep = .signIn
        }
        print("➡️ Navigating to Sign In step")
    }
}

// MARK: - Feature Highlight

struct FeatureHighlight: View {
    let icon: String
    let text: String
    let primaryColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(primaryColor)
                .frame(width: 32)
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

