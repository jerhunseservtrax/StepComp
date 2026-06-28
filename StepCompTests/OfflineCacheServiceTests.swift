//
//  OfflineCacheServiceTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class OfflineCacheServiceTests: XCTestCase {
    func testUserScopedKeySeparatesUsersForSameLogicalCacheKey() {
        let logicalKey = "weight_history_90"

        let firstUserKey = OfflineCacheService.userScopedKey(logicalKey, userId: "user-a")
        let secondUserKey = OfflineCacheService.userScopedKey(logicalKey, userId: "user-b")

        XCTAssertNotEqual(firstUserKey, secondUserKey)
        XCTAssertTrue(firstUserKey.contains("user-a"))
        XCTAssertTrue(secondUserKey.contains("user-b"))
        XCTAssertTrue(firstUserKey.hasSuffix(logicalKey))
        XCTAssertTrue(secondUserKey.hasSuffix(logicalKey))
    }
}
