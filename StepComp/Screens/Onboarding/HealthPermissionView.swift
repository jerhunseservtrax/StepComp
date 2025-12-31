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
                    // Glowing background circle
                    Circle()
                        .fill(primaryYellow.opacity(0.2))
                        .frame(width: 256, height: 256)
                        .blur(radius: 40)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    // Main icon container - white circle with yellow glow
                    ZStack {
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: 256, height: 256)
                            .shadow(color: primaryYellow.opacity(0.3), radius: 20, x: 0, y: 8)
                        
                        // Red heart icon
                        Image(systemName: "heart.fill")
                            .font(.system(size: 120))
                            .foregroundColor(.red)
                            .symbolEffect(.pulse, value: isAnimating)
                        
                        // Green lightning bolt badge at bottom right
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .frame(width: 48, height: 48)
                                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.green)
                                }
                                .offset(x: -20, y: -20)
                            }
                        }
                    }
                }
                .frame(height: 256)
                .padding(.bottom, 40)
                
                // Text Content
                VStack(spacing: 16) {
                    Text("Sync your stride")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("We need access to your Health data including steps, distance, calories, height, weight, and age to provide accurate fitness tracking and personalized insights.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)
                
                // Apple Health Card Preview
                HStack(spacing: 12) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Health")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Steps, Distance, Energy, Height, Weight, Age")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                Spacer()
                
                // Actions
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await requestAuthorization()
                        }
                    }) {
                        Text("Enable Health Access")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.black)
                            .cornerRadius(999)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isLoading)
                    
                    Button(action: {
                        withAnimation {
                            currentStep = .avatarSelection
                        }
                    }) {
                        Text("Skip for now")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
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
