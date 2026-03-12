//
//  RootView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif

// MARK: - Session Loading View
/// Displayed briefly while checking for an existing session on app launch.
/// This prevents the login screen from flashing when the user is already authenticated.
private struct SessionLoadingView: View {
    var body: some View {
        ZStack {
            // Match the app's background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App icon or logo placeholder
                Image(systemName: "figure.walk.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)
                
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.blue)
            }
        }
    }
}

struct RootView: View {
    @ObservedObject private var authService = AuthService.shared
    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var challengeService = ChallengeService()
    @StateObject private var friendsService = FriendsService()
    @StateObject private var themeManager = ThemeManager()
    @ObservedObject private var router = DeepLinkRouter.shared
    @ObservedObject private var workoutViewModel = WorkoutViewModel.shared
    
    @StateObject private var sessionViewModel: SessionViewModel
    @State private var showingPasswordReset = false
    @State private var passwordResetURL: URL?
    
    init() {
        // Use the shared AuthService instance
        _sessionViewModel = StateObject(
            wrappedValue: SessionViewModel(
                authService: AuthService.shared,
                healthKitService: HealthKitService()
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
            } else if sessionViewModel.isCheckingSession {
                // Show loading state while checking for existing session
                // This prevents flashing the login screen on app restart
                SessionLoadingView()
            } else if !sessionViewModel.isAuthenticated {
                OnboardingFlowView(sessionViewModel: sessionViewModel)
            } else if !sessionViewModel.hasCompletedOnboarding {
                OnboardingFlowView(sessionViewModel: sessionViewModel)
            } else {
                MainTabView(sessionViewModel: sessionViewModel)
                    .id(sessionViewModel.isAuthenticated) // Force view recreation on auth state change
            }
        }
        .environmentObject(authService)
        .environmentObject(healthKitService)
        .environmentObject(challengeService)
        .environmentObject(friendsService)
        .environmentObject(themeManager)
        .preferredColorScheme(themeManager.colorScheme)
        .onAppear {
            // Initialize notification service to request permissions
            _ = StepGoalNotificationService.shared
            
            // Clear delivered notifications and badge when app opens
            clearDeliveredNotificationsAndBadge()
            
            // Reconcile active workout state on app launch
            workoutViewModel.reconcileActiveWorkoutState()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Clear delivered notifications and badge when app becomes active
            clearDeliveredNotificationsAndBadge()
            
            // Reconcile active workout state when app enters foreground
            workoutViewModel.reconcileActiveWorkoutState()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            // Save active workout draft when app enters background
            workoutViewModel.reconcileActiveWorkoutState()
        }
        .onReceive(router.$pendingPasswordResetURL) { url in
            if let url = url {
                passwordResetURL = url
                showingPasswordReset = true
                // Clear the pending URL after handling
                router.pendingPasswordResetURL = nil
            }
        }
        .sheet(item: Binding(
            get: { router.pendingInviteToken.map { InviteTokenItem(token: $0) } },
            set: { _ in router.pendingInviteToken = nil }
        )) { item in
            NavigationStack {
                InviteAcceptView(token: item.token, service: friendsService)
            }
        }
    }
    
    // Clear all delivered notifications and badge when app opens or becomes active
    private func clearDeliveredNotificationsAndBadge() {
        Task {
            let center = UNUserNotificationCenter.current()
            
            // Get all delivered notifications
            let delivered = await center.deliveredNotifications()
            print("📱 Found \(delivered.count) delivered notifications")
            
            // Log them for debugging
            for notification in delivered {
                print("  - \(notification.request.identifier): \(notification.request.content.title)")
            }
            
            // Remove all delivered notifications from notification center
            center.removeAllDeliveredNotifications()
            print("🧹 Cleared all delivered notifications")
            
            // Clear the badge
            if #available(iOS 16.0, *) {
                try? await center.setBadgeCount(0)
            } else {
                await MainActor.run {
                    UIApplication.shared.applicationIconBadgeNumber = 0
                }
            }
            print("✅ Badge cleared")
        }
    }
}

