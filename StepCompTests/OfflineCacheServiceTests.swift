//
//  OfflineCacheServiceTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class OfflineCacheServiceTests: XCTestCase {
    override func tearDown() {
        OfflineCacheService.clearUserScope()
        OfflineCacheService.clearAll()
        super.tearDown()
    }

    func testCacheEntriesAreScopedByUser() {
        OfflineCacheService.clearAll()

        OfflineCacheService.setUserScope("user-a")
        OfflineCacheService.save(["steps": 12345], key: "metrics_summary_30")

        OfflineCacheService.setUserScope("user-b")
        let userBCachedValue = OfflineCacheService.load([String: Int].self, key: "metrics_summary_30")
        XCTAssertNil(userBCachedValue)

        OfflineCacheService.setUserScope("user-a")
        let userACachedValue = OfflineCacheService.load([String: Int].self, key: "metrics_summary_30")
        XCTAssertEqual(userACachedValue?["steps"], 12345)
    }

    func testClearingUserScopeDoesNotReadPrivateScopedEntries() {
        OfflineCacheService.clearAll()

        OfflineCacheService.setUserScope("user-a")
        OfflineCacheService.save(["steps": 12345], key: "metrics_summary_30")

        OfflineCacheService.clearUserScope()
        let unscopedValue = OfflineCacheService.load([String: Int].self, key: "metrics_summary_30")

        XCTAssertNil(unscopedValue)
    }

    func testUnscopedSavesAreIgnored() {
        OfflineCacheService.clearAll()
        OfflineCacheService.clearUserScope()

        OfflineCacheService.save(["steps": 12345], key: "metrics_summary_30")

        OfflineCacheService.setUserScope("user-a")
        let scopedValue = OfflineCacheService.load([String: Int].self, key: "metrics_summary_30")

        XCTAssertNil(scopedValue)
    }

    func testFetchResultIsDiscardedWhenUserScopeChangesBeforeCompletion() async {
        OfflineCacheService.clearAll()
        OfflineCacheService.setUserScope("user-a")

        let result: [String: Int]? = await OfflineCacheService.fetchWithFallback(key: "metrics_summary_30") {
            OfflineCacheService.setUserScope("user-b")
            return ["steps": 12345]
        }

        XCTAssertNil(result)

        let userBCachedValue = OfflineCacheService.load([String: Int].self, key: "metrics_summary_30")
        XCTAssertNil(userBCachedValue)
    }
}
