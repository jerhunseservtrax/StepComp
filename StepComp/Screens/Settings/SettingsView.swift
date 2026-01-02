//
//  SettingsView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine
import Supabase
#if canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var healthKitService: HealthKitService
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingDeleteAccountConfirmation = false
    @State private var deleteAccountConfirmationText = ""
    @State private var isDeletingAccount = false
    @State private var healthKitEnabled = true
    @State private var appleWatchSetup = false
    @State private var dailyRecap = true
    @State private var leaderboardAlerts = false
    @State private var motivationalNudges = true
    @State private var darkMode = false
    @State private var unitSystem: UnitSystem = .metric
    
    // HealthKit data
    @State private var todaySteps: Int = 0
    @State private var currentStreak: Int = 0
    @State private var totalSteps: Int = 0
    @State private var totalDistanceMiles: Double = 0.0
    @State private var averageStepsThisMonth: Int = 0
    @State private var refreshTimer: Timer?
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    enum UnitSystem {
        case metric
        case imperial
    }
    
    var body: some View {
        contentView
            .modifier(SettingsLifecycleModifiers(
                healthKitService: healthKitService,
                onLoadHealthKit: {
                    Task {
                        await loadHealthKitData()
                    }
                },
                onAppear: setupInitialState,
                onDisappear: stopAutoRefresh
            ))
            .modifier(SettingsAlertsModifiers(
                showingSignOutAlert: $showingSignOutAlert,
                showingDeleteAccountAlert: $showingDeleteAccountAlert,
                showingDeleteAccountConfirmation: $showingDeleteAccountConfirmation,
                deleteAccountConfirmationText: $deleteAccountConfirmationText,
                isDeletingAccount: isDeletingAccount,
                onSignOut: {
                    Task {
                        await sessionViewModel.signOut()
                        dismiss()
                    }
                },
                onDeleteAccount: {
                    Task {
                        await deleteAccount()
                        showingDeleteAccountConfirmation = false
                    }
                }
            ))
            .modifier(SettingsPreferencesModifiers(
                darkMode: darkMode,
                dailyRecap: dailyRecap,
                leaderboardAlerts: leaderboardAlerts,
                motivationalNudges: motivationalNudges,
                unitSystem: unitSystem,
                themeManager: themeManager
            ))
            .navigationBarHidden(true)
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        GeometryReader { geometry in
            if geometry.size.width > 768 {
                iPadLayout
            } else {
                mobileLayout
            }
        }
    }
    
    // MARK: - Layout Components
    
    private var iPadLayout: some View {
        HStack(spacing: 0) {
            // Sidebar
            SettingsSidebar(
                user: sessionViewModel.currentUser,
                totalSteps: totalSteps,
                currentStreak: currentStreak,
                totalDistanceMiles: totalDistanceMiles,
                averageStepsThisMonth: averageStepsThisMonth
            )
            .frame(width: 320)
            
            // Main Content
            mainContent
        }
    }
    
    private var mobileLayout: some View {
        VStack(spacing: 0) {
            // Mobile Header
            SettingsMobileHeader(onBack: { dismiss() })
            
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Section (Mobile)
                    SettingsProfileSection(
                        user: sessionViewModel.currentUser,
                        totalSteps: totalSteps,
                        currentStreak: currentStreak,
                        totalDistanceMiles: totalDistanceMiles,
                        averageStepsThisMonth: averageStepsThisMonth
                    )
                    .padding()
                    
                    // Settings Cards
                    mainContent
                }
            }
        }
    }
    
    private var mainContent: some View {
        SettingsMainContent(
            healthKitEnabled: $healthKitEnabled,
            appleWatchSetup: $appleWatchSetup,
            dailyRecap: $dailyRecap,
            leaderboardAlerts: $leaderboardAlerts,
            motivationalNudges: $motivationalNudges,
            darkMode: $darkMode,
            unitSystem: $unitSystem,
            sessionViewModel: sessionViewModel,
            onSignOut: {
                showingSignOutAlert = true
            },
            onDeleteAccount: {
                showingDeleteAccountAlert = true
            },
            isDeletingAccount: isDeletingAccount
        )
    }
    
    // MARK: - HealthKit Data Loading
    
    private func loadHealthKitData() async {
        // Ensure HealthKit is initialized and check authorization
        _ = healthKitService.isHealthKitAvailable
        healthKitService.checkAuthorizationStatus()
        
        guard healthKitService.isAuthorized else {
            // Use fallback values if HealthKit not authorized
            print("⚠️ HealthKit not authorized in Settings, using fallback values")
            totalSteps = sessionViewModel.currentUser?.totalSteps ?? 0
            todaySteps = 0
            currentStreak = 0
            return
        }
        
        do {
            print("🔄 Loading HealthKit data in Settings...")
            // Get today's steps
            todaySteps = try await healthKitService.getTodaySteps()
            print("✅ Today's steps: \(todaySteps)")
            
            // Get weekly stats for streak calculation
            let calendar = Calendar.current
            let now = Date()
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            let weeklyStats = try await healthKitService.getSteps(from: weekAgo, to: now)
            
            // Calculate streak from HealthKit data
            currentStreak = calculateStreak(from: weeklyStats)
            print("✅ Streak: \(currentStreak) days")
            
            // Total steps: use user's total steps from database (since joining the app)
            // This is stored in the profiles table and synced from HealthKit
            totalSteps = sessionViewModel.currentUser?.totalSteps ?? 0
            print("✅ Total steps since joining: \(totalSteps)")
            
            // Calculate total distance in miles (estimated: 2000 steps ≈ 1 mile)
            totalDistanceMiles = Double(totalSteps) / 2000.0
            print("✅ Total distance: \(String(format: "%.1f", totalDistanceMiles)) miles")
            
            // Calculate average steps for current month
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            let monthStats = try await healthKitService.getSteps(from: monthStart, to: now)
            
            let totalStepsThisMonth = monthStats.reduce(0) { $0 + $1.steps }
            let daysInMonth = calendar.dateComponents([.day], from: monthStart, to: now).day ?? 1
            averageStepsThisMonth = daysInMonth > 0 ? totalStepsThisMonth / daysInMonth : 0
            print("✅ Average steps this month: \(averageStepsThisMonth)")
        } catch {
            print("⚠️ Error loading HealthKit data in Settings: \(error.localizedDescription)")
            // Fallback to user's stored total steps
            totalSteps = sessionViewModel.currentUser?.totalSteps ?? 0
            totalDistanceMiles = Double(totalSteps) / 2000.0
            todaySteps = 0
            currentStreak = 0
            averageStepsThisMonth = 0
        }
    }
    
    private func calculateStreak(from stats: [StepStats]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        
        // Check today first
        if let todayStat = stats.first(where: { calendar.isDate($0.date, inSameDayAs: today) }),
           todayStat.steps > 0 {
            streak = 1
            
            // Check previous days
            for i in 1..<30 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today),
                   let stat = stats.first(where: { calendar.isDate($0.date, inSameDayAs: date) }),
                   stat.steps > 0 {
                    streak += 1
                } else {
                    break
                }
            }
        }
        
        return max(streak, 0)
    }
    
    // MARK: - Auto Refresh
    
    private func setupInitialState() {
        healthKitEnabled = healthKitService.isAuthorized
        darkMode = themeManager.isDarkMode
        
        // Load notification preferences from UserDefaults
        dailyRecap = UserDefaults.standard.bool(forKey: "notif_dailyRecap")
        leaderboardAlerts = UserDefaults.standard.bool(forKey: "notif_leaderboardAlerts")
        motivationalNudges = UserDefaults.standard.bool(forKey: "notif_motivationalNudges")
        
        // If never set before, set defaults
        if !UserDefaults.standard.bool(forKey: "notif_prefsInitialized") {
            dailyRecap = true
            leaderboardAlerts = false
            motivationalNudges = true
            UserDefaults.standard.set(true, forKey: "notif_dailyRecap")
            UserDefaults.standard.set(false, forKey: "notif_leaderboardAlerts")
            UserDefaults.standard.set(true, forKey: "notif_motivationalNudges")
            UserDefaults.standard.set(true, forKey: "notif_prefsInitialized")
        }
        
        // Load unit system from UserDefaults
        if let savedUnit = UserDefaults.standard.string(forKey: "unitSystem") {
            unitSystem = savedUnit == "metric" ? .metric : .imperial
        }
        
        startAutoRefresh()
    }
    
    private func startAutoRefresh() {
        // Refresh every 30 seconds to keep HealthKit data up-to-date
        // Note: SettingsView is a struct, so we can't use [weak self]. 
        // We use a notification to trigger the refresh, which is handled by onReceive.
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                print("🔄 Auto-refreshing HealthKit data in Settings...")
                NotificationCenter.default.post(name: NSNotification.Name("RefreshHealthKitData"), object: nil)
            }
        }
        // Ensure timer runs on main thread
        if let timer = refreshTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - Account Deletion
    
    private func deleteAccount() async {
        guard let userId = sessionViewModel.currentUser?.id else {
            print("⚠️ Cannot delete account: No user ID found")
            return
        }
        
        isDeletingAccount = true
        defer { isDeletingAccount = false }
        
        do {
            print("🗑️ Starting account deletion for user: \(userId)")
            
            // Call the delete_user_account RPC function
            // This will cascade delete all related data:
            // - friendships (both directions)
            // - challenge_members (removes from all challenges)
            // - daily_steps
            // - challenge_messages
            // - challenge_invites
            // - inbox_notifications
            // - profiles
            // - auth.users (final deletion)
            try await supabase
                .rpc("delete_user_account")
                .execute()
            
            print("✅ Account deleted successfully")
            
            // Sign out locally
            await sessionViewModel.signOut()
            
            // Dismiss the settings view
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("❌ Error deleting account: \(error.localizedDescription)")
            await MainActor.run {
                // Show error alert
                // TODO: Add error handling UI
            }
        }
    }
}

