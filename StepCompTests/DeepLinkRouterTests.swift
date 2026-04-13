//
//  DeepLinkRouterTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class DeepLinkRouterTests: XCTestCase {
    private var router: DeepLinkRouter!

    override func setUp() {
        super.setUp()
        router = DeepLinkRouter.shared
        router.pendingInviteToken = nil
        router.pendingPasswordResetURL = nil
    }

    func testCustomSchemeInviteToken() {
        let url = URL(string: "fitcomp://friend-invite?token=ABCD1234")!
        router.handle(url: url)
        XCTAssertEqual(router.pendingInviteToken, "ABCD1234")
    }

    func testInvalidTokenTooShort() {
        let url = URL(string: "fitcomp://friend-invite?token=AB")!
        router.handle(url: url)
        XCTAssertNil(router.pendingInviteToken)
    }

    func testInvalidTokenSpecialChars() {
        let url = URL(string: "fitcomp://friend-invite?token=ABC!@%23%24%25%5E%26*")!
        router.handle(url: url)
        XCTAssertNil(router.pendingInviteToken)
    }

    func testPasswordResetURL() {
        let url = URL(string: "fitcomp://reset-password#access_token=abc&type=recovery")!
        router.handle(url: url)
        XCTAssertNotNil(router.pendingPasswordResetURL)
    }

    func testUniversalLinkInvite() {
        let url = URL(string: "https://fitcomp.app/invite/friend/TEST1234")!
        router.handle(url: url)
        XCTAssertEqual(router.pendingInviteToken, "TEST1234")
    }

    func testLegacyUniversalLinkInvite() {
        let url = URL(string: "https://fitcomp.app/friend-invite/LEGACY12")!
        router.handle(url: url)
        XCTAssertEqual(router.pendingInviteToken, "LEGACY12")
    }

    func testUnrelatedURLIgnored() {
        let url = URL(string: "https://example.com/some/path")!
        router.handle(url: url)
        XCTAssertNil(router.pendingInviteToken)
        XCTAssertNil(router.pendingPasswordResetURL)
    }
}
