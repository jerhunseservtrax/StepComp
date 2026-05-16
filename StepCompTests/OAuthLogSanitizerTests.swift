//
//  OAuthLogSanitizerTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class OAuthLogSanitizerTests: XCTestCase {
    func testRedactedDescriptionRemovesQueryAndFragmentSecrets() {
        let url = URL(string: "fitcomp://auth/callback?code=secret-code#access_token=secret-token&refresh_token=secret-refresh")!

        let description = OAuthLogSanitizer.redactedDescription(for: url)

        XCTAssertEqual(description, "fitcomp://auth/callback?<redacted>#<redacted>")
        XCTAssertFalse(description.contains("secret-code"))
        XCTAssertFalse(description.contains("secret-token"))
        XCTAssertFalse(description.contains("secret-refresh"))
    }
}
