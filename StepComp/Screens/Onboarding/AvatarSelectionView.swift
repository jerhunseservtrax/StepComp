//
//  AvatarSelectionView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

struct AvatarSelectionOnboardingView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @Binding var currentStep: OnboardingFlowView.OnboardingStep
    
    @State private var selectedAvatarIndex: Int = 0
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    // Emoji avatars matching the design
    private let avatarOptions: [(emoji: String, name: String, color: Color)] = [
        ("🤖", "Botty", Color.blue),
        ("🐱", "Cat", Color.pink),
        ("👽", "Alien", Color.green),
        ("🥷", "Ninja", Color.purple),
        ("🦊", "Fox", Color.orange),
        ("📷", "Custom", Color.gray)
    ]
    
    var body: some View {
        OnboardingScreenBase(currentStep: currentStep.stepIndex) {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Choose your walker")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("You can change this later.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)
                .padding(.bottom, 24)
                
                // Avatar Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(Array(avatarOptions.enumerated()), id: \.offset) { index, avatar in
                            AvatarOption(
                                emoji: avatar.emoji,
                                name: avatar.name,
                                backgroundColor: avatar.color,
                                isSelected: selectedAvatarIndex == index,
                                onSelect: {
                                    withAnimation {
                                        selectedAvatarIndex = index
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
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
                        completeOnboarding()
                    }) {
                        Text("Lookin' Good")
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
    
    private func completeOnboarding() {
        // Store selected avatar emoji temporarily
        // Will be applied when user signs in
        UserDefaults.standard.set(avatarOptions[selectedAvatarIndex].emoji, forKey: "selectedAvatarEmoji")
        
        // Move to sign in step
        withAnimation {
            currentStep = .signIn
        }
    }
}

struct AvatarOption: View {
    let emoji: String
    let name: String
    let backgroundColor: Color
    let isSelected: Bool
    let onSelect: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                ZStack {
                    // Card background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected ? primaryYellow : Color.clear,
                                    lineWidth: 4
                                )
                        )
                        .shadow(
                            color: isSelected ? primaryYellow.opacity(0.3) : Color.black.opacity(0.05),
                            radius: isSelected ? 20 : 8,
                            x: 0,
                            y: isSelected ? 8 : 2
                        )
                    
                    // Avatar circle
                    Circle()
                        .fill(backgroundColor.opacity(0.2))
                        .frame(width: 96, height: 96)
                        .overlay(
                            Text(emoji)
                                .font(.system(size: 48))
                        )
                    
                    // Checkmark badge
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(primaryYellow)
                                        .frame(width: 24, height: 24)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.black)
                                }
                                .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                
                // Name label (only for selected or first item)
                if isSelected && name != "Custom" {
                    Text(name.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(2)
                        .padding(.top, 8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
