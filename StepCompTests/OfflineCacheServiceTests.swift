//
//  OfflineCacheServiceTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class OfflineCacheServiceTests: XCTestCase {
    private struct CachedSummary: Codable, Equatable {
        let owner: String
        let value: Int
    }

    override func setUp() {
        super.setUp()
        OfflineCacheService.clearAll()
        OfflineCacheService.setUserScope(userId: nil)
    }

    override func tearDown() {
        OfflineCacheService.clearAll()
        OfflineCacheService.setUserScope(userId: nil)
        super.tearDown()
    }

    func testCacheKeysAreIsolatedByUserScope() {
        OfflineCacheService.setUserScope(userId: "user-a")
        OfflineCacheService.save(CachedSummary(owner: "user-a", value: 10), key: "metrics_summary_30")

        OfflineCacheService.setUserScope(userId: "user-b")

        XCTAssertNil(
            OfflineCacheService.load(CachedSummary.self, key: "metrics_summary_30"),
            "A second signed-in user must not read the previous user's cached metrics."
        )
    }

    func testClearAllRemovesScopedCacheData() {
        OfflineCacheService.setUserScope(userId: "user-a")
        OfflineCacheService.save(CachedSummary(owner: "user-a", value: 10), key: "metrics_summary_30")

        OfflineCacheService.clearAll()

        XCTAssertNil(OfflineCacheService.load(CachedSummary.self, key: "metrics_summary_30"))
    }

    func testFetchWithFallbackDropsResultWhenScopeChanges() async {
        OfflineCacheService.setUserScope(userId: "user-a")

        let result = await OfflineCacheService.fetchWithFallback(key: "metrics_summary_30") {
            OfflineCacheService.setUserScope(userId: "user-b")
            return CachedSummary(owner: "user-a", value: 10)
        }

        XCTAssertNil(result)
        XCTAssertNil(OfflineCacheService.load(CachedSummary.self, key: "metrics_summary_30"))

        OfflineCacheService.setUserScope(userId: "user-a")
        XCTAssertNil(OfflineCacheService.load(CachedSummary.self, key: "metrics_summary_30"))
    }
}
