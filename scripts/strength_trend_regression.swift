import Foundation

typealias ExerciseBestMap = [String: Double]

struct StrengthTrendResult {
    let percent: Double?
    let comparedExerciseCount: Int
}

func perExerciseBest1RMTrend(recentBest: ExerciseBestMap, priorBest: ExerciseBestMap) -> StrengthTrendResult {
    let commonExercises = Set(recentBest.keys).intersection(priorBest.keys)
    guard !commonExercises.isEmpty else {
        return StrengthTrendResult(percent: nil, comparedExerciseCount: 0)
    }

    let trends = commonExercises.compactMap { name -> Double? in
        guard let recent = recentBest[name], let prior = priorBest[name], prior > 0 else { return nil }
        return ((recent - prior) / prior) * 100.0
    }.sorted()

    guard !trends.isEmpty else {
        return StrengthTrendResult(percent: nil, comparedExerciseCount: 0)
    }

    let mid = trends.count / 2
    let median = trends.count.isMultiple(of: 2)
        ? (trends[mid - 1] + trends[mid]) / 2.0
        : trends[mid]
    return StrengthTrendResult(percent: median, comparedExerciseCount: trends.count)
}

@discardableResult
func assertTrue(_ condition: @autoclosure () -> Bool, _ message: String) -> Bool {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        return false
    }
    return true
}

func assertAlmostEqual(_ actual: Double?, _ expected: Double, tolerance: Double = 0.0001, message: String) -> Bool {
    guard let actual else {
        fputs("FAIL: \(message) (actual: nil)\n", stderr)
        return false
    }
    if abs(actual - expected) > tolerance {
        fputs("FAIL: \(message) (actual: \(actual), expected: \(expected))\n", stderr)
        return false
    }
    return true
}

func runRegressionSuite() -> Int32 {
    var passed = true

    // 1) Consistent progression across overlapping lifts
    do {
        let prior = ["Squat": 100.0, "Bench": 80.0, "Deadlift": 120.0]
        let recent = ["Squat": 110.0, "Bench": 88.0, "Deadlift": 132.0]
        let result = perExerciseBest1RMTrend(recentBest: recent, priorBest: prior)
        passed = assertTrue(result.comparedExerciseCount == 3, "Expected 3 comparable lifts") && passed
        passed = assertAlmostEqual(result.percent, 10.0, message: "Expected +10% median trend") && passed
    }

    // 2) Mixed lift changes should compute the median, not a mean
    do {
        let prior = ["Squat": 100.0, "Bench": 100.0, "Row": 100.0]
        let recent = ["Squat": 110.0, "Bench": 95.0, "Row": 100.0]
        let result = perExerciseBest1RMTrend(recentBest: recent, priorBest: prior)
        passed = assertTrue(result.comparedExerciseCount == 3, "Expected 3 comparable lifts in mixed case") && passed
        passed = assertAlmostEqual(result.percent, 0.0, message: "Expected median trend of 0% for [-5, 0, +10]") && passed
    }

    // 3) No overlapping lifts should return no numeric trend
    do {
        let prior = ["Squat": 100.0]
        let recent = ["Bench": 90.0]
        let result = perExerciseBest1RMTrend(recentBest: recent, priorBest: prior)
        passed = assertTrue(result.comparedExerciseCount == 0, "Expected 0 comparable lifts when names don't overlap") && passed
        passed = assertTrue(result.percent == nil, "Expected nil trend when no overlapping lifts") && passed
    }

    // 4) Tiny deltas near rounding boundary should survive at high precision
    do {
        let prior = ["Squat": 200.0]
        let recent = ["Squat": 201.0] // +0.5%
        let result = perExerciseBest1RMTrend(recentBest: recent, priorBest: prior)
        passed = assertTrue(result.comparedExerciseCount == 1, "Expected 1 comparable lift in tiny-delta case") && passed
        passed = assertAlmostEqual(result.percent, 0.5, message: "Expected +0.5% trend for tiny improvement") && passed
    }

    if passed {
        print("Strength trend regression suite passed.")
        return 0
    }
    return 1
}

exit(runRegressionSuite())
