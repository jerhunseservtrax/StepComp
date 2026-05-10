//
//  OfflineCacheServiceTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class OfflineCacheServiceTests: XCTestCase {
    override func tearDown() {
        OfflineCacheService.clearAll()
        super.tearDown()
    }

    func testUserScopedKeysDoNotShareCachedValues() {
        let baseKey = "metrics_summary_30"
        let firstUserKey = OfflineCacheService.userScopedKey(baseKey, userId: "user-a")
        let secondUserKey = OfflineCacheService.userScopedKey(baseKey, userId: "user-b")

        OfflineCacheService.save("first-user-metrics", key: firstUserKey)

        XCTAssertEqual(OfflineCacheService.load(String.self, key: firstUserKey), "first-user-metrics")
        XCTAssertNil(OfflineCacheService.load(String.self, key: secondUserKey))
    }

    func testClearAllRemovesUserScopedEntries() {
        let cacheKey = OfflineCacheService.userScopedKey("weight_history_90", userId: "user-a")
        OfflineCacheService.save(["cached-weight"], key: cacheKey)

        OfflineCacheService.clearAll()

        XCTAssertNil(OfflineCacheService.load([String].self, key: cacheKey))
    }
}
