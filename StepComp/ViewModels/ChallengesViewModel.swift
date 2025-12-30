//
//  ChallengesViewModel.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import SwiftUI
import Combine
#if canImport(Supabase)
import Supabase
#endif

@MainActor
final class ChallengesViewModel: ObservableObject {
    @Published var privateChallenges: [Challenge] = []
    @Published var publicChallenges: [Challenge] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var challengeService: ChallengeService
    private let userId: String
    
    init(challengeService: ChallengeService, userId: String) {
        self.challengeService = challengeService
        self.userId = userId
    }
    
    func updateService(_ service: ChallengeService) {
        self.challengeService = service
    }
    
    func loadChallenges() async {
        isLoading = true
        errorMessage = nil
        
        #if canImport(Supabase)
        await loadChallengesFromSupabase()
        #else
        // Fallback to local challenges
        privateChallenges = challengeService.challenges.filter { !$0.isActive || $0.creatorId == userId }
        publicChallenges = challengeService.challenges.filter { $0.isActive && $0.creatorId != userId }
        #endif
        
        isLoading = false
    }
    
    #if canImport(Supabase)
    private func loadChallengesFromSupabase() async {
        do {
            // Get current user's challenges (private - challenges they're a member of)
            let memberChallenges: [SupabaseChallenge] = try await supabase
                .from("challenges")
                .select()
                .in("id", values: await getUserChallengeIds())
                .eq("is_public", value: false)
                .execute()
                .value
            
            // Convert to Challenge models
            privateChallenges = try await convertToChallenges(memberChallenges)
            
            // Get all public challenges (excluding ones user is already in)
            let userChallengeIds = await getUserChallengeIds()
            let allPublicChallenges: [SupabaseChallenge] = try await supabase
                .from("challenges")
                .select()
                .eq("is_public", value: true)
                .execute()
                .value
            
            // Filter out challenges user is already in
            let availablePublic = allPublicChallenges.filter { challenge in
                !userChallengeIds.contains(challenge.id) &&
                challenge.endDate >= Date()
            }
            
            publicChallenges = try await convertToChallenges(availablePublic)
            
        } catch {
            print("⚠️ Error loading challenges: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            privateChallenges = []
            publicChallenges = []
        }
    }
    
    private func getUserChallengeIds() async -> [String] {
        do {
            let members: [ChallengeMember] = try await supabase
                .from("challenge_members")
                .select("challenge_id")
                .eq("user_id", value: userId)
                .execute()
                .value
            
            return members.map { $0.challengeId }
        } catch {
            print("⚠️ Error getting user challenge IDs: \(error.localizedDescription)")
            return []
        }
    }
    
    private func convertToChallenges(_ supabaseChallenges: [SupabaseChallenge]) async throws -> [Challenge] {
        var challenges: [Challenge] = []
        
        for supabaseChallenge in supabaseChallenges {
            // Get participants
            let members: [ChallengeMember] = try await supabase
                .from("challenge_members")
                .select("user_id")
                .eq("challenge_id", value: supabaseChallenge.id)
                .execute()
                .value
            
            let participantIds = members.map { $0.userId }
            
            let challenge = Challenge(
                id: supabaseChallenge.id,
                name: supabaseChallenge.name,
                description: supabaseChallenge.description ?? "",
                startDate: supabaseChallenge.startDate,
                endDate: supabaseChallenge.endDate,
                targetSteps: 10000, // Default, could be stored in DB
                creatorId: supabaseChallenge.createdBy,
                participantIds: participantIds,
                isActive: supabaseChallenge.endDate >= Date(),
                createdAt: supabaseChallenge.createdAt,
                inviteCode: supabaseChallenge.inviteCode
            )
            
            challenges.append(challenge)
        }
        
        return challenges
    }
    #endif
}

