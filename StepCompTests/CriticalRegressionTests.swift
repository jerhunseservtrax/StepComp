//
//  CriticalRegressionTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class CriticalRegressionTests: XCTestCase {
    func testChatLatestPageReconciliationPreservesLoadedOlderMessages() {
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        let loadedMessages = (0..<60).map { index in
            makeMessage(id: "message-\(index)", createdAt: baseDate.addingTimeInterval(TimeInterval(index)))
        }
        let latestPage = (21..<61).map { index in
            makeMessage(id: "message-\(index)", createdAt: baseDate.addingTimeInterval(TimeInterval(index)))
        }

        let reconciled = ChallengeChatViewModel.reconciledMessages(
            existing: loadedMessages,
            latest: latestPage,
            latestPageHasMore: true
        )

        XCTAssertEqual(reconciled.count, 61)
        XCTAssertEqual(reconciled.first?.id, "message-0")
        XCTAssertEqual(reconciled.last?.id, "message-60")
    }

    func testChatLatestPageReconciliationReplacesWhenLatestContainsAllMessages() {
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        let loadedMessages = (0..<10).map { index in
            makeMessage(id: "message-\(index)", createdAt: baseDate.addingTimeInterval(TimeInterval(index)))
        }
        let latestPage = (1..<10).map { index in
            makeMessage(id: "message-\(index)", createdAt: baseDate.addingTimeInterval(TimeInterval(index)))
        }

        let reconciled = ChallengeChatViewModel.reconciledMessages(
            existing: loadedMessages,
            latest: latestPage,
            latestPageHasMore: false
        )

        XCTAssertEqual(reconciled.map(\.id), latestPage.map(\.id))
    }

    func testChatLatestPageReconciliationReplacesWhenLatestExactlyFillsOnePage() {
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        let loadedMessages = (0..<60).map { index in
            makeMessage(id: "message-\(index)", createdAt: baseDate.addingTimeInterval(TimeInterval(index)))
        }
        let latestPage = (20..<60).map { index in
            makeMessage(id: "message-\(index)", createdAt: baseDate.addingTimeInterval(TimeInterval(index)))
        }

        let reconciled = ChallengeChatViewModel.reconciledMessages(
            existing: loadedMessages,
            latest: latestPage,
            latestPageHasMore: false
        )

        XCTAssertEqual(reconciled.count, 40)
        XCTAssertEqual(reconciled.first?.id, "message-20")
        XCTAssertEqual(reconciled.last?.id, "message-59")
    }

    func testOfflineCacheUserScopedKeysDoNotCollideAcrossAccounts() {
        let userAKey = OfflineCacheService.userScopedKey("metrics_summary_30", userId: "user-a")
        let userBKey = OfflineCacheService.userScopedKey("metrics_summary_30", userId: "user-b")

        XCTAssertNotEqual(userAKey, userBKey)
        XCTAssertEqual(userAKey, "user_user-a/metrics_summary_30")
        XCTAssertEqual(userBKey, "user_user-b/metrics_summary_30")
    }

    private func makeMessage(id: String, createdAt: Date) -> ChallengeMessage {
        ChallengeMessage(
            id: id,
            challengeId: "challenge-1",
            userId: "user-1",
            content: id,
            messageType: .text,
            createdAt: createdAt,
            editedAt: nil,
            isDeleted: false,
            senderName: "User",
            senderAvatarURL: nil
        )
    }
}
