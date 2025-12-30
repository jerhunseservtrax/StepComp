//
//  JoinChallengeViewModel.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import SwiftUI
import Combine // Required for @Published and ObservableObject

@MainActor
final class JoinChallengeViewModel: ObservableObject {
    @Published var availableChallenges: [Challenge] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var challengeService: ChallengeService
    private let userId: String
    
    init(challengeService: ChallengeService, userId: String) {
        self.challengeService = challengeService
        self.userId = userId
        
        loadAvailableChallenges()
    }
    
    func updateService(_ service: ChallengeService) {
        self.challengeService = service
        loadAvailableChallenges()
    }
    
    func loadAvailableChallenges() {
        isLoading = true
        errorMessage = nil
        
        Task {
            // Filter out challenges user is already in
            let allChallenges = challengeService.challenges
            availableChallenges = allChallenges.filter { challenge in
                challenge.isOngoing &&
                challenge.creatorId != userId &&
                !challenge.participantIds.contains(userId)
            }
            
            if !searchText.isEmpty {
                availableChallenges = availableChallenges.filter { challenge in
                    challenge.name.localizedCaseInsensitiveContains(searchText) ||
                    challenge.description.localizedCaseInsensitiveContains(searchText)
                }
            }
            
            isLoading = false
        }
    }
    
    func joinChallenge(_ challenge: Challenge) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await challengeService.joinChallenge(challenge.id, userId: userId)
            loadAvailableChallenges()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refresh() {
        loadAvailableChallenges()
    }
}

