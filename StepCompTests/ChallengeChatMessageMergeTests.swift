//
//  ChallengeChatMessageMergeTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class ChallengeChatMessageMergeTests: XCTestCase {
    func testLatestPageMergePreservesPreviouslyLoadedOlderMessages() {
        let older = message(id: "older", minutesFromBase: 0, content: "older")
        let current = message(id: "current", minutesFromBase: 1, content: "current")
        let newest = message(id: "newest", minutesFromBase: 2, content: "newest")
        let updatedCurrent = message(id: "current", minutesFromBase: 1, content: "current edited")

        let merged = [older, current].mergingLatestPagePreservingHistory([updatedCurrent, newest])

        XCTAssertEqual(merged.map(\.id), ["older", "current", "newest"])
        XCTAssertEqual(merged.first(where: { $0.id == "current" })?.content, "current edited")
    }

    private func message(id: String, minutesFromBase: TimeInterval, content: String) -> ChallengeMessage {
        ChallengeMessage(
            id: id,
            challengeId: "challenge-1",
            userId: "user-1",
            content: content,
            messageType: .text,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000 + minutesFromBase * 60),
            editedAt: nil,
            isDeleted: false,
            senderName: "Tester",
            senderAvatarURL: nil
        )
    }
}
