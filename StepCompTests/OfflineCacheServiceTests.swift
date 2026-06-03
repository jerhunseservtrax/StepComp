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

    func testUserScopedCacheDoesNotLeakAcrossUsers() {
        OfflineCacheService.save("user-a-metrics", key: "metrics_summary_30", userId: "user-a")

        XCTAssertEqual(
            OfflineCacheService.load(String.self, key: "metrics_summary_30", userId: "user-a"),
            "user-a-metrics"
        )
        XCTAssertNil(
            OfflineCacheService.load(String.self, key: "metrics_summary_30", userId: "user-b")
        )
    }

    func testClearAllRemovesUserScopedCache() {
        OfflineCacheService.save("cached-weight-history", key: "weight_history_90", userId: "user-a")

        OfflineCacheService.clearAll()

        XCTAssertNil(
            OfflineCacheService.load(String.self, key: "weight_history_90", userId: "user-a")
        )
    }
}
