//
//  UserScopedPersistenceTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class UserScopedPersistenceTests: XCTestCase {
    func testOfflineCacheKeyIncludesUserScope() {
        let logicalKey = "metrics_summary_30"

        let firstUserKey = OfflineCacheService.userScopedKey(logicalKey, userId: "user-a")
        let secondUserKey = OfflineCacheService.userScopedKey(logicalKey, userId: "user-b")

        XCTAssertNotEqual(firstUserKey, secondUserKey)
        XCTAssertTrue(firstUserKey.contains("user-a"))
        XCTAssertTrue(secondUserKey.contains("user-b"))
    }

    func testMetricsSyncTrackingKeysIncludeUserScope() {
        let firstUserKey = MetricsService.userScopedPersistenceKey("metrics_synced_session_ids", userId: "user-a")
        let secondUserKey = MetricsService.userScopedPersistenceKey("metrics_synced_session_ids", userId: "user-b")

        XCTAssertNotEqual(firstUserKey, secondUserKey)
        XCTAssertTrue(firstUserKey.contains("user-a"))
        XCTAssertTrue(secondUserKey.contains("user-b"))
    }
}
