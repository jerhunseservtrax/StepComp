//
//  ComprehensiveMetrics.swift
//  FitComp
//

import Foundation

enum PersonalRecordType: String, Codable, CaseIterable, Identifiable {
    case maxWeight
    case maxReps
    case maxVolume

    var id: String { rawValue }

    var title: String {
        switch self {
        case .maxWeight: return "Max Weight"
        case .maxReps: return "Max Reps"
        case .maxVolume: return "Max Volume"
        }
    }
}

struct PersonalRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let exerciseName: String
    let type: PersonalRecordType
    let value: Double
    let achievedAt: Date
}

struct StrengthMetricSnapshot: Codable, Hashable {
    let totalVolume: Double
    let estimatedOneRM: Double
    let overloadSuccessRate: Int
    let strongestExercise: String?
    let personalRecords: [PersonalRecord]
    let muscleGroupVolume: [MuscleGroupVolume]
}

struct MuscleGroupVolume: Identifiable, Codable, Hashable {
    var id: String { muscleGroup }
    let muscleGroup: String
    let volume: Double
}

struct BodyMetricEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let recordedOn: Date
    let bodyFatPercent: Double?
    let waistCm: Double?
}

struct BodyMetricSnapshot: Codable, Hashable {
    let currentWeightKg: Double?
    let bodyFatPercent: Double?
    let bmi: Double?
    let leanMassKg: Double?
    let weeklyWeightChangeKg: Double?
    let weeklyLeanMassChangeKg: Double?
    let weeklyFatMassChangeKg: Double?
}

struct RecoveryMetricSnapshot: Codable, Hashable {
    let averageSleepHours: Double
    let sleepQualityScore: Int
    let restingHeartRate: Double?
    let hrv: Double?
    let vo2Max: Double?
    let readinessScore: Int
    let stressScore: Int
    let overtrainingRisk: Bool
    let suggestedRestDays: Int
}

struct CardioWorkoutMetric: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let durationSeconds: Double
    let distanceKm: Double
    let avgHeartRate: Double?
    let paceMinPerKm: Double?
    let zone1Minutes: Double
    let zone2Minutes: Double
    let zone3Minutes: Double
    let zone4Minutes: Double
    let zone5Minutes: Double
}

struct CardioMetricSnapshot: Codable, Hashable {
    let averagePaceMinPerKm: Double?
    let speedImprovementPercent: Int
    let totalZoneMinutes: Double
    let vo2Max: Double?
}

struct NutritionLog: Identifiable, Codable, Hashable {
    let id: UUID
    let loggedAt: Date
    let calories: Int
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
    let waterMl: Int
}

struct NutritionMetricSnapshot: Codable, Hashable {
    let todayCalories: Int
    let todayProteinG: Int
    let todayCarbsG: Int
    let todayFatG: Int
    let todayWaterMl: Int
    let macroAdherenceScore: Int
}

struct EngagementScores: Codable, Hashable {
    let consistencyScore: Int
    let trainingLoadScore: Int
    let performanceScore: Int
    let goalCompletionRate: Int
    let workoutStreak: Int
    let longestWorkoutStreak: Int
}

struct InsightItem: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let message: String
    let confidence: Int
}

enum DashboardTimeScope: String, CaseIterable, Identifiable {
    case daily
    case weekly
    case longTerm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .longTerm: return "Long-Term"
        }
    }
}

enum MetricStatus: String, Codable, CaseIterable, Identifiable {
    case excellent
    case optimal
    case good
    case moderate
    case low
    case atRisk

    var id: String { rawValue }

    var label: String {
        switch self {
        case .excellent: return "EXCELLENT"
        case .optimal: return "OPTIMAL"
        case .good: return "GOOD"
        case .moderate: return "MODERATE"
        case .low: return "LOW"
        case .atRisk: return "AT RISK"
        }
    }
}

enum TrendDirection: String, Codable, CaseIterable, Identifiable {
    case improving
    case stable
    case declining

    var id: String { rawValue }
}

enum RecoveryStatus: String, Codable, CaseIterable, Identifiable {
    case recovered
    case maintaining
    case fatigued
    case overreached

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

enum DailyRecommendation: String, Codable, CaseIterable, Identifiable {
    case trainHeavy
    case trainModerate
    case activeRecovery
    case restDay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .trainHeavy: return "Train heavy"
        case .trainModerate: return "Train moderate"
        case .activeRecovery: return "Active recovery"
        case .restDay: return "Rest day"
        }
    }
}

