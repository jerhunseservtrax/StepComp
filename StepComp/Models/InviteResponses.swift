//
//  InviteResponses.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation

struct InviteCreateResponse: Codable {
    let token: String
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case token
        case expiresAt = "expires_at"
    }
}

struct InviteConsumeResponse: Codable {
    let friendshipId: String
    let inviterId: String
    let inviterUsername: String
    let inviterDisplayName: String?
    let inviterAvatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case friendshipId = "friendship_id"
        case inviterId = "inviter_id"
        case inviterUsername = "inviter_username"
        case inviterDisplayName = "inviter_display_name"
        case inviterAvatarUrl = "inviter_avatar_url"
    }
}

