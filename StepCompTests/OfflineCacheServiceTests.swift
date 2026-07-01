//
//  OfflineCacheServiceTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class OfflineCacheServiceTests: XCTestCase {
    override func tearDown() {
        OfflineCacheService.clearAll()
        super.tearDown()
    }

    func testUserScopedKeysPreventCrossUserFallbackReads() {
        let baseKey = "metrics_summary_30"
        let userAKey = OfflineCacheService.userScopedKey(baseKey, userId: "USER-A")
        let userBKey = OfflineCacheService.userScopedKey(baseKey, userId: "USER-B")

        XCTAssertNotEqual(userAKey, userBKey)

        OfflineCacheService.save(["steps": 12_345], key: userAKey)

        XCTAssertEqual(
            OfflineCacheService.load([String: Int].self, key: userAKey)?["steps"],
            12_345
        )
        XCTAssertNil(OfflineCacheService.load([String: Int].self, key: userBKey))
    }
}
