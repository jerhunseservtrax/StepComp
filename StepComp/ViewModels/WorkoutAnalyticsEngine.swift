//
//  WorkoutAnalyticsEngine.swift
//  FitComp
//

import Foundation

// MARK: - Exercise History Data

/// A single recorded set from a completed session, used for trend analysis.
struct HistoricalSet {
    let date: Date
    let weight: Double
    let reps: Int

    var volume: Double { weight * Double(reps) }
}

/// The trend detected from analyzing historical performance.
enum OverloadTrend: String {
    case progressing   // Volume trending upward
    case plateau       // Stuck at same level for 3+ sessions
    case regressing    // Volume trending downward
    case newExercise   // Fewer than 3 data points
}

/// A smart progressive overload recommendation.
struct OverloadSuggestion {
    let suggestedWeight: Double
    let suggestedReps: Int
    let trend: OverloadTrend
    /// A short description of why this was suggested (shown in UI).
    let reasoning: String
}

// MARK: - Smart Rest Timer

/// Suggested rest duration based on set exertion.
struct RestSuggestion {
    let duration: TimeInterval
    let reasoning: String
}

// MARK: - Engine

struct WorkoutAnalyticsEngine {

    // MARK: - 1RM Estimation

    func estimatedOneRepMax(weight: Double, reps: Int) -> Double {
        guard reps >= 1 && reps <= 10 else { return weight }
        if reps == 1 { return weight }
        // Brzycki formula
        return weight * (1.0 + Double(reps) / 30.0)
    }

    // MARK: - Legacy Simple Suggestion (kept for fallback)

    func progressiveOverloadSuggestion(previousWeight: Double?, previousReps: Int?) -> (Double?, Int?) {
        guard let prevWeight = previousWeight, let prevReps = previousReps else {
            return (nil, nil)
        }

        if prevReps >= 10 {
            return (prevWeight + 2.5, 8)
        } else if prevReps >= 8 {
            return (prevWeight, min(10, prevReps + 1))
        } else {
            return (prevWeight, prevReps)
        }
    }

    // MARK: - Smart Progressive Overload (Last 10 Sessions)

    /// Analyzes up to the last 10 completed sets for a specific exercise and set number,
    /// then produces a data-driven suggestion for the next workout.
    ///
    /// Algorithm overview:
    /// 1. Gather historical sets (up to 10 most recent sessions)
    /// 2. Compute per-session volume (weight x reps) and detect trend via linear regression
    /// 3. Detect plateaus (3+ consecutive sessions at same weight & reps)
    /// 4. Detect regression (negative volume slope over recent sessions)
    /// 5. Suggest based on trend:
    ///    - Progressing: small weight bump if reps are at top of range, else add a rep
    ///    - Plateau: force a micro-progression (weight bump or rep bump)
    ///    - Regressing: recommend deload (reduce weight ~10%, reset reps to comfortable range)
    ///    - New exercise: use simple last-set-based logic
    func smartOverloadSuggestion(
        history: [HistoricalSet],
        exerciseName: String
    ) -> OverloadSuggestion? {
        guard !history.isEmpty else { return nil }

        // Sort newest first
        let sorted = history.sorted { $0.date > $1.date }

        let increment = weightIncrement(for: exerciseName)
        let isCompound = isCompoundExercise(exerciseName)

        // Need at least 3 data points for trend analysis
        guard sorted.count >= 3 else {
            return newExerciseSuggestion(from: sorted, increment: increment)
        }

        let trend = detectTrend(sorted)
        let latest = sorted[0]

        switch trend {
        case .progressing:
            return progressingSuggestion(latest: latest, increment: increment, isCompound: isCompound)
        case .plateau:
            return plateauSuggestion(latest: latest, increment: increment, isCompound: isCompound)
        case .regressing:
            return regressingSuggestion(latest: latest, history: sorted, increment: increment)
        case .newExercise:
            return newExerciseSuggestion(from: sorted, increment: increment)
        }
    }

    // MARK: - Trend Detection

    private func detectTrend(_ sortedHistory: [HistoricalSet]) -> OverloadTrend {
        // Check for plateau first: 3+ most recent at same weight AND reps
        if isPlateaued(sortedHistory) {
            return .plateau
        }

        // Use linear regression on volume (oldest to newest) to detect slope
        let volumes = sortedHistory.reversed().map { $0.volume } // oldest first
        let slope = linearRegressionSlope(values: volumes)

        // Also check weight trend specifically
        let weights = sortedHistory.reversed().map { $0.weight }
        let weightSlope = linearRegressionSlope(values: weights)

        // Threshold: if volume slope is meaningfully negative, regressing
        let avgVolume = volumes.reduce(0, +) / Double(volumes.count)
        let relativeSlope = avgVolume > 0 ? slope / avgVolume : 0

        if relativeSlope < -0.03 && weightSlope <= 0 {
            // Volume dropping by more than 3% per session AND weight isn't going up
            return .regressing
        }

        if relativeSlope > 0.01 || weightSlope > 0 {
            return .progressing
        }

        // Flat but not plateaued by strict definition
        return .plateau
    }

