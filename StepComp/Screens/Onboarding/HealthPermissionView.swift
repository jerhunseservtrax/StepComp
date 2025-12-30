//
//  HealthPermissionView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

struct HealthPermissionOnboardingView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @Binding var currentStep: OnboardingFlowView.OnboardingStep
    @EnvironmentObject var healthKitService: HealthKitService
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var isAnimating = false
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        OnboardingScreenBase(currentStep: currentStep.stepIndex) {
            VStack(spacing: 0) {
                Spacer()
                
                // Permission Visual
                ZStack {
                    // Ripple effects
                    Circle()
                        .fill(primaryYellow.opacity(0.05))
                        .frame(width: 256, height: 256)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(
                            Animation.easeOut(duration: 3.0)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    
                    Circle()
                        .fill(primaryYellow.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    // Main icon container
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [primaryYellow, Color.yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 128, height: 128)
                            .shadow(color: primaryYellow.opacity(0.3), radius: 20, x: 0, y: 8)
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 4)
                            )
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.black)
                    }
                    
                    // Floating badge
                    VStack {
                        HStack {
                            Spacer()
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.green)
                                Text("Verified")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        }
                        Spacer()
                    }
                    .padding(.top, 32)
                    .padding(.trailing, 32)
                    .offset(y: isAnimating ? -5 : 5)
                    .animation(
                        Animation.easeInOut(duration: 2.5)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                }
                .frame(height: 256)
                .padding(.bottom, 40)
                
                // Text Content
                VStack(spacing: 16) {
                    Text("Sync your steps")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("To make the game fair for everyone, we need to verify your movement with HealthKit. Your data stays private on your device. 🔒")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
                
                Spacer()
                
                // Actions
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await requestAuthorization()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 20))
                            Text("Enable Health Access")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(primaryYellow)
                        .cornerRadius(999)
                        .shadow(color: primaryYellow.opacity(0.3), radius: 16, x: 0, y: 8)
                    }
                    .disabled(isLoading)
                    
                    Button(action: {
                        currentStep = .avatarSelection
                    }) {
                        Text("Skip for now")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private func requestAuthorization() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await sessionViewModel.requestHealthKitAuthorization()
            // Always proceed to avatar selection, even if HealthKit authorization failed
            // The app can work without HealthKit (with mock data)
            currentStep = .avatarSelection
        } catch {
            // Log error but don't block - allow user to continue
            errorMessage = error.localizedDescription
            // Still proceed to next step
            currentStep = .avatarSelection
        }
        
        isLoading = false
    }
}
