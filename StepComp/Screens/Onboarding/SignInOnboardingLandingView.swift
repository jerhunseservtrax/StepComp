//
//  SignInOnboardingLandingView.swift
//  FitComp
//
//  Extracted from SignInView.swift for maintainability.
//

import AuthenticationServices
import SwiftUI

struct SignInOnboardingLandingView: View {
    @Environment(\.colorScheme) private var currentColorScheme

    let onAppleSignIn: (Result<ASAuthorization, Error>) -> Void
    let onSignUpWithEmail: () -> Void
    let onSignInWithEmail: () -> Void
    let onShowTerms: () -> Void
    let onShowPrivacy: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Image - Trophy and Cloud
                    ZStack {
                        // Background blurs
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 160, height: 160)
                            .blur(radius: 40)
                            .offset(x: -20, y: 20)

                        Circle()
                            .fill(FitCompColors.primary.opacity(0.1))
                            .frame(width: 128, height: 128)
                            .blur(radius: 30)
                            .offset(x: 20, y: -20)

                        // Icon Group - Overlapping cards
                        VStack(spacing: 0) {
                            // Trophy card (top, rotated)
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color(.systemBackground))
                                    .frame(width: 120, height: 120)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)

                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(FitCompColors.primary)
                            }
                            .rotationEffect(.degrees(-6))
                            .offset(y: 20)

                            // Cloud card (bottom, rotated)
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color(.systemGray6))
                                    .frame(width: 192, height: 128)
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)

                                Image(systemName: "cloud.upload.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                            }
                            .rotationEffect(.degrees(6))
                            .offset(y: -20)
                        }
                    }
                    .frame(height: 256)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 32)

                    // Text Content
                    VStack(spacing: 12) {
                        Text("Welcome back!")
                            .font(.system(size: 32, weight: .bold))

                        Text("Sign in to continue your journey, or create a new account to get started.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 32)

                    // Auth Buttons
                    VStack(spacing: 12) {
                        // Apple Sign In
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                onAppleSignIn(result)
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 56)
                        .cornerRadius(999)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(Color.clear, lineWidth: 0)
                        )

                        // Email Sign Up
                        Button(action: onSignUpWithEmail) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 16, weight: .semibold))

                                Text("Sign up with Email")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(FitCompColors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 999)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .cornerRadius(999)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }

            // Bottom Section with Terms and Sign In Link
            VStack(spacing: 16) {
                // Terms Text
                HStack(spacing: 0) {
                    Text("By continuing, you agree to our ")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Button(action: onShowTerms) {
                        Text("Terms")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .underline()
                    }

                    Text(" and ")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Button(action: onShowPrivacy) {
                        Text("Privacy Policy")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .underline()
                    }

                    Text(".")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

                // Email sign in link
                HStack {
                    Spacer()
                    Button(action: onSignInWithEmail) {
                        HStack(spacing: 0) {
                            Text("Sign in with email instead?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(" Tap here")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(currentColorScheme == .light ? .black : FitCompColors.primary)
                        }
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 8)
                }
            }
            .padding(.bottom, 32)
        }
    }
}
