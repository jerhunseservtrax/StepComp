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
#if canImport(UserNotifications)
import UserNotifications
#endif

struct SettingsView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var healthKitService: HealthKitService
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject private var unitPreferenceManager = UnitPreferenceManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
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
    
    // HealthKit data
    @State private var todaySteps: Int = 0
    @State private var currentStreak: Int = 0
    @State private var totalSteps: Int = 0
    @State private var totalDistanceMiles: Double = 0.0
    @State private var averageStepsThisMonth: Int = 0
    @State private var refreshTimer: Timer?
    @State private var dailyStepGoal: Int = 10000
    
    
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
                        // Don't call dismiss() - view hierarchy will update automatically
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
            SettingsMobileHeader()
            
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
        .background(StepCompColors.background.ignoresSafeArea())
    }
    
    private var mainContent: some View {
        SettingsMainContent(
            healthKitEnabled: $healthKitEnabled,
            appleWatchSetup: $appleWatchSetup,
            dailyRecap: $dailyRecap,
            leaderboardAlerts: $leaderboardAlerts,
            motivationalNudges: $motivationalNudges,
            darkMode: $darkMode,
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
            
            // Load daily step goal from UserDefaults
            var goal = UserDefaults.standard.integer(forKey: "dailyStepGoal")
            if goal <= 0 {
                goal = 10000 // Default
            }
            dailyStepGoal = goal
            print("🎯 Daily step goal: \(dailyStepGoal)")
            
            // Get today's steps (same as Home and Workout: full calendar day from HealthKit)
            todaySteps = (try? await healthKitService.getSteps(for: Date())) ?? 0
            print("✅ Today's steps: \(todaySteps)")
            
            // Get 30 days of stats for streak calculation
            // Use start of day for proper date alignment
            let calendar = Calendar.current
            let now = Date()
            let today = calendar.startOfDay(for: now)
            guard let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today),
                  let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
                currentStreak = 0
                return
            }
            let streakStats = try await healthKitService.getSteps(from: thirtyDaysAgo, to: tomorrow)
            
            // Calculate streak from HealthKit data, passing today's steps separately
            // (in case today isn't in the stats array yet)
            currentStreak = calculateStreak(from: streakStats, todaySteps: todaySteps)
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
    
    private func calculateStreak(from stats: [StepStats], todaySteps: Int) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        
        // Get user's daily step goal
        var dailyGoal = UserDefaults.standard.integer(forKey: "dailyStepGoal")
        if dailyGoal <= 0 {
            dailyGoal = 10000 // Default goal if not set
        }
        
        print("📊 Calculating streak with daily goal: \(dailyGoal), today's steps: \(todaySteps)")
        print("📊 Stats array has \(stats.count) entries")
        
        // Helper to get steps for a specific date
        func stepsForDate(_ date: Date) -> Int {
            // For today, prefer the directly-fetched todaySteps value
            if calendar.isDate(date, inSameDayAs: today) {
                return todaySteps
            }
            // Otherwise look in stats array
            if let stat = stats.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                return stat.steps
            }
            return 0
        }
        
        // Check if today meets the goal
        let todayMeetsGoal = todaySteps >= dailyGoal
        
        if todayMeetsGoal {
            // Today meets goal - count from today backwards
            streak = 1
            print("✅ Today's goal met: \(todaySteps) >= \(dailyGoal)")
            
            // Check previous days
            for i in 1..<30 {
                guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { break }
                let daySteps = stepsForDate(date)
                
                if daySteps >= dailyGoal {
                    streak += 1
                    print("✅ Day -\(i) goal met: \(daySteps) >= \(dailyGoal)")
                } else {
                    print("❌ Day -\(i) goal NOT met: \(daySteps) < \(dailyGoal) - streak ends")
                    break
                }
            }
        } else {
            // Today doesn't meet goal yet - but still count streak from yesterday
            // This shows users their recent achievement even if they haven't walked today
            print("⏳ Today's goal not yet met: \(todaySteps) < \(dailyGoal)")
            print("📊 Checking for streak from yesterday...")
            
            for i in 1..<30 {
                guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { break }
                let daySteps = stepsForDate(date)
                
                if daySteps >= dailyGoal {
                    streak += 1
                    print("✅ Day -\(i) goal met: \(daySteps) >= \(dailyGoal)")
                } else {
                    print("❌ Day -\(i) goal NOT met: \(daySteps) < \(dailyGoal) - streak ends")
                    break
                }
            }
        }
        
        print("🔥 Final streak: \(streak) days")
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
        
        // Unit system is now managed by UnitPreferenceManager (loads automatically)
        
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
    var body: some View {
        HStack {
            Spacer()
            
            Text("Settings")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(StepCompColors.textPrimary)
            
            Spacer()
        }
        .padding()
        .background(StepCompColors.background)
    }
}

