//
//  ChallengeChatViewModelTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class ChallengeChatViewModelTests: XCTestCase {
    func testRefreshMergePreservesOlderLoadedMessages() {
        let base = Date(timeIntervalSince1970: 1_000)
        let older = Self.message(id: "older", date: base)
        let firstLatest = Self.message(id: "latest-1", date: base.addingTimeInterval(60))
        let secondLatest = Self.message(id: "latest-2", date: base.addingTimeInterval(120))
        let updatedLatest = Self.message(id: "latest-2", content: "edited", date: base.addingTimeInterval(120))

        let merged = [older, firstLatest, secondLatest]
            .mergedWithLatestChallengeMessages([firstLatest, updatedLatest])

        XCTAssertEqual(merged.map(\.id), ["older", "latest-1", "latest-2"])
        XCTAssertEqual(merged.last?.content, "edited")
    }

    func testRefreshMergeRemovesMessagesMissingFromCompleteLatestPage() {
        let base = Date(timeIntervalSince1970: 1_000)
        let deleted = Self.message(id: "deleted", date: base)
        let remaining = Self.message(id: "remaining", date: base.addingTimeInterval(60))

        let merged = [deleted, remaining]
            .mergedWithLatestChallengeMessages([remaining], latestPageIsCompleteHistory: true)

        XCTAssertEqual(merged.map(\.id), ["remaining"])
    }

    private static func message(id: String, content: String = "message", date: Date) -> ChallengeMessage {
        ChallengeMessage(
            id: id,
            challengeId: "challenge",
            userId: "user",
            content: content,
            messageType: .text,
            createdAt: date,
            editedAt: nil,
            isDeleted: false,
            senderName: nil,
            senderAvatarURL: nil
        )
    }
}
