//
//  LeaderboardEntry.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation

struct LeaderboardEntry: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let challengeId: String
    var displayName: String
    var avatarURL: String?
    var steps: Int
    var rank: Int
    var lastUpdated: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        challengeId: String,
        displayName: String,
        avatarURL: String? = nil,
        steps: Int = 0,
        rank: Int = 0,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.challengeId = challengeId
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.steps = steps
        self.rank = rank
        self.lastUpdated = lastUpdated
    }
}

enum LeaderboardScope: String, CaseIterable, Identifiable {
    case daily
    case weekly
    case allTime
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .daily: return "Today"
        case .weekly: return "This Week"
        case .allTime: return "All Time"
        }
    }
}

