//
//  ComprehensiveMetricsStore.swift
//  FitComp
//

import Foundation
import Combine

@MainActor
final class ComprehensiveMetricsStore: ObservableObject {
    static let shared = ComprehensiveMetricsStore()

    @Published private(set) var bodyMetrics: [BodyMetricEntry] = []
    @Published private(set) var nutritionLogs: [NutritionLog] = []

    private let bodyMetricsKey = "comprehensive_body_metrics"
    private let nutritionLogsKey = "comprehensive_nutrition_logs"

    private init() {
        load()
    }

    func addBodyMetric(bodyFatPercent: Double?, waistCm: Double?, date: Date = Date()) {
        bodyMetrics.append(
            BodyMetricEntry(
                id: UUID(),
                recordedOn: date,
                bodyFatPercent: bodyFatPercent,
                waistCm: waistCm
            )
        )
        bodyMetrics.sort { $0.recordedOn > $1.recordedOn }
        save()
    }

    func addNutritionLog(
        calories: Int,
        proteinG: Int,
        carbsG: Int,
        fatG: Int,
        waterMl: Int,
        loggedAt: Date = Date()
    ) {
        nutritionLogs.append(
            NutritionLog(
                id: UUID(),
                loggedAt: loggedAt,
                calories: calories,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                waterMl: waterMl
            )
        )
        nutritionLogs.sort { $0.loggedAt > $1.loggedAt }
        save()
    }

    func replaceNutritionLogs(_ logs: [NutritionLog]) {
        nutritionLogs = logs.sorted { $0.loggedAt > $1.loggedAt }
        save()
    }

    func computeStrengthSnapshot(sessions: [CompletedWorkoutSession]) -> StrengthMetricSnapshot {
        var recordMap: [String: [PersonalRecordType: PersonalRecord]] = [:]
        var muscleVolume: [String: Double] = [:]
        var totalVolume: Double = 0
        var estimated1RM: Double = 0
        var successfulOverloadSets = 0
        var suggestedSets = 0

        for session in sessions {
            totalVolume += session.totalVolume
            for exercise in session.exercises {
                for set in exercise.sets where set.isCompleted {
                    guard let weight = set.weight, let reps = set.reps else { continue }
                    let setVolume = weight * Double(reps)
                    let oneRM = weight * (1 + Double(reps) / 30.0)
                    estimated1RM = max(estimated1RM, oneRM)

                    let exerciseName = exercise.exercise.name
                    let date = session.endTime

                    let maxWeight = PersonalRecord(id: UUID(), exerciseName: exerciseName, type: .maxWeight, value: weight, achievedAt: date)
                    let maxReps = PersonalRecord(id: UUID(), exerciseName: exerciseName, type: .maxReps, value: Double(reps), achievedAt: date)
                    let maxVolume = PersonalRecord(id: UUID(), exerciseName: exerciseName, type: .maxVolume, value: setVolume, achievedAt: date)

                    updateRecord(map: &recordMap, candidate: maxWeight)
                    updateRecord(map: &recordMap, candidate: maxReps)
                    updateRecord(map: &recordMap, candidate: maxVolume)

                    for muscle in splitMuscles(exercise.exercise.targetMuscles) {
                        muscleVolume[muscle, default: 0] += setVolume
                    }

                    if let suggestedWeight = set.suggestedWeight, let suggestedReps = set.suggestedReps {
                        suggestedSets += 1
                        if weight >= suggestedWeight || reps >= suggestedReps {
                            successfulOverloadSets += 1
                        }
                    }
                }
            }
        }

        let records = recordMap
            .values
            .flatMap { $0.values }
            .sorted { $0.achievedAt > $1.achievedAt }

        let strongestExercise = records
            .filter { $0.type == .maxWeight }
            .max(by: { $0.value < $1.value })?
            .exerciseName

        let overloadRate = suggestedSets > 0
            ? Int((Double(successfulOverloadSets) / Double(suggestedSets) * 100).rounded())
            : 0

        let muscleGroupVolume = muscleVolume
            .map { MuscleGroupVolume(muscleGroup: $0.key, volume: $0.value) }
            .sorted { $0.volume > $1.volume }

        return StrengthMetricSnapshot(
            totalVolume: totalVolume,
            estimatedOneRM: estimated1RM,
            overloadSuccessRate: overloadRate,
            strongestExercise: strongestExercise,
            personalRecords: Array(records.prefix(20)),
            muscleGroupVolume: Array(muscleGroupVolume.prefix(8))
        )
    }

    func computeBodySnapshot(
        weightEntries: [WeightEntry],
        heightCm: Double?
    ) -> BodyMetricSnapshot {
        let sortedWeights = weightEntries.sorted { $0.date < $1.date }
        let currentWeight = sortedWeights.last?.weightKg
        let latestBodyFat = bodyMetrics.sorted { $0.recordedOn < $1.recordedOn }.last?.bodyFatPercent

        let bmi: Double?
        if let h = heightCm, h > 0, let w = currentWeight {
            let heightMeters = h / 100.0
            bmi = w / (heightMeters * heightMeters)
        } else {
            bmi = nil
        }

        let leanMass = (currentWeight != nil && latestBodyFat != nil)
            ? currentWeight! * (1.0 - (latestBodyFat! / 100.0))
            : nil

        let weeklyWeightChange = weeklyChange(entries: sortedWeights.map { ($0.date, $0.weightKg) })
        let weeklyLeanMassChange = (leanMass != nil && latestBodyFat != nil && sortedWeights.count >= 2)
            ? estimateWeeklyLeanMassChange(weights: sortedWeights, bodyFatPercent: latestBodyFat!)
            : nil
        let weeklyFatMassChange = (weeklyWeightChange != nil && weeklyLeanMassChange != nil)
            ? weeklyWeightChange! - weeklyLeanMassChange!
            : nil

        return BodyMetricSnapshot(
            currentWeightKg: currentWeight,
            bodyFatPercent: latestBodyFat,
            bmi: bmi,
            leanMassKg: leanMass,
            weeklyWeightChangeKg: weeklyWeightChange,
            weeklyLeanMassChangeKg: weeklyLeanMassChange,
            weeklyFatMassChangeKg: weeklyFatMassChange
        )
    }

