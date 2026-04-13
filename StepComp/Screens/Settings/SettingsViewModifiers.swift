//
//  SettingsViewModifiers.swift
//  FitComp
//
//  View modifiers for settings lifecycle, alerts, and preference sync extracted from SettingsView.swift.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SettingsLifecycleModifiers: ViewModifier {
    let healthKitService: HealthKitService
    let onLoadHealthKit: () -> Void
    let onAppear: () -> Void
    let onDisappear: () -> Void
    
    func body(content: Content) -> some View {
        content
            .task {
                onLoadHealthKit()
            }
            .onChange(of: healthKitService.isAuthorized) { _, _ in
                onLoadHealthKit()
            }
            .onAppear {
                onAppear()
            }
            .onDisappear {
                onDisappear()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                onLoadHealthKit()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshHealthKitData"))) { _ in
                onLoadHealthKit()
            }
    }
}

struct SettingsAlertsModifiers: ViewModifier {
    @Binding var showingSignOutAlert: Bool
    @Binding var showingDeleteAccountAlert: Bool
    @Binding var showingDeleteAccountConfirmation: Bool
    @Binding var deleteAccountConfirmationText: String
    let isDeletingAccount: Bool
    let onSignOut: () -> Void
    let onDeleteAccount: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    onSignOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Continue", role: .destructive) {
                    showingDeleteAccountConfirmation = true
                }
            } message: {
                Text("This action cannot be undone. Your account, friendships, challenge memberships, and all data will be permanently deleted.")
            }
            .sheet(isPresented: $showingDeleteAccountConfirmation) {
                DeleteAccountConfirmationView(
                    confirmationText: $deleteAccountConfirmationText,
                    onConfirm: onDeleteAccount,
                    isDeletingAccount: isDeletingAccount
                )
                .interactiveDismissDisabled(isDeletingAccount)
            }
    }
}

struct SettingsPreferencesModifiers: ViewModifier {
    let darkMode: Bool
    let dailyRecap: Bool
    let leaderboardAlerts: Bool
    let motivationalNudges: Bool
    let themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .modifier(ThemePreferenceModifier(darkMode: darkMode, themeManager: themeManager))
            .modifier(NotificationPreferencesModifier(
                dailyRecap: dailyRecap,
                leaderboardAlerts: leaderboardAlerts,
                motivationalNudges: motivationalNudges
            ))
            // Unit system preference is now managed by UnitPreferenceManager singleton
    }
}

// MARK: - Sub-Modifiers

struct ThemePreferenceModifier: ViewModifier {
    let darkMode: Bool
    let themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .onChange(of: darkMode) { _, newValue in
                themeManager.setColorScheme(newValue ? .dark : .light)
            }
    }
}

struct NotificationPreferencesModifier: ViewModifier {
    let dailyRecap: Bool
    let leaderboardAlerts: Bool
    let motivationalNudges: Bool
    
    func body(content: Content) -> some View {
        content
            .onChange(of: dailyRecap) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "notif_dailyRecap")
                NotificationManager.shared.updateNotificationPreferences(dailyRecap: newValue)
            }
            .onChange(of: leaderboardAlerts) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "notif_leaderboardAlerts")
                NotificationManager.shared.updateNotificationPreferences(leaderboardAlerts: newValue)
            }
            .onChange(of: motivationalNudges) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "notif_motivationalNudges")
                NotificationManager.shared.updateNotificationPreferences(motivationalNudges: newValue)
            }
    }
}

// UnitSystemPreferenceModifier removed - Unit system is now managed by UnitPreferenceManager singleton
