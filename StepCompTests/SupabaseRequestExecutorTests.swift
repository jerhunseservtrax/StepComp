//
//  SupabaseRequestExecutorTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class SupabaseRequestExecutorTests: XCTestCase {
    func testInviteTokenBusinessErrorIsNotAuthRetryable() {
        let error = NSError(
            domain: "PostgREST",
            code: 400,
            userInfo: [NSLocalizedDescriptionKey: "Invalid invite token"]
        )

        XCTAssertFalse(SupabaseRequestExecutor.isAuthRetryableError(error))
    }

    func testUnauthorizedErrorIsAuthRetryable() {
        let error = NSError(
            domain: "PostgREST",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "401 Unauthorized"]
        )

        XCTAssertTrue(SupabaseRequestExecutor.isAuthRetryableError(error))
    }
}