// MARK: - Sidebar

// MARK: - Mobile Header

struct SettingsMobileHeader: View {
    let onBack: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Settings")
                .font(.system(size: 18, weight: .bold))
            
            Spacer()
            
            // Spacer for balance
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding()
        .background(
            Color(.systemBackground)
                .opacity(0.95)
                .background(.ultraThinMaterial)
        )
    }
}

// MARK: - Sidebar

struct SettingsSidebar: View {
    let user: User?
    let totalSteps: Int
    let currentStreak: Int
    let totalDistanceMiles: Double
    let averageStepsThisMonth: Int
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Section
                    SettingsProfileSection(
                        user: user,
                        totalSteps: totalSteps,
                        currentStreak: currentStreak,
                        totalDistanceMiles: totalDistanceMiles,
                        averageStepsThisMonth: averageStepsThisMonth
                    )
                    .padding(32)
                    
                    // Version Info
                    Text("v2.4.0 (Build 390)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.top, 32)
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .trailing
        )
    }
}

// MARK: - Profile Section

struct SettingsProfileSection: View {
    let user: User?
    let totalSteps: Int
    let currentStreak: Int
    let totalDistanceMiles: Double
    let averageStepsThisMonth: Int
    
    @State private var showingProfileEditor = false
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var displayName: String {
        user?.displayName ?? "User"
    }
    
