//
//  LeaderboardCacheKeyTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class LeaderboardCacheKeyTests: XCTestCase {
    func testDailyLeaderboardCacheKeyDoesNotCollideWithAllTime() {
        let challengeId = "challenge-123"

        XCTAssertEqual(
            ChallengeService.leaderboardCacheKey(challengeId: challengeId, scope: .allTime),
            "leaderboard_\(challengeId)"
        )
        XCTAssertNotEqual(
            ChallengeService.leaderboardCacheKey(challengeId: challengeId, scope: .daily),
            ChallengeService.leaderboardCacheKey(challengeId: challengeId, scope: .allTime)
        )
    }
}
