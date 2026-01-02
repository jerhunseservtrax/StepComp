//
//  DashboardViewModel.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var activeChallenges: [Challenge] = []
    @Published var todaySteps: Int = 0
    @Published var weeklySteps: Int = 0
    @Published var caloriesBurned: Int = 0
    @Published var distanceKm: Double = 0.0
    @Published var currentStreak: Int = 0
    
    var distanceMiles: Double {
        // Convert km to miles (1 km = 0.621371 miles)
        return distanceKm * 0.621371
    }
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var challengeService: ChallengeService
    private var healthKitService: HealthKitService
    private var stepSyncService: StepSyncService?
    private var userId: String
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init(
        challengeService: ChallengeService,
        healthKitService: HealthKitService,
        userId: String
    ) {
        self.challengeService = challengeService
        self.healthKitService = healthKitService
        self.stepSyncService = StepSyncService(healthKitService: healthKitService)
        self.userId = userId
        
        if !userId.isEmpty {
            loadData()
            startAutoRefresh()
        }
    }
    
    deinit {
        stopAutoRefresh()
    }
    
    func updateServices(challengeService: ChallengeService, healthKitService: HealthKitService, userId: String) {
        self.challengeService = challengeService
        self.healthKitService = healthKitService
        self.stepSyncService = StepSyncService(healthKitService: healthKitService)
        self.userId = userId
        loadData()
    }
    
    func refreshChallenges() async {
        // Force refresh challenges from Supabase
        #if canImport(Supabase)
        await challengeService.refreshChallenges()
        #endif
        await loadChallenges()
    }
    
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            await loadChallenges()
            await loadStepData()
            isLoading = false
        }
    }
    
    private func loadChallenges() async {
        // Ensure challenges are loaded from Supabase first
        #if canImport(Supabase)
        await challengeService.refreshChallenges()
        #endif
        activeChallenges = challengeService.getActiveChallenges(userId: userId)
        print("📊 DashboardViewModel: Loaded \(activeChallenges.count) active challenges for user \(userId)")
    }
    
    private func loadStepData() async {
        // Ensure HealthKit is initialized and check authorization
        _ = healthKitService.isHealthKitAvailable
        healthKitService.checkAuthorizationStatus()
        
        guard healthKitService.isAuthorized else {
            // Set default values when HealthKit is not authorized
            print("⚠️ HealthKit not authorized, using default values")
            todaySteps = 0
            weeklySteps = 0
            caloriesBurned = 0
            distanceKm = 0.0
            currentStreak = 0
            return
        }
        
        do {
            print("🔄 Loading HealthKit data...")
            todaySteps = try await healthKitService.getTodaySteps()
            print("✅ Today's steps: \(todaySteps)")
            
            let calendar = Calendar.current
            let now = Date()
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            
            let weeklyStats = try await healthKitService.getSteps(from: weekAgo, to: now)
            weeklySteps = weeklyStats.reduce(0) { $0 + $1.steps }
            print("✅ Weekly steps: \(weeklySteps)")
            
            // Calculate derived metrics
            // Approximate: 1 step ≈ 0.0008 km, 1 step ≈ 0.04 kcal
            distanceKm = Double(todaySteps) * 0.0008
            caloriesBurned = Int(Double(todaySteps) * 0.04)
            
            // Calculate streak (simplified - would need actual day-by-day data)
            currentStreak = calculateStreak(from: weeklyStats)
            print("✅ Streak: \(currentStreak) days")
            
            // Sync steps to Supabase profile and challenges
            // Note: Edge Function derives userId from JWT (secure!)
            if !userId.isEmpty, let stepSyncService = stepSyncService {
                await stepSyncService.syncAll(challengeService: challengeService)
            }
        } catch {
            print("⚠️ Error loading HealthKit data: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            // Set default values on error
            todaySteps = 0
            weeklySteps = 0
            caloriesBurned = 0
            distanceKm = 0.0
            currentStreak = 0
        }
    }
    
    private func calculateStreak(from stats: [StepStats]) -> Int {
        // Simplified streak calculation
        // In a real implementation, this would check consecutive days with steps > 0
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        
        // Check today first
        if let todayStat = stats.first(where: { calendar.isDate($0.date, inSameDayAs: today) }),
           todayStat.steps > 0 {
            streak = 1
            
            // Check previous days
            for i in 1..<30 { // Check up to 30 days back
                if let date = calendar.date(byAdding: .day, value: -i, to: today),
                   let stat = stats.first(where: { calendar.isDate($0.date, inSameDayAs: date) }),
                   stat.steps > 0 {
                    streak += 1
                } else {
                    // Break in streak
                    break
                }
            }
        }
        
        return max(streak, 0)
    }
    
    func refresh() {
        loadData()
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

