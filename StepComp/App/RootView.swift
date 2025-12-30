//
//  RootView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

struct RootView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var challengeService = ChallengeService()
    @StateObject private var friendsService = FriendsService()
    @StateObject private var themeManager = ThemeManager()
    
    @StateObject private var sessionViewModel: SessionViewModel
    @State private var showingPasswordReset = false
    @State private var passwordResetURL: URL?
    
    init() {
        // Create temporary instances for SessionViewModel initialization
        let tempAuthService = AuthService()
        let tempHealthKitService = HealthKitService()
        _sessionViewModel = StateObject(
            wrappedValue: SessionViewModel(
                authService: tempAuthService,
                healthKitService: tempHealthKitService
            )
        )
    }
    
    var body: some View {
        Group {
            if showingPasswordReset, let resetURL = passwordResetURL {
                PasswordResetView(resetURL: resetURL) {
                    showingPasswordReset = false
                    passwordResetURL = nil
                }
            } else if !sessionViewModel.isAuthenticated {
                OnboardingFlowView(sessionViewModel: sessionViewModel)
            } else if !sessionViewModel.hasCompletedOnboarding {
                OnboardingFlowView(sessionViewModel: sessionViewModel)
            } else {
                MainTabView(sessionViewModel: sessionViewModel)
            }
        }
        .environmentObject(authService)
        .environmentObject(healthKitService)
        .environmentObject(challengeService)
        .environmentObject(friendsService)
        .environmentObject(themeManager)
        .preferredColorScheme(themeManager.colorScheme)
        .onAppear {
            // Update SessionViewModel with the actual service instances
            sessionViewModel.updateServices(authService: authService, healthKitService: healthKitService)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PasswordResetCallback"))) { notification in
            if let url = notification.userInfo?["url"] as? URL {
                passwordResetURL = url
                showingPasswordReset = true
            }
        }
    }
}

