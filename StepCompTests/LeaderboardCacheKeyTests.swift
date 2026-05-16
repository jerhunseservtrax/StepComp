//
//  LeaderboardCacheKeyTests.swift
//  FitComp Tests
//

import XCTest
@testable import StepComp

final class LeaderboardCacheKeyTests: XCTestCase {
    func testDailyLeaderboardCacheKeyDoesNotCollideWithAllTime() {
        let challengeId = "challenge-123"

        XCTAssertNotEqual(
            ChallengeService.leaderboardCacheKey(challengeId: challengeId, scope: .daily),
            ChallengeService.leaderboardCacheKey(challengeId: challengeId, scope: .allTime)
        )
    }
}