// MARK: - Sidebar

struct SettingsSidebar: View {
    let user: User?
    let totalSteps: Int
    let currentStreak: Int
    let totalDistanceMiles: Double
    let averageStepsThisMonth: Int
    
    
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
        .background(StepCompColors.background)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(StepCompColors.cardBorder),
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
                        .stroke(StepCompColors.primary, lineWidth: 4)
                )
                .shadow(color: StepCompColors.primary.opacity(0.1), radius: 10, x: 0, y: 4)
                
                // Edit button
                Button(action: {
                    showingProfileEditor = true
                }) {
                    ZStack {
                        Circle()
                            .fill(StepCompColors.primary)
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
                .foregroundColor(StepCompColors.buttonTextOnPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(StepCompColors.primary.opacity(0.2))
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
        .background(StepCompColors.surfaceElevated)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(StepCompColors.cardBorder, lineWidth: 1)
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
    
    let sessionViewModel: SessionViewModel?
    let onSignOut: () -> Void
    let onDeleteAccount: () -> Void
    let isDeletingAccount: Bool
    
    
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
                        .background(StepCompColors.surface)
                        .cornerRadius(999)
                        .overlay(
                            RoundedRectangle(cornerRadius: 999)
                                .stroke(StepCompColors.cardBorder, lineWidth: 1)
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
                        GridItem(.flexible(minimum: 280), spacing: 24),
                        GridItem(.flexible(minimum: 280), spacing: 24)
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
                            sessionViewModel: sessionViewModel
                        )
                        
                        // Support & Legal Card
                        SupportLegalCard()
                        
                        // Test Goal Celebration Button (for testing)
                        #if DEBUG
                        Button(action: {
                            // Get daily goal from UserDefaults
                            var goal = UserDefaults.standard.integer(forKey: "dailyStepGoal")
                            if goal <= 0 {
                                goal = 10000 // Default
                            }
                            
                            // Trigger goal celebration
                            let goalManager = GoalCelebrationManager.shared
                            goalManager.forceTriggerCelebration(
                                steps: goal + 500,
                                goal: goal
                            )
                            HapticManager.shared.success()
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Test Goal Celebration")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.yellow, Color.orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.yellow.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        #endif
                        
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
                            .background(StepCompColors.surface)
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
        .background(StepCompColors.surface)
    }
}

// MARK: - Connectivity Card

struct ConnectivityCard: View {
    @Binding var healthKitEnabled: Bool
    @Binding var appleWatchSetup: Bool
    @EnvironmentObject var healthKitService: HealthKitService
    
    
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
                            .toggleStyle(SwitchToggleStyle(tint: StepCompColors.primary))
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
                                .background(StepCompColors.surfaceElevated)
                                .cornerRadius(999)
                        } else {
                            Toggle("", isOn: $appleWatchSetup)
                                .toggleStyle(SwitchToggleStyle(tint: StepCompColors.primary))
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
    
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var isRequestingPermission = false
    
    var body: some View {
        SettingsCard(
            icon: "bell.badge.fill",
            iconColor: .yellow,
            title: "Notifications"
        ) {
            VStack(spacing: 16) {
                // Permission status banner
                if notificationManager.authorizationStatus == .notDetermined {
                    Button(action: {
                        Task {
                            isRequestingPermission = true
                            do {
                                try await notificationManager.requestAuthorization()
                            } catch {
                                print("❌ Error requesting notification permission: \(error)")
                            }
                            isRequestingPermission = false
                        }
                    }) {
                        HStack(spacing: 12) {
                            if isRequestingPermission {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "bell.badge")
                                    .font(.system(size: 18))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable Notifications")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Get updates on your progress")
                                    .font(.system(size: 12))
                                    .opacity(0.8)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(12)
                        .background(StepCompColors.primary)
                        .cornerRadius(12)
                    }
                    .disabled(isRequestingPermission)
                } else if notificationManager.authorizationStatus == .denied {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notifications Disabled")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Enable in Settings app")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Open Settings")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(StepCompColors.primary)
                        }
                    }
                    .padding(12)
                    .background(StepCompColors.surfaceElevated)
                    .cornerRadius(12)
                }
                
                // Notification toggles
                SettingItemRow(
                    icon: "doc.text.fill",
                    title: "Daily Recap",
                    subtitle: "8 PM summary",
                    trailing: {
                        Toggle("", isOn: $dailyRecap)
                            .toggleStyle(SwitchToggleStyle(tint: StepCompColors.primary))
                            .disabled(!notificationManager.isAuthorized)
                    }
                )
                
                SettingItemRow(
                    icon: "trophy.fill",
                    title: "Leaderboard Alerts",
                    subtitle: "Rank changes",
                    trailing: {
                        Toggle("", isOn: $leaderboardAlerts)
                            .toggleStyle(SwitchToggleStyle(tint: StepCompColors.primary))
                            .disabled(!notificationManager.isAuthorized)
                    }
                )
                
                SettingItemRow(
                    icon: "bolt.fill",
                    title: "Motivational Nudges",
                    subtitle: "10 AM, 2 PM, 6 PM",
                    trailing: {
                        Toggle("", isOn: $motivationalNudges)
                            .toggleStyle(SwitchToggleStyle(tint: StepCompColors.primary))
                            .disabled(!notificationManager.isAuthorized)
                    }
                )
            }
        }
        .onAppear {
            notificationManager.checkAuthorizationStatus()
        }
    }
}