    func computeNutritionSnapshot() -> NutritionMetricSnapshot {
        let today = Calendar.current.startOfDay(for: Date())
        let todays = nutritionLogs.filter { Calendar.current.isDate($0.loggedAt, inSameDayAs: today) }
        let calories = todays.reduce(0) { $0 + $1.calories }
        let protein = todays.reduce(0) { $0 + $1.proteinG }
        let carbs = todays.reduce(0) { $0 + $1.carbsG }
        let fat = todays.reduce(0) { $0 + $1.fatG }
        let water = todays.reduce(0) { $0 + $1.waterMl }

        let targetCalories = UserDefaults.standard.integer(forKey: "daily_calorie_goal").clamped(
            to: 1200...5000,
            default: 2200
        )
        let targetProtein = UserDefaults.standard.integer(forKey: "daily_protein_goal_g").clamped(
            to: 30...400,
            default: 160
        )
        let targetCarbs = 220
        let targetFat = 70
        let calorieScore = closenessScore(current: calories, target: targetCalories)
        let proteinScore = closenessScore(current: protein, target: targetProtein)
        let carbScore = closenessScore(current: carbs, target: targetCarbs)
        let fatScore = closenessScore(current: fat, target: targetFat)
        let adherence = Int(((Double(calorieScore + proteinScore + carbScore + fatScore) / 4.0)).rounded())

        return NutritionMetricSnapshot(
            todayCalories: calories,
            todayProteinG: protein,
            todayCarbsG: carbs,
            todayFatG: fat,
            todayWaterMl: water,
            macroAdherenceScore: adherence
        )
    }

    func computeEngagementScores(
        sessions: [CompletedWorkoutSession],
        stepHistory: [StepHistoryPoint],
        strength: StrengthMetricSnapshot,
        cardio: CardioMetricSnapshot
    ) -> EngagementScores {
        let consistencyScore = stepHistory.isEmpty
            ? 0
            : Int((Double(stepHistory.filter(\.goalMet).count) / Double(stepHistory.count) * 100).rounded())

        let weeklyVolume = sessions
            .filter { Calendar.current.dateComponents([.day], from: $0.endTime, to: Date()).day ?? 999 <= 7 }
            .reduce(0.0) { $0 + $1.totalVolume }
        let baselineVolume = sessions
            .filter { value in
                let days = Calendar.current.dateComponents([.day], from: value.endTime, to: Date()).day ?? 999
                return days > 7 && days <= 35
            }
            .reduce(0.0) { $0 + $1.totalVolume } / 4.0
        let trainingLoadRaw = baselineVolume > 0 ? (weeklyVolume / baselineVolume) * 100 : 0
        let trainingLoadScore = max(0, min(100, Int(trainingLoadRaw.rounded())))

        let strengthComponent = min(100, Int((strength.estimatedOneRM / 180.0) * 100))
        let cardioComponent = max(0, min(100, 50 + cardio.speedImprovementPercent))
        let performanceScore = Int(((Double(strengthComponent + cardioComponent + consistencyScore) / 3.0)).rounded())

        let goalCompletionRate = consistencyScore
        let workoutStreak = currentWorkoutStreak(from: sessions)
        let longestWorkoutStreak = longestWorkoutStreak(from: sessions)

        return EngagementScores(
            consistencyScore: consistencyScore,
            trainingLoadScore: trainingLoadScore,
            performanceScore: performanceScore,
            goalCompletionRate: goalCompletionRate,
            workoutStreak: workoutStreak,
            longestWorkoutStreak: longestWorkoutStreak
        )
    }

    func generateInsights(
        sessions: [CompletedWorkoutSession],
        recovery: RecoveryMetricSnapshot,
        stepHistory: [StepHistoryPoint],
        strength: StrengthMetricSnapshot
    ) -> [InsightItem] {
        var insights: [InsightItem] = []

        if recovery.averageSleepHours >= 7.0 {
            insights.append(
                InsightItem(
                    id: UUID(),
                    title: "Recovery Advantage",
                    message: "You perform best with 7+ hours sleep. Keep this pattern to sustain progress.",
                    confidence: 82
                )
            )
        }

        let mondaySessions = sessions.filter { Calendar.current.component(.weekday, from: $0.endTime) == 2 }
        let mondayAvg = mondaySessions.isEmpty ? 0 : mondaySessions.reduce(0.0) { $0 + $1.totalVolume } / Double(mondaySessions.count)
        let allAvg = sessions.isEmpty ? 0 : sessions.reduce(0.0) { $0 + $1.totalVolume } / Double(sessions.count)
        if allAvg > 0 && mondayAvg > allAvg * 1.1 {
            let uplift = Int((((mondayAvg - allAvg) / allAvg) * 100).rounded())
            insights.append(
                InsightItem(
                    id: UUID(),
                    title: "Best Strength Day",
                    message: "You lift about \(uplift)% stronger on Mondays than your average.",
                    confidence: 77
                )
            )
        }

        let friday = stepHistory.filter { Calendar.current.component(.weekday, from: $0.date) == 6 }
        let fridayAvg = friday.isEmpty ? 0 : friday.reduce(0) { $0 + $1.steps } / friday.count
        let overallAvg = stepHistory.isEmpty ? 0 : stepHistory.reduce(0) { $0 + $1.steps } / stepHistory.count
        if overallAvg > 0 && fridayAvg < Int(Double(overallAvg) * 0.88) {
            insights.append(
                InsightItem(
                    id: UUID(),
                    title: "Friday Dip",
                    message: "Your step count consistently drops on Fridays. Add a short walk trigger.",
                    confidence: 73
                )
            )
        }

        if strength.overloadSuccessRate < 45 {
            insights.append(
                InsightItem(
                    id: UUID(),
                    title: "Overload Tuning",
                    message: "Progressive overload hit rate is \(strength.overloadSuccessRate)%. Keep weight steady and push reps first.",
                    confidence: 80
                )
            )
        } else {
            insights.append(
                InsightItem(
                    id: UUID(),
                    title: "Overload Momentum",
                    message: "Progressive overload hit rate is \(strength.overloadSuccessRate)%. Consider +2.5kg on your next key lift.",
                    confidence: 79
                )
            )
        }

        return Array(insights.prefix(4))
    }

