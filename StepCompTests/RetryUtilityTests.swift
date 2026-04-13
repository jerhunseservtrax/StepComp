//
//  RetryUtilityTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class RetryUtilityTests: XCTestCase {
    func testSucceedsWithoutRetry() async throws {
        var attempts = 0
        let result: Int = try await RetryUtility.withExponentialBackoff(maxRetries: 3) {
            attempts += 1
            return 42
        }
        XCTAssertEqual(result, 42)
        XCTAssertEqual(attempts, 1)
    }

    func testRetriesOnFailureThenSucceeds() async throws {
        var attempts = 0
        let result: String = try await RetryUtility.withExponentialBackoff(maxRetries: 3) {
            attempts += 1
            if attempts < 3 {
                throw NSError(domain: "test", code: 500)
            }
            return "ok"
        }
        XCTAssertEqual(result, "ok")
        XCTAssertEqual(attempts, 3)
    }
}