// MARK: - Preferences Card

struct PreferencesCard: View {
    @Binding var darkMode: Bool
    @ObservedObject private var unitPreferenceManager = UnitPreferenceManager.shared
    let sessionViewModel: SessionViewModel?
    @State private var showingDailyStepGoalEditor = false
    @State private var refreshTrigger = UUID() // Add refresh trigger
    @EnvironmentObject var themeManager: ThemeManager
    
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
                            .toggleStyle(SwitchToggleStyle(tint: StepCompColors.primary))
                    }
                )
                
                SettingItemRow(
                    icon: "ruler.fill",
                    title: "Unit System",
                    trailing: {
                        HStack(spacing: 4) {
                            Button(action: { 
                                print("🔘 KM button tapped")
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    unitPreferenceManager.unitSystem = .metric
                                }
                            }) {
                                Text("KM")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(unitPreferenceManager.unitSystem == .metric ? .black : .secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        unitPreferenceManager.unitSystem == .metric 
                                            ? StepCompColors.primary  // Yellow when selected
                                            : Color.clear
                                    )
                                    .cornerRadius(999)
                                    .contentShape(Rectangle())  // Ensure full tap area
                            }
                            .buttonStyle(.plain)
                            .allowsHitTesting(true)
                            
                            Button(action: { 
                                print("🔘 MI button tapped")
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    unitPreferenceManager.unitSystem = .imperial
                                }
                            }) {
                                Text("MI")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(unitPreferenceManager.unitSystem == .imperial ? .black : .secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        unitPreferenceManager.unitSystem == .imperial 
                                            ? StepCompColors.primary  // Yellow when selected
                                            : Color.clear
                                    )
                                    .cornerRadius(999)
                                    .contentShape(Rectangle())  // Ensure full tap area
                            }
                            .buttonStyle(.plain)
                            .allowsHitTesting(true)
                        }
                        .padding(4)
                        .background(StepCompColors.surfaceElevated)
                        .cornerRadius(999)
                    }
                )
                
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
                                        // Trigger view refresh
                                        DispatchQueue.main.async {
                                            refreshTrigger = UUID()
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
        .id(refreshTrigger) // Add id modifier to force refresh when trigger changes
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
                    .background(StepCompColors.cardBorder)
                
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
                    .background(StepCompColors.cardBorder)
                
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
                    .background(StepCompColors.cardBorder)
                
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
    
    
    var body: some View {
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
        .background(StepCompColors.surface)
        .cornerRadius(12)
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
        .background(StepCompColors.surface)
        .cornerRadius(32)
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(StepCompColors.cardBorder, lineWidth: 1)
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
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconBackground == Color.black ? .white : .primary)
            }
            .flexibleFrame(minWidth: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
            }
            .layoutPriority(1)
            
            Spacer(minLength: 4)
            
            trailing()
                .flexibleFrame(minWidth: 50)
        }
        .padding(8)
    }
}

