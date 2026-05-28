//
//  SensitiveURLRedactorTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class SensitiveURLRedactorTests: XCTestCase {
    func testRedactsOAuthTokensFromFragment() {
        let url = URL(string: "fitcomp://auth-callback#access_token=access123&refresh_token=refresh456&type=recovery")!

        let redacted = SensitiveURLRedactor.redacted(url)

        XCTAssertFalse(redacted.contains("access123"))
        XCTAssertFalse(redacted.contains("refresh456"))
        XCTAssertTrue(redacted.contains("access_token=%5BREDACTED%5D"))
        XCTAssertTrue(redacted.contains("refresh_token=%5BREDACTED%5D"))
        XCTAssertTrue(redacted.contains("type=recovery"))
    }

    func testRedactsOAuthCodesFromQuery() {
        let url = URL(string: "fitcomp://auth-callback?code=auth-code-123&state=visible")!

        let redacted = SensitiveURLRedactor.redacted(url)

        XCTAssertFalse(redacted.contains("auth-code-123"))
        XCTAssertTrue(redacted.contains("code=%5BREDACTED%5D"))
        XCTAssertTrue(redacted.contains("state=visible"))
    }
}
