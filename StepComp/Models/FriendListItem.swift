//
//  FriendListItem.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation

struct FriendListItem: Identifiable, Equatable {
    let id: String              // friendship id
    let profile: Profile      // the "other" person
    let status: FriendshipStatus
    let isIncomingRequest: Bool
    let isOutgoingRequest: Bool
}

