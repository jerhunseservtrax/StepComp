//
//  OfflineCacheServiceTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class OfflineCacheServiceTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        OfflineCacheService.clearAll()
    }

    func testFetchFallbackDoesNotLeakDataAcrossUsers() async {
        OfflineCacheService.clearAll()

        let key = "metrics_summary_30"
        let userA = "user-a"
        let userB = "user-b"

        let savedForUserA: String? = await OfflineCacheService.fetchWithFallback(key: key, userId: userA) {
            "alice-private-metrics"
        }
        XCTAssertEqual(savedForUserA, "alice-private-metrics")

        let fallbackForUserB: String? = await OfflineCacheService.fetchWithFallback(key: key, userId: userB) {
            throw NSError(domain: "network", code: -1009)
        }

        XCTAssertNil(fallbackForUserB)

        let fallbackWithoutUser: String? = await OfflineCacheService.fetchWithFallback(key: key, userId: nil) {
            throw NSError(domain: "network", code: -1009)
        }

        XCTAssertNil(fallbackWithoutUser)
    }
}