    // MARK: - V2 Pillar Scoring

    func computeReadiness(
        sleepHours: Double,
        hrvCurrent: Double?,
        hrvBaseline: Double,
        rhrCurrent: Double?,
        rhrBaseline: Double,
        sessions: [CompletedWorkoutSession],
        readinessHistory: [Int] = [],
        days: Int = 30
    ) -> ReadinessResult {
        let sleepScore = max(0, min(100, Int((sleepHours / 8.0 * 100.0).rounded())))
        let hrvScore: Int? = {
            guard let hrvCurrent, hrvBaseline > 0 else { return nil }
            let pct = (hrvCurrent / hrvBaseline) * 100.0
            return max(0, min(100, Int(pct.rounded())))
        }()
        let rhrScore: Int? = {
            guard let rhrCurrent, rhrBaseline > 0 else { return nil }
            let deviation = ((rhrBaseline - rhrCurrent) / rhrBaseline) * 100.0
            return max(0, min(100, Int((70.0 + deviation * 3.0).rounded())))
        }()
        let loadBalance = computeTrainingLoadBalance(sessions: sessions, days: days)
        let loadScore = trainingBalanceScore(from: loadBalance.ratio)

        var weightedTotal = 0.0
        var weightSum = 0.0
        weightedTotal += Double(sleepScore) * 0.35
        weightSum += 0.35
        if let hrvScore {
            weightedTotal += Double(hrvScore) * 0.25
            weightSum += 0.25
        }
        if let rhrScore {
            weightedTotal += Double(rhrScore) * 0.15
            weightSum += 0.15
        }
        weightedTotal += Double(loadScore) * 0.25
        weightSum += 0.25

        let normalized = weightSum > 0 ? weightedTotal / weightSum : 0
        let score = max(0, min(100, Int(normalized.rounded())))
        let status = metricStatus(for: score)

        let recommendation: DailyRecommendation
        let recoveryStatus: RecoveryStatus
        switch score {
        case 90...100:
            recommendation = .trainHeavy
            recoveryStatus = .recovered
        case 75...89:
            recommendation = .trainModerate
            recoveryStatus = .maintaining
        case 60...74:
            recommendation = .activeRecovery
            recoveryStatus = .fatigued
        default:
            recommendation = .restDay
            recoveryStatus = .overreached
        }

        let idealWeeklySleep = 49.0
        let actualWeeklySleep = sleepHours * 7.0
        let recoveryDebt = max(0, idealWeeklySleep - actualWeeklySleep)

        let history = Array((readinessHistory + [score]).suffix(7))
        let trend = TrainingReadinessTrend(
            values: history,
            direction: trendDirection(values: history.map(Double.init), lowerIsBetter: false),
            daysImproving: consecutiveImprovementDays(values: history.map(Double.init), lowerIsBetter: false)
        )

        var missingInputs: [String] = []
        if hrvCurrent == nil || hrvBaseline == 0 { missingInputs.append("HRV") }
        if rhrCurrent == nil || rhrBaseline == 0 { missingInputs.append("RHR") }

        return ReadinessResult(
            score: score,
            status: status,
            recoveryStatus: recoveryStatus,
            recommendation: recommendation,
            recoveryDebtHours: recoveryDebt,
            trend: trend,
            missingInputs: missingInputs
        )
    }

    func computePerformancePillar(sessions: [CompletedWorkoutSession], days: Int = 30) -> PerformancePillarData {
        let windowDays = max(7, days)
        let recent = sessionsBetween(daysAgoStart: 0, daysAgoEnd: windowDays, sessions: sessions)
        let prior = sessionsBetween(daysAgoStart: windowDays, daysAgoEnd: windowDays * 2, sessions: sessions)

        let strengthTrend = perExerciseBest1RMTrend(recent: recent, prior: prior)
        let strengthTrendValue = strengthTrend.percent ?? 0
        let strengthScore = max(0, min(100, Int((50.0 + strengthTrendValue * 3.0).rounded())))

        let overloadScore = computeProgressiveOverloadScore(sessions: sessions)
        let loadBalance = computeTrainingLoadBalance(sessions: sessions)
        let plateau = detectPlateau(sessions: sessions)
        let prVelocity = computePRVelocity(sessions: sessions)
        let muscleBalance = computeStrengthSnapshot(sessions: sessions).muscleGroupVolume

        return PerformancePillarData(
            strengthTrendPercent: strengthTrend.percent,
            comparedLiftCount: strengthTrend.comparedExerciseCount,
            strengthScore: strengthScore,
            overloadScore: overloadScore,
            trainingLoadBalance: loadBalance,
            plateauDetection: plateau,
            muscleBalance: muscleBalance,
            prVelocity: prVelocity
        )
    }

