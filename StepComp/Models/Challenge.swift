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
    var imageUrl: String? // Background image URL
    
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
        category: ChallengeCategory? = nil,
        imageUrl: String? = nil
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
        self.imageUrl = imageUrl
    }
    
    var isOngoing: Bool {
        let now = Date()
        return isActive && now >= startDate && now <= endDate
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let now = Date()
        guard now <= endDate else { 
            print("⚠️ [Challenge] \(name): Challenge has ended (now: \(now), endDate: \(endDate))")
            return 0 
        }
        
        // Normalize both dates to start of day for accurate day count
        let startOfToday = calendar.startOfDay(for: now)
        let startOfEndDate = calendar.startOfDay(for: endDate)
        
        // Calculate the number of calendar days between today and end date
        // If end date is today, days = 0 (today is the last day)
        // If end date is tomorrow, days = 1 (1 day left)
        // If end date is day after tomorrow, days = 2 (2 days left)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfEndDate)
        let days = components.day ?? 0
        
        // Debug logging for days calculation
        if name == "Test group" || name.contains("Test group") {
            print("🔍 [Challenge.daysRemaining] '\(name)': now=\(startOfToday), endDate=\(startOfEndDate), days=\(days)")
        }
        
        // Return days: 0 = last day, 1 = 1 day left, 2 = 2 days left, etc.
        return max(0, days)
    }
}

