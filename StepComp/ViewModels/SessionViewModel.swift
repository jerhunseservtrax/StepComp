//
//  SessionViewModel.swift
//  StepComp
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
                // If logged out, reset onboarding status
                if !isAuthenticated {
                    self.hasCompletedOnboarding = false
                    UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
                }
            }
            .store(in: &cancellables)
    }
    
    func signIn(email: String, password: String) async throws {
        try await authService.signIn(email: email, password: password)
    }
    
    func signUp(email: String, password: String, username: String, firstName: String, lastName: String, height: Int?, weight: Int?) async throws {
        try await authService.signUp(email: email, password: password, username: username, firstName: firstName, lastName: lastName, height: height, weight: weight)
    }
    
    func signOut() async {
        do {
            try await authService.signOut()
            // Force update local state
            currentUser = nil
            isAuthenticated = false
            hasCompletedOnboarding = false
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        } catch {
            print("⚠️ Error signing out: \(error.localizedDescription)")
            // Still clear local state even if there's an error
            currentUser = nil
            isAuthenticated = false
            hasCompletedOnboarding = false
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        }
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

