//
//  SignInView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import AuthenticationServices
import Combine
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if canImport(Supabase)
import Supabase
#endif

struct SignInOnboardingView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @Binding var currentStep: OnboardingFlowView.OnboardingStep
    
    @State private var showingEmailAuth = false
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var username: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var isSignUp: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showingForgotPassword = false
    @State private var showingTerms = false
    @State private var showingPrivacyPolicy = false
    @Environment(\.colorScheme) private var currentColorScheme
    
    
    var body: some View {
        OnboardingScreenBase(currentStep: currentStep.stepIndex) {
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
                                .fill(StepCompColors.primary.opacity(0.1))
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
                                        .foregroundColor(StepCompColors.primary)
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
                                    handleAppleSignIn(result: result)
                                }
                            )
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 56)
                            .cornerRadius(999)
                            .overlay(
                                RoundedRectangle(cornerRadius: 999)
                                    .stroke(Color.clear, lineWidth: 0)
                            )
                            
                            // Google Sign In
                            Button(action: {
                                // #region agent log
                                print("🔍 [H1] Google button tapped - handleGoogleSignIn about to be called")
                                // #endregion
                                handleGoogleSignIn()
                            }) {
                                HStack {
                                    // Google G logo approximation
                                    Text("G")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.blue)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("Sign in with Google")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(StepCompColors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                                .cornerRadius(999)
                            }
                            
                            // Email Sign Up
                            Button(action: {
                                isSignUp = true
                                showingEmailAuth = true
                            }) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    Text("Sign up with Email")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(StepCompColors.surface)
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
                        
                        Button(action: {
                            showingTerms = true
                        }) {
                            Text("Terms")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .underline()
                        }
                        
                        Text(" and ")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showingPrivacyPolicy = true
                        }) {
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
                        Button(action: {
                            isSignUp = false
                            showingEmailAuth = true
                        }) {
                            HStack(spacing: 0) {
                                Text("Sign in with email instead?")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text(" Tap here")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(currentColorScheme == .light ? .black : StepCompColors.primary)
                            }
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 8)
                    }
                }
                    .padding(.bottom, 32)
            }
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
                },
                onGoogleSignIn: {
                    handleGoogleSignIn()
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
    
    @State private var isAnimating = false
    @State private var appleSignInDelegate: AppleSignInDelegate?
    
    private func triggerAppleSignIn() {
        // Create Apple ID provider
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        // Create and configure authorization controller
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleSignInDelegate { result in
            self.handleAppleSignIn(result: result)
        }
        self.appleSignInDelegate = delegate
        authorizationController.delegate = delegate
        
        // Perform authorization request
        authorizationController.performRequests()
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Failed to get Apple ID credential. Please try again."
                return
            }
            
            Task {
                isLoading = true
                errorMessage = nil
                
                do {
                    // Extract identity token from Apple ID credential
                    guard let identityTokenData = appleIDCredential.identityToken,
                          let identityTokenString = String(data: identityTokenData, encoding: .utf8) else {
                        errorMessage = "Failed to get identity token from Apple. Please try again."
                        isLoading = false
                        return
                    }
                    
                    // Extract user information from Apple ID credential
                    let authorizationCode = appleIDCredential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
                    let fullName = appleIDCredential.fullName
                    let email = appleIDCredential.email
                    
                    // Extract first and last name
                    let firstName = fullName?.givenName
                    let lastName = fullName?.familyName
                    
                    // Sign in with Apple using Supabase OAuth
                    try await sessionViewModel.signInWithApple(
                        identityToken: identityTokenString,
                        authorizationCode: authorizationCode,
                        email: email,
                        firstName: firstName,
                        lastName: lastName
                    )
                    
                    // Wait a moment for state to update
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                    
                    // Apply avatar if selected during onboarding
                    if var user = sessionViewModel.currentUser,
                       let avatarURL = UserDefaults.standard.string(forKey: "selectedAvatarURL") {
                        user.avatarURL = avatarURL
                        sessionViewModel.updateUser(user)
                        UserDefaults.standard.removeObject(forKey: "selectedAvatarURL")
                    }
                    
                    // Verify authentication succeeded
                    if sessionViewModel.isAuthenticated, sessionViewModel.currentUser != nil {
                        isLoading = false
                        sessionViewModel.completeOnboarding()
                    } else {
                        isLoading = false
                        errorMessage = "Sign in with Apple failed. Please try again."
                    }
                } catch {
                    isLoading = false
                    let errorDescription = error.localizedDescription
                    print("⚠️ Apple Sign In error: \(errorDescription)")
                    
                    // Provide user-friendly error messages
                    if errorDescription.contains("1000") || errorDescription.contains("AuthorizationError") {
                        errorMessage = "Sign in with Apple is not configured. Please use email sign in instead."
                    } else {
                        errorMessage = errorDescription.isEmpty ? "Sign in with Apple failed. Please try again or use email sign in." : errorDescription
                    }
                }
            }
        case .failure(let error):
            isLoading = false
            let errorDescription = error.localizedDescription
            let nsError = error as NSError
            
            print("⚠️ Apple Sign In error: \(errorDescription), Code: \(nsError.code)")
            
            // Handle specific error codes
            if nsError.domain == "com.apple.AuthenticationServices.AuthorizationError" {
                switch nsError.code {
                case 1000:
                    errorMessage = "Sign in with Apple is not configured. Please use email sign in instead."
                case 1001:
                    errorMessage = "Sign in with Apple was cancelled."
                default:
                    errorMessage = "Sign in with Apple failed. Please try email sign in instead."
                }
            } else {
                errorMessage = errorDescription.isEmpty ? "Sign in with Apple was cancelled or failed. Please try email sign in." : errorDescription
            }
        }
    }
    
    private func performEmailAuth() async {
        isLoading = true
        errorMessage = nil
        
        // Trim whitespace from inputs
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHeight = height.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedWeight = weight.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate inputs
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email"
            isLoading = false
            return
        }
        
        guard !trimmedPassword.isEmpty else {
            errorMessage = "Please enter your password"
            isLoading = false
            return
        }
        
        if isSignUp {
            guard !trimmedUsername.isEmpty else {
                errorMessage = "Please enter a username"
                isLoading = false
                return
            }
            
            // Validate username format (alphanumeric and underscores only, 3-20 characters)
            let usernameRegex = "^[a-z0-9_]{3,20}$"
            let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
            guard usernamePredicate.evaluate(with: trimmedUsername) else {
                errorMessage = "Username must be 3-20 characters and contain only letters, numbers, and underscores"
                isLoading = false
                return
            }
            
            guard !trimmedFirstName.isEmpty else {
                errorMessage = "Please enter your first name"
                isLoading = false
                return
            }
            
            guard !trimmedLastName.isEmpty else {
                errorMessage = "Please enter your last name"
                isLoading = false
                return
            }
            
            // Validate height and weight (optional but should be numbers if provided)
            let heightValue = trimmedHeight.isEmpty ? nil : Int(trimmedHeight)
            let weightValue = trimmedWeight.isEmpty ? nil : Int(trimmedWeight)
            
            if !trimmedHeight.isEmpty && heightValue == nil {
                errorMessage = "Height must be a valid number"
                isLoading = false
                return
            }
            
            if !trimmedWeight.isEmpty && weightValue == nil {
                errorMessage = "Weight must be a valid number"
                isLoading = false
                return
            }
        }
        
        do {
            if isSignUp {
                let heightValue = trimmedHeight.isEmpty ? nil : Int(trimmedHeight)
                let weightValue = trimmedWeight.isEmpty ? nil : Int(trimmedWeight)
                
                try await sessionViewModel.signUp(
                    email: trimmedEmail,
                    password: trimmedPassword,
                    username: trimmedUsername,
                    firstName: trimmedFirstName,
                    lastName: trimmedLastName,
                    height: heightValue,
                    weight: weightValue
                )
            } else {
                try await sessionViewModel.signIn(
                    email: trimmedEmail,
                    password: trimmedPassword
                )
            }
            
            // Wait a moment for the state to update
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            // Check authentication status - refresh from authService
            // The SessionViewModel should have updated via Combine, but let's verify
            if sessionViewModel.isAuthenticated, sessionViewModel.currentUser != nil {
                showingEmailAuth = false
                // Apply avatar if selected during onboarding
                await applySelectedAvatar()
                sessionViewModel.completeOnboarding()
            } else {
                errorMessage = "Authentication failed. Please check your credentials and try again."
            }
        } catch {
            let errorMsg = error.localizedDescription.isEmpty ? "An error occurred. Please try again." : error.localizedDescription
            errorMessage = errorMsg
            print("⚠️ Auth error: \(errorMsg)")
        }
        
        isLoading = false
    }
    
    private func applySelectedAvatar() async {
        guard var user = sessionViewModel.currentUser else { return }
        
        #if canImport(Supabase)
        // Check for custom photo upload first
        if let photoData = UserDefaults.standard.data(forKey: "selectedAvatarPhotoData") {
            do {
                let fileName = "\(user.id)/avatar_\(Int(Date().timeIntervalSince1970)).jpg"
                
                // Upload to Supabase Storage
                try await supabase.storage
                    .from("avatars")
                    .upload(
                        fileName,
                        data: photoData,
                        options: FileOptions(contentType: "image/jpeg", upsert: true)
                    )
                
                // Get public URL
                let publicURL = try supabase.storage
                    .from("avatars")
                    .getPublicURL(path: fileName)
                
                // Update profile with avatar URL
                try await supabase
                    .from("profiles")
                    .update(["avatar_url": publicURL.absoluteString])
                    .eq("id", value: user.id)
                    .execute()
                
                user.avatarURL = publicURL.absoluteString
                sessionViewModel.updateUser(user)
                print("✅ Custom avatar uploaded and applied")
            } catch {
                print("⚠️ Failed to upload avatar: \(error.localizedDescription)")
            }
            UserDefaults.standard.removeObject(forKey: "selectedAvatarPhotoData")
        }
        // Check for emoji avatar
        else if let avatarEmoji = UserDefaults.standard.string(forKey: "selectedAvatarEmoji") {
            do {
                // Update profile with emoji avatar
                try await supabase
                    .from("profiles")
                    .update(["avatar_url": avatarEmoji])
                    .eq("id", value: user.id)
                    .execute()
                
                user.avatarURL = avatarEmoji
                sessionViewModel.updateUser(user)
                print("✅ Emoji avatar applied: \(avatarEmoji)")
            } catch {
                print("⚠️ Failed to apply avatar: \(error.localizedDescription)")
            }
            UserDefaults.standard.removeObject(forKey: "selectedAvatarEmoji")
        }
        #endif
    }
    
    private func handleGoogleSignIn() {
        // #region agent log
        #if canImport(Supabase) && canImport(UIKit)
        print("🔍 [H2] handleGoogleSignIn called - Using Supabase path")
        #else
        print("🔍 [H2] handleGoogleSignIn called - Using mock path")
        #endif
        // #endregion
        
        #if canImport(Supabase) && canImport(UIKit)
        // #region agent log
        print("🔍 [H2] Inside Supabase path - starting Task")
        // #endregion
        
        Task {
            // #region agent log
            print("🔍 [H2] Task started - setting isLoading=true")
            // #endregion
            
            isLoading = true
            errorMessage = nil
            
            do {
                // #region agent log
                print("🔍 [H3] Calling sessionViewModel.signInWithGoogle()")
                // #endregion
                
                // Use Supabase OAuth for Google Sign-In
                let oauthURL = try await sessionViewModel.signInWithGoogle()
                
                // #region agent log
                print("🔍 [H3] OAuth URL received: \(oauthURL.absoluteString)")
                // #endregion
                
                // Open OAuth URL using ASWebAuthenticationSession
                await MainActor.run {
                    // #region agent log
                    print("🔍 [H4] Calling openGoogleOAuth with URL")
                    // #endregion
                    
                    openGoogleOAuth(url: oauthURL)
                }
            } catch {
                // #region agent log
                print("🔍 [H3] Error caught: \(error.localizedDescription)")
                // #endregion
                
                isLoading = false
                if case AuthError.oauthURLGenerated(let url) = error {
                    // URL was generated, open it
                    await MainActor.run {
                        openGoogleOAuth(url: url)
                    }
                } else {
                    errorMessage = error.localizedDescription.isEmpty ? "Sign in with Google failed. Please try again." : error.localizedDescription
                    print("⚠️ Google Sign In error: \(error.localizedDescription)")
                }
            }
        }
        #else
        // #region agent log
        print("🔍 [H2] In fallback/mock path - Supabase not available")
        // #endregion
        
        // Fallback to mock when Supabase is not available
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Create a mock Google user
                try await sessionViewModel.signInWithGoogle(
                    email: "google.user@example.com",
                    displayName: "Google User"
                )
                
                // Wait a moment for state to update
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                
                // Apply avatar if selected during onboarding
                if var user = sessionViewModel.currentUser,
                   let avatarURL = UserDefaults.standard.string(forKey: "selectedAvatarURL") {
                    user.avatarURL = avatarURL
                    sessionViewModel.updateUser(user)
                    UserDefaults.standard.removeObject(forKey: "selectedAvatarURL")
                }
                
                // Verify authentication succeeded
                if sessionViewModel.isAuthenticated, sessionViewModel.currentUser != nil {
                    sessionViewModel.completeOnboarding()
                } else {
                    errorMessage = "Sign in with Google failed. Please try again."
                }
            } catch {
                errorMessage = error.localizedDescription.isEmpty ? "Sign in with Google failed. Please try again." : error.localizedDescription
                print("⚠️ Google Sign In error: \(error.localizedDescription)")
            }
            
            isLoading = false
        }
        #endif
    }
    
    #if canImport(UIKit)
    @State private var webAuthSession: ASWebAuthenticationSession?
    @State private var presentationContextProvider: WebAuthPresentationContextProvider?
    
    // Presentation context provider for ASWebAuthenticationSession
    private class WebAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            // #region agent log
            print("🔍 [H6] presentationAnchor called - finding window")
            // #endregion
            
            // Return the key window
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                // #region agent log
                print("❌ [H6] No window found, returning new UIWindow")
                // #endregion
                return UIWindow()
            }
            
            // #region agent log
            print("✅ [H6] Found window: \(window)")
            // #endregion
            return window
        }
    }
    
    private func openGoogleOAuth(url: URL) {
        // #region agent log
        print("🔍 [H4] openGoogleOAuth called with URL: \(url.absoluteString)")
        print("🔍 [H4] Creating ASWebAuthenticationSession with callbackURLScheme: stepcomp")
        
        // Check if URL scheme is registered
        if let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] {
            print("🔍 [H5] Registered URL Types: \(urlTypes)")
            let schemes = urlTypes.compactMap { $0["CFBundleURLSchemes"] as? [String] }.flatMap { $0 }
            print("🔍 [H5] Registered URL Schemes: \(schemes)")
            if schemes.contains("stepcomp") {
                print("✅ [H5] URL scheme 'stepcomp' IS registered")
            } else {
                print("❌ [H5] URL scheme 'stepcomp' NOT registered! This is the problem.")
                print("❌ [H5] Available schemes: \(schemes)")
            }
        } else {
            print("❌ [H5] No URL types found in Info.plist")
        }
        // #endregion
        
        let callbackURLScheme = "stepcomp" // Must match Info.plist URL scheme
        
        // #region agent log
        // Cancel any existing session first
        if let existingSession = webAuthSession {
            print("🔍 [H6] Cancelling existing auth session")
            existingSession.cancel()
            webAuthSession = nil
        }
        // #endregion
        
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackURLScheme
        ) { callbackURL, error in
            // #region agent log
            print("🔍 [H7] Completion handler called")
            if let error = error {
                print("❌ [H7] Error: \(error.localizedDescription)")
                print("❌ [H7] Error code: \((error as NSError).code)")
                print("❌ [H7] Error domain: \((error as NSError).domain)")
            }
            if let callbackURL = callbackURL {
                print("✅ [H7] Callback URL received: \(callbackURL.absoluteString)")
            } else {
                print("⚠️ [H7] No callback URL received")
            }
            // #endregion
            
            Task { @MainActor in
                isLoading = false
                
                if let error = error {
                    // User cancelled or error occurred
                    if (error as NSError).code != ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        errorMessage = "Google Sign In failed: \(error.localizedDescription)"
                    }
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    errorMessage = "Google Sign In failed: No callback URL"
                    return
                }
                
                // Handle the OAuth callback
                await handleOAuthCallback(url: callbackURL)
            }
        }
        
        // Set presentation context provider (required for iPad and some iOS scenarios)
        // IMPORTANT: Store in @State to retain it - weak reference otherwise causes start() to fail
        let provider = WebAuthPresentationContextProvider()
        presentationContextProvider = provider
        session.presentationContextProvider = provider
        
        // #region agent log
        print("🔍 [H8] Setting prefersEphemeralWebBrowserSession = true (using in-app browser)")
        // #endregion
        
        // Use ephemeral session (in-app browser) instead of shared Safari
        // This often works better on iPad and avoids cookie/session issues
        session.prefersEphemeralWebBrowserSession = true
        
        webAuthSession = session
        
        // #region agent log
        print("🔍 [H4] ASWebAuthenticationSession created, calling start()")
        print("🔍 [H6] presentationContextProvider retained: \(presentationContextProvider != nil)")
        // #endregion
        
        let started = session.start()
        
        // #region agent log
        print("🔍 [H4] session.start() returned: \(started)")
        if !started {
            print("❌ [H4] session.start() failed - possible reasons:")
            print("   - Another auth session might be active")
            print("   - Presentation context invalid")
            print("   - URL scheme not in Info.plist")
        }
        // #endregion
    }
    
    private func handleOAuthCallback(url: URL) async {
        #if canImport(Supabase)
        print("🔵 OAuth callback received: \(url)")
        
        // Process the OAuth callback URL with Supabase
        // Extract tokens from the callback URL
        // Supabase OAuth callbacks contain tokens in the URL fragment or query parameters
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        // Check if this is a valid OAuth callback
        if let fragment = components?.fragment, fragment.contains("access_token") {
            // Parse the fragment to extract tokens
            print("🔵 Found OAuth tokens in URL fragment")
        } else if let queryItems = components?.queryItems, queryItems.contains(where: { $0.name == "code" || $0.name == "access_token" }) {
            // Parse query parameters
            print("🔵 Found OAuth tokens in URL query")
        }
        
        // Supabase SDK should handle the callback automatically
        // Try to get the current session
        do {
            let session = try await supabase.auth.session
            print("✅ OAuth session established: \(session.user.id)")
            
            // Load user profile
            await sessionViewModel.checkSession()
            
            // Wait for state to update
            try? await Task.sleep(nanoseconds: 1000_000_000) // 1 second
            
            // Check if we're now authenticated
            if sessionViewModel.isAuthenticated, sessionViewModel.currentUser != nil {
                print("✅ User authenticated successfully")
                // Apply avatar if selected during onboarding
                if var user = sessionViewModel.currentUser,
                   let avatarURL = UserDefaults.standard.string(forKey: "selectedAvatarURL") {
                    user.avatarURL = avatarURL
                    sessionViewModel.updateUser(user)
                    UserDefaults.standard.removeObject(forKey: "selectedAvatarURL")
                }
                sessionViewModel.completeOnboarding()
            } else {
                print("⚠️ Session exists but user not authenticated")
                errorMessage = "Google Sign In completed but authentication failed. Please try again."
            }
        } catch {
            print("⚠️ No session found after OAuth callback: \(error.localizedDescription)")
            errorMessage = "Google Sign In completed but no session was established. Please try again."
        }
        #else
        errorMessage = "Supabase is not available. Google Sign In cannot be used."
        #endif
    }
    #endif
}

