//
//  FeedbackModels.swift
//  StepComp
//
//  Created by Jeffery Erhunse

import Foundation

// MARK: - Feedback Post

struct FeedbackPost: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    var title: String
    var description: String
    var category: FeedbackCategory
    var status: FeedbackStatus
    var upvotes: Int
    var downvotes: Int
    let createdAt: Date
    var updatedAt: Date
    var authorUsername: String?
    var authorDisplayName: String?
    var authorAvatarUrl: String?
    var userVote: VoteType?
    var isAuthor: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case category
        case status
        case upvotes
        case downvotes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case authorUsername = "author_username"
        case authorDisplayName = "author_display_name"
        case authorAvatarUrl = "author_avatar_url"
        case userVote = "user_vote"
        case isAuthor = "is_author"
    }
    
    var netVotes: Int {
        return upvotes - downvotes
    }
    
    var controversyScore: Int {
        return min(upvotes, downvotes)
    }
}

// MARK: - Feedback Category

enum FeedbackCategory: String, Codable, CaseIterable {
    case bug = "bug"
    case feature = "feature"
    case improvement = "improvement"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .bug: return "Bug Report"
        case .feature: return "Feature Request"
        case .improvement: return "Improvement"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .bug: return "ant.fill"
        case .feature: return "sparkles"
        case .improvement: return "arrow.up.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .bug: return "red"
        case .feature: return "blue"
        case .improvement: return "green"
        case .other: return "gray"
        }
    }
}

// MARK: - Feedback Status

enum FeedbackStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case underReview = "under_review"
    case planned = "planned"
    case completed = "completed"
    case declined = "declined"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .underReview: return "Under Review"
        case .planned: return "Planned"
        case .completed: return "Completed"
        case .declined: return "Declined"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .underReview: return "eye.fill"
        case .planned: return "calendar.badge.clock"
        case .completed: return "checkmark.circle.fill"
        case .declined: return "xmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "gray"
        case .underReview: return "orange"
        case .planned: return "blue"
        case .completed: return "green"
        case .declined: return "red"
        }
    }
}

// MARK: - Vote Type

enum VoteType: String, Codable {
    case up = "up"
    case down = "down"
}

// MARK: - Sort Option

enum FeedbackSortOption: String, CaseIterable {
    case recent = "recent"
    case popular = "popular"
    case controversial = "controversial"
    
    var displayName: String {
        switch self {
        case .recent: return "Most Recent"
        case .popular: return "Most Popular"
        case .controversial: return "Most Controversial"
        }
    }
    
    var icon: String {
        switch self {
        case .recent: return "clock.fill"
        case .popular: return "flame.fill"
        case .controversial: return "bolt.fill"
        }
    }
}

// MARK: - Create Feedback Request

struct CreateFeedbackRequest: Codable {
    let title: String
    let description: String
    let category: FeedbackCategory
}

