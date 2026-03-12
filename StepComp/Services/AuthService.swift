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
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    /// True while we're checking for an existing session on app launch.
    /// This prevents showing the login screen before we've had a chance to restore the session.
    @Published var isCheckingSession: Bool = true
    
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
    
    private init() {
        if useSupabase {
            // Start session check - isCheckingSession is true until this completes
            checkSupabaseSession()
        } else {
            loadUser()
            // No async check needed for mock mode
            isCheckingSession = false
        }
    }
    
    // MARK: - Supabase Authentication
    
    // ============================================================================
    // CORRECT AUTH ARCHITECTURE (Instagram/Facebook/Snapchat pattern)
    // ============================================================================
    // 
    // 1. Supabase SDK handles session persistence internally (NOT UserDefaults)
    // 2. On app launch: restore session → if valid → Home, else → Login
    // 3. Logout is the ONLY way to show login screen
    // 4. 401 errors trigger refresh, NOT logout
    //
    // ============================================================================
    
    func checkSupabaseSession() {
        #if canImport(Supabase)
        Task {
            await restoreSession()
        }
        #else
        // Supabase not available - use mock mode
        loadUser()
        isCheckingSession = false
        #endif
    }
    
    /// Restores the auth session from Supabase's internal storage.
    /// This is the ONLY place session restoration should happen.
    @MainActor
    private func restoreSession() async {
        #if canImport(Supabase)
        defer {
            isCheckingSession = false
            print("✅ Session restore complete - isCheckingSession = false")
        }
        
        do {
            // Supabase SDK automatically restores session from its internal storage
            // This includes the access token AND refresh token
            let session = try await supabase.auth.session
            
            print("🔐 Session found for user: \(session.user.id)")
            
            // Session exists - load user profile
            await loadUserProfile(userId: session.user.id.uuidString)
            
            // If we have a valid session and profile, user has definitely completed onboarding
            // This ensures the flag is restored when session is restored
            if isAuthenticated && currentUser != nil {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            }
            
        } catch {
            // No session found - this is expected for:
            // 1. First-time users
            // 2. Users who explicitly logged out
            // 
            // Do NOT treat this as an error - just show login
            print("ℹ️ No session found - showing login screen")
            isAuthenticated = false
            currentUser = nil
        }
        #endif
    }
    
    /// Refreshes the session when a 401 is received.
    /// Call this from API handlers when they get 401 errors.
    /// Returns true if refresh succeeded, false if user needs to login again.
    @MainActor
    func refreshSessionOn401() async -> Bool {
        #if canImport(Supabase)
        do {
            print("🔄 Attempting to refresh session after 401...")
            let refreshedSession = try await supabase.auth.refreshSession()
            print("✅ Session refreshed successfully")
            
            // Reload profile with new session
            await loadUserProfile(userId: refreshedSession.user.id.uuidString)
            return true
        } catch {
            // Refresh failed - session is truly invalid
            // This is the ONLY case where we force logout (besides manual logout)
            print("❌ Session refresh failed - user must login again: \(error.localizedDescription)")
            await forceLogout()
            return false
        }
        #else
        return false
        #endif
    }
    
    /// Force logout - only called when session refresh fails or user explicitly logs out
    @MainActor
    private func forceLogout() async {
        #if canImport(Supabase)
        try? await supabase.auth.signOut()
        #endif
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        
        // Clear active workout state (draft, widget, live activity)
        WorkoutViewModel.clearAllActiveWorkoutState()
        
        print("🚪 User logged out")
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
            
            // Generate display name
            let displayName = [firstName, lastName].compactMap { $0 }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            let finalDisplayName = displayName.isEmpty ? username : displayName
            
            // Get daily step goal from UserDefaults (set during onboarding) or use default
            let savedDailyGoal = UserDefaults.standard.integer(forKey: "dailyStepGoal")
            let dailyGoal = savedDailyGoal > 0 ? savedDailyGoal : 10000
            
            let profile = UserProfile(
                id: userId,
                username: username,
                firstName: firstName,
                lastName: lastName,
                avatar: nil,
                avatarUrl: nil,
                displayName: finalDisplayName,
                isPremium: false,
                height: nil,
                weight: nil,
                email: email,
                publicProfile: true, // Default to public for easier friend discovery
                totalSteps: 0,
                dailyStepGoal: dailyGoal // Use goal from onboarding or default
            )
            
            if profileExists {
                // Profile already exists - DON'T overwrite user data (username, name, etc.)
                // Just load the existing profile
                print("✅ Profile already exists - keeping user's existing data")
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
        
        print("🔵 Calling supabase.auth.getOAuthSignInURL...")
        print("🔵 Provider: google")
        print("🔵 Redirect URL: \(finalRedirectURL)")
        
        
        // Supabase Swift SDK: getOAuthSignInURL generates the OAuth URL
        // The PKCE flow is handled automatically by the SDK
        let url = try supabase.auth.getOAuthSignInURL(
            provider: .google,
            scopes: "email profile", // Request email and profile scopes
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
        // ============================================================================
        // LOGOUT - The ONLY place that should clear auth state
        // ============================================================================
        print("🔵 User initiated logout...")
        
        #if canImport(Supabase)
        if useSupabase {
            do {
                // This clears the session from Supabase's internal storage
                try await supabase.auth.signOut()
                print("✅ Supabase sign out successful")
            } catch {
                print("⚠️ Error during Supabase sign out: \(error.localizedDescription)")
                // Continue with local cleanup even if Supabase sign out fails
            }
        }
        #endif
        
        // Clear local state
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        
        // Clear active workout state (draft, widget, live activity)
        WorkoutViewModel.clearAllActiveWorkoutState()
        
        print("🚪 User logged out - will show login screen")
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
            
            // Generate display name from first and last name
            let displayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            
            // Get daily step goal from UserDefaults (set during onboarding) or use default
            let savedDailyGoal = UserDefaults.standard.integer(forKey: "dailyStepGoal")
            let dailyGoal = savedDailyGoal > 0 ? savedDailyGoal : 10000
            
            // Use UserProfile struct which has proper CodingKeys mapping
            let profile = UserProfile(
                id: userId,
                username: username,
                firstName: firstName,
                lastName: lastName,
                avatar: nil,
                avatarUrl: nil,
                displayName: displayName, // ✅ NEW: Set display name
                isPremium: false,
                height: height,
                weight: weight,
                email: email,
                publicProfile: true, // Default to public for easier friend discovery
                totalSteps: 0,
                dailyStepGoal: dailyGoal // Use goal from onboarding or default
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
                        // Update the existing profile with username, name, height, weight, and daily step goal
                        let updatedProfile = UserProfile(
                            id: userId,
                            username: username,
                            firstName: firstName,
                            lastName: lastName,
                            avatar: existingProfile?.avatar,
                            isPremium: existingProfile?.isPremium ?? false,
                            height: height,
                            weight: weight,
                            publicProfile: existingProfile?.publicProfile ?? false,
                            dailyStepGoal: dailyGoal // Include daily step goal from onboarding
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
                publicProfile: true, // Default to public for easier friend discovery
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
            // PERMANENT LOGIN: Load profile directly from database using userId
            // Don't require a valid session - the profile has all the info we need
            // This allows users to stay logged in even if session is being refreshed
            
            // Try to get email from session (optional - won't fail if not available)
            var sessionEmail: String? = nil
            do {
                let session = try await supabase.auth.session
                sessionEmail = session.user.email
            } catch {
                // Session not available yet - that's OK, we'll use email from profile
                print("ℹ️ Session not available, will use email from profile")
            }
            
            // Fetch profile from database - this is the source of truth
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
            
            // Use email from session if available, otherwise from profile
            let email = sessionEmail ?? profile.email ?? ""
            
            let user = User(
                id: profile.id,
                username: profile.username,
                firstName: firstName,
                lastName: lastName,
                avatarURL: avatarURL,
                email: email,
                publicProfile: profile.publicProfile,
                totalSteps: profile.totalSteps ?? 0,
                totalChallenges: 0
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
            
            print("✅ User profile loaded successfully - user is authenticated")
        } catch {
            print("⚠️ Error loading user profile: \(error.localizedDescription)")
            
            // If we can't load from database, try to use locally cached user
            // This handles offline scenarios
            if let cachedUser = loadCachedUser() {
                print("ℹ️ Using cached user data for offline access")
                currentUser = cachedUser
                isAuthenticated = true
            } else {
                // No cached user - create a minimal profile to keep them logged in
                // They'll get full data when network is available
                let email: String? = nil
                
                let user = User(
                    id: userId,
                    username: "user_\(userId.prefix(8))",
                    firstName: "User",
                    lastName: "",
                    email: email,
                    publicProfile: true,
                    totalSteps: 0,
                    totalChallenges: 0
                )
                currentUser = user
                isAuthenticated = true
                saveUser()
                print("⚠️ Created minimal user profile - will sync when online")
            }
        }
    }
    
    /// Load cached user from UserDefaults (for offline access)
    private func loadCachedUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return nil
        }
        return try? JSONDecoder().decode(User.self, from: data)
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
            print("✅ Daily step goal saved to UserDefaults: \(goal)")
            
            // Update only the daily_step_goal field in database (partial update)
            try await supabase
                .from("profiles")
                .update(["daily_step_goal": goal])
                .eq("id", value: userId)
                .execute()
            
            print("✅ Daily step goal updated in database: \(goal)")
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

