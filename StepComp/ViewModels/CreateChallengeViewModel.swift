//
//  CreateChallengeViewModel.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class CreateChallengeViewModel: ObservableObject {
    @Published var name: String = "Morning Sprinters"
    @Published var description: String = ""
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
    @Published var targetSteps: Int = 10000
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var createdChallenge: Challenge?
    
    // New properties for the redesigned UI
    @Published var selectedDuration: ChallengeDuration = .threeDays
    @Published var customDays: Int = 7 // Default custom days
    @Published var startDateMode: StartDateMode = .today
    @Published var isPrivate: Bool = true
    @Published var selectedParticipants: [String] = [] // User IDs
    
    private var challengeService: ChallengeService
    private let creatorId: String
    
    enum ChallengeDuration: Int, CaseIterable, Hashable {
        case oneDay = 1
        case threeDays = 3
        case sevenDays = 7
        case thirtyDays = 30
        case custom
        
        var displayName: String {
            switch self {
            case .oneDay: return "24 Hours"
            case .threeDays: return "3 Days"
            case .sevenDays: return "7 Days"
            case .thirtyDays: return "30 Days"
            case .custom: return "Custom"
            }
        }
    }
    
    enum StartDateMode {
        case today
        case pickDate
    }
    
    init(challengeService: ChallengeService, creatorId: String) {
        self.challengeService = challengeService
        self.creatorId = creatorId
    }
    
    func updateService(_ service: ChallengeService) {
        self.challengeService = service
    }
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        startDate < endDate &&
        targetSteps > 0
    }
    
    var durationInDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return max(components.day ?? 0, 1)
    }
    
    func updateDuration(_ duration: ChallengeDuration) {
        selectedDuration = duration
        if duration != .custom {
            let days = duration.rawValue
            endDate = Calendar.current.date(byAdding: .day, value: days, to: startDate) ?? startDate
        } else {
            // For custom, use the customDays value
            endDate = Calendar.current.date(byAdding: .day, value: customDays, to: startDate) ?? startDate
        }
    }
    
    func updateCustomDays(_ days: Int) {
        customDays = max(1, min(days, 365)) // Clamp between 1 and 365 days
        if selectedDuration == .custom {
            endDate = Calendar.current.date(byAdding: .day, value: customDays, to: startDate) ?? startDate
        }
    }
    
    func updateStartDateMode(_ mode: StartDateMode) {
        startDateMode = mode
        if mode == .today {
            startDate = Date()
            updateDuration(selectedDuration) // Recalculate end date
        }
    }
    
    func createChallenge() async {
        guard isValid else {
            errorMessage = "Please fill in all fields correctly"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Include creator and selected participants
            var participantIds = [creatorId]
            participantIds.append(contentsOf: selectedParticipants)
            
            let challenge = Challenge(
                name: name,
                description: description,
                startDate: startDate,
                endDate: endDate,
                targetSteps: targetSteps,
                creatorId: creatorId,
                participantIds: participantIds
            )
            
            try await challengeService.createChallenge(challenge)
            createdChallenge = challenge
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func reset() {
        name = ""
        description = ""
        startDate = Date()
        endDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        targetSteps = 10000
        selectedDuration = .threeDays
        startDateMode = .today
        isPrivate = true
        selectedParticipants = []
        errorMessage = nil
        createdChallenge = nil
    }
}

