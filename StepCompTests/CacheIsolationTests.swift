//
//  CacheIsolationTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class CacheIsolationTests: XCTestCase {
    override func tearDown() {
        OfflineCacheService.clearAll()
        ChallengeService.clearPersistedLocalData()
        super.tearDown()
    }

    func testSignOutCacheCleanupRemovesOfflineCacheData() {
        OfflineCacheService.save(["private": "metrics"], key: "metrics_summary_30")
        XCTAssertNotNil(OfflineCacheService.load([String: String].self, key: "metrics_summary_30"))

        OfflineCacheService.clearAll()

        XCTAssertNil(OfflineCacheService.load([String: String].self, key: "metrics_summary_30"))
    }

    func testSignOutCacheCleanupRemovesPersistedChallengeFallbacks() {
        UserDefaults.standard.set(Data([1, 2, 3]), forKey: "challenges")
        UserDefaults.standard.set(Data([4, 5, 6]), forKey: "leaderboard")

        ChallengeService.clearPersistedLocalData()

        XCTAssertNil(UserDefaults.standard.data(forKey: "challenges"))
        XCTAssertNil(UserDefaults.standard.data(forKey: "leaderboard"))
    }
}
