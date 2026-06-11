//
//  ChatListViewModelTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

@MainActor
final class ChatListViewModelTests: XCTestCase {
    func testVisibleChatChallengesExcludeEndedChallengesWithoutDeletingMemberships() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let activeChallenge = SimpleChallengeInfo(
            id: "active",
            name: "Active Challenge",
            endDate: now.addingTimeInterval(60)
        )
        let endedChallenge = SimpleChallengeInfo(
            id: "ended",
            name: "Ended Challenge",
            endDate: now.addingTimeInterval(-60)
        )

        let visibleChallenges = ChatListViewModel.visibleChatChallenges(
            from: [activeChallenge, endedChallenge],
            now: now
        )

        XCTAssertEqual(visibleChallenges.map(\.id), ["active"])
    }
}