// Helper extension for flexible frames
extension View {
    func flexibleFrame(minWidth: CGFloat) -> some View {
        self.frame(minWidth: minWidth)
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

// MARK: - Edit Height Weight Sheet

struct EditHeightWeightSheet: View {
    let user: User
    let onSave: (Int?, Int?) -> Void
    
    @State private var selectedFeet: Int = 5
    @State private var selectedInches: Int = 9
    @State private var selectedWeight: Int = 150
    @State private var heightUnit: HeightUnit = .imperial
    @State private var weightUnit: WeightUnit = .imperial
    @State private var isLoadingHealthKit = false
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var healthKitService: HealthKitService
    
    enum HeightUnit {
        case imperial // ft/in
        case metric   // cm
    }
    
    enum WeightUnit {
        case imperial // lbs
        case metric   // kg
    }
    
    // Convert cm to feet/inches
    private func cmToImperial(_ cm: Int) -> (feet: Int, inches: Int) {
        let totalInches = Double(cm) / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        return (feet, inches)
    }
    
    // Convert feet/inches to cm
    private func imperialToCm(feet: Int, inches: Int) -> Int {
        let totalInches = Double(feet * 12 + inches)
        return Int(totalInches * 2.54)
    }
    
    // Convert kg to lbs
    private func kgToLbs(_ kg: Int) -> Int {
        return Int(Double(kg) * 2.20462)
    }
    
    // Convert lbs to kg
    private func lbsToKg(_ lbs: Int) -> Int {
        return Int(Double(lbs) / 2.20462)
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                    .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("Measurements")
                        .font(.system(size: 18, weight: .heavy))
                    
                    Spacer()
                    
                    Button("Save") {
                        saveData()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .fontWeight(.bold)
                    .clipShape(Capsule())
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Subtitle
                        Text("UPDATE YOUR STATS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                            .tracking(2)
                        
                        // Height Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Height")
                                    .font(.system(size: 20, weight: .heavy))
                                
                                Spacer()
                                
                                // Unit Toggle
                                HStack(spacing: 0) {
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            heightUnit = .imperial
                                        }
                                    } label: {
                                        Text("FT")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(heightUnit == .imperial ? .black : .gray)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 6)
                                            .background(heightUnit == .imperial ? Color.white : Color.clear)
                                            .clipShape(Capsule())
                                    }
                                    
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            heightUnit = .metric
                                        }
                                    } label: {
                                        Text("CM")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(heightUnit == .metric ? .black : .gray)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 6)
                                            .background(heightUnit == .metric ? Color.white : Color.clear)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(4)
                                .background(StepCompColors.cardBorder)
                                .clipShape(Capsule())
                            }
                            
