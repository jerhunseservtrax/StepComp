//
//  User.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: String
    var username: String // Unique username identifier (e.g., @username)
    var firstName: String
    var lastName: String
    var displayName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    var avatarURL: String?
    var email: String?
    var publicProfile: Bool // Whether user appears in public search
    var totalSteps: Int
    var totalChallenges: Int
    var badges: [Badge]
    var createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        username: String = "",
        firstName: String = "",
        lastName: String = "",
        displayName: String? = nil, // For backward compatibility
        avatarURL: String? = nil,
        email: String? = nil,
        publicProfile: Bool = false,
        totalSteps: Int = 0,
        totalChallenges: Int = 0,
        badges: [Badge] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.username = username
        // Handle backward compatibility: if displayName is provided, split it
        if let displayName = displayName, !displayName.isEmpty {
            let components = displayName.split(separator: " ", maxSplits: 1)
            self.firstName = components.first.map(String.init) ?? ""
            self.lastName = components.count > 1 ? String(components[1]) : ""
        } else {
            self.firstName = firstName
            self.lastName = lastName
        }
        self.avatarURL = avatarURL
        self.email = email
        self.publicProfile = publicProfile
        self.totalSteps = totalSteps
        self.totalChallenges = totalChallenges
        self.badges = badges
        self.createdAt = createdAt
    }
}

// MARK: - Helper Extension
extension User {
    /// Returns the user's first name, or a fallback if empty
    var firstNameOrFallback: String {
        !firstName.isEmpty ? firstName : (username.isEmpty ? "User" : username)
    }
}