    private func isPlateaued(_ sortedHistory: [HistoricalSet]) -> Bool {
        guard sortedHistory.count >= 3 else { return false }

        let recent = Array(sortedHistory.prefix(3))
        let firstWeight = recent[0].weight
        let firstReps = recent[0].reps

        return recent.allSatisfy { set in
            abs(set.weight - firstWeight) < 0.01 && set.reps == firstReps
        }
    }

    // MARK: - Suggestion Generators

    private func progressingSuggestion(
        latest: HistoricalSet,
        increment: Double,
        isCompound: Bool
    ) -> OverloadSuggestion {
        let topReps = isCompound ? 8 : 12
        let baseReps = isCompound ? 5 : 8

        if latest.reps >= topReps {
            // At top of rep range → bump weight, reset to base reps
            return OverloadSuggestion(
                suggestedWeight: roundToIncrement(latest.weight + increment, increment: increment),
                suggestedReps: baseReps,
                trend: .progressing,
                reasoning: "Strong progress — add weight, reset reps"
            )
        } else {
            // Not at top of range yet → add a rep
            return OverloadSuggestion(
                suggestedWeight: latest.weight,
                suggestedReps: latest.reps + 1,
                trend: .progressing,
                reasoning: "Progressing well — add 1 rep"
            )
        }
    }

    private func plateauSuggestion(
        latest: HistoricalSet,
        increment: Double,
        isCompound: Bool
    ) -> OverloadSuggestion {
        let topReps = isCompound ? 8 : 12

        if latest.reps >= topReps {
            // At top of rep range during plateau → micro weight increase
            return OverloadSuggestion(
                suggestedWeight: roundToIncrement(latest.weight + increment, increment: increment),
                suggestedReps: latest.reps - 2,
                trend: .plateau,
                reasoning: "Plateau detected — micro weight increase"
            )
        } else {
            // Can still push reps before adding weight
            return OverloadSuggestion(
                suggestedWeight: latest.weight,
                suggestedReps: latest.reps + 1,
                trend: .plateau,
                reasoning: "Plateau detected — push for 1 more rep"
            )
        }
    }

    private func regressingSuggestion(
        latest: HistoricalSet,
        history: [HistoricalSet],
        increment: Double
    ) -> OverloadSuggestion {
        // Find the best recent performance to base deload on
        let bestRecent = history.prefix(5).max(by: { $0.volume < $1.volume }) ?? latest

        // Deload: reduce weight by ~10%, round to nearest increment
        let deloadWeight = roundToIncrement(bestRecent.weight * 0.9, increment: increment)
        let deloadReps = max(bestRecent.reps, latest.reps) // keep the higher rep count

        return OverloadSuggestion(
            suggestedWeight: max(increment, deloadWeight), // never suggest 0
            suggestedReps: deloadReps,
            trend: .regressing,
            reasoning: "Performance dipping — deload to rebuild"
        )
    }

    private func newExerciseSuggestion(
        from sortedHistory: [HistoricalSet],
        increment: Double
    ) -> OverloadSuggestion {
        let latest = sortedHistory[0]

        if latest.reps >= 10 {
            return OverloadSuggestion(
                suggestedWeight: roundToIncrement(latest.weight + increment, increment: increment),
                suggestedReps: 8,
                trend: .newExercise,
                reasoning: "Building baseline — try adding weight"
            )
        } else if latest.reps >= 6 {
            return OverloadSuggestion(
                suggestedWeight: latest.weight,
                suggestedReps: latest.reps + 1,
                trend: .newExercise,
                reasoning: "Building baseline — add 1 rep"
            )
        } else {
            return OverloadSuggestion(
                suggestedWeight: latest.weight,
                suggestedReps: latest.reps,
                trend: .newExercise,
                reasoning: "Building baseline — hold steady"
            )
        }
    }

    // MARK: - Smart Rest Timer Suggestion

