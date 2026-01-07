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
    @Environment(\.colorScheme) private var colorScheme
    
    
    var body: some View {
        ZStack {
            // Background Image (Running Legs)
            Image("Image")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
            
            // Dark gradient overlay for better text readability
            LinearGradient(
                colors: [
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page Indicator
                HStack(spacing: 8) {
                    Capsule()
                        .fill(StepCompColors.primary)
                        .frame(width: 40, height: 6)
                    
                    ForEach(1..<4) { _ in
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Logo and Content
                VStack(spacing: 32) {
                    
                    // Logo
                    VStack(spacing: 0) {
                        Text("STEP")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(-2)
                        
                        Text("COMP")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundColor(StepCompColors.primary)
                            .tracking(-2)
                            .offset(y: -10)
                    }
                    
                    // Tagline
                    Text("Turn your daily walks into a game.\nEarn rewards and compete with\nfriends.")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                    
                    // Social Proof
                    Text("Join thousands of walkers competing\ndaily.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Bottom Buttons
                VStack(spacing: 16) {
                    // Get Started Button
                    Button(action: {
                        withAnimation {
                            currentStep = .healthPermission
                        }
                    }) {
                        HStack {
                            Text("Get Started")
                                .font(.system(size: 18, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(StepCompColors.buttonTextOnPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(StepCompColors.primary)
                        .cornerRadius(16)
                        .shadow(color: StepCompColors.primary.opacity(0.4), radius: 16, x: 0, y: 8)
                    }
                    
                    // Log In Button
                    Button(action: {
                        withAnimation {
                            currentStep = .signIn
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Log in")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(StepCompColors.primary)
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}
