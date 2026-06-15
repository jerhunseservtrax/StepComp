//
//  OfflineCacheServiceTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class OfflineCacheServiceTests: XCTestCase {
    private let personalMetricsKey = "metrics_summary_30"

    override func setUp() {
        super.setUp()
        OfflineCacheService.clearAll()
    }

    override func tearDown() {
        OfflineCacheService.clearAll()
        super.tearDown()
    }

    func testUserScopedFallbackDoesNotReturnAnotherUsersCachedPersonalData() async {
        OfflineCacheService.save("user-a-private-metrics", key: personalMetricsKey, userId: "user-a")

        let userBFallback: String? = await OfflineCacheService.fetchWithFallback(
            key: personalMetricsKey,
            userId: "user-b"
        ) {
            throw NSError(domain: "OfflineCacheServiceTests", code: 1)
        }

        XCTAssertNil(userBFallback)
        XCTAssertEqual(
            OfflineCacheService.load(String.self, key: personalMetricsKey, userId: "user-a"),
            "user-a-private-metrics"
        )
    }
}
