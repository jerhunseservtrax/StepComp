//
//  Friendship.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation

enum FriendshipStatus: String, Codable {
    case pending
    case accepted
}

struct Friendship: Codable, Identifiable {
    let id: String
    let requesterId: String
    let addresseeId: String
    let status: FriendshipStatus

    enum CodingKeys: String, CodingKey {
        case id
        case requesterId = "requester_id"
        case addresseeId = "addressee_id"
        case status
    }
}

