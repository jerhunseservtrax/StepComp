//
//  OfflineCacheServiceTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class OfflineCacheServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        OfflineCacheService.clearAll()
    }

    override func tearDown() {
        OfflineCacheService.clearAll()
        super.tearDown()
    }

    func testScopedKeysDoNotCollideAcrossUsers() throws {
        let userAKey = try XCTUnwrap(OfflineCacheService.scopedKey("metrics_summary_30", userId: "user-a"))
        let userBKey = try XCTUnwrap(OfflineCacheService.scopedKey("metrics_summary_30", userId: "user-b"))

        OfflineCacheService.save("a-private-metrics", key: userAKey)
        OfflineCacheService.save("b-private-metrics", key: userBKey)

        XCTAssertEqual(OfflineCacheService.load(String.self, key: userAKey), "a-private-metrics")
        XCTAssertEqual(OfflineCacheService.load(String.self, key: userBKey), "b-private-metrics")
    }

    func testScopedKeyRejectsMissingUserIdentifier() {
        XCTAssertNil(OfflineCacheService.scopedKey("metrics_summary_30", userId: nil))
        XCTAssertNil(OfflineCacheService.scopedKey("metrics_summary_30", userId: ""))
    }
}
