//
//  GroupViewModel.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import SwiftUI
import Combine // Required for @Published and ObservableObject

@MainActor
final class GroupViewModel: ObservableObject {
    @Published var challenge: Challenge?
    @Published var members: [User] = []
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var challengeService: ChallengeService
    private let challengeId: String
    private let currentUserId: String
    
    init(
        challengeService: ChallengeService,
        challengeId: String,
        currentUserId: String
    ) {
        self.challengeService = challengeService
        self.challengeId = challengeId
        self.currentUserId = currentUserId
        
        loadGroupData()
    }
    
    func updateService(_ service: ChallengeService) {
        self.challengeService = service
        loadGroupData()
    }
    
    func loadGroupData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            challenge = challengeService.getChallenge(challengeId)
            leaderboardEntries = await challengeService.getLeaderboard(for: challengeId)
            
            // TODO: Load actual member data from user service
            // For now, create placeholder users
            members = leaderboardEntries.map { entry in
                User(
                    id: entry.userId,
                    displayName: entry.displayName,
                    avatarURL: entry.avatarURL
                )
            }
            
            isLoading = false
        }
    }
    
    func leaveChallenge() async {
        guard var challenge = challenge else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            challenge.participantIds.removeAll { $0 == currentUserId }
            try await challengeService.updateChallenge(challenge)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteChallenge() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await challengeService.deleteChallenge(challengeId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    var canDelete: Bool {
        challenge?.creatorId == currentUserId
    }
    
    func refresh() {
        loadGroupData()
    }
}

