//
//  SettingsView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Supabase

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
        .background(FitCompColors.background.ignoresSafeArea())
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
