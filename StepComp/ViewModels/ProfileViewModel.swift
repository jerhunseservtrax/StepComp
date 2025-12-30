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
    
    private var themeManager: ThemeManager?
    
    init(
        user: User,
        challengeService: ChallengeService,
        authService: AuthService
    ) {
        self.user = user
        self.challengeService = challengeService
        self.authService = authService
        
        loadStats()
        loadDarkModePreference()
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
    
    func updateServices(challengeService: ChallengeService, authService: AuthService) {
        self.challengeService = challengeService
        self.authService = authService
        loadStats()
    }
    
    func loadStats() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let userChallenges = challengeService.getUserChallenges(userId: user.id)
            totalChallenges = userChallenges.count
            totalSteps = user.totalSteps
            
            // Calculate derived stats
            caloriesBurned = Int(Double(totalSteps) * 0.04) // Approximate
            activeTimeHours = Int(Double(totalSteps) * 0.0001) // Approximate
            
            // Generate sample weekly data (would come from HealthKit in real app)
            weeklyActivityData = generateWeeklyData()
            monthlyActivityData = generateMonthlyData()
            // Ensure we have exactly 7 days of data
            if weeklyActivityData.count < 7 {
                weeklyActivityData = Array(weeklyActivityData.prefix(7))
                while weeklyActivityData.count < 7 {
                    weeklyActivityData.append(0)
                }
            }
            todaySteps = weeklyActivityData.isEmpty ? 0 : (weeklyActivityData.last ?? 0)
            
            // Load height and weight from UserDefaults (set by AuthService.loadUserProfile)
            // These are synced from the database when the user profile is loaded
            height = UserDefaults.standard.integer(forKey: "userHeight")
            if height == 0 { height = 175 } // Default
            weight = UserDefaults.standard.integer(forKey: "userWeight")
            if weight == 0 { weight = 68 } // Default
            memberSince = Calendar.current.component(.year, from: user.createdAt)
            
            isLoading = false
        }
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
}

