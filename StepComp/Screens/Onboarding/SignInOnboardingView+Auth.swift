//
//  SignInOnboardingView+Auth.swift
//  FitComp
//
//  Extracted from SignInView.swift for maintainability.
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

extension SignInOnboardingView {
    func triggerAppleSignIn() {
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
    
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
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
                    
                    // Update daily step goal from UserDefaults (set during onboarding)
                    let savedDailyGoal = UserDefaults.standard.integer(forKey: "dailyStepGoal")
                    if savedDailyGoal > 0 {
                        await sessionViewModel.authServiceAccess.updateDailyStepGoal(savedDailyGoal)
                        print("✅ Daily step goal updated after Apple Sign-In: \(savedDailyGoal)")
                    }
                    
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
    
    func performEmailAuth() async {
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
                
                // Update daily step goal from UserDefaults (set during onboarding)
                // This ensures the goal is synced even if the user signed in (not signed up)
                let savedDailyGoal = UserDefaults.standard.integer(forKey: "dailyStepGoal")
                if savedDailyGoal > 0 {
                    await sessionViewModel.authServiceAccess.updateDailyStepGoal(savedDailyGoal)
                    print("✅ Daily step goal updated after email auth: \(savedDailyGoal)")
                }
                
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
    
    func applySelectedAvatar() async {
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
    
    func handleGoogleSignIn() {
        #if canImport(Supabase) && canImport(UIKit)
        #else
        #endif
        
        #if canImport(Supabase) && canImport(UIKit)
        
        Task {
            
            isLoading = true
            errorMessage = nil
            
            do {
                
                // Use Supabase OAuth for Google Sign-In
                let oauthURL = try await sessionViewModel.signInWithGoogle()
                
                
                // Open OAuth URL using ASWebAuthenticationSession
                await MainActor.run {
                    
                    openGoogleOAuth(url: oauthURL)
                }
            } catch {
                
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
}

#if canImport(UIKit)
extension SignInOnboardingView {
    class WebAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
        func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            
            // Return the key window
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                print("❌ [H6] No window found, returning new UIWindow")
                return UIWindow()
            }
            
            print("✅ [H6] Found window: \(window)")
            return window
        }
    }
    func openGoogleOAuth(url: URL) {
        
        // Check if URL scheme is registered
        if let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] {
            let schemes = urlTypes.compactMap { $0["CFBundleURLSchemes"] as? [String] }.flatMap { $0 }
            if schemes.contains("fitcomp") {
                print("✅ [H5] URL scheme 'fitcomp' IS registered")
            } else {
                print("❌ [H5] URL scheme 'fitcomp' NOT registered! This is the problem.")
                print("❌ [H5] Available schemes: \(schemes)")
            }
        } else {
            print("❌ [H5] No URL types found in Info.plist")
        }
        
        let callbackURLScheme = "fitcomp" // Must match Info.plist URL scheme
        
        // Cancel any existing session first
        if let existingSession = webAuthSession {
            existingSession.cancel()
            webAuthSession = nil
        }
        
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackURLScheme
        ) { callbackURL, error in
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
        
        
        // Use ephemeral session (in-app browser) instead of shared Safari
        // This often works better on iPad and avoids cookie/session issues
        session.prefersEphemeralWebBrowserSession = true
        
        webAuthSession = session
        
        
        let started = session.start()
        
        if !started {
            print("❌ [H4] session.start() failed - possible reasons:")
            print("   - Another auth session might be active")
            print("   - Presentation context invalid")
            print("   - URL scheme not in Info.plist")
        }
    }
    
    func handleOAuthCallback(url: URL) async {
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
                
                // Update daily step goal from UserDefaults (set during onboarding)
                let savedDailyGoal = UserDefaults.standard.integer(forKey: "dailyStepGoal")
                if savedDailyGoal > 0 {
                    await sessionViewModel.authServiceAccess.updateDailyStepGoal(savedDailyGoal)
                    print("✅ Daily step goal updated after OAuth: \(savedDailyGoal)")
                }
                
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
}
#endif
