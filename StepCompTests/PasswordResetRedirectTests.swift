//
//  PasswordResetRedirectTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class PasswordResetRedirectTests: XCTestCase {
    func testResetPasswordRedirectUsesRegisteredFitCompScheme() {
        XCTAssertEqual(PasswordResetRedirect.url.scheme, "fitcomp")
        XCTAssertEqual(PasswordResetRedirect.url.host, "reset-password")
    }
}
