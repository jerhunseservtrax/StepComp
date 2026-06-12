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

    func testUserScopedKeysPreventCrossAccountFallback() {
        let baseKey = "metrics_summary_30"
        let userAKey = OfflineCacheService.userScopedKey(baseKey, userId: "user-a")
        let userBKey = OfflineCacheService.userScopedKey(baseKey, userId: "user-b")

        OfflineCacheService.save(["steps": 12_345], key: userAKey)

        let userAValue = OfflineCacheService.load([String: Int].self, key: userAKey)
        let userBValue = OfflineCacheService.load([String: Int].self, key: userBKey)

        XCTAssertEqual(userAValue?["steps"], 12_345)
        XCTAssertNil(userBValue)
    }
}
