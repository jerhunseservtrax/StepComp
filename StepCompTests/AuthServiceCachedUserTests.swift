//
//  AuthServiceCachedUserTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

@MainActor
final class AuthServiceCachedUserTests: XCTestCase {
    func testCachedUserMustMatchActiveSessionUserId() {
        let cachedUser = User(id: "user-a", username: "alice", firstName: "Alice")

        let matchedUser = AuthService.cachedUser(cachedUser, matching: "user-b")

        XCTAssertNil(matchedUser)
    }

    func testCachedUserMatchingActiveSessionUserIdIsAccepted() {
        let cachedUser = User(id: "user-a", username: "alice", firstName: "Alice")

        let matchedUser = AuthService.cachedUser(cachedUser, matching: "user-a")

        XCTAssertEqual(matchedUser, cachedUser)
    }

    func testCachedUserMatchingIsCaseInsensitiveForUUIDs() {
        let lowercasedId = "a3bdcf7d-3c8f-45f5-a297-97b9963b1a1c"
        let uppercasedId = lowercasedId.uppercased()
        let cachedUser = User(id: lowercasedId, username: "alice", firstName: "Alice")

        let matchedUser = AuthService.cachedUser(cachedUser, matching: uppercasedId)

        XCTAssertEqual(matchedUser, cachedUser)
    }

    func testNilInitialSessionCannotRestoreCachedUserAsAuthenticated() {
        let cachedUser = User(id: "user-a", username: "alice", firstName: "Alice")

        let restoredUser = AuthService.cachedUserForInitialSession(nil, cachedUser: cachedUser)

        XCTAssertNil(restoredUser)
    }

    func testProfileLoadResultRequiresActiveSessionUserMatch() {
        XCTAssertTrue(
            AuthService.canPublishProfileLoadResult(
                requestedUserId: "user-a",
                activeSessionUserId: "user-a"
            )
        )
        XCTAssertFalse(
            AuthService.canPublishProfileLoadResult(
                requestedUserId: "user-a",
                activeSessionUserId: "user-b"
            )
        )
        XCTAssertFalse(
            AuthService.canPublishProfileLoadResult(
                requestedUserId: "user-a",
                activeSessionUserId: nil
            )
        )
    }

    func testProfileLoadResultAllowsUUIDCaseDifference() {
        XCTAssertTrue(
            AuthService.canPublishProfileLoadResult(
                requestedUserId: "a3bdcf7d-3c8f-45f5-a297-97b9963b1a1c",
                activeSessionUserId: "A3BDCF7D-3C8F-45F5-A297-97B9963B1A1C"
            )
        )
    }
}