    func computeRecoveryPillar(
        sleepHours: Double,
        hrvHistory: [(Date, Double)],
        rhrHistory: [(Date, Double)],
        vo2Max: Double?,
        sessions: [CompletedWorkoutSession],
        days: Int = 30
    ) -> RecoveryPillarData {
        let hrvValues = hrvHistory.map(\.1)
        let rhrValues = rhrHistory.map(\.1)
        let hrvTrend = trendPercent(values: hrvValues)
        let rhrTrend = trendPercent(values: rhrValues, lowerIsBetter: true)

        let sleepQuality = max(0, min(100, Int((sleepHours / 8.0 * 100.0).rounded())))

        let trainingLoad = trainingBalanceScore(from: computeTrainingLoadBalance(sessions: sessions).ratio)
        let stressRaw = Int((Double(100 - sleepQuality) * 0.4 + Double(100 - trainingLoad) * 0.6).rounded())
        let stress = max(0, min(100, stressRaw))

        let hrvDirection = trendDirection(values: hrvValues, lowerIsBetter: false)
        let rhrDirection = trendDirection(values: rhrValues, lowerIsBetter: true)
        let recoveryEfficiency = computeRecoveryEfficiency(hrvValues: hrvValues)

        let riskRaw = Int((Double(stress) * 0.5 + Double(100 - recoveryEfficiency) * 0.35 + Double(max(0, 70 - sleepQuality)) * 0.15).rounded())
        let riskScore = max(0, min(100, riskRaw))
        let riskStatus: MetricStatus = riskScore >= 75 ? .atRisk : (riskScore >= 55 ? .moderate : .good)

        _ = vo2Max // retained for future weighting and source parity

        return RecoveryPillarData(
            hrvTrendPercent: hrvTrend,
            hrvDirection: hrvDirection,
            rhrTrendPercent: rhrTrend,
            rhrDirection: rhrDirection,
            stressLoadScore: stress,
            recoveryEfficiency: recoveryEfficiency,
            overtrainingRiskScore: riskScore,
            overtrainingRiskStatus: riskStatus,
            sleepQualityScore: sleepQuality
        )
    }

    func computeBodyPillar(
        weightEntries: [WeightEntry],
        bodyMetrics: [BodyMetricEntry],
        heightCm: Double?,
        days: Int = 30
    ) -> BodyPillarData {
        let body = computeBodySnapshot(weightEntries: weightEntries, heightCm: heightCm)
        let fatLossVelocity: Double? = {
            if let weeklyFatMassChange = body.weeklyFatMassChangeKg {
                let fatLossKgPerWeek = -weeklyFatMassChange
                guard fatLossKgPerWeek > 0 else { return nil }
                return min(fatLossKgPerWeek, 1.5)
            }

            if let weeklyWeightChange = body.weeklyWeightChangeKg {
                let weightLossKgPerWeek = -weeklyWeightChange
                guard weightLossKgPerWeek > 0 else { return nil }
                return min(weightLossKgPerWeek, 1.5)
            }
            return nil
        }()

        let leanMassTrend = body.weeklyLeanMassChangeKg.map { $0 * 8.0 }
        let recompBase = (body.weeklyFatMassChangeKg ?? 0) < 0 && (body.weeklyLeanMassChangeKg ?? 0) > 0
        let leanMassDelta = body.weeklyLeanMassChangeKg ?? 0
        let fatMassDelta = body.weeklyFatMassChangeKg ?? 0
        let recompositionRaw = 50.0 + (leanMassDelta * 12.0) - (fatMassDelta * 8.0)
        let recompositionScore = recompBase
            ? 85
            : max(0, min(100, Int(recompositionRaw.rounded())))

        let trendScore: BodyTrendScore
        if let weeklyWeightChange = body.weeklyWeightChangeKg {
            if weeklyWeightChange <= -0.2 {
                trendScore = .improving
            } else if weeklyWeightChange < 0.2 {
                trendScore = .maintaining
            } else {
                trendScore = .regressing
            }
        } else {
            trendScore = .maintaining
        }

        let measurementWindow = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let measurementCount = bodyMetrics.filter { $0.recordedOn >= measurementWindow }.count
        let expectedMeasurements = max(1.0, Double(days) / 7.0)
        let consistency = max(0, min(100, Int((Double(measurementCount) / expectedMeasurements * 100.0).rounded())))

        return BodyPillarData(
            fatLossVelocityPerWeek: fatLossVelocity,
            leanMassTrendKg60d: leanMassTrend,
            recompositionScore: recompositionScore,
            bodyTrendScore: trendScore,
            measurementConsistency: consistency
        )
    }

