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
                    // Background gradient blob
                    Circle()
                        .fill(primaryYellow.opacity(0.2))
                        .frame(width: 256, height: 256)
                        .blur(radius: 60)
                    
                    // Hero illustration placeholder
                    Image(systemName: "figure.run")
                        .font(.system(size: 120))
                        .foregroundColor(primaryYellow)
                        .symbolEffect(.bounce, value: currentStep)
                }
                .frame(maxHeight: 400)
                .padding(.bottom, 24)
                
                // Text Content
                VStack(spacing: 16) {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Text("Step into")
                                .font(.system(size: 36, weight: .bold))
                            Text(" greatness ")
                                .font(.system(size: 36, weight: .bold))
                                .overlay(
                                    Rectangle()
                                        .fill(primaryYellow.opacity(0.5))
                                        .frame(height: 12)
                                        .offset(y: 6)
                                )
                            Text("🚶‍♂️🔥")
                                .font(.system(size: 36))
                        }
                    }
                    
                    Text("Turn every walk into a game. Track stats, beat friends, and earn real rewards.")
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
                        currentStep = .healthPermission
                    }) {
                        Text("Let's Go!")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
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
