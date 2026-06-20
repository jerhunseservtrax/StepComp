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

    func testScopedCacheDoesNotLeakAcrossUsers() {
        OfflineCacheService.save("user-a-metrics", key: "metrics_summary_30", scope: "user-a")

        let userBCached = OfflineCacheService.load(String.self, key: "metrics_summary_30", scope: "user-b")

        XCTAssertNil(userBCached)
    }

    func testClearAllRemovesScopedCaches() {
        OfflineCacheService.save("cached", key: "weight_history_90", scope: "user-a")

        OfflineCacheService.clearAll()

        XCTAssertNil(OfflineCacheService.load(String.self, key: "weight_history_90", scope: "user-a"))
    }
}
