//
//  SignInView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import AuthenticationServices
import Combine
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(Supabase)
import Supabase
#endif

struct SignInOnboardingView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @Binding var currentStep: OnboardingFlowView.OnboardingStep

    @State var showingEmailAuth = false
    @State var email: String = ""
    @State var password: String = ""
    @State var username: String = ""
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var height: String = ""
    @State var weight: String = ""
    @State var isSignUp: Bool = false
    @State var isLoading: Bool = false
    @State var errorMessage: String?
    @State var showingForgotPassword = false
    @State var showingTerms = false
    @State var showingPrivacyPolicy = false

    @State var isAnimating = false
    @State var appleSignInDelegate: AppleSignInDelegate?
    #if canImport(UIKit)
    @State var webAuthSession: ASWebAuthenticationSession?
    @State var presentationContextProvider: SignInOnboardingView.WebAuthPresentationContextProvider?
    #endif

    var body: some View {
        OnboardingScreenBase(currentStep: currentStep.stepIndex) {
            SignInOnboardingLandingView(
                onAppleSignIn: { handleAppleSignIn(result: $0) },
                onSignUpWithEmail: {
                    isSignUp = true
                    showingEmailAuth = true
                },
                onSignInWithEmail: {
                    isSignUp = false
                    showingEmailAuth = true
                },
                onShowTerms: { showingTerms = true },
                onShowPrivacy: { showingPrivacyPolicy = true }
            )
        }
        .sheet(isPresented: $showingEmailAuth) {
            EmailAuthSheet(
                isSignUp: $isSignUp,
                email: $email,
                password: $password,
                username: $username,
                firstName: $firstName,
                lastName: $lastName,
                height: $height,
                weight: $weight,
                isLoading: $isLoading,
                errorMessage: errorMessage,
                showingForgotPassword: $showingForgotPassword,
                onSignIn: {
                    Task {
                        await performEmailAuth()
                    }
                },
                onSignUp: {
                    Task {
                        await performEmailAuth()
                    }
                },
                onForgotPassword: {
                    showingForgotPassword = true
                },
                onAppleSignIn: {
                    triggerAppleSignIn()
                }
            )
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordSheet(email: $email)
        }
        .sheet(isPresented: $showingTerms) {
            NavigationStack {
                TermsOfServiceView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showingTerms = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            NavigationStack {
                PrivacyPolicyView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showingPrivacyPolicy = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            isAnimating = true
        }
        .onOpenURL { url in
            // Handle OAuth callback URL
            Task {
                await handleOAuthCallback(url: url)
            }
        }
    }
}