    var formattedSteps: String {
        if totalSteps >= 1_000_000 {
            return String(format: "%.1fM", Double(totalSteps) / 1_000_000.0)
        } else if totalSteps >= 1_000 {
            return String(format: "%.1fK", Double(totalSteps) / 1_000.0)
        }
        return "\(totalSteps)"
    }
    
    var formattedDistance: String {
        return String(format: "%.1f mi", totalDistanceMiles)
    }
    
    var formattedAverageSteps: String {
        if averageStepsThisMonth >= 1_000 {
            return String(format: "%.1fK", Double(averageStepsThisMonth) / 1_000.0)
        }
        return "\(averageStepsThisMonth)"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    displayName: displayName,
                    avatarURL: user?.avatarURL,
                    size: 128
                )
                .overlay(
                    Circle()
                        .stroke(primaryYellow, lineWidth: 4)
                )
                .shadow(color: primaryYellow.opacity(0.1), radius: 10, x: 0, y: 4)
                
                // Edit button
                Button(action: {
                    showingProfileEditor = true
                }) {
                    ZStack {
                        Circle()
                            .fill(primaryYellow)
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 4)
                    )
                }
            }
            .sheet(isPresented: $showingProfileEditor) {
                if let user = user {
                    ProfileSettingsView(user: user)
                }
            }
            
            // User Info
            VStack(spacing: 8) {
                Text(displayName)
                    .font(.system(size: 24, weight: .bold))
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                    Text("Step Master")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(primaryYellow)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(primaryYellow.opacity(0.2))
                .cornerRadius(999)
            }
            
            // Mini Stats - 2x2 Grid
            VStack(spacing: 12) {
            HStack(spacing: 12) {
                MiniStatCard(
                        label: "Total Steps",
                    value: formattedSteps
                )
                
                    MiniStatCard(
                        label: "Total Distance",
                        value: formattedDistance
                    )
                }
                
                HStack(spacing: 12) {
                MiniStatCard(
                    label: "Current Streak",
                    value: "\(currentStreak) Days"
                )
                    
                    MiniStatCard(
                        label: "Avg Steps/Month",
                        value: formattedAverageSteps
                    )
                }
            }
        }
    }
}

struct MiniStatCard: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(2)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

// MARK: - Main Content

struct SettingsMainContent: View {
    @Binding var healthKitEnabled: Bool
    @Binding var appleWatchSetup: Bool
    @Binding var dailyRecap: Bool
    @Binding var leaderboardAlerts: Bool
    @Binding var motivationalNudges: Bool
    @Binding var darkMode: Bool
    @Binding var unitSystem: SettingsView.UnitSystem
    
