//
//  WorkoutProgressView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 2/17/26.
//

import SwiftUI

struct WorkoutProgressView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @ObservedObject var unitManager = UnitPreferenceManager.shared
    @EnvironmentObject private var healthKitService: HealthKitService
    @State private var bodyWeightLbs: Int = 0
    @State private var todaySteps: Int = 0
    @State private var refreshTimer: Timer?
    
    private static func kgToLbs(_ kg: Int) -> Int {
        guard kg > 0 else { return 0 }
        return Int((Double(kg) * 2.20462).rounded())
    }
    
    /// Auto-calculated 1RMs for squat, bench, deadlift from completed workout sets (Brzycki formula).
    private var bigThree1RMs: (squat: Double?, bench: Double?, deadlift: Double?) {
        viewModel.getBigThreeEstimated1RMs()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Estimated 1RM Section (all three lifts)
            estimated1RMSection
            
            // Body weight & steps section (auto-refreshed)
            bodyWeightAndStepsSection
            
            // Consistency Section
            consistencySection
        }
    }
    
    private var estimated1RMSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ESTIMATED 1RM")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(StepCompColors.textSecondary.opacity(0.6))
                .tracking(1.2)
            
            Text("From your logged sets (weight × reps). Updates as you complete workouts.")
                .font(.system(size: 12))
                .foregroundColor(StepCompColors.textSecondary.opacity(0.8))
            
            VStack(spacing: 0) {
                bigThreeRow(label: "Squat", value: bigThree1RMs.squat)
                Divider().padding(.leading, 16)
                bigThreeRow(label: "Bench", value: bigThree1RMs.bench)
                Divider().padding(.leading, 16)
                bigThreeRow(label: "Deadlift", value: bigThree1RMs.deadlift)
            }
            .padding(16)
            .background(StepCompColors.textSecondary.opacity(0.05))
            .cornerRadius(16)
        }
        .padding(20)
        .background(StepCompColors.textSecondary.opacity(0.05))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(StepCompColors.textSecondary.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func bigThreeRow(label: String, value: Double?) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(StepCompColors.textPrimary)
            Spacer()
            if let value = value, value > 0 {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    // value is in kg, convert to display unit
                    let displayWeight = unitManager.convertWeightFromStorage(value)
                    let weightStr = displayWeight.truncatingRemainder(dividingBy: 1) == 0
                        ? String(Int(displayWeight))
                        : String(format: "%.1f", displayWeight)
                    Text(weightStr)
                        .font(.system(size: 20, weight: .black))
                        .italic()
                        .foregroundColor(StepCompColors.primary)
                    Text(unitManager.weightUnit.lowercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(StepCompColors.textSecondary)
                }
            } else {
                Text("—")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(StepCompColors.textSecondary.opacity(0.6))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }
    
    private var bodyWeightAndStepsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(StepCompColors.textSecondary.opacity(0.6))
                .tracking(1.2)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                // Body Weight Card
                VStack(alignment: .leading, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(StepCompColors.buttonTextOnPrimary.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(StepCompColors.buttonTextOnPrimary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("BODY WEIGHT")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(StepCompColors.buttonTextOnPrimary.opacity(0.4))
                            .tracking(0.5)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(bodyWeightLbs)")
                                .font(.system(size: 28, weight: .black))
                                .italic()
                            Text("lbs")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(StepCompColors.buttonTextOnPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .padding(16)
                .background(StepCompColors.primary)
                .cornerRadius(24)
                .shadow(color: StepCompColors.primary.opacity(0.15), radius: 12, x: 0, y: 6)
                
                // Today's Steps Card
                VStack(alignment: .leading, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "figure.walk")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(StepCompColors.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("STEPS")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.gray.opacity(0.5))
                            .tracking(0.5)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(todaySteps.formatted())
                                .font(.system(size: 28, weight: .black))
                                .italic()
                        }
                        .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .padding(16)
                .background(Color.black)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
            }
        }
        .onAppear {
            refreshBodyWeightAndSteps()
            startRefreshTimer()
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }
    
    private func refreshBodyWeightAndSteps() {
        // Body weight: UserDefaults (kg) first, then HealthKit fallback if not set
        let storedKg = UserDefaults.standard.integer(forKey: "userWeight")
        if storedKg > 0 {
            bodyWeightLbs = Self.kgToLbs(storedKg)
        } else {
            Task { @MainActor in
                if let kg = try? await healthKitService.getWeight() {
                    bodyWeightLbs = Self.kgToLbs(Int(kg))
                }
            }
        }
        // Steps: HealthKit — use same definition as Home (full calendar day) so numbers match
        Task { @MainActor in
            todaySteps = (try? await healthKitService.getSteps(for: Date())) ?? 0
        }
    }
    
    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            refreshBodyWeightAndSteps()
        }
        RunLoop.main.add(refreshTimer!, forMode: .common)
    }
    
    private var consistencySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("CONSISTENCY")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(StepCompColors.textSecondary.opacity(0.6))
                    .tracking(1.2)
                
                Spacer()
                
                Text("LAST 90 DAYS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(StepCompColors.textSecondary.opacity(0.4))
            }
            
            // Heatmap Grid
            ConsistencyHeatmapView(consistencyData: viewModel.getConsistencyData())
            
            // Stats
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT STREAK")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(StepCompColors.textSecondary.opacity(0.6))
                        .tracking(0.5)
                    
                    Text("\(viewModel.getCurrentStreak()) Days")
                        .font(.system(size: 18, weight: .black))
                        .italic()
                        .foregroundColor(StepCompColors.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Rectangle()
                    .fill(StepCompColors.textSecondary.opacity(0.2))
                    .frame(width: 1)
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL SESSIONS")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(StepCompColors.textSecondary.opacity(0.6))
                        .tracking(0.5)
                    
                    Text("\(viewModel.getTotalSessions())")
                        .font(.system(size: 18, weight: .black))
                        .italic()
                        .foregroundColor(StepCompColors.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
            }
        }
        .padding(20)
        .background(StepCompColors.textSecondary.opacity(0.05))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(StepCompColors.textSecondary.opacity(0.1), lineWidth: 1)
        )
    }
    
}

