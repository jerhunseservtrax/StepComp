//
//  Badge.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation

struct Badge: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var description: String
    var iconName: String
    var earnedDate: Date?
    var requirement: BadgeRequirement
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        iconName: String,
        earnedDate: Date? = nil,
        requirement: BadgeRequirement
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.earnedDate = earnedDate
        self.requirement = requirement
    }
    
    var isEarned: Bool {
        earnedDate != nil
    }
}

enum BadgeRequirement: Codable, Equatable {
    case steps(Int)
    case challenges(Int)
    case winStreak(Int)
    case custom(String)
}