    func computeConsistencyPillar(
        sessions: [CompletedWorkoutSession],
        stepHistory: [StepHistoryPoint],
        nutritionLogs: [NutritionLog],
        days: Int = 30,
        weeklyWorkoutTarget: Double = 4.0
    ) -> ConsistencyPillarData {
        let totalWeeks = max(1.0, Double(days) / 7.0)
        let sessionsInPeriod = sessionsInLast(days: days, sessions: sessions)
        let weeklyAvg = Double(sessionsInPeriod.count) / totalWeeks
        let workoutAdherence = min(100, Int((weeklyAvg / max(1.0, weeklyWorkoutTarget) * 100.0).rounded()))

        let goalMetCount = stepHistory.filter(\.goalMet).count
        let stepScore = stepHistory.isEmpty
            ? 0
            : Int((Double(goalMetCount) / Double(stepHistory.count) * 100.0).rounded())

        let nutritionCutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let periodLogs = nutritionLogs.filter { $0.loggedAt >= nutritionCutoff }
        let nutritionDays = Set(periodLogs.map { Calendar.current.startOfDay(for: $0.loggedAt) }).count
        let nutritionScore = Int((Double(nutritionDays) / max(1.0, Double(days)) * 100.0).rounded())
        let nutritionActive = nutritionDays >= 3

        let goalCompletion = Int((Double(workoutAdherence + stepScore) / 2.0).rounded())

        // When nutrition logging is inactive, redistribute its weight to workout and steps
        let consistency: Int
        if nutritionActive {
            consistency = Int((Double(workoutAdherence) * 0.3 + Double(goalCompletion) * 0.25 + Double(nutritionScore) * 0.2 + Double(stepScore) * 0.25).rounded())
        } else {
            consistency = Int((Double(workoutAdherence) * 0.40 + Double(goalCompletion) * 0.25 + Double(stepScore) * 0.35).rounded())
        }

        // Require minimum workout data for PR/volume scores to avoid inflated values
        let prVelocity = computePRVelocity(sessions: sessions).workoutsPerPR
        let hasEnoughData = sessionsInPeriod.count >= 3
        let prFrequencyScore: Int
        if hasEnoughData {
            prFrequencyScore = max(0, min(100, Int((100.0 - min(prVelocity, 25.0) * 3.5).rounded())))
        } else {
            // With sparse data, scale PR score down proportionally
            let rawPR = max(0, min(100, Int((100.0 - min(prVelocity, 25.0) * 3.5).rounded())))
            prFrequencyScore = Int((Double(rawPR) * Double(sessionsInPeriod.count) / 3.0).rounded())
        }

        let trendWindow = max(14, days)
        let trendSessions = sessionsInLast(days: trendWindow, sessions: sessions)
        let volumeTrend = trendPercent(values: trendSessions.map(\.totalVolume)) ?? 0
        let volumeTrendScore: Int
        if hasEnoughData {
            volumeTrendScore = max(0, min(100, Int((50.0 + volumeTrend * 4.0).rounded())))
        } else {
            // With sparse data, don't assume a 50-point baseline
            let rawTrend = max(0, min(100, Int((50.0 + volumeTrend * 4.0).rounded())))
            volumeTrendScore = Int((Double(rawTrend) * Double(trendSessions.count) / 3.0).rounded())
        }

        let momentumRaw = Int((Double(consistency) * 0.4 + Double(prFrequencyScore) * 0.3 + Double(volumeTrendScore) * 0.3).rounded())
        let momentum = max(0, min(100, momentumRaw))

        let frequency = Double(sessionsInPeriod.count) / totalWeeks
        let recentVolumeDays = min(7, days)
        let streakStrength = min(100, currentWorkoutStreak(from: sessions) * 8 + Int((sessionsInLast(days: recentVolumeDays, sessions: sessions).reduce(0.0) { $0 + $1.totalVolume } / 500.0).rounded()))

        let stepConsistencyDays = min(stepHistory.count, 7)
        let recentStepGoalHits = Array(stepHistory.suffix(stepConsistencyDays)).filter(\.goalMet).count

        // Habit adherence: percentage of days with any tracked activity (steps met OR workout done)
        let workoutDays = Set(sessionsInPeriod.map { Calendar.current.startOfDay(for: $0.endTime) })
        let stepGoalDays = Set(stepHistory.filter(\.goalMet).map { Calendar.current.startOfDay(for: $0.date) })
        let activeDays = workoutDays.union(stepGoalDays).count
        let habitAdherence = min(100, Int((Double(activeDays) / max(1.0, Double(days)) * 100.0).rounded()))

        return ConsistencyPillarData(
            consistencyScore: consistency,
            momentumScore: MomentumScore(score: momentum, status: metricStatus(for: momentum)),
            habitAdherencePercent: habitAdherence,
            workoutFrequencyPerWeek: frequency,
            stepConsistencyDaysHit: recentStepGoalHits,
            streakStrengthScore: max(0, min(100, streakStrength))
        )
    }

    func computeInsightsPillar(
        sessions: [CompletedWorkoutSession],
        recovery _: RecoveryPillarData,
        stepHistory _: [StepHistoryPoint],
        body _: BodyPillarData
    ) -> InsightsPillarData {
        var daily: [InsightItem] = []
        var weekly: [InsightItem] = []
        var monthly: [InsightItem] = []

        if sessions.count >= 3 {
            daily.append(
                InsightItem(
                    id: UUID(),
                    title: "Training Rhythm",
                    message: "You logged \(sessions.count) workouts in this period. Keep the same cadence to compound progress.",
                    confidence: 78
                )
            )
        }

        let mondayVolume = averageVolume(forWeekday: 2, sessions: sessions)
        let allVolume = averageVolume(forWeekday: nil, sessions: sessions)
        if allVolume > 0, mondayVolume > allVolume * 1.1 {
            weekly.append(
                InsightItem(
                    id: UUID(),
                    title: "Peak Day",
                    message: "You are strongest on Mondays. Schedule your hardest lift then.",
                    confidence: 79
                )
            )
        }

        if monthly.isEmpty {
            monthly.append(
                InsightItem(
                    id: UUID(),
                    title: "Consistency Opportunity",
                    message: "Increasing workout consistency by one day per week would raise momentum fastest.",
                    confidence: 70
                )
            )
        }

        return InsightsPillarData(
            dailyInsights: Array(daily.prefix(1)),
            weeklyInsights: Array(weekly.prefix(5)),
            monthlyInsights: Array(monthly.prefix(1))
        )
    }

