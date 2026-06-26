//
//  OfflineCacheServiceTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class OfflineCacheServiceTests: XCTestCase {
    func testUserScopedKeysSeparateAccounts() {
        let baseKey = "metrics_summary_30"

        let userAKey = OfflineCacheService.userScopedKey(baseKey, userId: "user-a")
        let userBKey = OfflineCacheService.userScopedKey(baseKey, userId: "user-b")

        XCTAssertNotEqual(userAKey, userBKey)
        XCTAssertTrue(userAKey.contains("user-a"))
        XCTAssertTrue(userBKey.contains("user-b"))
        XCTAssertTrue(userAKey.hasSuffix(baseKey))
        XCTAssertTrue(userBKey.hasSuffix(baseKey))
    }
}
