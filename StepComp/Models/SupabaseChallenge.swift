//
//  SupabaseChallenge.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/30/25.
//

import Foundation

// MARK: - Database Challenge Model (from Supabase Database)
// This represents the challenge stored in the challenges table

struct SupabaseChallenge: Codable, Identifiable {
    let id: String // UUID from database
    var name: String
    var description: String?
    var startDate: Date
    var endDate: Date
    var createdBy: String // UUID of creator
    var isPublic: Bool
    var inviteCode: String?
    var category: String? // Challenge category
    var imageUrl: String? // Background image URL
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case startDate = "start_date"
        case endDate = "end_date"
        case createdBy = "created_by"
        case isPublic = "is_public"
        case inviteCode = "invite_code"
        case category
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Challenge Member Model (from challenge_members table)

struct ChallengeMember: Codable, Identifiable {
    let id: String // UUID
    let challengeId: String
    let userId: String
    var totalSteps: Int
    var dailySteps: [String: Int] // Date string -> steps count
    var joinedAt: Date
    var lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case challengeId = "challenge_id"
        case userId = "user_id"
        case totalSteps = "total_steps"
        case dailySteps = "daily_steps"
        case joinedAt = "joined_at"
        case lastUpdated = "last_updated"
    }
    
    // Regular initializer
    init(
        id: String,
        challengeId: String,
        userId: String,
        totalSteps: Int = 0,
        dailySteps: [String: Int] = [:],
        joinedAt: Date = Date(),
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.challengeId = challengeId
        self.userId = userId
        self.totalSteps = totalSteps
        self.dailySteps = dailySteps
        self.joinedAt = joinedAt
        self.lastUpdated = lastUpdated
    }
    
    // Custom decoder to handle JSONB daily_steps
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        challengeId = try container.decode(String.self, forKey: .challengeId)
        userId = try container.decode(String.self, forKey: .userId)
        totalSteps = try container.decode(Int.self, forKey: .totalSteps)
        joinedAt = try container.decode(Date.self, forKey: .joinedAt)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        
        // Decode daily_steps JSONB
        if let dailyStepsData = try? container.decode([String: Int].self, forKey: .dailySteps) {
            dailySteps = dailyStepsData
        } else {
            dailySteps = [:]
        }
    }
    
    // Custom encoder to handle JSONB daily_steps
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(challengeId, forKey: .challengeId)
        try container.encode(userId, forKey: .userId)
        try container.encode(totalSteps, forKey: .totalSteps)
        try container.encode(joinedAt, forKey: .joinedAt)
        try container.encode(lastUpdated, forKey: .lastUpdated)
        try container.encode(dailySteps, forKey: .dailySteps)
    }
}

// MARK: - Challenge Snapshot Model (from challenge_snapshots table)

struct ChallengeSnapshot: Codable, Identifiable {
    let id: String
    let challengeId: String
    let userId: String
    let username: String
    let displayName: String
    let avatarUrl: String?
    let totalSteps: Int
    let rank: Int
    let snapshottedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case challengeId = "challenge_id"
        case userId = "user_id"
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case totalSteps = "total_steps"
        case rank
        case snapshottedAt = "snapshotted_at"
    }
    
    func toLeaderboardEntry() -> LeaderboardEntry {
        LeaderboardEntry(
            id: id,
            userId: userId,
            challengeId: challengeId,
            username: username,
            displayName: displayName,
            avatarURL: avatarUrl,
            steps: totalSteps,
            rank: rank,
            lastUpdated: snapshottedAt
        )
    }
}

// MARK: - Leaderboard Result from Database Function

struct LeaderboardResult: Codable {
    let userId: String
    let username: String
    let avatar: String?
    let totalSteps: Int
    let rank: Int64
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case avatar
        case totalSteps = "total_steps"
        case rank
    }
}

