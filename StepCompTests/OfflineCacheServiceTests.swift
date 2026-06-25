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

    func testClearAllRemovesCachedUserData() {
        let key = "test_metrics_summary_\(UUID().uuidString)"
        OfflineCacheService.save(["steps": 12_345], key: key)

        let cachedBeforeClear = OfflineCacheService.load([String: Int].self, key: key)
        XCTAssertEqual(cachedBeforeClear?["steps"], 12_345)

        OfflineCacheService.clearAll()

        XCTAssertNil(OfflineCacheService.load([String: Int].self, key: key))
    }
}
