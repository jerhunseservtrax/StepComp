//
//  ChallengeChatViewModelTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class ChallengeChatViewModelTests: XCTestCase {
    func testMergingLatestPagePreservesLoadedOlderHistory() {
        let existing = (1...80).map { makeMessage(number: $0) }
        let latest = (42...81).map { number in
            makeMessage(number: number, content: number == 42 ? "updated" : "message-\(number)")
        }

        let merged = existing.mergingLatestPage(latest)

        XCTAssertEqual(merged.map(\.id), (1...81).map { String($0) })
        XCTAssertEqual(merged.first(where: { $0.id == "42" })?.content, "updated")
    }

    func testEmptyLatestPageClearsMessages() {
        let existing = (1...3).map { makeMessage(number: $0) }

        XCTAssertTrue(existing.mergingLatestPage([]).isEmpty)
    }

    private func makeMessage(number: Int, content: String? = nil) -> ChallengeMessage {
        ChallengeMessage(
            id: String(number),
            challengeId: "challenge-1",
            userId: "user-1",
            content: content ?? "message-\(number)",
            messageType: .text,
            createdAt: Date(timeIntervalSince1970: TimeInterval(number)),
            editedAt: nil,
            isDeleted: false,
            senderName: "User",
            senderAvatarURL: nil
        )
    }
}