struct ConsistencyHeatmapView: View {
    let consistencyData: [Date: Bool]
    
    private var sortedWeeks: [[Date?]] {
        let calendar = Calendar.current
        
        // Get all dates and sort them (oldest first)
        let sortedDates = consistencyData.keys.sorted()
        
        guard let oldestDate = sortedDates.first,
              let newestDate = sortedDates.last else { return [] }
        
        var weeks: [[Date?]] = []
        
        // Find the starting Sunday (or the oldest date's week start)
        let oldestWeekday = calendar.component(.weekday, from: oldestDate)
        let daysToSubtract = oldestWeekday - 1
        
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysToSubtract, to: oldestDate) else {
            return []
        }
        
        // Number of days we need to cover from startOfWeek through newestDate (inclusive)
        let daysToNewest = calendar.dateComponents([.day], from: startOfWeek, to: newestDate).day ?? 0
        let totalDaysToShow = daysToNewest + 1
        let numberOfWeeks = max(13, (totalDaysToShow + 6) / 7) // at least 13 weeks, or enough to reach today
        
        for weekOffset in 0..<numberOfWeeks {
            var week: [Date?] = []
            
            for dayInWeek in 0..<7 {
                let totalDaysOffset = (weekOffset * 7) + dayInWeek
                if let date = calendar.date(byAdding: .day, value: totalDaysOffset, to: startOfWeek) {
                    // Only include dates within our range
                    if date <= newestDate && date >= oldestDate {
                        week.append(date)
                    } else if date < oldestDate {
                        week.append(nil) // Pad before start
                    } else {
                        week.append(nil) // Pad after end
                    }
                } else {
                    week.append(nil)
                }
            }
            
            weeks.append(week)
        }
        
        return weeks
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 3) {
                ForEach(Array(sortedWeeks.enumerated()), id: \.offset) { weekIndex, week in
                    VStack(spacing: 3) {
                        ForEach(Array(week.enumerated()), id: \.offset) { dayIndex, date in
                            if let date = date {
                                let dateKey = Calendar.current.startOfDay(for: date)
                                let hasWorkout = consistencyData[dateKey] ?? false
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(hasWorkout ? StepCompColors.primary : StepCompColors.textSecondary.opacity(0.15))
                                    .frame(width: 12, height: 12)
                            } else {
                                Color.clear
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    WorkoutProgressView(viewModel: WorkoutViewModel.shared)
        .environmentObject(HealthKitService())
        .padding()
}
