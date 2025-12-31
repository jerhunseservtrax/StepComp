//
//  WelcomeView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

struct WelcomeOnboardingView: View {
    @Binding var currentStep: OnboardingFlowView.OnboardingStep
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        OnboardingScreenBase(currentStep: currentStep.stepIndex) {
            VStack(spacing: 0) {
                Spacer()
                
                // Hero Image Section
                ZStack {
                    // Background gradient
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.8, blue: 0.9).opacity(0.3),
                            Color(red: 0.1, green: 0.7, blue: 0.8).opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(maxWidth: .infinity, maxHeight: 400)
                    .cornerRadius(24)
                    
                    // Hero illustration - Sneakers
                    VStack {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 120))
                            .foregroundColor(.white)
                            .symbolEffect(.bounce, value: currentStep)
                        
                        // Decorative elements
                        HStack(spacing: 20) {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 12, height: 12)
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                        .offset(y: -40)
                    }
                }
                .frame(maxHeight: 400)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                
                // Text Content
                VStack(spacing: 16) {
                    Group {
                        Text("Step into ") +
                        Text("greatness")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.yellow, primaryYellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            ) +
                        Text(" 🚶‍♂️🔥")
                    }
                    .font(.system(size: 36, weight: .bold))
                    .multilineTextAlignment(.center)
                    
                    Text("Turn your daily walks into a game. Earn rewards and compete with friends.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)
                
                Spacer()
                
                // Fixed Bottom Button
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [
                            Color(.systemBackground),
                            Color(.systemBackground).opacity(0)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 40)
                    
                    Button(action: {
                        withAnimation {
                            currentStep = .healthPermission
                        }
                    }) {
                        Text("Get Started")
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
    }
}
