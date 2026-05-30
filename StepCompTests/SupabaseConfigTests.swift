//
//  SupabaseConfigTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class SupabaseConfigTests: XCTestCase {
    func testPasswordResetRedirectUsesRegisteredFitCompScheme() {
        XCTAssertEqual(SupabaseConfig.passwordResetRedirectURL.scheme, "fitcomp")
        XCTAssertEqual(SupabaseConfig.passwordResetRedirectURL.host, "reset-password")
    }
}
