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
        inviteCode: String? = nil
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