// MARK: - Email Auth Sheet

struct EmailAuthSheet: View {
    @Binding var isSignUp: Bool
    @Binding var email: String
    @Binding var password: String
    @Binding var username: String
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var height: String
    @Binding var weight: String
    @Binding var isLoading: Bool
    let errorMessage: String?
    @Binding var showingForgotPassword: Bool
    let onSignIn: () -> Void
    let onSignUp: () -> Void
    let onForgotPassword: () -> Void
    let onAppleSignIn: () -> Void
    let onGoogleSignIn: () -> Void
    
    @State private var confirmPassword: String = ""
    @State private var showingPassword: Bool = false
    @State private var showingConfirmPassword: Bool = false
    @Environment(\.colorScheme) private var currentColorScheme
    
    @Environment(\.dismiss) var dismiss
    
    private let backgroundDark = Color(red: 0.137, green: 0.133, blue: 0.059) // #23220f
    private let inputDark = Color(red: 0.208, green: 0.204, blue: 0.094) // #353418
    private let inputBorder = Color(red: 0.416, green: 0.412, blue: 0.184) // #6a692f
    
    var body: some View {
        if isSignUp {
            SignUpView(
                email: $email,
                password: $password,
                confirmPassword: $confirmPassword,
                username: $username,
                firstName: $firstName,
                lastName: $lastName,
                height: $height,
                weight: $weight,
                isLoading: $isLoading,
                errorMessage: errorMessage,
                showingPassword: $showingPassword,
                showingConfirmPassword: $showingConfirmPassword,
                onSignUp: onSignUp,
                onBack: { dismiss() },
                onSwitchToSignIn: {
                    isSignUp = false
                },
                onAppleSignIn: onAppleSignIn,
                onGoogleSignIn: onGoogleSignIn
            )
        } else {
            SignInView(
                email: $email,
                password: $password,
                isLoading: $isLoading,
                errorMessage: errorMessage,
                showingForgotPassword: $showingForgotPassword,
                onSignIn: onSignIn,
                onForgotPassword: onForgotPassword,
                onBack: { dismiss() },
                onSwitchToSignUp: {
                    isSignUp = true
                },
                onAppleSignIn: onAppleSignIn,
                onGoogleSignIn: onGoogleSignIn
            )
        }
    }
}

