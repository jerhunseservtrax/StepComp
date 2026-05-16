//
//  ChallengeChatMessageMergerTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class ChallengeChatMessageMergerTests: XCTestCase {
    func testMergeLatestPagePreservesPreviouslyLoadedOlderMessages() {
        let older = message(id: "older", minutesAgo: 60)
        let newestExisting = message(id: "newest", minutesAgo: 1, content: "old content")
        let newestUpdated = message(id: "newest", minutesAgo: 1, content: "edited content")

        let merged = ChallengeChatMessageMerger.mergeLatestPage(
            [newestUpdated],
            into: [older, newestExisting],
            pageSize: 1
        )

        XCTAssertEqual(merged.map(\.id), ["older", "newest"])
        XCTAssertEqual(merged.last?.content, "edited content")
    }

    func testMergeLatestPageDropsMessagesMissingFromCompleteLatestPage() {
        let deleted = message(id: "deleted", minutesAgo: 2)
        let remaining = message(id: "remaining", minutesAgo: 1)

        let merged = ChallengeChatMessageMerger.mergeLatestPage(
            [remaining],
            into: [deleted, remaining],
            pageSize: 40
        )

        XCTAssertEqual(merged.map(\.id), ["remaining"])
    }

    private func message(id: String, minutesAgo: TimeInterval, content: String = "message") -> ChallengeMessage {
        ChallengeMessage(
            id: id,
            challengeId: "challenge",
            userId: "user",
            content: content,
            messageType: .text,
            createdAt: Date(timeIntervalSince1970: 1_000_000 - (minutesAgo * 60)),
            editedAt: nil,
            isDeleted: false,
            senderName: "User",
            senderAvatarURL: nil
        )
    }
}
