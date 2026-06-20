//
//  ChatListViewModelTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class ChatListViewModelTests: XCTestCase {
    func testActiveChallengeCandidatesExcludeEndedChallengesWithoutMarkingThemForDeletion() {
        let activeChallengeId = "active-challenge"
        let endedChallengeId = "ended-challenge"

        let result = ChatListViewModel.activeChatCandidates(
            memberChallengeIds: [activeChallengeId, endedChallengeId],
            activeChallengeIds: [activeChallengeId]
        )

        XCTAssertEqual(result, [activeChallengeId])
    }
}
