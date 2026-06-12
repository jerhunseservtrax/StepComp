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

    func testUserScopedKeysNormalizeUserIdCase() {
        let baseKey = "weight_history_90"

        XCTAssertEqual(
            OfflineCacheService.userScopedKey(baseKey, userId: "A3F7E3D1-8E8A-4D8D-9B33-2D648F4D62B0"),
            OfflineCacheService.userScopedKey(baseKey, userId: "a3f7e3d1-8e8a-4d8d-9b33-2d648f4d62b0")
        )
    }
}
