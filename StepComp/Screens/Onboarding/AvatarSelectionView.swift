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
    
    @State private var selectedAvatarIndex: Int = 1
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    // Placeholder avatar URLs (would be replaced with actual avatar options)
    private let avatarOptions: [String] = [
        "https://lh3.googleusercontent.com/aida-public/AB6AXuDayMlHVGCDatlPdfkSR0CEK1YxUpeDb0Dj77cCeHyJHAABvJu643G6DqrAvSIlUexSsy-wdTyKU1GSzygltZ3flIBTIfRqKnGwbKLFlXnm-nYZ1jbFQWd2C8vk8Ux5wbSgXAs7tNxUeIoxIEBeEB7ILvYDPdb49fLSypwfufX2Ibvfe4_LCW1AMGbgsHIEyxu8aOVrnKIaTEmeTY6EtOgCOxvNiJfD7jAJUn0UcQR7AyntYLrS4mwEXYVn-2W2w2bwkBodHnbvsg",
        "https://lh3.googleusercontent.com/aida-public/AB6AXuB8J9muV284_SRN4ApSLk0ad2alWfqqo90ea-kS77VWBVfF31PUvJ-Vprk56jcDGdPSt-GMdd2ilByLOlxXBqSTew40su0qiyA83EWlFmvGXg6kNrhra1poVt0Vyzz578KLFjCNlLTgRA3VfjroxoI3VkNO4JwNUczZICmnp2yVRcJDDDNBWqbrvTvAlCaiv0L0M9slJNsNtCqZEuHCtcN746ISQtC7-sVFv-leetp2ifbgSxZXebU6Ehu5dTnHUgnjBvFWMKE2Fw",
        "https://lh3.googleusercontent.com/aida-public/AB6AXuCJxcKsJM2uoALenKraNCISl_43-_oSCKZjQsvL-TqxegKPjsHc3DJquQ7ixW1ppYe4cLCHGPgvlLM3w_ISyQ64qSNZDMj8WGrC3-GX5_AqiBoYSZwGDNbxeOcTaDmbtmpTpuywMh6Vt3ZMT7-MADlxiuCc2hslDzKWeOvUca-zLnTqjKw92hiaVaJ0_c9OEBQeGjbYjfBc-fXL7vmAeIw9Z0XT9MNfBqnabdOrGyPQdLPboZg64KUwPCuKuwGjy_41nnH6BqagjQ",
        "https://lh3.googleusercontent.com/aida-public/AB6AXuBvpb55uwN9_R3-EL_WZXz5p4w8UzFsg44Wfh0oMycbWoCxOH_LWfqakpkhzRQQEIm0dOl31J0lDSQGz-zJuuTYfwo8LplNAORCzzvz9eEN6jtc4-watgozKespc9dsUxP6n2mwasWRfocwkYO7XLbY0-6F8GfFZWNI70z0JwIAvIXqgSqwLA3ukWctPCgTLaowV4cnps9_uMuoxsUN95I-1AcptbbnrIa2Ow7eZyf8Lwy4IYLmTC895K9ZY_4l8MnooHE8-KFjDQ",
        "https://lh3.googleusercontent.com/aida-public/AB6AXuCOeQnSY7Q9tdPNqNr-duzwMv9m33o5nmScvsEbo8_n_VSFM8ha2GvjFfDTPfbDvomXszfQikoHYfDtbwWXZ0NwD7HGjqyrhjEOP6Y5mQQboQCUIccjku1rERevKJvcsYgk1pyCUhFj0Jra8Kv2QqH1bVe8P-DAEHrqTRUtUXxEBrIjYwO6_wxmh5jgg1ecb54QmZ742x_ZN_ofeQxCLIL9JJ3YXMi7eKK3dVkG1PC1Q9A1a-RzhQlXnmwpJHxAgIBjluqbETiBOg",
        "https://lh3.googleusercontent.com/aida-public/AB6AXuBSSEl-zEsBa5yWRg_q9fXPBpH-5fOGpPeJTjkeCpc3RNwMrRiwgSvGdzmlfaRbDVoW1_04Lr0nQZRc5XQk4Oh8hIJdQrpDeklYxNAap80CJGn66pZZ5c_TQntIBF2ynWsxZrWLFtF-MnRwsAqeUzo_67UtyvrPNtTHHjJRWj8pCOZ7qZo-wCF8Uxio7eBXVKxVeeC1d20sDo0K3_G_J_XSMtE0Prxh4s8iz8hYe9obuuXIylDb-DxZ3PjPmfSXBPdDzJh_5inyiA"
    ]
    
    var body: some View {
        OnboardingScreenBase(currentStep: currentStep.stepIndex) {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Who are you?")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("Choose an avatar that matches your vibe.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)
                .padding(.bottom, 32)
                
                // Avatar Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 24) {
                        ForEach(Array(avatarOptions.enumerated()), id: \.offset) { index, avatarURL in
                            AvatarOption(
                                avatarURL: avatarURL,
                                isSelected: selectedAvatarIndex == index,
                                onSelect: {
                                    selectedAvatarIndex = index
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
                        Text("Continue")
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
    
    private func completeOnboarding() {
        // Store selected avatar URL temporarily
        // Will be applied when user signs in
        UserDefaults.standard.set(avatarOptions[selectedAvatarIndex], forKey: "selectedAvatarURL")
        
        // Move to sign in step
        currentStep = .signIn
    }
}

struct AvatarOption: View {
    let avatarURL: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: avatarURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color(.systemGray5)
                }
                .frame(width: 128, height: 128)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? primaryYellow : Color.clear,
                            lineWidth: 4
                        )
                )
                .overlay(
                    Circle()
                        .stroke(Color(.systemBackground), lineWidth: 2)
                        .padding(2)
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .shadow(
                    color: isSelected ? primaryYellow.opacity(0.3) : Color.clear,
                    radius: isSelected ? 20 : 0,
                    x: 0,
                    y: isSelected ? 8 : 0
                )
                
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(primaryYellow)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    )
                    .offset(x: 4, y: 4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