struct TrainingReadinessTrend: Codable, Hashable {
    let values: [Int]
    let direction: TrendDirection
    let daysImproving: Int
}

struct ReadinessResult: Codable, Hashable {
    let score: Int
    let status: MetricStatus
    let recoveryStatus: RecoveryStatus
    let recommendation: DailyRecommendation
    let recoveryDebtHours: Double
    let trend: TrainingReadinessTrend
    let missingInputs: [String]
}

struct PlateauDetection: Codable, Hashable {
    let isDetected: Bool
    let muscleGroup: String?
    let weeksSincePR: Int
    let message: String?
}

struct TrainingLoadBalance: Codable, Hashable {
    let ratio: Double
    let status: MetricStatus
    let isOptimalRange: Bool
    let hasData: Bool
}

struct PRVelocity: Codable, Hashable {
    let workoutsPerPR: Double
    let status: MetricStatus
    let hasRecordedPRs: Bool
}

struct PerformancePillarData: Codable, Hashable {
    let strengthTrendPercent: Double?
    let comparedLiftCount: Int?
    let strengthScore: Int
    let overloadScore: Int?
    let trainingLoadBalance: TrainingLoadBalance
    let plateauDetection: PlateauDetection
    let muscleBalance: [MuscleGroupVolume]
    let prVelocity: PRVelocity
}

struct RecoveryPillarData: Codable, Hashable {
    let hrvTrendPercent: Double?
    let hrvDirection: TrendDirection
    let rhrTrendPercent: Double?
    let rhrDirection: TrendDirection
    let stressLoadScore: Int
    let recoveryEfficiency: Int
    let overtrainingRiskScore: Int
    let overtrainingRiskStatus: MetricStatus
    let sleepQualityScore: Int

    /// Composite recovery direction blending HRV, RHR, and sleep quality.
    var compositeRecoveryDirection: TrendDirection {
        var signalSum = 0.0
        var signalCount = 0.0

        if hrvTrendPercent != nil {
            let hrvSignal: Double = hrvDirection == .improving ? 1 : (hrvDirection == .declining ? -1 : 0)
            signalSum += hrvSignal * 0.4
            signalCount += 0.4
        }

        if rhrTrendPercent != nil {
            let rhrSignal: Double = rhrDirection == .improving ? 1 : (rhrDirection == .declining ? -1 : 0)
            signalSum += rhrSignal * 0.2
            signalCount += 0.2
        }

        let sleepSignal: Double
        if sleepQualityScore >= 80 { sleepSignal = 1 }
        else if sleepQualityScore >= 60 { sleepSignal = 0 }
        else { sleepSignal = -1 }
        signalSum += sleepSignal * 0.4
        signalCount += 0.4

        guard signalCount > 0 else { return .stable }
        let normalized = signalSum / signalCount
        if normalized > 0.2 { return .improving }
        if normalized < -0.2 { return .declining }
        return .stable
    }
}

struct BodyPillarData: Codable, Hashable {
    let fatLossVelocityPerWeek: Double?
    let leanMassTrendKg60d: Double?
    let recompositionScore: Int
    let bodyTrendScore: BodyTrendScore
    let measurementConsistency: Int
}

enum BodyTrendScore: String, Codable, CaseIterable, Identifiable {
    case improving
    case maintaining
    case regressing

    var id: String { rawValue }

    var title: String { rawValue.capitalized }
}

struct MomentumScore: Codable, Hashable {
    let score: Int
    let status: MetricStatus
}

struct ConsistencyPillarData: Codable, Hashable {
    let consistencyScore: Int
    let momentumScore: MomentumScore
    let habitAdherencePercent: Int
    let workoutFrequencyPerWeek: Double
    let stepConsistencyDaysHit: Int
    let streakStrengthScore: Int
}

struct InsightsPillarData: Codable, Hashable {
    let dailyInsights: [InsightItem]
    let weeklyInsights: [InsightItem]
    let monthlyInsights: [InsightItem]
}

struct WeeklyReport: Codable, Hashable {
    let strengthChangePercent: Double?
    let comparedLiftCount: Int
    let workoutsCompleted: Int
}

struct KillerScores: Codable, Hashable {
    let momentum: Int
    let fitness: Int
    let recovery: Int
    let trainingBalance: Int
    let discipline: Int
}
