//
//  MetricsViewModel.swift
//  FitComp
//

import Foundation
import Combine

@MainActor
final class MetricsViewModel: ObservableObject {
    @Published var selectedTimePeriod: MetricsTimePeriod = .weeks
    @Published var workoutScope: MetricsDetailScope = .monthly
    @Published var stepScope: MetricsDetailScope = .monthly

    @Published var metricsSummary: MetricsSummary?
    @Published var workoutHistory: [WorkoutHistoryPoint] = []
    @Published var weightHistory: [WeightHistoryPoint] = []
    @Published var stepHistory: [StepHistoryPoint] = []
    @Published var workoutBars: [MetricBarPoint] = []
    @Published var stepBars: [MetricBarPoint] = []
    @Published var yearlySteps: [YearMetricPoint] = []
    @Published var archivedChallenges: [Challenge] = []
    @Published var activeChallenges: [Challenge] = []
    @Published var challengeWins: Int = 0
    @Published var challengeLosses: Int = 0
    @Published var readiness: ReadinessResult?
    @Published var performance: PerformancePillarData?
    @Published var recovery: RecoveryPillarData?
    @Published var body: BodyPillarData?
    @Published var consistency: ConsistencyPillarData?
    @Published var insightsPillar: InsightsPillarData?
    @Published var killerScores: KillerScores?
    @Published var weeklyReport: WeeklyReport?
    @Published var strengthSnapshot = StrengthMetricSnapshot(
        totalVolume: 0,
        estimatedOneRM: 0,
        overloadSuccessRate: 0,
        strongestExercise: nil,
        personalRecords: [],
        muscleGroupVolume: []
    )

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let metricsService: MetricsService
    private let comprehensiveStore: ComprehensiveMetricsStore
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    private var readinessHistory: [Int] = []

    init(metricsService: MetricsService? = nil) {
        self.metricsService = metricsService ?? MetricsService.shared
        self.comprehensiveStore = ComprehensiveMetricsStore.shared
    }

    func loadData(
        challengeService: ChallengeService,
        healthKitService: HealthKitService,
        currentUserId: String?
    ) async {
        isLoading = true
        errorMessage = nil

        let lookbackDays = selectedTimePeriod.lookbackDays
        async let summaryTask = metricsService.fetchMetricsSummary(days: lookbackDays)
        async let workoutTask = metricsService.fetchWorkoutHistory(days: lookbackDays)
        async let weightTask = metricsService.fetchWeightHistory(days: lookbackDays)
        async let stepTask = loadStepHistory(healthKitService: healthKitService, days: lookbackDays)

        let summary = await summaryTask
        let workouts = await workoutTask
        let weights = await weightTask
        let steps = await stepTask

        metricsSummary = summary
        workoutHistory = workouts
        weightHistory = weights
        stepHistory = steps
        workoutBars = aggregateWorkouts(workouts, period: selectedTimePeriod)
        stepBars = aggregateSteps(steps, period: selectedTimePeriod)
        yearlySteps = aggregateYearlySteps(steps)
        mapChallengeStats(challengeService: challengeService, currentUserId: currentUserId)
        await loadPillarMetrics(healthKitService: healthKitService)
        isLoading = false
    }

    func addNutritionLog(calories: Int, proteinG: Int, carbsG: Int, fatG: Int, waterMl: Int) {
        let log = NutritionLog(
            id: UUID(),
            loggedAt: Date(),
            calories: calories,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            waterMl: waterMl
        )
        comprehensiveStore.addNutritionLog(
            calories: calories,
            proteinG: proteinG,
            carbsG: carbsG,
            fatG: fatG,
            waterMl: waterMl
        )
        Task.detached(priority: .utility) {
            await MetricsService.shared.syncNutritionLog(log)
        }
    }

    func addBodyMetric(bodyFatPercent: Double?, waistCm: Double?) {
        comprehensiveStore.addBodyMetric(bodyFatPercent: bodyFatPercent, waistCm: waistCm)
        Task.detached(priority: .utility) {
            await MetricsService.shared.syncBodyMetric(bodyFatPercent: bodyFatPercent, waistCm: waistCm)
        }
    }

    var bestWorkoutSession: WorkoutHistoryPoint? {
        workoutHistory.max(by: { $0.totalVolumeKg < $1.totalVolumeKg })
    }

    var bestStepDay: StepHistoryPoint? {
        stepHistory.max(by: { $0.steps < $1.steps })
    }

    var averageCalories: Int {
        guard !stepHistory.isEmpty else { return 0 }
        let total = stepHistory.reduce(0) { $0 + $1.calories }
        return total / stepHistory.count
    }

    var totalDistanceKm: Double {
        stepHistory.reduce(0) { $0 + $1.distanceKm }
    }

