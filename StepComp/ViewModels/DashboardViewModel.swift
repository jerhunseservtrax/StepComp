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
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var challengeService: ChallengeService
    private var healthKitService: HealthKitService
    private var userId: String
    
    init(
        challengeService: ChallengeService,
        healthKitService: HealthKitService,
        userId: String
    ) {
        self.challengeService = challengeService
        self.healthKitService = healthKitService
        self.userId = userId
        
        if !userId.isEmpty {
            loadData()
        }
    }
    
    func updateServices(challengeService: ChallengeService, healthKitService: HealthKitService, userId: String) {
        self.challengeService = challengeService
        self.healthKitService = healthKitService
        self.userId = userId
        loadData()
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
        activeChallenges = challengeService.getActiveChallenges(userId: userId)
    }
    
    private func loadStepData() async {
        guard healthKitService.isAuthorized else {
            // Set default values when HealthKit is not authorized
            caloriesBurned = 0
            distanceKm = 0.0
            currentStreak = 0
            return
        }
        
        do {
            todaySteps = try await healthKitService.getTodaySteps()
            
            let calendar = Calendar.current
            let now = Date()
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            
            let weeklyStats = try await healthKitService.getSteps(from: weekAgo, to: now)
            weeklySteps = weeklyStats.reduce(0) { $0 + $1.steps }
            
            // Calculate derived metrics
            // Approximate: 1 step ≈ 0.0008 km, 1 step ≈ 0.04 kcal
            distanceKm = Double(todaySteps) * 0.0008
            caloriesBurned = Int(Double(todaySteps) * 0.04)
            
            // Calculate streak (simplified - would need actual day-by-day data)
            currentStreak = calculateStreak(from: weeklyStats)
        } catch {
            errorMessage = error.localizedDescription
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
}