    /// Suggests rest duration based on the exertion of the just-completed set.
    ///
    /// Factors considered:
    /// 1. Relative intensity: how close the weight is to the user's estimated 1RM
    /// 2. Exercise type: compound lifts need more rest than isolation
    /// 3. Rep count: lower reps at heavy weight = more rest needed
    /// 4. Volume load of the set: weight × reps as absolute effort indicator
    ///
    /// Rest guidelines (based on sports science):
    /// - >85% 1RM or <5 reps heavy compound: 3-5 min
    /// - 70-85% 1RM moderate compound: 2-3 min
    /// - 50-70% 1RM or isolation work: 60-90 sec
    /// - Light/high-rep or bodyweight: 30-60 sec
    func suggestRestDuration(
        completedWeight: Double,
        completedReps: Int,
        exerciseName: String,
        exerciseHistory: [HistoricalSet]
    ) -> RestSuggestion {
        let compound = isCompoundExercise(exerciseName)

        // Estimate 1RM from history or current set
        let estimated1RM = bestEstimated1RM(
            currentWeight: completedWeight,
            currentReps: completedReps,
            history: exerciseHistory
        )

        // Calculate relative intensity (% of 1RM)
        let intensity: Double
        if estimated1RM > 0 {
            intensity = completedWeight / estimated1RM
        } else {
            // No history — estimate from reps alone
            intensity = completedReps <= 3 ? 0.9 : completedReps <= 6 ? 0.8 : completedReps <= 10 ? 0.7 : 0.6
        }

        // Determine rest based on intensity + exercise type
        let (duration, reasoning) = restForIntensity(
            intensity: intensity,
            reps: completedReps,
            isCompound: compound
        )

        return RestSuggestion(duration: duration, reasoning: reasoning)
    }

    private func restForIntensity(
        intensity: Double,
        reps: Int,
        isCompound: Bool
    ) -> (TimeInterval, String) {
        if isCompound {
            if intensity >= 0.85 || reps <= 3 {
                return (240, "Heavy compound — long rest")  // 4 min
            } else if intensity >= 0.75 || reps <= 5 {
                return (180, "Moderate-heavy — solid rest")  // 3 min
            } else if intensity >= 0.65 || reps <= 8 {
                return (120, "Moderate effort — standard rest")  // 2 min
            } else {
                return (90, "Lighter compound — shorter rest")  // 1.5 min
            }
        } else {
            // Isolation exercises
            if intensity >= 0.85 || reps <= 4 {
                return (120, "Heavy isolation — extra rest")  // 2 min
            } else if intensity >= 0.70 || reps <= 8 {
                return (90, "Moderate isolation — standard rest")  // 1.5 min
            } else {
                return (60, "Light isolation — quick rest")  // 1 min
            }
        }
    }

    private func bestEstimated1RM(
        currentWeight: Double,
        currentReps: Int,
        history: [HistoricalSet]
    ) -> Double {
        var best = estimatedOneRepMax(weight: currentWeight, reps: currentReps)

        for set in history where set.reps >= 1 && set.reps <= 10 {
            let e1rm = estimatedOneRepMax(weight: set.weight, reps: set.reps)
            best = max(best, e1rm)
        }

        return best
    }

    // MARK: - Exercise Classification

    /// Returns the appropriate weight increment for an exercise (in kg).
    /// Compounds get larger jumps, isolation gets smaller.
    func weightIncrement(for exerciseName: String) -> Double {
        if isCompoundExercise(exerciseName) {
            return 2.5  // kg
        } else {
            return 1.25 // kg
        }
    }

    /// Determines if an exercise is a compound movement based on name.
    func isCompoundExercise(_ name: String) -> Bool {
        let n = name.lowercased()
        let compounds = [
            "squat", "deadlift", "bench press", "overhead press", "military press",
            "barbell row", "bent over row", "pendlay row", "hip thrust",
            "pull-up", "chin-up", "dip", "push press", "clean", "snatch",
            "thruster", "good morning", "front squat", "hack squat",
            "leg press", "romanian deadlift", "sumo deadlift",
            "incline bench", "decline bench", "close grip bench",
            "flat bench", "inverted row", "row (machine)", "seated row",
            "cable row", "lat pulldown", "farmer"
        ]
        return compounds.contains { n.contains($0) }
    }

    // MARK: - Math Utilities

    /// Simple linear regression slope for evenly-spaced values.
    /// Positive slope = values trending up over time.
    private func linearRegressionSlope(values: [Double]) -> Double {
        let n = Double(values.count)
        guard n >= 2 else { return 0 }

        var sumX: Double = 0
        var sumY: Double = 0
        var sumXY: Double = 0
        var sumX2: Double = 0

        for (i, y) in values.enumerated() {
            let x = Double(i)
            sumX += x
            sumY += y
            sumXY += x * y
            sumX2 += x * x
        }

        let denominator = n * sumX2 - sumX * sumX
        guard abs(denominator) > 0.0001 else { return 0 }

        return (n * sumXY - sumX * sumY) / denominator
    }

    /// Rounds a weight to the nearest increment (e.g., nearest 2.5kg or 1.25kg).
    private func roundToIncrement(_ weight: Double, increment: Double) -> Double {
        return (weight / increment).rounded() * increment
    }
}
