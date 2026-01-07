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

struct RootView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var challengeService = ChallengeService()
    @StateObject private var friendsService = FriendsService()
    @StateObject private var themeManager = ThemeManager()
    @ObservedObject private var router = DeepLinkRouter.shared
    
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
            // Initialize notification service to request permissions
            _ = StepGoalNotificationService.shared
            
            // Update SessionViewModel with the actual service instances
            sessionViewModel.updateServices(authService: authService, healthKitService: healthKitService)
            
            // Clear delivered notifications and badge when app opens
            clearDeliveredNotificationsAndBadge()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Clear delivered notifications and badge when app becomes active
            clearDeliveredNotificationsAndBadge()
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