// MARK: - Sign Up View

struct SignUpView: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var confirmPassword: String
    @Binding var username: String
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var height: String
    @Binding var weight: String
    @Binding var isLoading: Bool
    let errorMessage: String?
    @Binding var showingPassword: Bool
    @Binding var showingConfirmPassword: Bool
    let onSignUp: () -> Void
    let onBack: () -> Void
    let onSwitchToSignIn: () -> Void
    let onAppleSignIn: () -> Void
    let onGoogleSignIn: () -> Void
    
    @State private var fullName: String = ""
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                StepCompColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Section
                        VStack(spacing: 24) {
                            // Circular background with email icon
                            ZStack {
                                // Outer glow circle
                                Circle()
                                    .fill(StepCompColors.primary.opacity(0.2))
                                    .frame(width: 128, height: 128)
                                
                                // Pulsing animation circle
                                Circle()
                                    .fill(StepCompColors.primary.opacity(0.1))
                                    .frame(width: 128, height: 128)
                                    .scaleEffect(1.2)
                                    .opacity(0.5)
                                
                                // Email icon
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 52, weight: .medium))
                                        .foregroundColor(StepCompColors.primary)
                            }
                            
                            // Title and Subtitle
                            VStack(spacing: 8) {
                                Text("Join the Step Squad")
                                    .font(.system(size: 32, weight: .black))
                                    .tracking(-0.5)
                                
                                Text("Track every step, reach every goal.")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            // Full Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "person")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    
                                    TextField("What should we call you?", text: $fullName)
                                        .textContentType(.name)
                                        .foregroundColor(.primary)
                                        .onChange(of: fullName) { oldValue, newValue in
                                            // Split full name into first and last
                                            let components = newValue.split(separator: " ", maxSplits: 1)
                                            firstName = components.first.map(String.init) ?? ""
                                            lastName = components.count > 1 ? String(components[1]) : ""
                                        }
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                            
                            // Username
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "at")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    
                                    TextField("Choose a username", text: $username)
                                        .textContentType(.username)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                        .foregroundColor(.primary)
                                        .onChange(of: username) { oldValue, newValue in
                                            // Auto-lowercase and remove spaces
                                            username = newValue.lowercased().replacingOccurrences(of: " ", with: "")
                                        }
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                            
                            // Email
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email Address")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    
                                    TextField("name@example.com", text: $email)
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                            
                            // Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    
                                    if showingPassword {
                                        TextField("Create a password", text: $password)
                                            .textContentType(.newPassword)
                                            .foregroundColor(.primary)
                                    } else {
                                        SecureField("Create a password", text: $password)
                                            .textContentType(.newPassword)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Button(action: {
                                        showingPassword.toggle()
                                    }) {
                                        Image(systemName: showingPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                            
                            // Confirm Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "lock.rotation")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    
                                    SecureField("Repeat password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                            
                            // Height and Weight in a row
                            VStack(spacing: 16) {
                                // Height in feet/inches
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Height")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    HStack(spacing: 12) {
                                        HStack {
                                            Image(systemName: "ruler")
                                                .foregroundColor(.secondary)
                                                .frame(width: 24)
                                            
                                            TextField("5", text: Binding(
                                                get: {
                                                    // Convert stored cm to feet for display
                                                    if let cm = Int(height), cm > 0 {
                                                        let totalInches = Double(cm) / 2.54
                                                        let feet = Int(totalInches / 12)
                                                        return "\(feet)"
                                                    }
                                                    return ""
                                                },
                                                set: { newValue in
                                                    if let feet = Int(newValue) {
                                                        let currentCm = Int(height) ?? 0
                                                        let currentInches = Int((Double(currentCm) / 2.54).truncatingRemainder(dividingBy: 12))
                                                        let newCm = Int(Double(feet * 12 + currentInches) * 2.54)
                                                        height = "\(newCm)"
                                                    }
                                                }
                                            ))
                                            .keyboardType(.numberPad)
                                            .foregroundColor(.primary)
                                            
                                            Text("ft")
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal, 16)
                                        .frame(height: 56)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                        
                                        HStack {
                                            TextField("10", text: Binding(
                                                get: {
                                                    // Convert stored cm to inches for display
                                                    if let cm = Int(height), cm > 0 {
                                                        let totalInches = Double(cm) / 2.54
                                                        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
                                                        return "\(inches)"
                                                    }
                                                    return ""
                                                },
                                                set: { newValue in
                                                    if let inches = Int(newValue) {
                                                        let currentCm = Int(height) ?? 0
                                                        let currentFeet = Int((Double(currentCm) / 2.54) / 12)
                                                        let newCm = Int(Double(currentFeet * 12 + inches) * 2.54)
                                                        height = "\(newCm)"
                                                    }
                                                }
                                            ))
                                            .keyboardType(.numberPad)
                                            .foregroundColor(.primary)
                                            
                                            Text("in")
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal, 16)
                                        .frame(height: 56)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                    }
                                }
                                
                                // Weight in lbs
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Weight (lbs)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    HStack {
                                        Image(systemName: "scalemass")
                                            .foregroundColor(.secondary)
                                            .frame(width: 24)
                                        
                                        TextField("150", text: Binding(
                                            get: {
                                                // Convert stored kg to lbs for display
                                                if let kg = Int(weight), kg > 0 {
                                                    let lbs = Int(Double(kg) * 2.20462)
                                                    return "\(lbs)"
                                                }
                                                return ""
                                            },
                                            set: { newValue in
                                                if let lbs = Int(newValue) {
                                                    let kg = Int(Double(lbs) / 2.20462)
                                                    weight = "\(kg)"
                                                }
                                            }
                                        ))
                                        .keyboardType(.numberPad)
                                        .foregroundColor(.primary)
                                    }
                                    .padding(.horizontal, 16)
                                    .frame(height: 56)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        // Terms and Conditions
                        Text("By signing up, you agree to our [Terms and Conditions](https://example.com/terms) and [Privacy Policy](https://example.com/privacy).")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 24)
                        
                        // Error Message
                        if let errorMessage = errorMessage, !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 16)
                        }
                        
                        // Start Walking Button
                        Button(action: {
                            // Validate passwords match
                            if password != confirmPassword {
                                // Error will be shown
                                return
                            }
                            onSignUp()
                        }) {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text("Start Walking")
                                        .font(.system(size: 18, weight: .black))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(StepCompColors.primary)
                            .foregroundColor(StepCompColors.buttonTextOnPrimary)
                            .cornerRadius(12)
                            .shadow(color: StepCompColors.primary.opacity(0.39), radius: 14, x: 0, y: 4)
                        }
                        .disabled(isLoading || fullName.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || password != confirmPassword)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("Or sign up with")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 12)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        // Social Login Buttons
                        HStack(spacing: 16) {
                            // Apple Sign In
                            Button(action: onAppleSignIn) {
                                ZStack {
                                    Circle()
                                        .fill(Color(.systemGray6))
                                        .frame(width: 56, height: 56)
                                        .overlay(
                                            Circle()
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                    
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 24))
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            // Google Sign In
                            Button(action: onGoogleSignIn) {
                                ZStack {
                                    Circle()
                                        .fill(Color(.systemGray6))
                                        .frame(width: 56, height: 56)
                                        .overlay(
                                            Circle()
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                    
                                    Text("G")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(.bottom, 32)
                        
                        // Log In Link
                        HStack {
                            Text("Already have an account?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Button(action: onSwitchToSignIn) {
                                Text("Log In")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(StepCompColors.primary)
                            }
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onBack) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Sign Up")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .dismissKeyboardOnTap()
    }
}

// MARK: - Sign In View

struct SignInView: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var isLoading: Bool
    let errorMessage: String?
    @Binding var showingForgotPassword: Bool
    let onSignIn: () -> Void
    let onForgotPassword: () -> Void
    let onBack: () -> Void
    let onSwitchToSignUp: () -> Void
    let onAppleSignIn: () -> Void
    let onGoogleSignIn: () -> Void
    
    @State private var showingPassword: Bool = false
    @Environment(\.colorScheme) private var currentColorScheme
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                StepCompColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Section
                        VStack(spacing: 24) {
                            // Circular background with email icon
                            ZStack {
                                // Outer glow circle
                                Circle()
                                    .fill(StepCompColors.primary.opacity(0.2))
                                    .frame(width: 128, height: 128)
                                
                                // Pulsing animation circle
                                Circle()
                                    .fill(StepCompColors.primary.opacity(0.1))
                                    .frame(width: 128, height: 128)
                                    .scaleEffect(1.2)
                                    .opacity(0.5)
                                
                                // Email icon
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 52, weight: .medium))
                                        .foregroundColor(StepCompColors.primary)
                            }
                            
                            // Title and Subtitle
                            VStack(spacing: 8) {
                                Text("Welcome Back")
                                    .font(.system(size: 32, weight: .black))
                                    .tracking(-0.5)
                                
                                Text("Continue your step journey.")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            // Email
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email Address")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    
                                    TextField("name@example.com", text: $email)
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                            
                            // Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    
                                    if showingPassword {
                                        TextField("Enter your password", text: $password)
                                            .textContentType(.password)
                                            .foregroundColor(.primary)
                                    } else {
                                        SecureField("Enter your password", text: $password)
                                            .textContentType(.password)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Button(action: {
                                        showingPassword.toggle()
                                    }) {
                                        Image(systemName: showingPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 56)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        
                        // Forgot Password Link
                        HStack {
                            Spacer()
                            Button(action: onForgotPassword) {
                                Text("Forgot Password?")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(currentColorScheme == .light ? .black : StepCompColors.primary)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        // Error Message
                        if let errorMessage = errorMessage, !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 16)
                        }
                        
                        // Sign In Button
                        Button(action: onSignIn) {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text("Sign In")
                                        .font(.system(size: 18, weight: .black))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(StepCompColors.primary)
                            .foregroundColor(StepCompColors.buttonTextOnPrimary)
                            .cornerRadius(12)
                            .shadow(color: StepCompColors.primary.opacity(0.39), radius: 14, x: 0, y: 4)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            Text("Or sign in with")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 12)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        // Social Login Buttons
                        HStack(spacing: 16) {
                            // Apple Sign In
                            Button(action: onAppleSignIn) {
                                ZStack {
                                    Circle()
                                        .fill(Color(.systemGray6))
                                        .frame(width: 56, height: 56)
                                        .overlay(
                                            Circle()
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                    
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 24))
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            // Google Sign In
                            Button(action: onGoogleSignIn) {
                                ZStack {
                                    Circle()
                                        .fill(Color(.systemGray6))
                                        .frame(width: 56, height: 56)
                                        .overlay(
                                            Circle()
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                    
                                    Text("G")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(.bottom, 32)
                        
                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Button(action: onSwitchToSignUp) {
                                Text("Sign Up")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(currentColorScheme == .light ? .black : StepCompColors.primary)
                            }
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: onBack) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Sign In")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .dismissKeyboardOnTap()
    }
}

// MARK: - Forgot Password Sheet

struct ForgotPasswordSheet: View {
    @Binding var email: String
    @State private var resetEmail: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    @Environment(\.dismiss) var dismiss
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                StepCompColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Icon
                        ZStack {
                            Circle()
                                .fill(StepCompColors.primary.opacity(0.2))
                                .frame(width: 128, height: 128)
                            
                            Image(systemName: "key.fill")
                                .font(.system(size: 52, weight: .medium))
                                .foregroundColor(StepCompColors.primary)
                        }
                        .padding(.top, 40)
                        
                        // Title and Description
                        VStack(spacing: 12) {
                            Text("Forgot Password?")
                                .font(.system(size: 32, weight: .bold))
                            
                    Text("Enter your email address and we'll send you a link to reset your password.")
                                .font(.system(size: 16))
                        .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 24)
                            
                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(.secondary)
                                    .frame(width: 24)
                                
                                TextField("your.email@example.com", text: $resetEmail)
                        .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                        .autocorrectionDisabled(true)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        
                        // Error or Success Message
                        if let errorMessage = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        if let successMessage = successMessage {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text(successMessage)
                                        .font(.system(size: 14))
                                        .foregroundColor(.green)
                                }
                                
                                Button(action: {
                                    dismiss()
                                }) {
                                    Text("Got it")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Send Reset Link Button
                        if successMessage == nil {
                    Button(action: {
                        Task {
                            await resetPassword()
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .tint(.black)
                            }
                            Text("Send Reset Link")
                                        .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(StepCompColors.primary)
                                .foregroundColor(StepCompColors.buttonTextOnPrimary)
                                .cornerRadius(12)
                    }
                    .disabled(isLoading || resetEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity((isLoading || resetEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.5 : 1.0)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                resetEmail = email
            }
        }
    }
    
    private func resetPassword() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        let trimmedEmail = resetEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email address."
            isLoading = false
            return
        }
        
        // Validate email format
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: trimmedEmail) else {
            errorMessage = "Please enter a valid email address."
            isLoading = false
            return
        }
        
        do {
            #if canImport(Supabase)
            // Use custom URL scheme for deep link
            let redirectURL = URL(string: "je.stepcomp://reset-password")!
            try await supabase.auth.resetPasswordForEmail(
                trimmedEmail,
                redirectTo: redirectURL
            )
            
            // ✅ Security Best Practice: Never reveal if email exists
            // Always show success message regardless of whether account exists
            successMessage = "If an account with that email exists, you'll receive a password reset link shortly. Please check your inbox and spam folder."
            #else
            // Mock implementation
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            successMessage = "If an account with that email exists, you'll receive a password reset link shortly."
            #endif
        } catch {
            // ✅ Security Best Practice: Generic error message
            // Don't reveal specific errors that might leak information
            print("⚠️ Password reset error: \(error.localizedDescription)")
            successMessage = "If an account with that email exists, you'll receive a password reset link shortly."
        }
        
        isLoading = false
    }
}

// MARK: - Password Reset View

struct PasswordResetView: View {
    let resetURL: URL
    let onComplete: () -> Void
    
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showingPassword: Bool = false
    @State private var showingConfirmPassword: Bool = false
    
    @EnvironmentObject var authService: AuthService
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                StepCompColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "lock.rotation")
                                .font(.system(size: 64))
                                .foregroundColor(StepCompColors.primary)
                            
                            Text("Reset Your Password")
                                .font(.system(size: 32, weight: .bold))
                            
                            Text("Enter your new password below")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                        
                        // Password Fields
                        VStack(spacing: 20) {
                            // New Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("New Password")
                                    .font(.system(size: 14, weight: .semibold))
                                
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    
                                    if showingPassword {
                                        TextField("Enter new password", text: $newPassword)
                                            .textContentType(.newPassword)
                                    } else {
                                        SecureField("Enter new password", text: $newPassword)
                                            .textContentType(.newPassword)
                                    }
                                    
                                    Button(action: {
                                        showingPassword.toggle()
                                    }) {
                                        Image(systemName: showingPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            // Confirm Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 14, weight: .semibold))
                                
                                HStack {
                                    Image(systemName: "lock.rotation")
                                        .foregroundColor(.secondary)
                                        .frame(width: 24)
                                    
                                    if showingConfirmPassword {
                                        TextField("Confirm new password", text: $confirmPassword)
                                            .textContentType(.newPassword)
                                    } else {
                                        SecureField("Confirm new password", text: $confirmPassword)
                                            .textContentType(.newPassword)
                                    }
                                    
                                    Button(action: {
                                        showingConfirmPassword.toggle()
                                    }) {
                                        Image(systemName: showingConfirmPassword ? "eye.slash" : "eye")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Error Message
                if let errorMessage = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                    .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                            .padding(.horizontal, 24)
                }
                
                        // Success Message
                if let successMessage = successMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(successMessage)
                                    .font(.system(size: 14))
                                .foregroundColor(.green)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Reset Button
                        Button(action: {
                            Task {
                                await resetPassword()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text("Reset Password")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(StepCompColors.primary)
                            .foregroundColor(StepCompColors.buttonTextOnPrimary)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading || newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        
                        // Password Requirements
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password Requirements:")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            Text("• At least 8 characters")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text("• At least one letter")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            Text("• At least one number")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onComplete()
                    }
                }
            }
        }
    }
    
    private func resetPassword() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        // Validate passwords
        guard !newPassword.isEmpty else {
            errorMessage = "Please enter a new password"
            isLoading = false
            return
        }
        
        // ✅ Security Best Practice: Enforce strong password requirements
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            isLoading = false
            return
        }
        
        // Validate password strength
        let hasLetter = newPassword.rangeOfCharacter(from: .letters) != nil
        let hasNumber = newPassword.rangeOfCharacter(from: .decimalDigits) != nil
        
        guard hasLetter && hasNumber else {
            errorMessage = "Password must contain at least one letter and one number"
            isLoading = false
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            isLoading = false
            return
        }
        
        do {
            #if canImport(Supabase)
            // Supabase password reset URLs contain tokens in the fragment
            // Parse the URL to extract tokens
            let components = URLComponents(url: resetURL, resolvingAgainstBaseURL: false)
            var accessToken: String?
            var refreshToken: String?
            
            // Extract tokens from URL fragment (common format)
            if let fragment = components?.fragment {
                let params = fragment.components(separatedBy: "&")
                for param in params {
                    let parts = param.components(separatedBy: "=")
                    if parts.count == 2 {
                        if parts[0] == "access_token" {
                            accessToken = parts[1].removingPercentEncoding
                        } else if parts[0] == "refresh_token" {
                            refreshToken = parts[1].removingPercentEncoding
                        }
                    }
                }
            }
            
            // Extract from query parameters (alternative format)
            if accessToken == nil, let queryItems = components?.queryItems {
                for item in queryItems {
                    if item.name == "access_token" {
                        accessToken = item.value
                    } else if item.name == "refresh_token" {
                        refreshToken = item.value
                    }
                }
            }
            
            guard let accessToken = accessToken, let refreshToken = refreshToken else {
                errorMessage = "Invalid reset link. Please request a new password reset email."
                isLoading = false
                return
            }
            
            // Set the session with tokens from reset URL
            try await supabase.auth.setSession(
                accessToken: accessToken,
                refreshToken: refreshToken
            )
            
            // Wait a moment for session to be established
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Update the password
            try await supabase.auth.update(
                user: UserAttributes(password: newPassword)
            )
            
            successMessage = "Password updated successfully! You can now sign in with your new password."
            
            // ✅ Security Best Practice: Invalidate old sessions after password reset
            // Supabase automatically invalidates old sessions when password is updated
            
            // Wait to show success message
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                onComplete()
            }
            #else
            errorMessage = "Password reset is not available in mock mode"
            #endif
        } catch {
            let errorMsg = error.localizedDescription
            print("⚠️ Password reset error: \(errorMsg)")
            
            // Provide user-friendly error messages
            if errorMsg.contains("session") || errorMsg.contains("expired") {
                errorMessage = "Your reset link has expired. Please request a new password reset link."
            } else if errorMsg.contains("same") {
                errorMessage = "New password must be different from your current password."
            } else {
                errorMessage = errorMsg.isEmpty ? "Failed to reset password. Please try again." : errorMsg
            }
        }
        
        isLoading = false
    }
}

// MARK: - Apple Sign In Delegate

class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    let completion: (Result<ASAuthorization, Error>) -> Void
    
    init(completion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        completion(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
}
