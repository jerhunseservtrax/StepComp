//
//  InboxModels.swift
//  StepComp
//
//  Models for inbox notifications and challenge invites
//

import Foundation

// MARK: - Inbox Notification

struct InboxNotification: Identifiable, Codable {
    let id: String
    let userId: String
    let type: NotificationType
    let title: String
    let message: String
    let relatedId: String?
    var isRead: Bool
    let createdAt: Date
    
    enum NotificationType: String, Codable {
        case friendRequest = "friend_request"
        case friendRequestAccepted = "friend_request_accepted"
        case challengeInvite = "challenge_invite"
        case challengeUpdate = "challenge_update"
        case challengeJoined = "challenge_joined"
        case achievement = "achievement"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case title
        case message
        case relatedId = "related_id"
        case isRead = "is_read"
        case createdAt = "created_at"
    }
    
    var icon: String {
        switch type {
        case .friendRequest:
            return "person.badge.plus"
        case .friendRequestAccepted:
            return "person.2.fill"
        case .challengeInvite:
            return "trophy.fill"
        case .challengeUpdate:
            return "bell.fill"
        case .challengeJoined:
            return "person.2.fill"
        case .achievement:
            return "star.fill"
        }
    }
    
    var iconColor: String {
        switch type {
        case .friendRequest:
            return "blue"
        case .friendRequestAccepted:
            return "green"
        case .challengeInvite:
            return "yellow"
        case .challengeUpdate:
            return "purple"
        case .challengeJoined:
            return "green"
        case .achievement:
            return "orange"
        }
    }
}

// MARK: - Challenge Invite

struct ChallengeInvite: Identifiable, Codable {
    let id: String
    let challengeId: String
    let inviterId: String
    let inviteeId: String
    var status: InviteStatus
    let createdAt: Date
    let updatedAt: Date
    
    enum InviteStatus: String, Codable {
        case pending
        case accepted
        case declined
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case challengeId = "challenge_id"
        case inviterId = "inviter_id"
        case inviteeId = "invitee_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Friend Selection for Invite

struct FriendForInvite: Identifiable {
    let id: String
    let displayName: String
    let username: String?
    let avatarURL: String?
    let isAlreadyMember: Bool
    var isSelected: Bool = false
}