    var totalActiveMinutes: Int {
        stepHistory.reduce(0) { $0 + $1.activeMinutes }
    }

    var habitConsistencyPercent: Int {
        guard !stepHistory.isEmpty else { return 0 }
        let goalHits = stepHistory.filter(\.goalMet).count
        return Int((Double(goalHits) / Double(stepHistory.count)) * 100.0)
    }

    var workoutChangeText: String {
        comparisonText(for: workoutBars)
    }

    var stepChangeText: String {
        comparisonText(for: stepBars)
    }

    var completedSessions: [CompletedWorkoutSession] {
        WorkoutViewModel.shared.completedSessions.sorted(by: { $0.endTime > $1.endTime })
    }

    func sessions(in range: DateInterval?) -> [CompletedWorkoutSession] {
        let sessions = completedSessions
        guard let range else { return sessions }
        return sessions.filter { range.contains($0.endTime) }
    }

    func muscleGroupSetCounts(for sessions: [CompletedWorkoutSession]) -> [MuscleGroup: Int] {
        var counts: [MuscleGroup: Int] = Dictionary(
            uniqueKeysWithValues: MuscleGroup.allCases.map { ($0, 0) }
        )

        for session in sessions {
            for workoutExercise in session.exercises {
                let completedSets = workoutExercise.sets.filter(\.isCompleted).count
                guard completedSets > 0 else { continue }

                let target = workoutExercise.exercise.targetMuscles.lowercased()
                let matchingGroups = MuscleGroup.allCases.filter { group in
                    group.matchKeywords.contains(where: { target.contains($0.lowercased()) })
                }

                if matchingGroups.isEmpty {
                    continue
                }

                let splitValue = max(1, Int((Double(completedSets) / Double(matchingGroups.count)).rounded()))
                for group in matchingGroups {
                    counts[group, default: 0] += splitValue
                }
            }
        }

        return counts
    }

    func workoutTotals(for sessions: [CompletedWorkoutSession]) -> (workouts: Int, sets: Int, volume: Double, maxSessionVolume: Double) {
        let workouts = sessions.count
        let sets = sessions.reduce(0) { partial, session in
            partial + session.exercises.reduce(0) { $0 + $1.sets.filter(\.isCompleted).count }
        }
        let volume = sessions.reduce(0.0) { $0 + $1.totalVolume }
        let maxSessionVolume = sessions.map(\.totalVolume).max() ?? 0
        return (workouts, sets, volume, maxSessionVolume)
    }

    func workoutVolumeByDay(forYear year: Int) -> [Date: Double] {
        var map: [Date: Double] = [:]
        for session in completedSessions {
            let sessionYear = calendar.component(.year, from: session.endTime)
            guard sessionYear == year else { continue }
            let day = calendar.startOfDay(for: session.endTime)
            map[day, default: 0] += session.totalVolume
        }
        return map
    }

    func workoutBars(for scope: MetricsDetailScope) -> [MetricBarPoint] {
        guard selectedTimePeriod == .months || selectedTimePeriod == .years else {
            return workoutBars
        }
        let period: MetricsTimePeriod = scope == .monthly ? .months : .years
        return aggregateWorkouts(workoutHistory, period: period)
    }

    func stepBars(for scope: MetricsDetailScope) -> [MetricBarPoint] {
        guard selectedTimePeriod == .months || selectedTimePeriod == .years else {
            return stepBars
        }
        let period: MetricsTimePeriod = scope == .monthly ? .months : .years
        return aggregateSteps(stepHistory, period: period)
    }

    var heatmapYears: [Int] {
        let years = Set(completedSessions.map { calendar.component(.year, from: $0.endTime) })
        return years.sorted(by: >)
    }

    private func mapChallengeStats(challengeService: ChallengeService, currentUserId: String?) {
        let now = Date()
        archivedChallenges = challengeService.challenges.filter { $0.endDate < now || !$0.isActive }
        activeChallenges = challengeService.challenges.filter { $0.endDate >= now && $0.isActive }

        guard let currentUserId else {
            challengeWins = 0
            challengeLosses = 0
            return
        }

        var wins = 0
        var losses = 0

        for challenge in archivedChallenges {
            guard let leaderboard = challengeService.leaderboardEntries[challenge.id],
                  let currentUserEntry = leaderboard.first(where: { $0.userId == currentUserId }) else {
                continue
            }

            if currentUserEntry.rank == 1 {
                wins += 1
            } else {
                losses += 1
            }
        }

        challengeWins = wins
        challengeLosses = losses
    }

    private func loadStepHistory(healthKitService: HealthKitService, days: Int) async -> [StepHistoryPoint] {
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -(days - 1), to: today),
              let endDate = calendar.date(byAdding: .day, value: 1, to: today) else {
            return []
        }

