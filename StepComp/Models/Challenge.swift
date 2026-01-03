//
//  Challenge.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation

struct Challenge: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var description: String
    var startDate: Date
    var endDate: Date
    var targetSteps: Int
    var creatorId: String
    var participantIds: [String]
    var isActive: Bool
    var createdAt: Date
    var inviteCode: String?
    var category: ChallengeCategory?
    
    enum ChallengeCategory: String, Codable, CaseIterable {
        case shortTerm = "short_term"
        case friends = "friends"
        case corporate = "corporate"
        case marathon = "marathon"
        case fun = "fun"
        
        var displayName: String {
            switch self {
            case .shortTerm: return "Short Term"
            case .friends: return "Friends"
            case .corporate: return "Corporate"
            case .marathon: return "Marathon"
            case .fun: return "Fun"
            }
        }
        
        var icon: String {
            switch self {
            case .shortTerm: return "bolt.fill"
            case .friends: return "person.3.fill"
            case .corporate: return "building.2.fill"
            case .marathon: return "figure.run"
            case .fun: return "party.popper.fill"
            }
        }
        
        var description: String {
            switch self {
            case .shortTerm: return "Quick burst challenges"
            case .friends: return "Compete with friends"
            case .corporate: return "Company team challenges"
            case .marathon: return "Long-term endurance"
            case .fun: return "Casual & entertaining"
            }
        }
    }
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        startDate: Date,
        endDate: Date,
        targetSteps: Int,
        creatorId: String,
        participantIds: [String] = [],
        isActive: Bool = true,
        createdAt: Date = Date(),
        inviteCode: String? = nil,
        category: ChallengeCategory? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.targetSteps = targetSteps
        self.creatorId = creatorId
        self.participantIds = participantIds
        self.isActive = isActive
        self.createdAt = createdAt
        self.inviteCode = inviteCode
        self.category = category
    }
    
    var isOngoing: Bool {
        let now = Date()
        return isActive && now >= startDate && now <= endDate
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let now = Date()
        guard now <= endDate else { return 0 }
        return calendar.dateComponents([.day], from: now, to: endDate).day ?? 0
    }
}

