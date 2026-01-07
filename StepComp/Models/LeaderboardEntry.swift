//
//  LeaderboardEntry.swift
//  StepComp
//
//  Model for leaderboard entries (computed server-side)
//

import Foundation

// MARK: - Client Model (UI)
struct LeaderboardEntry: Identifiable, Codable, Equatable {
    var id: String
    var userId: String
    var challengeId: String
    var username: String
    var displayName: String
    var avatarURL: String?
    var steps: Int
    var rank: Int
    var rankChange: Int? // Positive = moved up, Negative = moved down
    var lastUpdated: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        challengeId: String,
        username: String = "",
        displayName: String,
        avatarURL: String? = nil,
        steps: Int,
        rank: Int,
        rankChange: Int? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.challengeId = challengeId
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.steps = steps
        self.rank = rank
        self.rankChange = rankChange
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Server Model (from RPC)
// This matches the structure returned by get_challenge_leaderboard() and get_challenge_leaderboard_today()
struct ServerLeaderboardEntry: Codable {
    let userId: String
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let steps: Int
    let rank: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case steps
        case rank
    }
    
    // Convert to client model
    func toLeaderboardEntry(challengeId: String) -> LeaderboardEntry {
        LeaderboardEntry(
            id: UUID().uuidString,
            userId: userId,
            challengeId: challengeId,
            username: username,
            displayName: displayName ?? username,
            avatarURL: avatarUrl,
            steps: steps,
            rank: rank,
            lastUpdated: Date()
        )
    }
}

enum LeaderboardScope: String, CaseIterable {
    case daily = "Today"
    case weekly = "Week"
    case allTime = "Overall"
}
