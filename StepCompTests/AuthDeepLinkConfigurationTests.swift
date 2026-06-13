//
//  AuthDeepLinkConfigurationTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class AuthDeepLinkConfigurationTests: XCTestCase {
    func testPasswordResetRedirectUsesRegisteredFitCompScheme() {
        XCTAssertEqual(AuthDeepLinkConfiguration.passwordResetRedirectURL.absoluteString, "fitcomp://reset-password")
    }

    func testOAuthCallbackSchemeMatchesRegisteredScheme() {
        XCTAssertEqual(AuthDeepLinkConfiguration.oauthCallbackScheme, "fitcomp")
    }
}
