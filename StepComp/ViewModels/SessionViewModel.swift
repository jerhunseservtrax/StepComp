//
//  SessionViewModel.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import Combine // Required for @Published and ObservableObject

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    /// True while AuthService is checking for an existing session on app launch.
    /// This prevents flashing the login screen before session restoration completes.
    @Published var isCheckingSession: Bool = true
    
    private var authService: AuthService
    private var healthKitService: HealthKitService
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthService, healthKitService: HealthKitService) {
        self.authService = authService
        self.healthKitService = healthKitService
        
        observeAuthService()
        checkOnboardingStatus()
    }
    
    func updateServices(authService: AuthService, healthKitService: HealthKitService) {
        // Cancel previous subscriptions
        cancellables.removeAll()
        
        self.authService = authService
        self.healthKitService = healthKitService
        observeAuthService()
    }
    
    private func observeAuthService() {
        // Observe currentUser changes
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentUser)
        
        // Observe isAuthenticated changes
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                guard let self = self else { return }
                self.isAuthenticated = isAuthenticated
                
                if isAuthenticated {
                    // Re-check onboarding status when user becomes authenticated
                    // This picks up the flag set by AuthService during session restore
                    self.checkOnboardingStatus()
                } else {
                    // Keep onboarding status intact for transient auth drops.
                    // Explicit logout flow is the only place that clears it.
                    self.hasCompletedOnboarding = false
                }
            }
            .store(in: &cancellables)
        
        // Observe isCheckingSession changes
        // This prevents showing login screen before session check completes
        authService.$isCheckingSession
            .receive(on: DispatchQueue.main)
            .assign(to: &$isCheckingSession)
    }
    
    func signIn(email: String, password: String) async throws {
        try await authService.signIn(email: email, password: password)
    }
    
    func signUp(email: String, password: String, username: String, firstName: String, lastName: String, height: Int?, weight: Int?) async throws {
        try await authService.signUp(email: email, password: password, username: username, firstName: firstName, lastName: lastName, height: height, weight: weight)
    }
    
    func signOut() async {
        // ============================================================================
        // LOGOUT - The ONLY action that should trigger login screen
        // ============================================================================
        do {
            try await authService.signOut()
        } catch {
            print("⚠️ Error signing out: \(error.localizedDescription)")
        }
        
        // Clear local state - already on main actor since class is @MainActor
        currentUser = nil
        isAuthenticated = false
        hasCompletedOnboarding = false
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }
    
    func updateUser(_ user: User) {
        authService.updateUser(user)
    }
    
    func signInWithApple(identityToken: String, authorizationCode: String?, email: String?, firstName: String?, lastName: String?) async throws {
        try await authService.signInWithApple(identityToken: identityToken, authorizationCode: authorizationCode, email: email, firstName: firstName, lastName: lastName)
    }
    
    func signInWithGoogle() async throws -> URL {
        try await authService.signInWithGoogle()
    }
    
    // Legacy method for mock mode (should not be used when Supabase is enabled)
    func signInWithGoogle(email: String, displayName: String) async throws {
        // This method is deprecated - use signInWithGoogle() instead for OAuth
        // Keeping for backward compatibility only
        // Always use OAuth when available
        _ = try await signInWithGoogle()
    }
    
    func checkSession() async {
        authService.checkSupabaseSession()
    }
    
    func requestHealthKitAuthorization() async throws {
        try await healthKitService.requestAuthorization()
    }
    
    var healthKitAuthorized: Bool {
        healthKitService.isAuthorized
    }
    
    // Expose authService for height/weight updates
    var authServiceAccess: AuthService {
        authService
    }
    
    private func checkOnboardingStatus() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

