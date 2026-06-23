//
//  LocalSignOutCleanupTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

@MainActor
final class LocalSignOutCleanupTests: XCTestCase {
    private let workoutKeys = [
        "saved_workouts",
        "completed_workout_sessions",
        "active_workout_draft",
        "weight_entries",
        "metrics_synced_session_ids",
        "metrics_synced_weight_entry_ids"
    ]

    override func tearDown() {
        for key in workoutKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        OfflineCacheService.clearAll()
        super.tearDown()
    }

    func testSignOutCleanupRemovesLocalFitnessSyncAndCacheState() {
        let payload = Data("private-fitness-data".utf8)
        UserDefaults.standard.set(payload, forKey: "saved_workouts")
        UserDefaults.standard.set(payload, forKey: "completed_workout_sessions")
        UserDefaults.standard.set(payload, forKey: "active_workout_draft")
        UserDefaults.standard.set(payload, forKey: "weight_entries")
        UserDefaults.standard.set(["session-a"], forKey: "metrics_synced_session_ids")
        UserDefaults.standard.set(["weight-a"], forKey: "metrics_synced_weight_entry_ids")
        OfflineCacheService.save("cached-private-metrics", key: "metrics_summary_30")
        ChallengeService.shared.leaderboardEntries["challenge-a"] = []

        WorkoutViewModel.clearUserScopedWorkoutDataForSignOut()
        WeightViewModel.clearUserScopedWeightDataForSignOut()
        MetricsService.shared.clearUserScopedSyncStateForSignOut()
        ChallengeService.shared.clearUserScopedDataForSignOut()
        OfflineCacheService.clearAll()

        for key in workoutKeys {
            XCTAssertNil(UserDefaults.standard.object(forKey: key), "\(key) should be cleared")
        }
        XCTAssertTrue(ChallengeService.shared.leaderboardEntries.isEmpty)
        XCTAssertNil(OfflineCacheService.load(String.self, key: "metrics_summary_30"))
    }

    func testOfflineCacheKeysAreScopedByUser() {
        let baseKey = "metrics_summary_30"
        let userAKey = OfflineCacheService.scopedKey(baseKey, userId: "user-a")
        let userBKey = OfflineCacheService.scopedKey(baseKey, userId: "user-b")

        XCTAssertNotEqual(userAKey, userBKey)

        OfflineCacheService.save("user-a-cache", key: userAKey)
        OfflineCacheService.save("user-b-cache", key: userBKey)

        XCTAssertEqual(OfflineCacheService.load(String.self, key: userAKey), "user-a-cache")
        XCTAssertEqual(OfflineCacheService.load(String.self, key: userBKey), "user-b-cache")
    }
}
