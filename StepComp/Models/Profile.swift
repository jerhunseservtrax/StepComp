//
//  Profile.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation

struct Profile: Codable, Identifiable, Equatable {
    let id: String
    var username: String
    var displayName: String?
    var firstName: String?
    var lastName: String?
    var avatarUrl: String?
    var publicProfile: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case firstName = "first_name"
        case lastName = "last_name"
        case avatarUrl = "avatar_url"
        case publicProfile = "public_profile"
    }
}