        do {
            let stats = try await healthKitService.getSteps(from: startDate, to: endDate)
            var goal = UserDefaults.standard.integer(forKey: "dailyStepGoal")
            if goal <= 0 { goal = 10000 }

            return stats.map { stat in
                let steps = max(stat.steps, 0)
                let distanceKm = Double(steps) * 0.0008
                let calories = Int(Double(steps) * 0.04)
                let activeMinutes = Int(Double(steps) / 120.0)

                return StepHistoryPoint(
                    id: dateFormatter.string(from: stat.date),
                    date: stat.date,
                    steps: steps,
                    distanceKm: distanceKm,
                    calories: calories,
                    activeMinutes: activeMinutes,
                    goalMet: steps >= goal
                )
            }
        } catch {
            errorMessage = "Unable to load step history."
            return []
        }
    }

    private func aggregateWorkouts(_ workouts: [WorkoutHistoryPoint], period: MetricsTimePeriod) -> [MetricBarPoint] {
        let byDate: [(Date, Int)] = workouts.compactMap { point in
            guard let date = dateFormatter.date(from: point.sessionDate) else { return nil }
            return (calendar.startOfDay(for: date), 1)
        }

        return aggregatePairs(byDate, period: period)
    }

    private func aggregateSteps(_ steps: [StepHistoryPoint], period: MetricsTimePeriod) -> [MetricBarPoint] {
        let pairs = steps.map { (calendar.startOfDay(for: $0.date), $0.steps) }
        return aggregatePairs(pairs, period: period)
    }

    private func aggregatePairs(_ pairs: [(Date, Int)], period: MetricsTimePeriod) -> [MetricBarPoint] {
        var buckets: [Date: Int] = [:]
        for (date, value) in pairs {
            let key: Date
            switch period {
            case .days:
                key = calendar.startOfDay(for: date)
            case .weeks:
                let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
                key = calendar.date(from: components) ?? date
            case .months:
                let components = calendar.dateComponents([.year, .month], from: date)
                key = calendar.date(from: components) ?? date
            case .years:
                let components = calendar.dateComponents([.year], from: date)
                key = calendar.date(from: components) ?? date
            }

            buckets[key, default: 0] += value
        }

        return buckets
            .map { date, value in
                MetricBarPoint(
                    id: "\(date.timeIntervalSince1970)",
                    date: date,
                    label: label(for: date, period: period),
                    value: Double(value)
                )
            }
            .sorted(by: { $0.date < $1.date })
    }

    private func aggregateYearlySteps(_ steps: [StepHistoryPoint]) -> [YearMetricPoint] {
        var buckets: [Int: Double] = [:]

        for point in steps {
            let year = calendar.component(.year, from: point.date)
            buckets[year, default: 0] += Double(point.steps)
        }

        return buckets
            .map { YearMetricPoint(id: "\($0.key)", year: $0.key, value: $0.value) }
            .sorted(by: { $0.year > $1.year })
    }

    private func comparisonText(for points: [MetricBarPoint]) -> String {
        guard points.count >= 2 else { return "No previous data" }
        let current = points[points.count - 1].value
        let previous = points[points.count - 2].value

        guard previous > 0 else {
            return current > 0 ? "New activity period" : "No previous data"
        }

        let percentChange = ((current - previous) / previous) * 100.0
        let sign = percentChange >= 0 ? "+" : ""
        return "\(sign)\(Int(percentChange.rounded()))% vs previous period"
    }

    private func label(for date: Date, period: MetricsTimePeriod) -> String {
        let formatter = DateFormatter()
        switch period {
        case .days:
            formatter.dateFormat = "E"
        case .weeks:
            formatter.dateFormat = "MMM d"
        case .months:
            formatter.dateFormat = "MMM"
        case .years:
            formatter.dateFormat = "yyyy"
        }
        return formatter.string(from: date).uppercased()
    }

    private func loadPillarMetrics(healthKitService: HealthKitService) async {
        let lookbackDays = selectedTimePeriod.lookbackDays
        let cutoff = calendar.date(byAdding: .day, value: -lookbackDays, to: Date()) ?? Date()

        let allSessions = WorkoutViewModel.shared.completedSessions
        let sessions = allSessions.filter { $0.endTime >= cutoff }
        let allWeightEntries = WeightViewModel.shared.entries
        let weightEntries = allWeightEntries.filter { $0.date >= cutoff }

        strengthSnapshot = comprehensiveStore.computeStrengthSnapshot(sessions: sessions)

        let sleepDays = max(7, lookbackDays)
        let historyDays = lookbackDays
        async let sleepTask = healthKitService.getAverageSleepHours(days: sleepDays)
        async let rhrTask = healthKitService.getLatestRestingHeartRate()
        async let hrvTask = healthKitService.getLatestHRV()
        async let vo2Task = healthKitService.getLatestVO2Max()
        async let hrvHistoryTask = healthKitService.getHRVHistory(days: historyDays)
        async let rhrHistoryTask = healthKitService.getRestingHeartRateHistory(days: historyDays)
        async let hrvBaselineTask = healthKitService.getHRVBaseline()
        async let rhrBaselineTask = healthKitService.getRHRBaseline()

        let sleepHours = await sleepTask
        let rhr = await rhrTask
        let hrv = await hrvTask
        let vo2 = await vo2Task
        let hrvHistory = await hrvHistoryTask
        let rhrHistory = await rhrHistoryTask
        let hrvBaseline = await hrvBaselineTask
        let rhrBaseline = await rhrBaselineTask
        let height = try? await healthKitService.getHeight()

        let readinessValue = comprehensiveStore.computeReadiness(
            sleepHours: sleepHours,
            hrvCurrent: hrv,
            hrvBaseline: hrvBaseline,
            rhrCurrent: rhr,
            rhrBaseline: rhrBaseline,
            sessions: sessions,
            readinessHistory: readinessHistory,
            days: lookbackDays
        )
        readiness = readinessValue
        readinessHistory = Array((readinessHistory + [readinessValue.score]).suffix(21))

        let performanceValue = comprehensiveStore.computePerformancePillar(sessions: sessions, days: lookbackDays)
        let recoveryValue = comprehensiveStore.computeRecoveryPillar(
            sleepHours: sleepHours,
            hrvHistory: hrvHistory,
            rhrHistory: rhrHistory,
            vo2Max: vo2,
            sessions: sessions,
            days: lookbackDays
        )
        let bodyValue = comprehensiveStore.computeBodyPillar(
            weightEntries: weightEntries,
            bodyMetrics: comprehensiveStore.bodyMetrics,
            heightCm: height,
            days: lookbackDays
        )
        let scheduledDaysPerWeek = Double(
            Set(WorkoutViewModel.shared.workouts
                .filter { $0.oneTimeDate == nil }
                .flatMap(\.assignedDays))
                .count
        )
        let workoutTarget = scheduledDaysPerWeek > 0 ? scheduledDaysPerWeek : 4.0
        let consistencyValue = comprehensiveStore.computeConsistencyPillar(
            sessions: sessions,
            stepHistory: stepHistory,
            nutritionLogs: comprehensiveStore.nutritionLogs,
            days: lookbackDays,
            weeklyWorkoutTarget: workoutTarget
        )
        let insightsValue = comprehensiveStore.computeInsightsPillar(
            sessions: sessions,
            recovery: recoveryValue,
            stepHistory: stepHistory,
            body: bodyValue
        )

        performance = performanceValue
        recovery = recoveryValue
        body = bodyValue
        consistency = consistencyValue
        insightsPillar = insightsValue
        killerScores = comprehensiveStore.computeKillerScores(
            performance: performanceValue,
            recovery: recoveryValue,
            consistency: consistencyValue
        )
        weeklyReport = comprehensiveStore.computeWeeklyReport(
            performance: performanceValue,
            consistency: consistencyValue,
            recovery: recoveryValue,
            body: bodyValue
        )
    }

    var topInsights: [InsightItem] {
        let all = (insightsPillar?.dailyInsights ?? [])
            + (insightsPillar?.weeklyInsights ?? [])
            + (insightsPillar?.monthlyInsights ?? [])
        return Array(all.prefix(5))
    }

    var activeYears: [Int] {
        let years = Set(stepHistory.map { calendar.component(.year, from: $0.date) })
        return years.sorted(by: >)
    }

    var nutritionLogs: [NutritionLog] {
        comprehensiveStore.nutritionLogs
    }

    var calorieTarget: Int {
        CalorieCalculator.currentDailyGoal()
    }

    func nutritionLogs(forLast days: Int) -> [NutritionLog] {
        let cutoff = calendar.date(byAdding: .day, value: -max(0, days - 1), to: Date()) ?? Date()
        return comprehensiveStore.nutritionLogs
            .filter { $0.loggedAt >= cutoff }
            .sorted { $0.loggedAt < $1.loggedAt }
    }

    var completedWorkoutsCount: Int {
        completedSessions.count
    }

    var averageSleepHours: Double {
        Double(readiness?.score ?? 0) * 0.08
    }

    var recoveryStatus: RecoveryStatus {
        readiness?.recoveryStatus ?? .maintaining
    }

    var dailyRecommendation: DailyRecommendation {
        readiness?.recommendation ?? .trainModerate
    }
}