    func computeKillerScores(
        performance: PerformancePillarData,
        recovery: RecoveryPillarData,
        consistency: ConsistencyPillarData
    ) -> KillerScores {
        let momentum = consistency.momentumScore.score
        let fitness = max(0, min(100, Int((Double(performance.strengthScore) * 0.6 + Double(100 - recovery.stressLoadScore) * 0.4).rounded())))
        let recoveryScore = max(0, min(100, Int((Double(recovery.sleepQualityScore) * 0.4 + Double(recovery.recoveryEfficiency) * 0.35 + Double(100 - recovery.stressLoadScore) * 0.25).rounded())))
        let trainingBalance = trainingBalanceScore(from: performance.trainingLoadBalance.ratio)
        let discipline = max(0, min(100, Int((Double(consistency.consistencyScore) * 0.5 + Double(consistency.stepConsistencyDaysHit) / 7.0 * 50.0).rounded())))

        return KillerScores(
            momentum: momentum,
            fitness: fitness,
            recovery: recoveryScore,
            trainingBalance: trainingBalance,
            discipline: discipline
        )
    }

    func computeWeeklyReport(
        performance: PerformancePillarData,
        sessions: [CompletedWorkoutSession]
    ) -> WeeklyReport {
        return WeeklyReport(
            strengthChangePercent: performance.strengthTrendPercent,
            comparedLiftCount: performance.comparedLiftCount ?? 0,
            workoutsCompleted: sessions.count
        )
    }

