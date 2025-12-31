//
//  AuthService.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import Combine // Required for @Published and ObservableObject
#if canImport(Supabase)
import Supabase
#endif

@MainActor
final class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    
    private let userDefaultsKey = "currentUser"
    private let useSupabase = true // Supabase is now configured and database tables are created
    
    // MARK: - Test Account Credentials
    // For testing purposes, use these credentials:
    // Email: test@stepcomp.app
    // Password: test123
    // 
    // Note: Any email/password combination will work in mock mode,
    // but this test account will have pre-populated data for better testing.
    
    private let testAccountEmail = "test@stepcomp.app"
    private let testAccountPassword = "test123"
    private let testAccountDisplayName = "Test User"
    
    init() {
        if useSupabase {
            checkSupabaseSession()
        } else {
            loadUser()
        }
    }
    
    // MARK: - Supabase Authentication
    
    func checkSupabaseSession() {
        #if canImport(Supabase)
        Task {
            do {
                let session = try await supabase.auth.session
                
                // For indefinite sign-in: refresh expired sessions instead of signing out
                // This allows users to stay signed in until they manually log out
                if session.isExpired {
                    print("🔄 Session expired, attempting to refresh...")
                    do {
                        // Try to refresh the session
                        let refreshedSession = try await supabase.auth.refreshSession()
                        print("✅ Session refreshed successfully")
                        
                        // Load user profile with refreshed session
                        if !refreshedSession.user.id.uuidString.isEmpty {
                            await loadUserProfile(userId: refreshedSession.user.id.uuidString)
                        } else {
                            isAuthenticated = false
                            currentUser = nil
                        }
                    } catch {
                        // If refresh fails, user needs to sign in again
                        print("⚠️ Failed to refresh session: \(error.localizedDescription)")
                        isAuthenticated = false
                        currentUser = nil
                    }
                    return
                }
                
                // Only proceed if we have a valid, non-expired session with a user
                if !session.user.id.uuidString.isEmpty {
                    await loadUserProfile(userId: session.user.id.uuidString)
                } else {
                    // No valid session - this is expected for new users
                    isAuthenticated = false
                    currentUser = nil
                }
            } catch {
                // Check if this is just a missing session (expected for new users)
                let errorDescription = error.localizedDescription.lowercased()
                if errorDescription.contains("session") && 
                   (errorDescription.contains("missing") || 
                    errorDescription.contains("not found") ||
                    errorDescription.contains("no session")) {
                    // This is expected - user is not logged in yet
                    // Don't log as an error, just set state
                    isAuthenticated = false
                    currentUser = nil
                } else {
                    // This is an unexpected error - log it
                    print("⚠️ Error checking Supabase session: \(error.localizedDescription)")
                    isAuthenticated = false
                    currentUser = nil
                }
            }
        }
        #else
        // Supabase not available - use mock mode
        loadUser()
        #endif
    }
    
    func signIn(email: String, password: String) async throws {
        print("🔵 signIn called - useSupabase: \(useSupabase)")
        #if canImport(Supabase)
        print("✅ Supabase package is available")
        if useSupabase {
            print("🔵 Using Supabase sign-in")
            try await signInWithSupabase(email: email, password: password)
        } else {
            print("⚠️ Supabase available but useSupabase=false, using mock")
            try await signInMock(email: email, password: password)
        }
        #else
        print("❌ Supabase package NOT available, using mock")
        try await signInMock(email: email, password: password)
        #endif
    }
    
    func signUp(email: String, password: String, username: String, firstName: String, lastName: String, height: Int?, weight: Int?) async throws {
        print("🔵 signUp called - useSupabase: \(useSupabase)")
        #if canImport(Supabase)
        print("✅ Supabase package is available")
        if useSupabase {
            print("🔵 Using Supabase sign-up")
            // Check if username already exists (email check is now handled by Supabase sign-up)
            try await checkUsernameExists(username: username)
            try await signUpWithSupabase(email: email, password: password, username: username, firstName: firstName, lastName: lastName, height: height, weight: weight)
        } else {
            print("⚠️ Supabase available but useSupabase=false, using mock")
            try await signUpMock(email: email, password: password, username: username, firstName: firstName, lastName: lastName, height: height, weight: weight)
        }
        #else
        print("❌ Supabase package NOT available, using mock")
        try await signUpMock(email: email, password: password, username: username, firstName: firstName, lastName: lastName, height: height, weight: weight)
        #endif
    }
    
    private func checkEmailExists(email: String) async throws {
        #if canImport(Supabase)
        // Instead of trying to sign in with a dummy password (which is unreliable),
        // we'll let Supabase handle the duplicate email check during sign-up.
        // Supabase will return a clear error if the email already exists.
        // This function now just validates the email format.
        
        // Basic email format validation
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            throw AuthError.invalidResponse // Or create a specific email format error
        }
        
        // Note: We removed the dummy sign-in check because:
        // 1. It's unreliable - Supabase may return "invalid credentials" for both existing and non-existing emails
        // 2. It's unnecessary - Supabase sign-up will return a clear error if email exists
        // 3. It creates false positives
        return
        #else
        // In mock mode, always allow sign-up
        return
        #endif
    }
    
    private func checkUsernameExists(username: String) async throws {
        #if canImport(Supabase)
        do {
            // Check if username exists in profiles table
            let profiles: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .eq("username", value: username)
                .execute()
                .value
            
            if !profiles.isEmpty {
                throw AuthError.usernameAlreadyExists
            }
        } catch {
            // If it's our custom error, rethrow it
            if error is AuthError {
                throw error
            }
            // For other errors (like network issues), log and rethrow
            print("⚠️ Error checking username: \(error.localizedDescription)")
            throw error
        }
        #else
        // In mock mode, always allow sign-up
        return
        #endif
    }
    
    func signInWithApple(identityToken: String, authorizationCode: String?, email: String?, firstName: String?, lastName: String?) async throws {
        print("🔵 signInWithApple called - useSupabase: \(useSupabase)")
        #if canImport(Supabase)
        print("✅ Supabase package is available")
        guard useSupabase else {
            print("⚠️ Supabase available but useSupabase=false, using mock")
            // Mock Apple Sign In with provided credentials
            let username = email?.components(separatedBy: "@").first?.lowercased() ?? "user_\(UUID().uuidString.prefix(8))"
            let user = User(
                username: username,
                firstName: firstName ?? "",
                lastName: lastName ?? "",
                email: email,
                totalSteps: 0,
                totalChallenges: 0
            )
            currentUser = user
            isAuthenticated = true
            saveUser()
            return
        }
        
        print("🔵 Using Supabase OAuth for Apple Sign-In")
        
        do {
            // Sign in with Apple using identity token
            let response = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: identityToken,
                    nonce: nil
                )
            )
            
            print("✅ Apple Sign-In successful. User ID: \(response.user.id)")
            
            guard let userId = response.user.id.uuidString as String? else {
                print("❌ Failed to get user ID from response")
                throw AuthError.invalidResponse
            }
            
            // Wait a moment for session to be established
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Check if profile exists, if not create it
            let profileExists: Bool
            do {
                let _: UserProfile = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: userId)
                    .single()
                    .execute()
                    .value
                profileExists = true
                print("✅ Profile already exists")
            } catch {
                profileExists = false
                print("🔵 Profile doesn't exist, will create it")
            }
            
            // Create or update profile with user information
            // Generate unique username - use email prefix if available, otherwise use full UUID for uniqueness
            let username: String
            if let email = email, !email.isEmpty {
                username = email.components(separatedBy: "@").first?.lowercased() ?? "apple_\(userId)"
            } else {
                // No email provided - use full UUID to ensure uniqueness
                username = "apple_\(userId)"
            }
            
            let profile = UserProfile(
                id: userId,
                username: username,
                firstName: firstName,
                lastName: lastName,
                avatar: nil,
                avatarUrl: nil,
                displayName: [firstName, lastName].compactMap { $0 }.joined(separator: " ").isEmpty ? nil : [firstName, lastName].compactMap { $0 }.joined(separator: " "),
                isPremium: false,
                height: nil,
                weight: nil,
                email: email,
                publicProfile: false, // Default to private
                totalSteps: 0,
                dailyStepGoal: 10000
            )
            
            if profileExists {
                // Update existing profile
                try await supabase
                    .from("profiles")
                    .update(profile)
                    .eq("id", value: userId)
                    .execute()
                print("✅ Profile updated for Apple Sign-In user")
            } else {
                // Create new profile
                do {
                    try await supabase
                        .from("profiles")
                        .insert(profile)
                        .execute()
                    print("✅ Profile created for Apple Sign-In user: \(username)")
                } catch {
                    print("❌ Failed to create profile: \(error.localizedDescription)")
                    print("❌ Profile data: username=\(username), firstName=\(firstName ?? "nil"), lastName=\(lastName ?? "nil")")
                    // This is critical - if profile creation fails, challenge creation will fail
                    throw error
                }
            }
            
            // Load user profile to ensure currentUser is set correctly
            await loadUserProfile(userId: userId)
            
            // Verify currentUser was set
            guard currentUser != nil else {
                print("❌ Failed to load user profile after Apple Sign-In")
                throw AuthError.invalidResponse
            }
            
            print("✅ Apple Sign-In complete - currentUser set: \(currentUser?.username ?? "unknown")")
        } catch {
            print("❌ Apple Sign-In error: \(error.localizedDescription)")
            print("❌ Error details: \(error)")
            throw error
        }
        #else
        print("❌ Supabase package NOT available, using mock")
        // Mock Apple Sign In when Supabase is not available
        let username = email?.components(separatedBy: "@").first?.lowercased() ?? "user_\(UUID().uuidString.prefix(8))"
        let user = User(
            username: username,
            firstName: firstName ?? "",
            lastName: lastName ?? "",
            email: email,
            totalSteps: 0,
            totalChallenges: 0
        )
        currentUser = user
        isAuthenticated = true
        saveUser()
        #endif
    }
    
    func signInWithGoogle() async throws -> URL {
        print("🔵 signInWithGoogle called - useSupabase: \(useSupabase)")
        #if canImport(Supabase)
        print("✅ Supabase package is available")
        guard useSupabase else {
            print("⚠️ Supabase available but useSupabase=false, using mock")
            // Mock Google Sign In - return dummy URL
            let user = User(
                displayName: "Google User",
                email: "google@example.com",
                totalSteps: 0,
                totalChallenges: 0
            )
            currentUser = user
            isAuthenticated = true
            saveUser()
            return URL(string: "https://example.com")!
        }
        
        print("🔵 Using Supabase OAuth for Google Sign-In")
        
        // Use Supabase OAuth for Google Sign-In
        // IMPORTANT: redirectTo must be the Supabase callback URL configured in Dashboard
        // Supabase will redirect to your app's custom URL scheme after processing OAuth
        let supabaseCallbackURL = URL(string: SupabaseConfig.supabaseOAuthCallbackURL)!
        
        // Build the redirect URL with the app's custom scheme as a parameter
        // Format: https://your-project.supabase.co/auth/v1/callback?redirect_to=your-app-scheme://auth-callback
        var components = URLComponents(url: supabaseCallbackURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "redirect_to", value: SupabaseConfig.oauthRedirectURL.absoluteString)
        ]
        let finalRedirectURL = components.url!
        
        print("🔵 Calling supabase.auth.signInWithOAuth...")
        print("🔵 Provider: google")
        print("🔵 Redirect URL: \(finalRedirectURL)")
        
        // Supabase Swift SDK: signInWithOAuth returns a URL for the OAuth flow
        // Use getOAuthSignInURL if signInWithOAuth doesn't return URL
        let url = try supabase.auth.getOAuthSignInURL(
            provider: .google,
            redirectTo: finalRedirectURL
        )
        
        print("✅ Google OAuth URL generated: \(url)")
        return url
        
        #else
        print("❌ Supabase package NOT available, using mock")
        // Mock Google Sign In when Supabase is not available - return dummy URL
        let user = User(
            displayName: "Google User",
            email: "google@example.com",
            totalSteps: 0,
            totalChallenges: 0
        )
        currentUser = user
        isAuthenticated = true
        saveUser()
        return URL(string: "https://example.com")!
        #endif
    }
    
    func signOut() async throws {
        #if canImport(Supabase)
        if useSupabase {
            try await supabase.auth.signOut()
        }
        #endif
        
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    func updatePassword(newPassword: String) async throws {
        #if canImport(Supabase)
        guard useSupabase else {
            throw AuthError.notImplemented
        }
        
        print("🔵 Updating password")
        try await supabase.auth.update(user: UserAttributes(password: newPassword))
        print("✅ Password updated successfully")
        #else
        throw AuthError.notImplemented
        #endif
    }
    
    func updateUser(_ user: User) {
        var updatedUser = user
        
        // Apply selected avatar from onboarding if available
        if let avatarURL = UserDefaults.standard.string(forKey: "selectedAvatarURL") {
            updatedUser.avatarURL = avatarURL
            UserDefaults.standard.removeObject(forKey: "selectedAvatarURL")
        }
        
        currentUser = updatedUser
        
        #if canImport(Supabase)
        if useSupabase {
            Task {
                await updateUserProfile(user: updatedUser)
            }
        } else {
            saveUser()
        }
        #else
        saveUser()
        #endif
    }
    
    // MARK: - Supabase Methods
    
    #if canImport(Supabase)
    private func signInWithSupabase(email: String, password: String) async throws {
        print("🔵 Starting Supabase sign-in for: \(email)")
        
        do {
            let response = try await supabase.auth.signIn(email: email, password: password)
            print("✅ Supabase sign-in successful. User ID: \(response.user.id)")
            
            guard let userId = response.user.id.uuidString as String? else {
                print("❌ Failed to get user ID from response")
                throw AuthError.invalidResponse
            }
            
            await loadUserProfile(userId: userId)
        } catch {
            print("❌ Supabase sign-in error: \(error.localizedDescription)")
            print("❌ Error details: \(error)")
            
            // Check for email confirmation error
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("email not confirmed") ||
               errorString.contains("email_not_confirmed") ||
               errorString.contains("confirm your email") ||
               errorString.contains("email confirmation") {
                throw AuthError.emailNotConfirmed
            }
            
            // Check for invalid credentials
            if errorString.contains("invalid login") ||
               errorString.contains("invalid credentials") ||
               errorString.contains("invalid password") ||
               errorString.contains("email or password") {
                throw AuthError.invalidCredentials
            }
            
            throw error
        }
    }
    
    private func signUpWithSupabase(email: String, password: String, username: String, firstName: String, lastName: String, height: Int?, weight: Int?) async throws {
        print("🔵 Starting Supabase sign-up for: \(email)")
        
        do {
            // Sign up with Supabase Auth
            // Supabase will return an error if the email already exists
            // Note: We disable email confirmation for development - users can sign in immediately
            // To enable email confirmation, configure in Supabase Dashboard
            // Metadata (username, first_name, last_name) will be stored in the profile table
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            // Check if sign-up was successful
            // response.user is non-optional in Supabase Swift SDK
            let authUser = response.user
            print("✅ Supabase sign-up successful. User ID: \(authUser.id)")
            
            guard let userId = authUser.id.uuidString as String? else {
                print("❌ Failed to get user ID from response")
                throw AuthError.invalidResponse
            }
        
            // Note: Profile creation is now handled by database trigger
            // The trigger on auth.users will automatically create a profile
            // when a new user is inserted. However, we can still try to create
            // it manually if the trigger doesn't fire (e.g., for existing users)
            
            // Wait a moment for session to be established
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Try to create profile manually (trigger should handle this, but this is a fallback)
            print("🔵 Attempting to create profile in database for user: \(userId)")
            
            // Use UserProfile struct which has proper CodingKeys mapping
            let profile = UserProfile(
                id: userId,
                username: username,
                firstName: firstName,
                lastName: lastName,
                avatar: nil,
                isPremium: false,
                height: height,
                weight: weight,
                publicProfile: false // Default to private
            )
            
            do {
                // Try to insert the profile
                // The CodingKeys will map 'id' to 'user_id' in the database
                try await supabase
                    .from("profiles")
                    .insert(profile)
                    .execute()
                
                print("✅ Profile created successfully")
            } catch {
                // Profile might already exist from trigger, or RLS might block it
                // Check if profile exists
                do {
                    let existingProfile: UserProfile? = try await supabase
                        .from("profiles")
                        .select()
                        .eq("id", value: userId)
                        .single()
                        .execute()
                        .value
                    
                    if existingProfile != nil {
                        print("✅ Profile already exists (likely created by trigger)")
                        // Update the existing profile with username, name, height, and weight
                        let updatedProfile = UserProfile(
                            id: userId,
                            username: username,
                            firstName: firstName,
                            lastName: lastName,
                            avatar: existingProfile?.avatar,
                            isPremium: existingProfile?.isPremium ?? false,
                            height: height,
                            weight: weight,
                            publicProfile: existingProfile?.publicProfile ?? false
                        )
                        _ = try? await supabase
                            .from("profiles")
                            .update(updatedProfile)
                            .eq("id", value: userId)
                            .execute()
                    } else {
                        print("⚠️ Profile creation failed: \(error.localizedDescription)")
                        print("⚠️ Will retry profile creation...")
                        // Retry once after a short delay
                        try? await Task.sleep(nanoseconds: 1000_000_000) // 1 second
                        _ = try? await supabase
                            .from("profiles")
                            .insert(profile)
                            .execute()
                        print("✅ Profile created on retry")
                    }
                } catch {
                    print("⚠️ Profile check/creation error: \(error.localizedDescription)")
                    // Continue anyway - profile might be created by trigger later
                }
            }
            
            // Create User object with username, firstName and lastName
            let appUser = User(
                id: userId,
                username: username,
                firstName: firstName,
                lastName: lastName,
                email: email,
                publicProfile: false, // Default to private
                totalSteps: 0,
                totalChallenges: 0
            )
            currentUser = appUser
            isAuthenticated = true
            saveUser()
            
            await loadUserProfile(userId: userId)
        } catch {
            // Handle sign-up errors
            let errorString = error.localizedDescription.lowercased()
            print("❌ Sign-up error: \(error.localizedDescription)")
            
            // Check if error is about existing email/user
            if errorString.contains("user already registered") ||
               errorString.contains("email already registered") ||
               errorString.contains("already exists") ||
               errorString.contains("duplicate") {
                print("⚠️ Email already exists in Supabase")
                throw AuthError.emailAlreadyExists
            }
            
            // Re-throw other errors
            throw error
        }
    }
    
    private func loadUserProfile(userId: String) async {
        do {
            // Get email from auth session
            // Note: session might be nil if user just logged out, so handle gracefully
            let session = try await supabase.auth.session
            guard let email = session.user.email, !email.isEmpty else {
                // No email in session - user might have logged out
                isAuthenticated = false
                currentUser = nil
                return
            }
            
            // Fetch profile from database
            let profile: UserProfile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            // Convert to app User model
            // Use firstName and lastName from profile, fallback to empty strings
            let firstName = profile.firstName ?? ""
            let lastName = profile.lastName ?? ""
            
            // Use avatar_url if available, fallback to avatar
            let avatarURL = profile.avatarUrl ?? profile.avatar
            
            let user = User(
                id: profile.id,
                username: profile.username,
                firstName: firstName,
                lastName: lastName,
                avatarURL: avatarURL,
                email: email, // Email from auth session
                publicProfile: profile.publicProfile, // Load from profiles.public_profile
                totalSteps: profile.totalSteps ?? 0, // Load from profiles.total_steps
                totalChallenges: 0 // Would come from challenge_members count
            )
            
            currentUser = user
            isAuthenticated = true
            saveUser()
            
            // Store height and weight in UserDefaults for ProfileViewModel to access
            if let height = profile.height {
                UserDefaults.standard.set(height, forKey: "userHeight")
            }
            if let weight = profile.weight {
                UserDefaults.standard.set(weight, forKey: "userWeight")
            }
            // Store daily step goal in UserDefaults
            if let dailyStepGoal = profile.dailyStepGoal {
                UserDefaults.standard.set(dailyStepGoal, forKey: "dailyStepGoal")
            } else {
                // Set default if not set
                UserDefaults.standard.set(10000, forKey: "dailyStepGoal")
            }
        } catch {
            print("⚠️ Error loading user profile: \(error.localizedDescription)")
            
            // Try to get email from auth session even if profile doesn't exist
            let email: String?
            do {
                let session = try await supabase.auth.session
                email = session.user.email
            } catch {
                email = nil
            }
            
            // Create default profile if doesn't exist
            let user = User(
                id: userId,
                username: "user_\(userId.prefix(8))",
                firstName: "User",
                lastName: "",
                email: email,
                publicProfile: false, // Default to private
                totalSteps: 0,
                totalChallenges: 0
            )
            currentUser = user
            isAuthenticated = true
            saveUser()
        }
    }
    
    private func updateUserProfile(user: User) async {
        guard let userId = user.id as String? else { return }
        
        do {
            // Get current height and weight from UserDefaults (set by ProfileViewModel)
            let height = UserDefaults.standard.integer(forKey: "userHeight")
            let weight = UserDefaults.standard.integer(forKey: "userWeight")
            
            // First, get existing profile to preserve publicProfile setting
            let existingProfiles: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            let existingProfile = existingProfiles.first
            
            // Use avatar_url if available, otherwise use avatar
            let avatarURL = user.avatarURL
            
            // Get daily step goal from UserDefaults or use existing profile value
            let dailyStepGoal = UserDefaults.standard.integer(forKey: "dailyStepGoal")
            let goal = dailyStepGoal > 0 ? dailyStepGoal : (existingProfile?.dailyStepGoal ?? 10000)
            
            let profile = UserProfile(
                id: userId,
                username: user.username,
                firstName: user.firstName,
                lastName: user.lastName,
                avatar: avatarURL, // Keep for backward compatibility
                avatarUrl: avatarURL, // Use new field
                isPremium: existingProfile?.isPremium ?? false,
                height: height > 0 ? height : nil,
                weight: weight > 0 ? weight : nil,
                publicProfile: existingProfile?.publicProfile ?? false,
                dailyStepGoal: goal
            )
            
            try await supabase
                .from("profiles")
                .update(profile)
                .eq("id", value: userId)
                .execute()
            
            print("✅ Profile updated successfully with height: \(height), weight: \(weight)")
        } catch {
            print("⚠️ Error updating user profile: \(error.localizedDescription)")
        }
    }
    
    func updateUserHeightWeight(height: Int?, weight: Int?) async {
        #if canImport(Supabase)
        guard useSupabase else { return }
        
        guard let userId = currentUser?.id as String? else {
            print("⚠️ No current user to update height/weight")
            return
        }
        
        do {
            // Update UserDefaults first
            if let height = height, height > 0 {
                UserDefaults.standard.set(height, forKey: "userHeight")
            }
            if let weight = weight, weight > 0 {
                UserDefaults.standard.set(weight, forKey: "userWeight")
            }
            
            // Update profile in database
            // First, get existing profile to preserve publicProfile setting
            let existingProfiles: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            let existingProfile = existingProfiles.first
            
            // Get daily step goal from UserDefaults or use existing profile value
            let dailyStepGoal = UserDefaults.standard.integer(forKey: "dailyStepGoal")
            let goal = dailyStepGoal > 0 ? dailyStepGoal : (existingProfile?.dailyStepGoal ?? 10000)
            
            let profile = UserProfile(
                id: userId,
                username: currentUser?.username ?? "",
                firstName: currentUser?.firstName,
                lastName: currentUser?.lastName,
                avatar: currentUser?.avatarURL,
                isPremium: existingProfile?.isPremium ?? false,
                height: height,
                weight: weight,
                publicProfile: existingProfile?.publicProfile ?? false,
                dailyStepGoal: goal
            )
            
            try await supabase
                .from("profiles")
                .update(profile)
                .eq("id", value: userId)
                .execute()
            
            print("✅ Height and weight updated successfully: height=\(height?.description ?? "nil"), weight=\(weight?.description ?? "nil")")
        } catch {
            print("⚠️ Error updating height/weight: \(error.localizedDescription)")
        }
        #endif
    }
    
    func updateDailyStepGoal(_ goal: Int) async {
        #if canImport(Supabase)
        guard useSupabase else { return }
        
        guard let userId = currentUser?.id as String? else {
            print("⚠️ No current user to update daily step goal")
            return
        }
        
        do {
            // Update UserDefaults first
            UserDefaults.standard.set(goal, forKey: "dailyStepGoal")
            
            // Update profile in database
            // First, get existing profile to preserve other settings
            let existingProfiles: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .execute()
                .value
            let existingProfile = existingProfiles.first
            
            let profile = UserProfile(
                id: userId,
                username: currentUser?.username ?? "",
                firstName: currentUser?.firstName,
                lastName: currentUser?.lastName,
                avatar: currentUser?.avatarURL,
                isPremium: existingProfile?.isPremium ?? false,
                height: existingProfile?.height,
                weight: existingProfile?.weight,
                publicProfile: existingProfile?.publicProfile ?? false,
                dailyStepGoal: goal
            )
            
            try await supabase
                .from("profiles")
                .update(profile)
                .eq("id", value: userId)
                .execute()
            
            print("✅ Daily step goal updated successfully: \(goal)")
        } catch {
            print("⚠️ Error updating daily step goal: \(error.localizedDescription)")
        }
        #endif
    }
    #endif
    
    // MARK: - Mock Methods (Fallback)
    
    private func signInMock(email: String, password: String) async throws {
        // Small delay to simulate network call
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Check if this is the test account
        let isTestAccount = email.lowercased() == testAccountEmail.lowercased()
        
        let user: User
        if isTestAccount {
            // Create test account with some sample data
            user = User(
                displayName: testAccountDisplayName,
                email: testAccountEmail,
                totalSteps: 12500,
                totalChallenges: 3
            )
        } else {
            // Create a regular mock user
            user = User(
                displayName: email.components(separatedBy: "@").first?.capitalized ?? "User",
                email: email,
                totalSteps: 0,
                totalChallenges: 0
            )
        }
        
        currentUser = user
        isAuthenticated = true
        saveUser()
    }
    
    private func signUpMock(email: String, password: String, username: String, firstName: String, lastName: String, height: Int?, weight: Int?) async throws {
        // Small delay to simulate network call
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        let user = User(
            username: username,
            firstName: firstName,
            lastName: lastName,
            email: email,
            totalSteps: 0,
            totalChallenges: 0
        )
        
        currentUser = user
        isAuthenticated = true
        saveUser()
    }
    
    // MARK: - Persistence
    
    private func saveUser() {
        if let user = currentUser,
           let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadUser() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return
        }
        
        currentUser = user
        isAuthenticated = true
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case emailAlreadyExists
    case usernameAlreadyExists
    case emailNotConfirmed
    case invalidCredentials
    case notImplemented
    case invalidResponse
    case networkError(Error)
    case oauthURLGenerated(URL)
    
    var errorDescription: String? {
        switch self {
        case .emailAlreadyExists:
            return "This email is already associated with an account"
        case .usernameAlreadyExists:
            return "This username is already taken. Please choose another."
        case .emailNotConfirmed:
            return "Please check your email and confirm your account before signing in. If you didn't receive an email, check your spam folder."
        case .invalidCredentials:
            return "Invalid email or password. Please check your credentials and try again."
        case .notImplemented:
            return "This feature is not yet implemented"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .oauthURLGenerated:
            return "OAuth URL generated - should be handled by view"
        }
    }
}

