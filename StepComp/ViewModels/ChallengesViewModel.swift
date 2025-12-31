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
    @Published var activeChallenges: [Challenge] = [] // All challenges user is participating in (private + public)
    @Published var publicChallenges: [Challenge] = [] // Public challenges available to join
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
        activeChallenges = challengeService.challenges.filter { $0.participantIds.contains(userId) && $0.isActive }
        publicChallenges = challengeService.challenges.filter { $0.isActive && !$0.participantIds.contains(userId) }
        #endif
        
        isLoading = false
    }
    
    #if canImport(Supabase)
    private func loadChallengesFromSupabase() async {
        do {
            // Get all challenges the user is participating in (both private and public)
            let userChallengeIds = await getUserChallengeIds()
            
            if !userChallengeIds.isEmpty {
                let memberChallenges: [SupabaseChallenge] = try await supabase
                    .from("challenges")
                    .select()
                    .in("id", values: userChallengeIds)
                    .gte("end_date", value: ISO8601DateFormatter().string(from: Date()))
                    .execute()
                    .value
                
                // Convert to Challenge models - these are the user's active challenges
                activeChallenges = try await convertToChallenges(memberChallenges)
            } else {
                activeChallenges = []
            }
            
            // Get all public challenges that haven't ended yet
            // This includes challenges that haven't started (future challenges) and ongoing ones
            let allPublicChallenges: [SupabaseChallenge] = try await supabase
                .from("challenges")
                .select()
                .eq("is_public", value: true)
                .gte("end_date", value: ISO8601DateFormatter().string(from: Date()))
                .execute()
                .value
            
            // Sort by created_at descending (newest first)
            let sortedPublicChallenges = allPublicChallenges.sorted { $0.createdAt > $1.createdAt }
            
            // Convert to Challenge models
            let allPublic = try await convertToChallenges(sortedPublicChallenges)
            
            // Filter out challenges the user is already participating in
            // These will show in the Active tab instead
            // But keep challenges the user created (so they can see their own public challenges)
            publicChallenges = allPublic.filter { challenge in
                // Show if user created it (so they can see their own public challenges)
                if challenge.creatorId == userId {
                    return true
                }
                // Otherwise, only show if user is NOT already a participant
                return !challenge.participantIds.contains(userId)
            }
            
        } catch {
            print("⚠️ Error loading challenges: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            activeChallenges = []
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

