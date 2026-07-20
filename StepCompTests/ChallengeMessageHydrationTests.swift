//
//  ChallengeMessageHydrationTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class ChallengeMessageHydrationTests: XCTestCase {
    func testHydrateAddsProfileWithoutEmbeddedRelationship() {
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let rows = [
            ChallengeMessageRow(
                id: "message-1",
                challengeId: "challenge-1",
                userId: "user-1",
                content: "Hello",
                messageType: "text",
                createdAt: createdAt,
                editedAt: nil,
                isDeleted: false
            )
        ]
        let profiles = [
            ChallengeMessageProfileRow(
                id: "user-1",
                username: "taylor",
                displayName: "Taylor",
                avatarUrl: "https://example.com/avatar.jpg"
            )
        ]

        let messages = ChallengeMessageHydrator.hydrate(rows: rows, profiles: profiles)

        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].senderName, "Taylor")
        XCTAssertEqual(messages[0].senderAvatarURL, "https://example.com/avatar.jpg")
    }

    func testHydrateKeepsMessagesWhenProfileIsUnavailable() {
        let rows = [
            ChallengeMessageRow(
                id: "message-1",
                challengeId: "challenge-1",
                userId: "missing-user",
                content: "Still visible",
                messageType: "text",
                createdAt: Date(timeIntervalSince1970: 1_700_000_000),
                editedAt: nil,
                isDeleted: false
            )
        ]

        let messages = ChallengeMessageHydrator.hydrate(rows: rows, profiles: [])

        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].content, "Still visible")
        XCTAssertEqual(messages[0].senderName, "Unknown")
    }
}
