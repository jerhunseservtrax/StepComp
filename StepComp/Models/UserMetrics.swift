//
//  UserMetrics.swift
//  FitComp
//
//  Codable structs that map to the Supabase user_metrics tables and RPC responses.
//

import Foundation

// MARK: - Workout Session (maps to workout_sessions table)

struct SupabaseWorkoutSession: Codable, Identifiable {
    let id: String
    let userId: String
    let workoutId: String?
    let workoutName: String
    let startedAt: Date
    let endedAt: Date
    let durationSeconds: Int?
    let totalVolumeKg: Int
    let maxWeightKg: Int
    let source: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case workoutId = "workout_id"
        case workoutName = "workout_name"
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case durationSeconds = "duration_seconds"
        case totalVolumeKg = "total_volume_kg"
        case maxWeightKg = "max_weight_kg"
        case source
    }
}

// MARK: - Workout Session Set (maps to workout_session_sets table)

struct SupabaseWorkoutSet: Codable, Identifiable {
    let id: String
    let sessionId: String
    let exerciseName: String
    let targetMuscles: String?
    let setNumber: Int
    let weightKg: Int?
    let reps: Int?
    let isCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case exerciseName = "exercise_name"
        case targetMuscles = "target_muscles"
        case setNumber = "set_number"
        case weightKg = "weight_kg"
        case reps
        case isCompleted = "is_completed"
    }
}

// MARK: - Weight Log Entry (maps to weight_log table)

struct SupabaseWeightEntry: Codable, Identifiable {
    let id: String
    let userId: String
    let recordedOn: String
    let weightKg: Double
    let source: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case recordedOn = "recorded_on"
        case weightKg = "weight_kg"
        case source
    }
}

// MARK: - Metrics Summary (returned by get_user_metrics_summary RPC)

struct MetricsSummary: Codable {
    let totalWorkouts: Int
    let totalVolume: Int
    let avgDurationSeconds: Int
    let currentWeightKg: Double?
    let weightChangeKg: Double?
    let totalSteps: Int
    let avgDailySteps: Int
    let workoutStreak: Int

    enum CodingKeys: String, CodingKey {
        case totalWorkouts = "total_workouts"
        case totalVolume = "total_volume"
        case avgDurationSeconds = "avg_duration_seconds"
        case currentWeightKg = "current_weight_kg"
        case weightChangeKg = "weight_change_kg"
        case totalSteps = "total_steps"
        case avgDailySteps = "avg_daily_steps"
        case workoutStreak = "workout_streak"
    }
}

// MARK: - Exercise History Point (returned by get_exercise_history RPC)

struct ExerciseHistoryPoint: Codable, Identifiable {
    let sessionDate: String
    let maxWeightKg: Int
    let totalVolume: Int
    let maxReps: Int

    var id: String { sessionDate }

    enum CodingKeys: String, CodingKey {
        case sessionDate = "session_date"
        case maxWeightKg = "max_weight_kg"
        case totalVolume = "total_volume"
        case maxReps = "max_reps"
    }
}

// MARK: - Weight History Point (returned by get_weight_history RPC)

struct WeightHistoryPoint: Codable, Identifiable {
    let recordedOn: String
    let weightKg: Double

    var id: String { recordedOn }

    enum CodingKeys: String, CodingKey {
        case recordedOn = "recorded_on"
        case weightKg = "weight_kg"
    }

    /// Convert from a local WeightEntry
    init(entry: WeightEntry) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.recordedOn = formatter.string(from: entry.date)
        self.weightKg = entry.weightKg
    }
}

// MARK: - Workout History Point (returned by get_workout_history RPC)

struct WorkoutHistoryPoint: Codable, Identifiable {
    let sessionDate: String
    let workoutName: String
    let durationSeconds: Int
    let totalVolumeKg: Int

    var id: String { "\(sessionDate)-\(workoutName)" }

    enum CodingKeys: String, CodingKey {
        case sessionDate = "session_date"
        case workoutName = "workout_name"
        case durationSeconds = "duration_seconds"
        case totalVolumeKg = "total_volume_kg"
    }
}

enum MetricsTimePeriod: String, CaseIterable, Identifiable, Codable {
    case days
    case weeks
    case months
    case years

    var id: String { rawValue }

    var title: String {
        switch self {
        case .days:
            return "Days"
        case .weeks:
            return "Weeks"
        case .months:
            return "Months"
        case .years:
            return "Years"
        }
    }

    var lookbackDays: Int {
        switch self {
        case .days:
            return 30
        case .weeks:
            return 84
        case .months:
            return 365
        case .years:
            return 1460
        }
    }
}

enum MetricsDetailScope: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }
}

struct MetricBarPoint: Identifiable, Hashable {
    let id: String
    let date: Date
    let label: String
    let value: Double
}

struct YearMetricPoint: Identifiable, Hashable {
    let id: String
    let year: Int
    let value: Double
}

struct StepHistoryPoint: Identifiable, Hashable {
    let id: String
    let date: Date
    let steps: Int
    let distanceKm: Double
    let calories: Int
    let activeMinutes: Int
    let goalMet: Bool
}
