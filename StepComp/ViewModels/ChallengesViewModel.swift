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
            // Check if user is authenticated before trying to load challenges
            do {
                _ = try await supabase.auth.session
            } catch {
                // No session - user not authenticated yet
                print("ℹ️ Skipping challenge load - user not authenticated yet")
                // Don't clear existing data during refresh - only skip the update
                if activeChallenges.isEmpty && publicChallenges.isEmpty {
                    // First load - can set to empty
                    activeChallenges = []
                    publicChallenges = []
                }
                return
            }
            
            // Get all challenges the user is participating in (via challenge_members)
            let userChallengeIds = await getUserChallengeIds()
            
            // Also get challenges the user created (they might not be in challenge_members yet due to timing)
            let createdChallenges: [SupabaseChallenge] = try await supabase
                .from("challenges")
                .select()
                .eq("created_by", value: userId)
                .gte("end_date", value: ISO8601DateFormatter().string(from: Date()))
                .execute()
                .value
            
            // Get challenges user is a member of
            var memberChallenges: [SupabaseChallenge] = []
            if !userChallengeIds.isEmpty {
                memberChallenges = try await supabase
                    .from("challenges")
                    .select()
                    .in("id", values: userChallengeIds)
                    .gte("end_date", value: ISO8601DateFormatter().string(from: Date()))
                    .execute()
                    .value
            }
            
            // Combine and deduplicate
            var allUserChallenges: [SupabaseChallenge] = createdChallenges
            for memberChallenge in memberChallenges {
                if !allUserChallenges.contains(where: { $0.id == memberChallenge.id }) {
                    allUserChallenges.append(memberChallenge)
                }
            }
            
            // Convert to Challenge models - these are the user's active challenges
            activeChallenges = try await convertToChallenges(allUserChallenges)
            print("📊 ChallengesViewModel: Loaded \(activeChallenges.count) active challenges for user")
            
            // Use IDs of challenges user is already participating in
            let participatingChallengeIds = Set(allUserChallenges.map { $0.id })
            
            // Get all public challenges that haven't ended yet
            let allPublicChallenges: [SupabaseChallenge] = try await supabase
                .from("challenges")
                .select()
                .eq("is_public", value: true)
                .gte("end_date", value: ISO8601DateFormatter().string(from: Date()))
                .execute()
                .value
            
            // Filter out challenges user is already participating in
            let discoverableChallenges = allPublicChallenges.filter { challenge in
                !participatingChallengeIds.contains(challenge.id)
            }
            
            // Sort by created_at descending (newest first)
            let sortedPublicChallenges = discoverableChallenges.sorted { $0.createdAt > $1.createdAt }
            
            // Convert to Challenge models
            let allPublic = try await convertToChallenges(sortedPublicChallenges)
            
            // Show only public challenges that user is NOT already participating in
            // This allows users to discover and join new challenges
            publicChallenges = allPublic            
            print("📊 ChallengesViewModel: Loaded \(publicChallenges.count) discoverable challenges (excluding \(participatingChallengeIds.count) user is already in)")
            
        } catch {
            print("⚠️ Error loading challenges: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            // Don't clear existing data on error - keep what we have
            // Only clear on first load if both arrays are empty
            if activeChallenges.isEmpty && publicChallenges.isEmpty {
                activeChallenges = []
                publicChallenges = []
            }
        }
    }
    
    private func getUserChallengeIds() async -> [String] {
        do {
            let members: [ChallengeMember] = try await supabase
                .from("challenge_members")
                .select()
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
            // Get participants - select all fields to avoid decoding errors
            let members: [ChallengeMember] = try await supabase
                .from("challenge_members")
                .select()
                .eq("challenge_id", value: supabaseChallenge.id)
                .execute()
                .value
            
            let participantIds = members.map { $0.userId }
            
            // Convert category string to enum
            var category: Challenge.ChallengeCategory? = nil
            if let categoryString = supabaseChallenge.category {
                category = Challenge.ChallengeCategory(rawValue: categoryString)
            }
            
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
                inviteCode: supabaseChallenge.inviteCode,
                category: category
            )
            
            challenges.append(challenge)
        }
        
        return challenges
    }
    #endif
}

