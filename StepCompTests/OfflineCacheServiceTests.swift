//
//  OfflineCacheServiceTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class OfflineCacheServiceTests: XCTestCase {
    func testUserScopedKeySeparatesSameCacheEntryAcrossUsers() {
        let userAKey = OfflineCacheService.userScopedKey("metrics_summary_30", userId: "user-a")
        let userBKey = OfflineCacheService.userScopedKey("metrics_summary_30", userId: "user-b")

        XCTAssertNotEqual(userAKey, userBKey)
        XCTAssertEqual(userAKey, OfflineCacheService.userScopedKey("metrics_summary_30", userId: "user-a"))
    }

    func testMetricsCacheKeysAreUserScoped() {
        XCTAssertNotEqual(
            MetricsService.metricsSummaryCacheKey(days: 30, userId: "user-a"),
            MetricsService.metricsSummaryCacheKey(days: 30, userId: "user-b")
        )
        XCTAssertNotEqual(
            MetricsService.weightHistoryCacheKey(days: 90, userId: "user-a"),
            MetricsService.weightHistoryCacheKey(days: 90, userId: "user-b")
        )
        XCTAssertNotEqual(
            MetricsService.workoutHistoryCacheKey(days: 90, userId: "user-a"),
            MetricsService.workoutHistoryCacheKey(days: 90, userId: "user-b")
        )
    }
}
