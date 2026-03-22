//
//  DashboardViewModel.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import SwiftUI
import Combine

struct DashboardMetricPair {
    let titleA: String
    let valueA: String
    let titleB: String
    let valueB: String
}

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var activeChallenges: [Challenge] = []
    @Published var todaySteps: Int = 0
    @Published var weeklySteps: Int = 0
    @Published var caloriesBurned: Int = 0
    @Published var distanceKm: Double = 0.0
    @Published var currentStreak: Int = 0
    @Published var weeklyScopeMetricPairs: [DashboardMetricPair] = []
    @Published var longTermScopeMetricPairs: [DashboardMetricPair] = []
    
    var distanceMiles: Double {
        // Convert km to miles (1 km = 0.621371 miles)
        return distanceKm * 0.621371
    }
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var challengeService: ChallengeService?
    private var healthKitService: HealthKitService?
    private var stepSyncService: StepSyncService?
    private var notificationService = StepGoalNotificationService.shared
    private var celebrationManager = GoalCelebrationManager.shared
    private var userId: String
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var lastCheckedSteps: Int = 0
    private var lastCheckedDate: Date?
    private var isLoadingData = false
    
    init(userId: String = "") {
        self.userId = userId
        
        if !userId.isEmpty {
            startAutoRefresh()
        }
    }
    
    deinit {
        // Immediately invalidate timer on the current thread
        // Don't use async/await in deinit as it can create retain cycles
        refreshTimer?.invalidate()
        refreshTimer = nil
        cancellables.removeAll()
    }
    
    func updateServices(challengeService: ChallengeService, healthKitService: HealthKitService, userId: String) {
        self.challengeService = challengeService
        self.healthKitService = healthKitService
        self.stepSyncService = StepSyncService(healthKitService: healthKitService)
        self.userId = userId
        loadData()
    }
    
    func refreshChallenges() async {
        guard let challengeService else { return }
        // Force refresh challenges from Supabase
        #if canImport(Supabase)
        await challengeService.refreshChallenges()
        #endif
        await loadChallenges()
    }
    
    func loadData() {
        guard !isLoadingData else { return }
        guard !userId.isEmpty,
              challengeService != nil,
              healthKitService != nil else {
            isLoading = false
            return
        }
        
        isLoadingData = true
        isLoading = true
        errorMessage = nil
        
        Task {
            await loadChallenges()
            await loadStepData()
            isLoading = false
            isLoadingData = false
        }
    }
    
    private func loadChallenges() async {
        guard let challengeService else { return }
        // Ensure challenges are loaded from Supabase first
        #if canImport(Supabase)
        await challengeService.refreshChallenges()
        #endif
        activeChallenges = challengeService.getActiveChallenges(userId: userId)
        print("📊 DashboardViewModel: Loaded \(activeChallenges.count) active challenges for user \(userId)")
        
        // Debug logging for "Test group" challenge
        for challenge in activeChallenges {
            if challenge.name == "Test group" || challenge.name.contains("Test group") {
                print("🔍 [DashboardViewModel] 'Test group' challenge:")
                print("  → Participant IDs count: \(challenge.participantIds.count)")
                print("  → Participant IDs: \(challenge.participantIds)")
                print("  → Start Date: \(challenge.startDate)")
                print("  → End Date: \(challenge.endDate)")
                print("  → Days Remaining: \(challenge.daysRemaining)")
                print("  → Is Ongoing: \(challenge.isOngoing)")
            }
        }
    }
    
    private func loadStepData() async {
        guard let healthKitService else { return }
        // Ensure HealthKit is initialized and check authorization
        _ = healthKitService.isHealthKitAvailable
        healthKitService.checkAuthorizationStatus()
        
        guard healthKitService.isAuthorized else {
            // Set default values when HealthKit is not authorized
            print("⚠️ HealthKit not authorized, using default values")
            todaySteps = 0
            lastCheckedSteps = 0
            weeklySteps = 0
            caloriesBurned = 0
            distanceKm = 0.0
            currentStreak = 0
            return
        }
        
        do {
            print("🔄 Loading HealthKit data...")
            // Use getSteps(for: Date()) so today's steps match Home date picker and Workout page (same HealthKit query)
            let newSteps = try await healthKitService.getSteps(for: Date())
            let today = Date()
            let calendar = Calendar.current
            let _ = calendar.startOfDay(for: today)
            
            // Reset tracking if it's a new day
            if let lastDate = lastCheckedDate, !calendar.isDate(lastDate, inSameDayAs: today) {
                lastCheckedSteps = 0
            }
            
            // Only check milestones if steps increased (to avoid duplicate notifications)
            if newSteps > lastCheckedSteps {
                let previousSteps = todaySteps
                todaySteps = newSteps
                lastCheckedSteps = newSteps
                lastCheckedDate = today
                
                // Get daily goal
                var dailyGoal = UserDefaults.standard.integer(forKey: "dailyStepGoal")
                if dailyGoal <= 0 {
                    dailyGoal = 10000 // Default goal if not set
                }
                
                // Check for milestone notifications
                notificationService.checkMilestones(currentSteps: todaySteps, dailyGoal: dailyGoal)
                
                // Check for goal celebration (full-screen takeover)
                celebrationManager.checkForCelebration(
                    previousSteps: previousSteps,
                    currentSteps: todaySteps,
                    dailyGoal: dailyGoal
                )
            } else {
                todaySteps = newSteps
                if lastCheckedDate == nil {
                    lastCheckedDate = today
                }
            }
            
            print("✅ Today's steps: \(todaySteps)")
            
            let now = Date()
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            
            let weeklyStats = try await healthKitService.getSteps(from: weekAgo, to: now)
            weeklySteps = weeklyStats.reduce(0) { $0 + $1.steps }
            print("✅ Weekly steps: \(weeklySteps)")
            
            // Calculate derived metrics
            // Approximate: 1 step ≈ 0.0008 km, 1 step ≈ 0.04 kcal
            distanceKm = Double(todaySteps) * 0.0008
            caloriesBurned = Int(Double(todaySteps) * 0.04)
            
            // Calculate streak using the daily goal
            currentStreak = calculateStreak(from: weeklyStats, todaySteps: todaySteps)
            print("✅ Streak: \(currentStreak) days")
            
            // Sync steps to Supabase profile and challenges
            // Note: Edge Function derives userId from JWT (secure!)
            if !userId.isEmpty,
               let stepSyncService = stepSyncService,
               let challengeService = challengeService {
                await stepSyncService.syncAll(challengeService: challengeService)
            }
        } catch {
            print("⚠️ Error loading HealthKit data: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            // Set default values on error
            todaySteps = 0
            lastCheckedSteps = 0
            weeklySteps = 0
            caloriesBurned = 0
            distanceKm = 0.0
            currentStreak = 0
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
            if calendar.isDate(date, inSameDayAs: today) {
                return todaySteps
            }
            if let stat = stats.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                return stat.steps
            }
            return 0
        }
        
        // Check if today meets the goal
        let todayMeetsGoal = todaySteps >= dailyGoal
        
        if todayMeetsGoal {
            streak = 1
            
            // Check previous days
            for i in 1..<30 {
                guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { break }
                if stepsForDate(date) >= dailyGoal {
                    streak += 1
                } else {
                    break
                }
            }
        } else {
            // Today doesn't meet goal - count streak from yesterday
            for i in 1..<30 {
                guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { break }
                if stepsForDate(date) >= dailyGoal {
                    streak += 1
                } else {
                    break
                }
            }
        }
        
        return max(streak, 0)
    }
    
    func refresh() {
        loadData()
    }

    func computeScopeMetrics(weeklyStepData: [Int], dailyGoal: Int) {
        let workoutVm = WorkoutViewModel.shared
        let thisWeekWorkouts = workoutVm.completedSessions.filter {
            Calendar.current.dateComponents([.day], from: $0.endTime, to: Date()).day ?? 999 <= 7
        }.count
        let avgSteps = weeklyStepData.isEmpty ? 0 : weeklyStepData.reduce(0, +) / weeklyStepData.count
        let consistency = weeklyStepData.isEmpty
            ? 0
            : Int((Double(weeklyStepData.filter { $0 >= dailyGoal }.count) / Double(weeklyStepData.count) * 100).rounded())
        let weightTrend = WeightViewModel.shared.getEntriesForGraph(days: 7)
        let weightChange: Double = {
            guard let first = weightTrend.first?.weightKg, let last = weightTrend.last?.weightKg else { return 0 }
            return last - first
        }()

        weeklyScopeMetricPairs = [
            DashboardMetricPair(titleA: "Workouts", valueA: "\(thisWeekWorkouts)", titleB: "Avg Steps", valueB: "\(avgSteps)"),
            DashboardMetricPair(titleA: "Consistency", valueA: "\(consistency)%", titleB: "Weight Trend", valueB: String(format: "%+.1fkg", weightChange))
        ]

        let store = ComprehensiveMetricsStore.shared
        let strength = store.computeStrengthSnapshot(sessions: workoutVm.completedSessions)
        let scores = store.computeEngagementScores(
            sessions: workoutVm.completedSessions,
            stepHistory: [],
            strength: strength,
            cardio: CardioMetricSnapshot(averagePaceMinPerKm: nil, speedImprovementPercent: 0, totalZoneMinutes: 0, vo2Max: nil)
        )
        let body = store.computeBodySnapshot(
            weightEntries: WeightViewModel.shared.entries,
            heightCm: nil
        )

        longTermScopeMetricPairs = [
            DashboardMetricPair(
                titleA: "Strength 1RM",
                valueA: "\(Int(strength.estimatedOneRM.rounded()))kg",
                titleB: "Performance",
                valueB: "\(scores.performanceScore)"
            ),
            DashboardMetricPair(
                titleA: "Overload",
                valueA: "\(strength.overloadSuccessRate)%",
                titleB: "Lean Mass",
                valueB: body.leanMassKg.map { String(format: "%.1fkg", $0) } ?? "-"
            )
        ]
    }
    
    // MARK: - Auto Refresh
    
    private func startAutoRefresh() {
        // Refresh every 60 seconds to keep data up-to-date from HealthKit
        // This balances real-time updates with battery efficiency
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, !self.userId.isEmpty else { return }
                print("🔄 Auto-refreshing HealthKit data...")
                await self.loadStepData()
            }
        }
        // Ensure timer runs on main thread and continues during scrolling
        if let timer = refreshTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        cancellables.removeAll()
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