                            // Height Picker
                            if heightUnit == .imperial {
                                HeightPickerImperial(selectedFeet: $selectedFeet, selectedInches: $selectedInches)
                            } else {
                                HeightPickerMetric(selectedCm: Binding(
                                    get: { imperialToCm(feet: selectedFeet, inches: selectedInches) },
                                    set: { cm in
                                        let (feet, inches) = cmToImperial(cm)
                                        selectedFeet = feet
                                        selectedInches = inches
                                    }
                                ))
                            }
                        }
                        .padding(24)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
                        
                        // Weight Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Weight")
                                    .font(.system(size: 20, weight: .heavy))
                                
                                Spacer()
                                
                                // Unit Toggle
                                HStack(spacing: 0) {
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            weightUnit = .imperial
                                        }
                                    } label: {
                                        Text("LBS")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(weightUnit == .imperial ? .black : .gray)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 6)
                                            .background(weightUnit == .imperial ? Color.white : Color.clear)
                                            .clipShape(Capsule())
                                    }
                                    
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            weightUnit = .metric
                                        }
                                    } label: {
                                        Text("KG")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(weightUnit == .metric ? .black : .gray)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 6)
                                            .background(weightUnit == .metric ? Color.white : Color.clear)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(4)
                                .background(StepCompColors.cardBorder)
                                .clipShape(Capsule())
                            }
                            
                            // Weight Picker
                            if weightUnit == .imperial {
                                WeightPickerImperial(selectedWeight: $selectedWeight)
                            } else {
                                WeightPickerMetric(selectedWeight: Binding(
                                    get: { lbsToKg(selectedWeight) },
                                    set: { kg in selectedWeight = kgToLbs(kg) }
                                ))
                            }
                        }
                        .padding(24)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
                        
                        // Footer Text
                        Text("These values are used for calculating calories burned and other health metrics accurately. Your data is private.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 16)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadSavedData()
            
            // Try to load from HealthKit if no saved data
            let height = UserDefaults.standard.integer(forKey: "userHeight")
            let weight = UserDefaults.standard.integer(forKey: "userWeight")
            if height == 0 || weight == 0 {
                Task {
                    await loadFromHealthKit()
                }
            }
        }
    }
    
    private func loadSavedData() {
        let heightCm = UserDefaults.standard.integer(forKey: "userHeight")
        let weightKg = UserDefaults.standard.integer(forKey: "userWeight")
        
        if heightCm > 0 {
            let (feet, inches) = cmToImperial(heightCm)
            selectedFeet = feet
            selectedInches = inches
        }
        
        if weightKg > 0 {
            selectedWeight = kgToLbs(weightKg)
        }
    }
    
    private func loadFromHealthKit() async {
        isLoadingHealthKit = true
        defer { isLoadingHealthKit = false }
        
        do {
            if let heightCm = try await healthKitService.getHeight() {
                let (feet, inches) = cmToImperial(Int(heightCm))
                selectedFeet = feet
                selectedInches = inches
            }
            
            if let weightKg = try await healthKitService.getWeight() {
                selectedWeight = kgToLbs(Int(weightKg))
            }
        } catch {
            print("⚠️ Failed to load from HealthKit: \(error)")
        }
    }
    
    private func saveData() {
        let heightCm = imperialToCm(feet: selectedFeet, inches: selectedInches)
        let weightKg = lbsToKg(selectedWeight)
        
        onSave(heightCm, weightKg)
        dismiss()
    }
}

// MARK: - Height Picker (Imperial - Feet/Inches)

struct HeightPickerImperial: View {
    @Binding var selectedFeet: Int
    @Binding var selectedInches: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Highlight Rectangle
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow)
                    .frame(width: geometry.size.width - 32, height: 56)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                HStack(spacing: 0) {
                    // Feet Picker
                    VStack(spacing: 4) {
                        Picker("Feet", selection: $selectedFeet) {
                            ForEach(3...8, id: \.self) { foot in
                                Text("\(foot)")
                                    .font(.system(size: 32, weight: .black))
                                    .tag(foot)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: geometry.size.width / 2 - 16, height: 192)
                        .compositingGroup()
                        .clipped()
                        
                        Text("ft")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.gray)
                    }
                    
                    // Inches Picker
                    VStack(spacing: 4) {
                        Picker("Inches", selection: $selectedInches) {
                            ForEach(0...11, id: \.self) { inch in
                                Text("\(inch)")
                                    .font(.system(size: 32, weight: .black))
                                    .tag(inch)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: geometry.size.width / 2 - 16, height: 192)
                        .compositingGroup()
                        .clipped()
                        
                        Text("in")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: geometry.size.width, height: 192)
            }
        }
        .frame(height: 240)
    }
}

