//
//  InfoPlistURLSchemeTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class InfoPlistURLSchemeTests: XCTestCase {
    func testPasswordResetSchemeIsRegisteredForIOSDelivery() throws {
        let schemes = try appURLSchemes()

        XCTAssertTrue(schemes.contains("fitcomp"))
        XCTAssertTrue(
            schemes.contains("je.fitcomp"),
            "ForgotPasswordSheet redirects to je.fitcomp://reset-password, so iOS must register that scheme."
        )
    }

    func testRegisteredPasswordResetSchemeRoutesToResetFlow() {
        let router = DeepLinkRouter.shared
        router.pendingPasswordResetURL = nil

        let url = URL(string: "je.fitcomp://reset-password#access_token=abc&type=recovery")!
        router.handle(url: url)

        XCTAssertEqual(router.pendingPasswordResetURL, url)
    }

    private func appURLSchemes() throws -> [String] {
        let testFile = URL(fileURLWithPath: #filePath)
        let repoRoot = testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let plistURL = repoRoot
            .appendingPathComponent("StepComp")
            .appendingPathComponent("Info.plist")

        let data = try Data(contentsOf: plistURL)
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        )
        let urlTypes = try XCTUnwrap(plist["CFBundleURLTypes"] as? [[String: Any]])

        return urlTypes.flatMap { urlType in
            urlType["CFBundleURLSchemes"] as? [String] ?? []
        }
    }
}
