//
//  AuthSessionFallbackTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class AuthSessionFallbackTests: XCTestCase {
    func testFallbackDoesNotUseCachedUserFromDifferentSession() {
        let sessionUserId = "session-user"
        let cachedUser = User(
            id: "previous-user",
            username: "previous",
            firstName: "Previous",
            lastName: "Account",
            email: "previous@example.com",
            publicProfile: false
        )

        let fallbackUser = AuthSessionFallback.user(
            forSessionUserId: sessionUserId,
            cachedUser: cachedUser
        )

        XCTAssertEqual(fallbackUser.id, sessionUserId)
        XCTAssertNotEqual(fallbackUser.id, cachedUser.id)
        XCTAssertEqual(fallbackUser.username, "user_session-")
    }

    func testFallbackUsesCachedUserWhenItMatchesSession() {
        let cachedUser = User(
            id: "same-user",
            username: "same",
            firstName: "Same",
            lastName: "Account",
            email: "same@example.com",
            publicProfile: true
        )

        let fallbackUser = AuthSessionFallback.user(
            forSessionUserId: cachedUser.id,
            cachedUser: cachedUser
        )

        XCTAssertEqual(fallbackUser, cachedUser)
    }
}