// MARK: - Height Picker (Metric - CM)

struct HeightPickerMetric: View {
    @Binding var selectedCm: Int
    
    var body: some View {
        ZStack {
            // Highlight Rectangle
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow)
                .frame(height: 56)
                .padding(.horizontal, 16)
            
            HStack {
                Picker("Height", selection: $selectedCm) {
                    ForEach(120...220, id: \.self) { cm in
                        Text("\(cm)")
                            .font(.system(size: selectedCm == cm ? 32 : 24, weight: selectedCm == cm ? .black : .bold))
                            .foregroundColor(selectedCm == cm ? .black : .gray.opacity(0.3))
                            .tag(cm)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 120, height: 192)
                .clipped()
                
                Text("cm")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.gray)
                    .offset(x: -20)
            }
        }
        .frame(height: 192)
    }
}

// MARK: - Weight Picker (Imperial - LBS)

struct WeightPickerImperial: View {
    @Binding var selectedWeight: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Highlight Rectangle
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow)
                    .frame(width: geometry.size.width - 32, height: 56)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                HStack(spacing: 8) {
                    Picker("Weight", selection: $selectedWeight) {
                        ForEach(80...400, id: \.self) { lbs in
                            Text("\(lbs)")
                                .font(.system(size: 32, weight: .black))
                                .tag(lbs)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: geometry.size.width - 80, height: 192)
                    .compositingGroup()
                    .clipped()
                    
                    Text("lbs")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(.gray)
                        .padding(.trailing, 16)
                }
                .frame(width: geometry.size.width, height: 192)
            }
        }
        .frame(height: 240)
    }
}

// MARK: - Weight Picker (Metric - KG)

struct WeightPickerMetric: View {
    @Binding var selectedWeight: Int
    
    var body: some View {
        ZStack {
            // Highlight Rectangle
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow)
                .frame(height: 56)
                .padding(.horizontal, 16)
            
            HStack {
                Picker("Weight", selection: $selectedWeight) {
                    ForEach(35...180, id: \.self) { kg in
                        Text("\(kg)")
                            .font(.system(size: selectedWeight == kg ? 32 : 24, weight: selectedWeight == kg ? .black : .bold))
                            .foregroundColor(selectedWeight == kg ? .black : .gray.opacity(0.3))
                            .tag(kg)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 140, height: 192)
                .clipped()
                
                Text("kg")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.gray)
                    .offset(x: -20)
            }
        }
        .frame(height: 192)
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
                            .foregroundColor(StepCompColors.primary)
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
                            .background(StepCompColors.primary)
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
                                        .stroke(StepCompColors.cardBorder, lineWidth: 12)
                                        .frame(width: 192, height: 192)
                                    
                                    // Progress arc
                                    Circle()
                                        .trim(from: 0, to: progressPercentage)
                                        .stroke(StepCompColors.primary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
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
                                            .foregroundColor(StepCompColors.primary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(StepCompColors.primary.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                    
                                    // Slider
                                    Slider(value: $sliderValue, in: 2000...25000, step: 500)
                                        .tint(StepCompColors.primary)
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
                            .background(StepCompColors.surfaceElevated)
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
                                        primaryColor: StepCompColors.primary
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
    let primaryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: preset.icon)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .black : primaryColor)
                
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
            .background(isSelected ? primaryColor : Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? primaryColor : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? primaryColor.opacity(0.3) : Color.clear, radius: 8)
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

