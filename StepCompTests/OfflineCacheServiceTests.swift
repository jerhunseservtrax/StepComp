//
//  OfflineCacheServiceTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class OfflineCacheServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        OfflineCacheService.clearAll()
    }

    override func tearDown() {
        OfflineCacheService.clearAll()
        super.tearDown()
    }

    func testUserScopedCacheDoesNotReturnAnotherUsersValue() {
        OfflineCacheService.save("user-a-metrics", key: "metrics_summary_30", userId: "user-a")

        let userBValue = OfflineCacheService.load(String.self, key: "metrics_summary_30", userId: "user-b")
        XCTAssertNil(userBValue)

        let userAValue = OfflineCacheService.load(String.self, key: "metrics_summary_30", userId: "user-a")
        XCTAssertEqual(userAValue, "user-a-metrics")
    }

    func testClearAllRemovesUserScopedValues() {
        OfflineCacheService.save(["steps": 1000], key: "leaderboard_challenge-1", userId: "user-a")
        OfflineCacheService.clearAll()

        let cached = OfflineCacheService.load([String: Int].self, key: "leaderboard_challenge-1", userId: "user-a")
        XCTAssertNil(cached)
    }

    func testMissingUserIdDoesNotReadOrWriteSharedCacheEntry() {
        OfflineCacheService.save("anonymous", key: "metrics_summary_30", userId: nil)

        let cached = OfflineCacheService.load(String.self, key: "metrics_summary_30", userId: nil)
        XCTAssertNil(cached)
    }
}
