//
//  ChallengeServiceCacheTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

@MainActor
final class ChallengeServiceCacheTests: XCTestCase {
    func testClearCachedChallengeDataRemovesInMemoryLeaderboards() {
        let service = ChallengeService(useSupabase: false)
        service.leaderboardEntries = [
            "private-challenge": [
                LeaderboardEntry(
                    userId: "user-a",
                    challengeId: "private-challenge",
                    username: "alice",
                    displayName: "Alice",
                    avatarURL: nil,
                    steps: 12_000,
                    rank: 1
                )
            ]
        ]

        service.clearCachedChallengeData()

        XCTAssertTrue(service.leaderboardEntries.isEmpty)
        XCTAssertTrue(service.challenges.isEmpty)
    }
}