    let sessionViewModel: SessionViewModel?
    let onSignOut: () -> Void
    let onDeleteAccount: () -> Void
    let isDeletingAccount: Bool
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(spacing: 0) {
            // Desktop Header (only visible on iPad/Desktop)
            #if canImport(UIKit)
            if UIDevice.current.userInterfaceIdiom == .pad {
                HStack {
                    Text("Preferences")
                        .font(.system(size: 32, weight: .bold))
                    
                    Spacer()
                    
                    Button(action: onSignOut) {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(.systemBackground))
                        .cornerRadius(999)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .background(
                    Color(.systemBackground)
                        .opacity(0.9)
                        .background(.ultraThinMaterial)
                )
            }
            #endif
            
            // Scrollable Content
            ScrollView {
                VStack(spacing: 24) {
                    // Settings Grid
                    #if canImport(UIKit)
                    let columns: [GridItem] = UIDevice.current.userInterfaceIdiom == .pad ? [
                        GridItem(.flexible(), spacing: 24),
                        GridItem(.flexible(), spacing: 24)
                    ] : [
                        GridItem(.flexible())
                    ]
                    #else
                    let columns: [GridItem] = [
                        GridItem(.flexible())
                    ]
                    #endif
                    
                    LazyVGrid(columns: columns, spacing: 24) {
                        // Connectivity Card
                        ConnectivityCard(
                            healthKitEnabled: $healthKitEnabled,
                            appleWatchSetup: $appleWatchSetup
                        )
                        
                        // Notifications Card
                        NotificationsCard(
                            dailyRecap: $dailyRecap,
                            leaderboardAlerts: $leaderboardAlerts,
                            motivationalNudges: $motivationalNudges
                        )
                        
                        // Preferences Card
                        PreferencesCard(
                            darkMode: $darkMode,
                            unitSystem: $unitSystem,
                            sessionViewModel: sessionViewModel
                        )
                        
                        // Support & Legal Card
                        SupportLegalCard()
                        
                        // Developer/Test Card (always visible for HealthKit testing)
                        DeveloperCard()
                        
                        // Logout Button
                        Button(action: onSignOut) {
                            HStack {
                                Spacer()
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Log Out")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(.red)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Delete Account Button
                        Button(action: onDeleteAccount) {
                            HStack {
                                Spacer()
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Delete Account")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isDeletingAccount)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    
                    // Fun Footer
                    FunFooter()
                        .padding(.top, 32)
                        .padding(.bottom, 48)
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Connectivity Card

struct ConnectivityCard: View {
    @Binding var healthKitEnabled: Bool
    @Binding var appleWatchSetup: Bool
    @EnvironmentObject var healthKitService: HealthKitService
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        SettingsCard(
            icon: "applewatch",
            iconColor: .blue,
            title: "Connectivity"
        ) {
            VStack(spacing: 16) {
                // HealthKit
                SettingItemRow(
                    icon: "heart.fill",
                    title: "HealthKit Sync",
                    subtitle: healthKitEnabled ? "Permissions Granted" : "Not Authorized",
                    trailing: {
                        Toggle("", isOn: Binding(
                            get: { healthKitEnabled },
                            set: { newValue in
                                if newValue {
                                    Task {
                                        do {
                                            try await healthKitService.requestAuthorization()
                                            await MainActor.run {
                                                healthKitEnabled = healthKitService.isAuthorized
                                            }
                                        } catch {
                                            print("⚠️ Error requesting HealthKit authorization: \(error.localizedDescription)")
                                        }
                                    }
                                } else {
                                    // Can't revoke HealthKit permissions from app
                                    // Redirect to Settings
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                        ))
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.976, green: 0.961, blue: 0.024)))
                    }
                )
                
                // Apple Watch
                SettingItemRow(
                    icon: "applewatch",
                    title: "Apple Watch",
                    subtitle: appleWatchSetup ? "Connected" : "Coming Soon",
                    trailing: {
                        if !appleWatchSetup {
                            Text("Soon")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .cornerRadius(999)
                        } else {
                            Toggle("", isOn: $appleWatchSetup)
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.976, green: 0.961, blue: 0.024)))
                                .disabled(true)
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Notifications Card

struct NotificationsCard: View {
    @Binding var dailyRecap: Bool
    @Binding var leaderboardAlerts: Bool
    @Binding var motivationalNudges: Bool
    
    var body: some View {
        SettingsCard(
            icon: "bell.badge.fill",
            iconColor: .yellow,
            title: "Notifications"
        ) {
            VStack(spacing: 16) {
                SettingItemRow(
                    icon: "doc.text.fill",
                    title: "Daily Recap",
                    trailing: {
                        Toggle("", isOn: $dailyRecap)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.976, green: 0.961, blue: 0.024)))
                    }
                )
                
                SettingItemRow(
                    icon: "trophy.fill",
                    title: "Leaderboard Alerts",
                    trailing: {
                        Toggle("", isOn: $leaderboardAlerts)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.976, green: 0.961, blue: 0.024)))
                    }
                )
                
                SettingItemRow(
                    icon: "bolt.fill",
                    title: "Motivational Nudges",
                    trailing: {
                        Toggle("", isOn: $motivationalNudges)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.976, green: 0.961, blue: 0.024)))
                    }
                )
            }
        }
    }
}

// MARK: - Preferences Card

struct PreferencesCard: View {
    @Binding var darkMode: Bool
    @Binding var unitSystem: SettingsView.UnitSystem
    let sessionViewModel: SessionViewModel?
    @State private var showingHeightWeightEditor = false
    @State private var showingDailyStepGoalEditor = false
    @EnvironmentObject var themeManager: ThemeManager
    
    // Helper function to convert cm to feet/inches
    private func heightInImperial(_ cm: Int) -> (feet: Int, inches: Int) {
        let totalInches = Double(cm) / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        return (feet, inches)
    }
    
    var body: some View {
        SettingsCard(
            icon: "slider.horizontal.3",
            iconColor: .purple,
            title: "App Preferences"
        ) {
            VStack(spacing: 16) {
                SettingItemRow(
                    icon: "moon.fill",
                    iconBackground: Color.black,
                    title: "Dark Mode",
                    subtitle: "Change app appearance",
                    trailing: {
                        Toggle("", isOn: Binding(
                            get: { themeManager.isDarkMode },
                            set: { newValue in
                                darkMode = newValue
                                themeManager.isDarkMode = newValue
                            }
                        ))
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.976, green: 0.961, blue: 0.024)))
                    }
                )
                
                SettingItemRow(
                    icon: "ruler.fill",
                    title: "Unit System",
                    trailing: {
                        HStack(spacing: 4) {
                            Button(action: { unitSystem = .metric }) {
                                Text("KM")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(unitSystem == .metric ? .black : .secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                    .background(unitSystem == .metric ? Color(.systemBackground) : Color.clear)
                                    .cornerRadius(999)
                            }
                            
                            Button(action: { unitSystem = .imperial }) {
                                Text("MI")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(unitSystem == .imperial ? .black : .secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                    .background(unitSystem == .imperial ? Color(.systemBackground) : Color.clear)
                                    .cornerRadius(999)
                            }
                        }
                        .padding(4)
                        .background(Color(.systemGray6))
                        .cornerRadius(999)
                    }
                )
                
                // Public Profile Toggle
                if let sessionViewModel = sessionViewModel {
                    SettingItemRow(
                        icon: "person.circle.fill",
                        iconBackground: .blue,
                        title: "Public Profile",
                        subtitle: "Allow others to find you in search",
                        trailing: {
                            Toggle("", isOn: Binding(
                                get: {
                                    // Read actual publicProfile value from current user
                                    return sessionViewModel.currentUser?.publicProfile ?? false
                                },
                                set: { newValue in
                                    Task {
                                        if let userId = sessionViewModel.currentUser?.id {
                                            let service = FriendsService()
                                            try? await service.setPublicProfile(newValue, myUserId: userId)
                                            // Refresh user profile to reflect change
                                            await sessionViewModel.checkSession()
                                        }
                                    }
                                }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.976, green: 0.961, blue: 0.024)))
                        }
                    )
                }
                
                // Height and Weight
                if let sessionViewModel = sessionViewModel {
                    Button(action: {
                        showingHeightWeightEditor = true
                    }) {
                        SettingItemRow(
                            icon: "figure.stand",
                            title: "Height & Weight",
                            subtitle: {
                                let height = UserDefaults.standard.integer(forKey: "userHeight")
                                let weight = UserDefaults.standard.integer(forKey: "userWeight")
                                
                                if height > 0 && weight > 0 {
                                    let imperialHeight = heightInImperial(height)
                                    let imperialWeight = Int(Double(weight) * 2.20462)
                                    return "\(imperialHeight.feet)'\(imperialHeight.inches)\", \(imperialWeight) lbs"
                                } else {
                                    return "Not set"
                                }
                            }(),
                            trailing: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $showingHeightWeightEditor) {
                        if let user = sessionViewModel.currentUser {
                            EditHeightWeightSheet(
                                user: user,
                                onSave: { height, weight in
                                    Task {
                                        await sessionViewModel.authServiceAccess.updateUserHeightWeight(height: height, weight: weight)
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Daily Step Goal
                if let sessionViewModel = sessionViewModel {
                    Button(action: {
                        showingDailyStepGoalEditor = true
                    }) {
                        SettingItemRow(
                            icon: "target",
                            iconBackground: .green,
                            title: "Daily Step Goal",
                            subtitle: {
                                let goal = UserDefaults.standard.integer(forKey: "dailyStepGoal")
                                if goal > 0 {
                                    let formatter = NumberFormatter()
                                    formatter.numberStyle = .decimal
                                    return "\(formatter.string(from: NSNumber(value: goal)) ?? "\(goal)") steps"
                                } else {
                                    return "10,000 steps (default)"
                                }
                            }(),
                            trailing: {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $showingDailyStepGoalEditor) {
                        if let user = sessionViewModel.currentUser {
                            EditDailyStepGoalSheet(
                                user: user,
                                currentGoal: UserDefaults.standard.integer(forKey: "dailyStepGoal") > 0 
                                    ? UserDefaults.standard.integer(forKey: "dailyStepGoal") 
                                    : 10000,
                                onSave: { goal in
                                    Task {
                                        await sessionViewModel.authServiceAccess.updateDailyStepGoal(goal)
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Support & Legal Card

struct SupportLegalCard: View {
    @State private var showingFeedback = false
    @State private var showingFAQ = false
    @State private var showingPrivacy = false
    @State private var showingAbout = false
    
    var body: some View {
        SettingsCard(
            icon: "questionmark.circle.fill",
            iconColor: .pink,
            title: "Support & Legal"
        ) {
            VStack(spacing: 8) {
                Button(action: {
                    showingFeedback = true
                }) {
                    SupportLinkRow(
                        icon: "bubble.left.and.bubble.right.fill",
                        title: "Feedback Board"
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(Color(.systemGray5))
                
                Button(action: {
                    showingFAQ = true
                }) {
                    SupportLinkRow(
                        icon: "questionmark.circle.fill",
                        title: "FAQ / Help Center"
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(Color(.systemGray5))
                
                Button(action: {
                    showingPrivacy = true
                }) {
                    SupportLinkRow(
                        icon: "lock.fill",
                        title: "Privacy Policy"
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(Color(.systemGray5))
                
                Button(action: {
                    showingAbout = true
                }) {
                    SupportLinkRow(
                        icon: "info.circle.fill",
                        title: "About Us"
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .sheet(isPresented: $showingFeedback) {
            FeedbackBoardView()
        }
        .sheet(isPresented: $showingFAQ) {
            FAQView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutUsView()
        }
    }
}

struct SupportLinkRow: View {
    let icon: String
    let title: String
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        Button(action: {}) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings Card

struct SettingsCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 20, weight: .bold))
            }
            
            // Content
            content()
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(32)
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Setting Item Row

struct SettingItemRow<Trailing: View>: View {
    let icon: String
    var iconBackground: Color = Color(.systemGray6)
    let title: String
    var subtitle: String? = nil
    @ViewBuilder let trailing: () -> Trailing
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconBackground == Color.black ? .white : .primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            trailing()
        }
        .padding(8)
    }
}

// MARK: - Fun Footer

struct FunFooter: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.hiking")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Text("Keep Moving")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(2)
        }
        .opacity(0.5)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Developer Card

struct DeveloperCard: View {
    @State private var showingSupabaseTest = false
    @State private var showingHealthKitTest = false
    @EnvironmentObject var healthKitService: HealthKitService
    
    var body: some View {
        SettingsCard(
            icon: "wrench.and.screwdriver.fill",
            iconColor: .orange,
            title: "Developer Tools"
        ) {
            VStack(spacing: 8) {
                Button(action: {
                    showingSupabaseTest = true
                }) {
                    HStack {
                        Image(systemName: "network")
                            .font(.system(size: 18))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Test Supabase Connection")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            showingHealthKitTest = true
                        }) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Test HealthKit Connection")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Text("Test Apple Health integration")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .sheet(isPresented: $showingSupabaseTest) {
            SupabaseTestView()
        }
            .sheet(isPresented: $showingHealthKitTest) {
                HealthKitTestView()
                    .environmentObject(healthKitService)
            }
        }
    }


// MARK: - Edit Height Weight Sheet

struct EditHeightWeightSheet: View {
    let user: User
    let onSave: (Int?, Int?) -> Void
    
    @State private var editingHeight: String = ""
    @State private var editingWeight: String = ""
    @State private var isLoadingHealthKit = false
    @State private var unitSystem: UnitSystem = {
        // Default to imperial (feet/inches, lbs)
        if let saved = UserDefaults.standard.string(forKey: "unitSystem"),
           saved == "metric" {
            return .metric
        }
        return .imperial
    }()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var healthKitService: HealthKitService
    
    enum UnitSystem {
        case metric
        case imperial
    }
    
    // Convert cm to feet/inches for display
    private func heightInImperial(_ cm: Int) -> (feet: Int, inches: Int) {
        let totalInches = Double(cm) / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        return (feet, inches)
    }
    
    // Convert kg to lbs for display
    private func weightInImperial(_ kg: Int) -> Int {
        return Int(Double(kg) * 2.20462)
    }
    
    // Convert feet/inches to cm
    private func heightToMetric(feet: Int, inches: Int) -> Int {
        let totalInches = Double(feet * 12 + inches)
        return Int(totalInches * 2.54)
    }
    
    // Convert lbs to kg
    private func weightToMetric(_ lbs: Int) -> Int {
        return Int(Double(lbs) / 2.20462)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Body Measurements")) {
                    // Height in feet/inches
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Height")
                        HStack {
                            TextField("5", text: Binding(
                                get: {
                                    let height = Int(editingHeight) ?? 0
                                    let imperial = heightInImperial(height)
                                    return "\(imperial.feet)"
                                },
                                set: { newValue in
                                    if let feet = Int(newValue) {
                                        let height = Int(editingHeight) ?? 0
                                        let currentImperial = heightInImperial(height)
                                        let newHeight = heightToMetric(feet: feet, inches: currentImperial.inches)
                                        editingHeight = "\(newHeight)"
                                    }
                                }
                            ))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            Text("ft")
                            
                            TextField("10", text: Binding(
                                get: {
                                    let height = Int(editingHeight) ?? 0
                                    let imperial = heightInImperial(height)
                                    return "\(imperial.inches)"
                                },
                                set: { newValue in
                                    if let inches = Int(newValue) {
                                        let height = Int(editingHeight) ?? 0
                                        let currentImperial = heightInImperial(height)
                                        let newHeight = heightToMetric(feet: currentImperial.feet, inches: inches)
                                        editingHeight = "\(newHeight)"
                                    }
                                }
                            ))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            Text("in")
                        }
                    }
                    
                    // Weight in lbs
                    HStack {
                        Text("Weight (lbs)")
                        Spacer()
                        TextField("150", text: Binding(
                            get: {
                                let weight = Int(editingWeight) ?? 0
                                return weight > 0 ? "\(weightInImperial(weight))" : ""
                            },
                            set: { newValue in
                                if let lbs = Int(newValue) {
                                    editingWeight = "\(weightToMetric(lbs))"
                                }
                            }
                        ))
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    }
                }
                
                Section(footer: Text("These values are used for calculating calories burned and other health metrics.")) {
                    Button(action: {
                        Task {
                            await loadFromHealthKit()
                        }
                    }) {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .foregroundColor(.red)
                            Text("Sync from HealthKit")
                                .foregroundColor(.blue)
                            Spacer()
                            if isLoadingHealthKit {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                    }
                    .disabled(isLoadingHealthKit)
                }
            }
            .navigationTitle("Height & Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        let height = editingHeight.isEmpty ? nil : Int(editingHeight)
                        let weight = editingWeight.isEmpty ? nil : Int(editingWeight)
                        onSave(height, weight)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .dismissKeyboardOnTap()
        .onAppear {
            let height = UserDefaults.standard.integer(forKey: "userHeight")
            let weight = UserDefaults.standard.integer(forKey: "userWeight")
            
            // If not set in UserDefaults, try to load from HealthKit
            if height == 0 || weight == 0 {
                Task {
                    await loadFromHealthKit()
                }
            } else {
                editingHeight = height > 0 ? "\(height)" : ""
                editingWeight = weight > 0 ? "\(weight)" : ""
            }
        }
    }
    
    // Load height and weight from HealthKit
    private func loadFromHealthKit() async {
        isLoadingHealthKit = true
        defer { isLoadingHealthKit = false }
        
        do {
            // Load height (in cm)
            if let heightCm = try await healthKitService.getHeight() {
                print("✅ Loaded height from HealthKit: \(heightCm) cm")
                editingHeight = "\(Int(heightCm))"
            }
            
            // Load weight (in kg)
            if let weightKg = try await healthKitService.getWeight() {
                print("✅ Loaded weight from HealthKit: \(Int(weightKg)) kg")
                editingWeight = "\(Int(weightKg))"
            }
        } catch {
            print("⚠️ Error loading from HealthKit: \(error.localizedDescription)")
        }
    }
}

// MARK: - Edit Daily Step Goal Sheet

struct EditDailyStepGoalSheet: View {
    let user: User
    let currentGoal: Int
    let onSave: (Int) -> Void
    
    @State private var sliderValue: Double = 10000
    @State private var selectedPreset: GoalPreset? = .tenThousand
    @Environment(\.dismiss) var dismiss
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    enum GoalPreset: Int, CaseIterable {
        case fiveThousand = 5000
        case sevenThousand = 7500
        case tenThousand = 10000
        case fifteenThousand = 15000
        
        var displayName: String {
            switch self {
            case .fiveThousand: return "5,000"
            case .sevenThousand: return "7,500"
            case .tenThousand: return "10,000"
            case .fifteenThousand: return "15,000"
            }
        }
        
        var label: String {
            switch self {
            case .fiveThousand: return "Casual"
            case .sevenThousand: return "Active"
            case .tenThousand: return "Standard"
            case .fifteenThousand: return "Athlete"
            }
        }
        
        var icon: String {
            switch self {
            case .fiveThousand: return "figure.walk"
            case .sevenThousand: return "figure.hiking"
            case .tenThousand: return "figure.strengthtraining.traditional"
            case .fifteenThousand: return "trophy.fill"
            }
        }
    }
    
    var currentGoalFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: Int(sliderValue))) ?? "\(Int(sliderValue))"
    }
    
    var progressPercentage: Double {
        // Calculate progress for the ring (0-360 degrees)
        return (sliderValue - 2000) / (25000 - 2000)
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .foregroundColor(primaryYellow)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    Text("Daily Step Goal")
                        .font(.system(size: 18, weight: .bold))
                    
                    Spacer()
                    
                    Button(action: {
                        onSave(Int(sliderValue))
                        dismiss()
                    }) {
                        Text("Save")
                            .foregroundColor(.black)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(primaryYellow)
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Target Setup Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("TARGET SETUP")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .tracking(1)
                            
                            VStack(spacing: 32) {
                                // Circular Progress
                                ZStack {
                                    // Background circle
                                    Circle()
                                        .stroke(Color(.systemGray5), lineWidth: 12)
                                        .frame(width: 192, height: 192)
                                    
                                    // Progress arc
                                    Circle()
                                        .trim(from: 0, to: progressPercentage)
                                        .stroke(primaryYellow, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                        .frame(width: 192, height: 192)
                                        .rotationEffect(.degrees(-90))
                                        .animation(.spring(response: 0.3), value: progressPercentage)
                                    
                                    // Center text
                                    VStack(spacing: 4) {
                                        Text(currentGoalFormatted)
                                            .font(.system(size: 44, weight: .bold))
                                        
                                        Text("STEPS/DAY")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .tracking(0.5)
                                    }
                                }
                                .padding(.vertical, 20)
                                
                                // Custom Goal Slider
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Custom Goal")
                                            .font(.system(size: 18, weight: .semibold))
                                        
                                        Spacer()
                                        
                                        Text("Recommended")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(primaryYellow)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(primaryYellow.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                    
                                    // Slider
                                    Slider(value: $sliderValue, in: 2000...25000, step: 500)
                                        .tint(primaryYellow)
                                        .onChange(of: sliderValue) { _, newValue in
                                            // Deselect preset if manually adjusted
                                            if let preset = selectedPreset, Double(preset.rawValue) != newValue {
                                                selectedPreset = nil
                                            }
                                        }
                                    
                                    HStack {
                                        Text("2,000")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Text("25,000")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(24)
                            .background(Color(.systemGray6))
                            .cornerRadius(24)
                        }
                        
                        // Quick Select
                        VStack(alignment: .leading, spacing: 16) {
                            Text("QUICK SELECT")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .tracking(1)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(GoalPreset.allCases, id: \.self) { preset in
                                    QuickSelectButton(
                                        preset: preset,
                                        isSelected: selectedPreset == preset,
                                        primaryYellow: primaryYellow
                                    ) {
                                        selectedPreset = preset
                                        sliderValue = Double(preset.rawValue)
                                    }
                                }
                            }
                        }
                        
                        // Footer text
                        Text("Set your daily step goal to track your progress and stay motivated. The default is 10,000 steps per day, recommended by health experts.")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 32)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            sliderValue = Double(currentGoal > 0 ? currentGoal : 10000)
            if let matchingPreset = GoalPreset.allCases.first(where: { $0.rawValue == currentGoal }) {
                selectedPreset = matchingPreset
            }
        }
    }
}

// MARK: - Quick Select Button

struct QuickSelectButton: View {
    let preset: EditDailyStepGoalSheet.GoalPreset
    let isSelected: Bool
    let primaryYellow: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: preset.icon)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .black : primaryYellow)
                
                Text(preset.displayName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isSelected ? .black : .primary)
                
                Text(preset.label.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isSelected ? .black.opacity(0.7) : .secondary)
                    .tracking(0.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(isSelected ? primaryYellow : Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? primaryYellow : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? primaryYellow.opacity(0.3) : Color.clear, radius: 8)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - View Modifiers

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
    let unitSystem: SettingsView.UnitSystem
    let themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .onChange(of: darkMode) { _, newValue in
                themeManager.setColorScheme(newValue ? .dark : .light)
            }
            .onChange(of: dailyRecap) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "notif_dailyRecap")
            }
            .onChange(of: leaderboardAlerts) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "notif_leaderboardAlerts")
            }
            .onChange(of: motivationalNudges) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "notif_motivationalNudges")
            }
            .onChange(of: unitSystem) { _, newValue in
                UserDefaults.standard.set(
                    newValue == .metric ? "metric" : "imperial",
                    forKey: "unitSystem"
                )
            }
    }
}
