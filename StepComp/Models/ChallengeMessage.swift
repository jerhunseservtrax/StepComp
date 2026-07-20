//
//  ChallengeMessage.swift
//  FitComp
//
//  Model for challenge group chat messages
//

import Foundation

// MARK: - Client Model (UI)
struct ChallengeMessage: Identifiable, Codable, Equatable {
    let id: String
    let challengeId: String
    let userId: String
    var content: String
    let messageType: MessageType
    let createdAt: Date
    var editedAt: Date?
    var isDeleted: Bool
    
    // Profile data (from join)
    var senderName: String?
    var senderAvatarURL: String?
    
    enum MessageType: String, Codable {
        case text
        case system
        case image // Future
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case challengeId = "challenge_id"
        case userId = "user_id"
        case content
        case messageType = "message_type"
        case createdAt = "created_at"
        case editedAt = "edited_at"
        case isDeleted = "is_deleted"
    }
    
    var isSystemMessage: Bool {
        messageType == .system
    }
    
    var displayTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

// MARK: - Direct database rows

/// A chat row decoded without a PostgREST embedded profile relationship.
struct ChallengeMessageRow: Codable {
    let id: String
    let challengeId: String
    let userId: String
    let content: String
    let messageType: String
    let createdAt: Date
    let editedAt: Date?
    let isDeleted: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case challengeId = "challenge_id"
        case userId = "user_id"
        case content
        case messageType = "message_type"
        case createdAt = "created_at"
        case editedAt = "edited_at"
        case isDeleted = "is_deleted"
    }
}

struct ChallengeMessageProfileRow: Codable {
    let id: String
    let username: String?
    let displayName: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

enum ChallengeMessageHydrator {
    static func hydrate(
        rows: [ChallengeMessageRow],
        profiles: [ChallengeMessageProfileRow]
    ) -> [ChallengeMessage] {
        let profilesById = Dictionary(
            uniqueKeysWithValues: profiles.map { ($0.id.lowercased(), $0) }
        )

        return rows.map { row in
            let profile = profilesById[row.userId.lowercased()]
            return ChallengeMessage(
                id: row.id,
                challengeId: row.challengeId,
                userId: row.userId,
                content: row.content,
                messageType: ChallengeMessage.MessageType(rawValue: row.messageType) ?? .text,
                createdAt: row.createdAt,
                editedAt: row.editedAt,
                isDeleted: row.isDeleted,
                senderName: preferredName(for: profile),
                senderAvatarURL: profile?.avatarUrl
            )
        }
    }

    private static func preferredName(for profile: ChallengeMessageProfileRow?) -> String {
        [profile?.displayName, profile?.username]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty }) ?? "Unknown"
    }
}

// MARK: - Server Model (from database with profiles join)
struct ServerChallengeMessage: Codable {
    let id: String
    let challengeId: String
    let userId: String
    let content: String
    let messageType: String
    let createdAt: Date
    let editedAt: Date?
    let isDeleted: Bool
    let profiles: ProfileInfo?
    
    struct ProfileInfo: Codable {
        let username: String?
        let displayName: String?
        let avatarUrl: String?
        
        enum CodingKeys: String, CodingKey {
            case username
            case displayName = "display_name"
            case avatarUrl = "avatar_url"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case challengeId = "challenge_id"
        case userId = "user_id"
        case content
        case messageType = "message_type"
        case createdAt = "created_at"
        case editedAt = "edited_at"
        case isDeleted = "is_deleted"
        case profiles
    }
    
    // Convert to client model
    func toChallengeMessage() -> ChallengeMessage {
        ChallengeMessage(
            id: id,
            challengeId: challengeId,
            userId: userId,
            content: content,
            messageType: ChallengeMessage.MessageType(rawValue: messageType) ?? .text,
            createdAt: createdAt,
            editedAt: editedAt,
            isDeleted: isDeleted,
            senderName: profiles?.username ?? "Unknown",
            senderAvatarURL: profiles?.avatarUrl
        )
    }
}

// MARK: - Send Message Response
struct SendMessageResponse: Codable {
    let messageId: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case createdAt = "created_at"
    }
}

