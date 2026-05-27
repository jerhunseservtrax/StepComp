//
//  OfflineCacheServiceTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class OfflineCacheServiceTests: XCTestCase {
    private struct CachedMetric: Codable, Equatable {
        let value: Int
    }

    override func tearDown() {
        OfflineCacheService.clearAll()
        super.tearDown()
    }

    func testScopedKeysSeparateUsers() {
        let userAKey = OfflineCacheService.scopedKey("metrics_summary_30", userId: "user-a")
        let userBKey = OfflineCacheService.scopedKey("metrics_summary_30", userId: "user-b")

        XCTAssertNotEqual(userAKey, userBKey)
        XCTAssertTrue(userAKey.contains("user-a"))
        XCTAssertTrue(userBKey.contains("user-b"))
    }

    func testAuthFailureDoesNotReturnCachedData() async {
        let cacheKey = OfflineCacheService.scopedKey("metrics_summary_30", userId: "user-a")
        OfflineCacheService.save(CachedMetric(value: 42), key: cacheKey)

        let value: CachedMetric? = await OfflineCacheService.fetchWithFallback(key: cacheKey) {
            throw NSError(
                domain: "Supabase",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "401 unauthorized"]
            )
        }

        XCTAssertNil(value)
    }
}
