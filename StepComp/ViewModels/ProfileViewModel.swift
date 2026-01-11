//
//  ProfileViewModel.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import SwiftUI
import Combine // Required for @Published and ObservableObject

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User
    @Published var totalChallenges: Int = 0
    @Published var totalSteps: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // New properties for redesigned UI
    @Published var caloriesBurned: Int = 0
    @Published var activeTimeHours: Int = 0
    @Published var todaySteps: Int = 0
    @Published var weeklyActivityData: [Int] = []
    @Published var monthlyActivityData: [Int] = []
    @Published var selectedActivityPeriod: ActivityPeriod = .week
    @Published var isPublicProfile: Bool = true
    @Published var shareActivity: Bool = false
    @Published var dailyReminders: Bool = true
    @Published var isDarkMode: Bool = false
    @Published var height: Int = 175 // cm
    @Published var weight: Int = 68 // kg
    @Published var memberSince: Int = 2023
    
    enum ActivityPeriod {
        case week
        case month
    }
    
    // Settings properties
    @Published var currentStreak: Int = 42 // Days
    @Published var healthKitEnabled: Bool = false
    @Published var dailyRecap: Bool = true
    @Published var leaderboardAlerts: Bool = false
    @Published var motivationalNudges: Bool = true
    @Published var unitSystem: UnitSystem = .metric
    
    enum UnitSystem {
        case metric // KM
        case imperial // MI
    }
    
    var level: Int {
        // Calculate level based on total steps (simplified)
        return min(totalSteps / 10000 + 1, 50)
    }
    
    var badge: String {
        // Return "Step Master" as shown in design
        return "Step Master"
    }
    
    private var challengeService: ChallengeService
    private var authService: AuthService
    private var healthKitService: HealthKitService?
    
    private var themeManager: ThemeManager?
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init(
        user: User,
        challengeService: ChallengeService,
        authService: AuthService,
        healthKitService: HealthKitService? = nil
    ) {
        self.user = user
        self.challengeService = challengeService
        self.authService = authService
        self.healthKitService = healthKitService
        
        loadStats()
        loadDarkModePreference()
        startAutoRefresh()
    }
    
    deinit {
        stopAutoRefresh()
    }
    
    func setThemeManager(_ themeManager: ThemeManager) {
        self.themeManager = themeManager
        loadDarkModePreference()
    }
    
    private func loadDarkModePreference() {
        if let themeManager = themeManager {
            isDarkMode = themeManager.isDarkMode
        } else {
            // Fallback to UserDefaults if ThemeManager not set
            if let value = UserDefaults.standard.string(forKey: "appColorScheme") {
                isDarkMode = value == "dark"
            } else {
                isDarkMode = false
            }
        }
    }
    
    func toggleDarkMode() {
        isDarkMode.toggle()
        themeManager?.setColorScheme(isDarkMode ? .dark : .light)
    }
    
    func updateServices(challengeService: ChallengeService, authService: AuthService, healthKitService: HealthKitService? = nil) {
        self.challengeService = challengeService
        self.authService = authService
        self.healthKitService = healthKitService
        loadStats()
        // Restart auto-refresh with new healthKitService
        stopAutoRefresh()
        startAutoRefresh()
    }
    
    func loadStats() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let userChallenges = challengeService.getUserChallenges(userId: user.id)
            totalChallenges = userChallenges.count
            
            // Load HealthKit data if available
            if let healthKitService = healthKitService, healthKitService.isAuthorized {
                await loadHealthKitStats(healthKitService: healthKitService)
            } else {
                // Fallback to user's stored data
                totalSteps = user.totalSteps
                caloriesBurned = Int(Double(totalSteps) * 0.04)
                activeTimeHours = Int(Double(totalSteps) * 0.0001)
                weeklyActivityData = generateWeeklyData()
                monthlyActivityData = generateMonthlyData()
                todaySteps = 0
            }
            
            // Ensure we have exactly 7 days of data
            if weeklyActivityData.count < 7 {
                weeklyActivityData = Array(weeklyActivityData.prefix(7))
                while weeklyActivityData.count < 7 {
                    weeklyActivityData.append(0)
                }
            }
            
            // Load height and weight from UserDefaults (set by AuthService.loadUserProfile)
            height = UserDefaults.standard.integer(forKey: "userHeight")
            if height == 0 { height = 175 } // Default
            weight = UserDefaults.standard.integer(forKey: "userWeight")
            if weight == 0 { weight = 68 } // Default
            memberSince = Calendar.current.component(.year, from: user.createdAt)
            
            isLoading = false
        }
    }
    
    private func loadHealthKitStats(healthKitService: HealthKitService) async {
        // Ensure HealthKit is initialized and check authorization
        _ = healthKitService.isHealthKitAvailable
        healthKitService.checkAuthorizationStatus()
        
        guard healthKitService.isAuthorized else {
            print("⚠️ HealthKit not authorized in Profile, using fallback values")
            todaySteps = 0
            weeklyActivityData = generateWeeklyData()
            monthlyActivityData = generateMonthlyData()
            caloriesBurned = Int(Double(totalSteps) * 0.04)
            activeTimeHours = Int(Double(totalSteps) * 0.0001)
            currentStreak = 0
            return
        }
        
        do {
            print("🔄 Loading HealthKit data in Profile...")
            // Get today's steps
            todaySteps = try await healthKitService.getTodaySteps()
            print("✅ Today's steps: \(todaySteps)")
            
            // Get weekly stats for activity chart
            let calendar = Calendar.current
            let now = Date()
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            let weeklyStats = try await healthKitService.getSteps(from: weekAgo, to: now)
            
            // Convert to array format for chart (7 days)
            weeklyActivityData = Array(repeating: 0, count: 7)
            for stat in weeklyStats {
                let daysAgo = calendar.dateComponents([.day], from: stat.date, to: now).day ?? 0
                if daysAgo >= 0 && daysAgo < 7 {
                    weeklyActivityData[6 - daysAgo] = stat.steps
                }
            }
            
            // Get monthly stats (last 30 days)
            let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            let monthlyStats = try await healthKitService.getSteps(from: monthAgo, to: now)
            monthlyActivityData = Array(repeating: 0, count: 30)
            for stat in monthlyStats {
                let daysAgo = calendar.dateComponents([.day], from: stat.date, to: now).day ?? 0
                if daysAgo >= 0 && daysAgo < 30 {
                    monthlyActivityData[29 - daysAgo] = stat.steps
                }
            }
            
            // Calculate total steps (sum of all weekly stats + today)
            let weeklyTotal = weeklyStats.reduce(0) { $0 + $1.steps }
            totalSteps = max(weeklyTotal, user.totalSteps) // Use max of HealthKit data or stored total
            
            // Calculate derived stats from today's steps
            caloriesBurned = Int(Double(todaySteps) * 0.04) // Approximate: 1 step ≈ 0.04 kcal
            activeTimeHours = Int(Double(todaySteps) * 0.0001) // Approximate: 1 step ≈ 0.0001 hours
            
            // Calculate streak using monthly stats (more data for accurate streak)
            currentStreak = calculateStreak(from: monthlyStats, todaySteps: todaySteps)
            print("✅ Profile HealthKit data loaded - Total: \(totalSteps), Streak: \(currentStreak)")
            
            // Load height and weight from HealthKit if available
            await loadHeightWeightFromHealthKit(healthKitService: healthKitService)
        } catch {
            print("⚠️ Error loading HealthKit stats: \(error.localizedDescription)")
            // Fallback to stored data
            totalSteps = user.totalSteps
            caloriesBurned = Int(Double(totalSteps) * 0.04)
            activeTimeHours = Int(Double(totalSteps) * 0.0001)
            weeklyActivityData = generateWeeklyData()
            monthlyActivityData = generateMonthlyData()
            todaySteps = 0
        }
    }
    
    private func loadHeightWeightFromHealthKit(healthKitService: HealthKitService) async {
        // Only load if user has default values (hasn't set custom height/weight)
        let currentHeight = UserDefaults.standard.integer(forKey: "userHeight")
        let currentWeight = UserDefaults.standard.integer(forKey: "userWeight")
        
        // Only auto-load if user hasn't set custom values
        guard currentHeight == 0 || currentHeight == 175, currentWeight == 0 || currentWeight == 68 else {
            // User already has custom values, don't overwrite
            return
        }
        
        do {
            // Try to load height from HealthKit
            if let heightInCm = try await healthKitService.getHeight() {
                let heightInt = Int(heightInCm)
                if heightInt > 0 {
                    print("✅ Loaded height from HealthKit: \(heightInt) cm")
                    height = heightInt
                    UserDefaults.standard.set(heightInt, forKey: "userHeight")
                    // Update in database
                    await authService.updateUserHeightWeight(height: heightInt, weight: weight)
                }
            }
            
            // Try to load weight from HealthKit
            if let weightInKg = try await healthKitService.getWeight() {
                let weightInt = Int(weightInKg)
                if weightInt > 0 {
                    print("✅ Loaded weight from HealthKit: \(weightInt) kg")
                    weight = weightInt
                    UserDefaults.standard.set(weightInt, forKey: "userWeight")
                    // Update in database
                    await authService.updateUserHeightWeight(height: height, weight: weightInt)
                }
            }
        } catch {
            print("⚠️ Error loading height/weight from HealthKit: \(error.localizedDescription)")
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
            
            // Check previous days
            for i in 1..<30 {
                guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { break }
                let daySteps = stepsForDate(date)
                
                if daySteps >= dailyGoal {
                    streak += 1
                } else {
                    break
                }
            }
        } else {
            // Today doesn't meet goal yet - count streak from yesterday
            for i in 1..<30 {
                guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { break }
                let daySteps = stepsForDate(date)
                
                if daySteps >= dailyGoal {
                    streak += 1
                } else {
                    break
                }
            }
        }
        
        return max(streak, 0)
    }
    
    private func generateWeeklyData() -> [Int] {
        // Generate sample data for the week (matches HTML design percentages)
        // Heights: 45%, 65%, 30%, 85%, 100%, 20%, 10%
        let maxSteps = 10000
        return [
            Int(Double(maxSteps) * 0.45), // M
            Int(Double(maxSteps) * 0.65), // T
            Int(Double(maxSteps) * 0.30), // W
            Int(Double(maxSteps) * 0.85), // T
            maxSteps, // F (highlighted)
            Int(Double(maxSteps) * 0.20), // S
            Int(Double(maxSteps) * 0.10)  // S
        ]
    }
    
    private func generateMonthlyData() -> [Int] {
        // Generate sample data for the month (30 days)
        return (0..<30).map { _ in Int.random(in: 2000...12000) }
    }
    
    func updateAccountInfo(height: Int, weight: Int) {
        self.height = height
        self.weight = weight
        UserDefaults.standard.set(height, forKey: "userHeight")
        UserDefaults.standard.set(weight, forKey: "userWeight")
        
        // Update in Supabase database
        Task {
            await authService.updateUserHeightWeight(height: height, weight: weight)
        }
    }
    
    func updateProfile(firstName: String, lastName: String, avatarURL: String?) {
        var updatedUser = user
        updatedUser.firstName = firstName
        updatedUser.lastName = lastName
        updatedUser.avatarURL = avatarURL
        
        user = updatedUser
        authService.updateUser(updatedUser)
    }
    
    func refresh() {
        loadStats()
    }
    
    // MARK: - Auto Refresh
    
    private func startAutoRefresh() {
        // Refresh every 60 seconds to keep HealthKit data up-to-date
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let healthKitService = self.healthKitService, healthKitService.isAuthorized else { return }
                print("🔄 Auto-refreshing HealthKit data in Profile...")
                await self.loadHealthKitStats(healthKitService: healthKitService)
            }
        }
        // Ensure timer runs on main thread
        if let timer = refreshTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    nonisolated private func stopAutoRefresh() {
        Task { @MainActor in
            refreshTimer?.invalidate()
            refreshTimer = nil
            cancellables.removeAll()
        }
    }
    
    func pauseAutoRefresh() {
        stopAutoRefresh()
    }
    
    func resumeAutoRefresh() {
        if refreshTimer == nil {
            startAutoRefresh()
        }
    }
}

