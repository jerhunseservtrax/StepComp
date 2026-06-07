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

    func testUserScopedCacheKeepsValuesIsolated() {
        OfflineCacheService.save("user-a-data", key: "metrics_summary_30", userId: "user-a")
        OfflineCacheService.save("user-b-data", key: "metrics_summary_30", userId: "user-b")

        XCTAssertEqual(
            OfflineCacheService.load(String.self, key: "metrics_summary_30", userId: "user-a"),
            "user-a-data"
        )
        XCTAssertEqual(
            OfflineCacheService.load(String.self, key: "metrics_summary_30", userId: "user-b"),
            "user-b-data"
        )
    }

    func testMissingUserIdDoesNotReadUnscopedData() {
        OfflineCacheService.save("unscoped-data", key: "metrics_summary_30")

        XCTAssertNil(OfflineCacheService.load(String.self, key: "metrics_summary_30", userId: nil))
    }
}