    private func save() {
        if let encodedBody = try? JSONEncoder().encode(bodyMetrics) {
            UserDefaults.standard.set(encodedBody, forKey: bodyMetricsKey)
        }
        if let encodedNutrition = try? JSONEncoder().encode(nutritionLogs) {
            UserDefaults.standard.set(encodedNutrition, forKey: nutritionLogsKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: bodyMetricsKey),
           let decoded = try? JSONDecoder().decode([BodyMetricEntry].self, from: data) {
            bodyMetrics = decoded
        }
        if let data = UserDefaults.standard.data(forKey: nutritionLogsKey),
           let decoded = try? JSONDecoder().decode([NutritionLog].self, from: data) {
            nutritionLogs = decoded
        }
    }

    private func updateRecord(map: inout [String: [PersonalRecordType: PersonalRecord]], candidate: PersonalRecord) {
        var exerciseRecords = map[candidate.exerciseName, default: [:]]
        if let existing = exerciseRecords[candidate.type] {
            if candidate.value > existing.value {
                exerciseRecords[candidate.type] = candidate
            }
        } else {
            exerciseRecords[candidate.type] = candidate
        }
        map[candidate.exerciseName] = exerciseRecords
    }

    private func splitMuscles(_ text: String) -> [String] {
        text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func weeklyChange(entries: [(Date, Double)]) -> Double? {
        guard entries.count >= 2 else { return nil }
        let sorted = entries.sorted { $0.0 < $1.0 }
        guard let earliest = sorted.first, let latest = sorted.last else { return nil }

        let spanDays = latest.0.timeIntervalSince(earliest.0) / (24 * 60 * 60)
        guard spanDays >= 3 else { return nil }

        // Least-squares linear regression over all entries
        let referenceDate = earliest.0
        let points = sorted.map { entry in
            (x: entry.0.timeIntervalSince(referenceDate) / (24 * 60 * 60), y: entry.1)
        }

        let n = Double(points.count)
        let sumX = points.reduce(0.0) { $0 + $1.x }
        let sumY = points.reduce(0.0) { $0 + $1.y }
        let sumXY = points.reduce(0.0) { $0 + $1.x * $1.y }
        let sumX2 = points.reduce(0.0) { $0 + $1.x * $1.x }

        let denominator = n * sumX2 - sumX * sumX
        guard abs(denominator) > 1e-10 else { return nil }

        let slope = (n * sumXY - sumX * sumY) / denominator
        // slope is kg/day, convert to kg/week
        return slope * 7.0
    }

    private func estimateWeeklyLeanMassChange(weights: [WeightEntry], bodyFatPercent: Double) -> Double? {
        let leanEntries: [(Date, Double)] = weights.map { entry in
            (entry.date, entry.weightKg * (1 - bodyFatPercent / 100.0))
        }
        return weeklyChange(entries: leanEntries)
    }

    private func closenessScore(current: Int, target: Int) -> Int {
        guard target > 0 else { return 0 }
        let delta = abs(current - target)
        let pct = max(0.0, 1.0 - (Double(delta) / Double(target)))
        return Int((pct * 100).rounded())
    }

    private func currentWorkoutStreak(from sessions: [CompletedWorkoutSession]) -> Int {
        let days = Set(sessions.map { Calendar.current.startOfDay(for: $0.endTime) })
        var streak = 0
        var cursor = Calendar.current.startOfDay(for: Date())
        let hadToday = days.contains(cursor)
        if !hadToday, let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: cursor) {
            cursor = yesterday
        }
        while days.contains(cursor) {
            streak += 1
            guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    private func longestWorkoutStreak(from sessions: [CompletedWorkoutSession]) -> Int {
        let ordered = Array(Set(sessions.map { Calendar.current.startOfDay(for: $0.endTime) })).sorted()
        guard !ordered.isEmpty else { return 0 }
        var longest = 1
        var current = 1
        for index in 1..<ordered.count {
            let prev = ordered[index - 1]
            let next = ordered[index]
            let diff = Calendar.current.dateComponents([.day], from: prev, to: next).day ?? 99
            if diff == 1 {
                current += 1
            } else {
                longest = max(longest, current)
                current = 1
            }
        }
        return max(longest, current)
    }

    private func sessionsInLast(days: Int, sessions: [CompletedWorkoutSession]) -> [CompletedWorkoutSession] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return sessions.filter { $0.endTime >= cutoff }
    }

    private func sessionsBetween(
        daysAgoStart: Int,
        daysAgoEnd: Int,
        sessions: [CompletedWorkoutSession]
    ) -> [CompletedWorkoutSession] {
        sessions.filter { session in
            guard let dayDelta = Calendar.current.dateComponents([.day], from: session.endTime, to: Date()).day else {
                return false
            }
            return dayDelta >= daysAgoStart && dayDelta < daysAgoEnd
        }
    }

    private func averageEstimatedOneRM(from sessions: [CompletedWorkoutSession]) -> Double {
        let oneRMs = sessions.flatMap { session in
            session.exercises.flatMap { exercise in
                exercise.sets.compactMap { set -> Double? in
                    guard set.isCompleted, let weight = set.weight, let reps = set.reps, reps > 0 else { return nil }
                    return weight * (1 + Double(reps) / 30.0)
                }
            }
        }
        guard !oneRMs.isEmpty else { return 0 }
        return oneRMs.reduce(0, +) / Double(oneRMs.count)
    }

    private func perExerciseBest1RMTrend(
        recent: [CompletedWorkoutSession],
        prior: [CompletedWorkoutSession]
    ) -> (percent: Double?, comparedExerciseCount: Int) {
        func bestOneRMByExercise(_ sessions: [CompletedWorkoutSession]) -> [String: Double] {
            var best: [String: Double] = [:]
            for session in sessions {
                for exercise in session.exercises {
                    let name = exercise.exercise.name
                    for set in exercise.sets where set.isCompleted {
                        guard let weight = set.weight, let reps = set.reps, reps > 0 else { continue }
                        let oneRM = weight * (1 + Double(reps) / 30.0)
                        best[name] = max(best[name] ?? 0, oneRM)
                    }
                }
            }
            return best
        }

        let recentBest = bestOneRMByExercise(recent)
        let priorBest = bestOneRMByExercise(prior)

        // Only compare exercises present in both windows
        let commonExercises = Set(recentBest.keys).intersection(priorBest.keys)
        guard !commonExercises.isEmpty else { return (nil, 0) }

        let trends = commonExercises.compactMap { name -> Double? in
            guard let r = recentBest[name], let p = priorBest[name], p > 0 else { return nil }
            return ((r - p) / p) * 100.0
        }.sorted()

        guard !trends.isEmpty else { return (nil, 0) }
        // Return median for robustness against outlier exercises
        let mid = trends.count / 2
        let median = trends.count % 2 == 0
            ? (trends[mid - 1] + trends[mid]) / 2.0
            : trends[mid]
        return (median, trends.count)
    }

    private func computeProgressiveOverloadScore(sessions: [CompletedWorkoutSession]) -> Int? {
        let sorted = sessions.sorted { $0.endTime < $1.endTime }
        guard sorted.count >= 2 else { return nil }

        var latestByExercise: [String: (weight: Double, reps: Int, volume: Double)] = [:]
        var previousByExercise: [String: (weight: Double, reps: Int, volume: Double)] = [:]

        let recent = Array(sorted.suffix(8))
        for (index, session) in recent.enumerated() {
            for exercise in session.exercises {
                let completed = exercise.sets.filter(\.isCompleted)
                let maxWeight = completed.compactMap(\.weight).max() ?? 0
                let maxReps = completed.compactMap(\.reps).max() ?? 0
                let volume = completed.reduce(0.0) { partial, set in
                    partial + ((set.weight ?? 0) * Double(set.reps ?? 0))
                }
                if index < max(1, recent.count / 2) {
                    previousByExercise[exercise.exercise.name] = (maxWeight, maxReps, volume)
                } else {
                    latestByExercise[exercise.exercise.name] = (maxWeight, maxReps, volume)
                }
            }
        }

        let tracked = latestByExercise.keys.filter { previousByExercise[$0] != nil }
        guard !tracked.isEmpty else { return nil }

        let improved = tracked.filter { key in
            guard let prev = previousByExercise[key], let current = latestByExercise[key] else { return false }
            return current.weight > prev.weight || current.reps > prev.reps || current.volume > prev.volume
        }.count

        return Int((Double(improved) / Double(tracked.count) * 100.0).rounded())
    }

    private func detectPlateau(sessions: [CompletedWorkoutSession], days: Int = 28) -> PlateauDetection {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recent = sessions.filter { $0.endTime >= cutoff }
        guard !recent.isEmpty else {
            return PlateauDetection(isDetected: false, muscleGroup: nil, weeksSincePR: 0, message: nil)
        }

        let prs = computeStrengthSnapshot(sessions: sessions).personalRecords
        let recentPRs = prs.filter { $0.achievedAt >= cutoff }
        if !recentPRs.isEmpty {
            return PlateauDetection(isDetected: false, muscleGroup: nil, weeksSincePR: 0, message: nil)
        }

        let weeksSincePR = max(1, days / 7)
        let dominantMuscle = computeStrengthSnapshot(sessions: recent).muscleGroupVolume.first?.muscleGroup
        return PlateauDetection(
            isDetected: true,
            muscleGroup: dominantMuscle,
            weeksSincePR: weeksSincePR,
            message: dominantMuscle.map { "\($0) plateau detected. Rotate variation or adjust volume." }
        )
    }

    private func computePRVelocity(sessions: [CompletedWorkoutSession]) -> PRVelocity {
        let prs = computeStrengthSnapshot(sessions: sessions).personalRecords
        guard !prs.isEmpty else {
            return PRVelocity(workoutsPerPR: Double(max(1, sessions.count)), status: .low, hasRecordedPRs: false)
        }
        let velocity = Double(max(1, sessions.count)) / Double(max(1, prs.count))
        let status: MetricStatus
        switch velocity {
        case ..<6: status = .excellent
        case ..<10: status = .good
        case ..<14: status = .moderate
        default: status = .low
        }
        return PRVelocity(workoutsPerPR: velocity, status: status, hasRecordedPRs: true)
    }

    private func computeTrainingLoadBalance(sessions: [CompletedWorkoutSession], days: Int = 28) -> TrainingLoadBalance {
        let acuteWindow = max(7, days / 4)
        let chronicWindow = max(28, days)
        let weeklyLoad = sessionsInLast(days: acuteWindow, sessions: sessions).reduce(0.0) { $0 + $1.totalVolume }
        let chronicLoad = sessionsInLast(days: chronicWindow, sessions: sessions).reduce(0.0) { $0 + $1.totalVolume }
        let weekCount = max(1.0, Double(chronicWindow) / 7.0)
        let monthlyAvgWeekly = chronicLoad / weekCount
        let acuteWeeks = max(1.0, Double(acuteWindow) / 7.0)
        let normalizedAcute = weeklyLoad / acuteWeeks
        let ratio = monthlyAvgWeekly > 0 ? (normalizedAcute / monthlyAvgWeekly) : 0

        let status: MetricStatus
        if ratio >= 0.8 && ratio <= 1.3 {
            status = .optimal
        } else if ratio >= 0.65 && ratio <= 1.5 {
            status = .moderate
        } else {
            status = .atRisk
        }

        return TrainingLoadBalance(
            ratio: ratio,
            status: status,
            isOptimalRange: ratio >= 0.8 && ratio <= 1.3,
            hasData: chronicLoad > 0
        )
    }

    private func metricStatus(for score: Int) -> MetricStatus {
        switch score {
        case 90...100: return .excellent
        case 75...89: return .good
        case 60...74: return .moderate
        case 40...59: return .low
        default: return .atRisk
        }
    }

    private func trainingBalanceScore(from ratio: Double) -> Int {
        guard ratio > 0 else { return 0 }
        if ratio >= 0.8 && ratio <= 1.3 { return 90 }
        if ratio >= 0.65 && ratio <= 1.5 { return 70 }
        if ratio >= 0.5 && ratio <= 1.8 { return 50 }
        return 30
    }

    private func trendPercent(values: [Double], lowerIsBetter: Bool = false) -> Double? {
        guard values.count >= 2, let first = values.first, let last = values.last, first != 0 else { return nil }
        let pct = ((last - first) / abs(first)) * 100.0
        return lowerIsBetter ? (-pct) : pct
    }

    private func trendDirection(values: [Double], lowerIsBetter: Bool) -> TrendDirection {
        guard let trend = trendPercent(values: values, lowerIsBetter: lowerIsBetter) else { return .stable }
        if trend > 2 { return .improving }
        if trend < -2 { return .declining }
        return .stable
    }

    private func consecutiveImprovementDays(values: [Double], lowerIsBetter: Bool) -> Int {
        guard values.count >= 2 else { return 0 }
        var count = 0
        for index in stride(from: values.count - 1, through: 1, by: -1) {
            let current = values[index]
            let previous = values[index - 1]
            let improved = lowerIsBetter ? current < previous : current > previous
            if improved {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    private func computeRecoveryEfficiency(hrvValues: [Double]) -> Int {
        guard hrvValues.count >= 4 else { return 60 }
        let recent = Array(hrvValues.suffix(7))
        let baseline = recent.prefix(max(1, recent.count / 2))
        let latest = recent.suffix(max(1, recent.count / 2))
        let baselineAvg = baseline.reduce(0, +) / Double(baseline.count)
        let latestAvg = latest.reduce(0, +) / Double(latest.count)
        guard baselineAvg > 0 else { return 60 }
        let recoveryRatio = latestAvg / baselineAvg
        return max(0, min(100, Int((recoveryRatio * 80.0).rounded())))
    }

    private func averageVolume(forWeekday weekday: Int?, sessions: [CompletedWorkoutSession]) -> Double {
        let filtered = sessions.filter { session in
            guard let weekday else { return true }
            return Calendar.current.component(.weekday, from: session.endTime) == weekday
        }
        guard !filtered.isEmpty else { return 0 }
        return filtered.reduce(0.0) { $0 + $1.totalVolume } / Double(filtered.count)
    }

    private func averageSteps(forWeekday weekday: Int?, history: [StepHistoryPoint]) -> Double {
        let filtered = history.filter { point in
            guard let weekday else { return true }
            return Calendar.current.component(.weekday, from: point.date) == weekday
        }
        guard !filtered.isEmpty else { return 0 }
        let total = filtered.reduce(0) { $0 + $1.steps }
        return Double(total) / Double(filtered.count)
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>, default fallback: Int) -> Int {
        if self == 0 { return fallback }
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
