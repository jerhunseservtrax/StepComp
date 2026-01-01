//
//  GroupViewModel.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import SwiftUI
import Combine // Required for @Published and ObservableObject
#if canImport(Supabase)
import Supabase
#endif

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
        guard challenge != nil else { return }
        
        isLoading = true
        errorMessage = nil
        
        #if canImport(Supabase)
        do {
            // Delete from challenge_members table
            try await supabase
                .from("challenge_members")
                .delete()
                .eq("challenge_id", value: challengeId)
                .eq("user_id", value: currentUserId)
                .execute()
            
            print("✅ Successfully left challenge \(challengeId)")
            
        } catch {
            print("⚠️ Error leaving challenge: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        #endif
        
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

