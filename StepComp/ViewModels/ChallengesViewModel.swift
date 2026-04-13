//
//  ChallengesViewModel.swift
//  FitComp
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
    @Published var archivedChallenges: [Challenge] = [] // Ended/inactive challenges user participated in
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var challengeService: ChallengeService?
    private let userId: String
    private var loadChallengesTask: Task<Void, Never>?
    private var loadArchivedTask: Task<Void, Never>?
    private let publicPageSize = 40
    private var publicChallengesOffset = 0
    @Published var hasMorePublicChallenges = true
    
    init(userId: String) {
        self.userId = userId
    }
    
    func updateService(_ service: ChallengeService) {
        self.challengeService = service
    }
    
    func loadChallenges() async {
        if let existingTask = loadChallengesTask {
            await existingTask.value
            return
        }
        
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            self.isLoading = true
            self.errorMessage = nil
            self.publicChallengesOffset = 0
            self.hasMorePublicChallenges = true
            
            #if canImport(Supabase)
            await self.loadChallengesFromSupabase()
            #else
            guard let challengeService = self.challengeService else {
                self.isLoading = false
                return
            }
            // Fallback to local challenges
            self.activeChallenges = challengeService.challenges.filter { $0.participantIds.contains(self.userId) && $0.isActive }
            self.publicChallenges = challengeService.challenges.filter { $0.isActive && !$0.participantIds.contains(self.userId) }
            #endif
            
            self.isLoading = false
        }
        
        loadChallengesTask = task
        await task.value
        loadChallengesTask = nil
    }
    
    func loadArchivedChallengesIfNeeded(force: Bool = false) async {
        if !force && !archivedChallenges.isEmpty {
            return
        }
        
        if let existingTask = loadArchivedTask {
            await existingTask.value
            return
        }
        
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            #if canImport(Supabase)
            await self.loadArchivedChallengesFromSupabase()
            #else
            guard let challengeService = self.challengeService else { return }
            self.archivedChallenges = challengeService.challenges.filter { $0.participantIds.contains(self.userId) && !$0.isActive }
            #endif
        }
        
        loadArchivedTask = task
        await task.value
        loadArchivedTask = nil
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
                if activeChallenges.isEmpty && publicChallenges.isEmpty && archivedChallenges.isEmpty {
                    // First load - can set to empty
                    activeChallenges = []
                    publicChallenges = []
                    archivedChallenges = []
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
                .order("created_at", ascending: false)
                .range(from: publicChallengesOffset, to: publicChallengesOffset + publicPageSize - 1)
                .execute()
                .value
            
            // Filter out challenges user is already participating in
            let discoverableChallenges = allPublicChallenges.filter { challenge in
                !participatingChallengeIds.contains(challenge.id)
            }
            
            // Convert to Challenge models
            let allPublic = try await convertToChallenges(discoverableChallenges)
            hasMorePublicChallenges = allPublicChallenges.count >= publicPageSize
            
            // Show only public challenges that user is NOT already participating in
            // This allows users to discover and join new challenges
            publicChallenges = allPublic            
            print("📊 ChallengesViewModel: Loaded \(publicChallenges.count) discoverable challenges (excluding \(participatingChallengeIds.count) user is already in)")
            
        } catch {
            print("⚠️ Error loading challenges: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            // Don't clear existing data on error - keep what we have
            // Only clear on first load if both arrays are empty
            if activeChallenges.isEmpty && publicChallenges.isEmpty && archivedChallenges.isEmpty {
                activeChallenges = []
                publicChallenges = []
                archivedChallenges = []
            }
        }
    }

    func loadMorePublicChallenges() async {
        guard hasMorePublicChallenges else { return }
        publicChallengesOffset += publicPageSize
        
        do {
            _ = try await supabase.auth.session
            
            let participatingChallengeIds = Set(activeChallenges.map { $0.id })
            
            let nextPage: [SupabaseChallenge] = try await supabase
                .from("challenges")
                .select()
                .eq("is_public", value: true)
                .gte("end_date", value: ISO8601DateFormatter().string(from: Date()))
                .order("created_at", ascending: false)
                .range(from: publicChallengesOffset, to: publicChallengesOffset + publicPageSize - 1)
                .execute()
                .value
            
            hasMorePublicChallenges = nextPage.count >= publicPageSize
            
            let discoverable = nextPage.filter { !participatingChallengeIds.contains($0.id) }
            let converted = try await convertToChallenges(discoverable)
            
            publicChallenges.append(contentsOf: converted)
        } catch {
            print("⚠️ Error loading more public challenges: \(error.localizedDescription)")
        }
    }
    
    private func loadArchivedChallengesFromSupabase() async {
        do {
            // Get all challenges the user is participating in (via challenge_members)
            let userChallengeIds = await getUserChallengeIds()
            
            // Get archived challenges the user created (ended or inactive)
            let createdArchivedChallenges: [SupabaseChallenge] = try await supabase
                .from("challenges")
                .select()
                .eq("created_by", value: userId)
                .lt("end_date", value: ISO8601DateFormatter().string(from: Date()))
                .execute()
                .value
            
            print("📊 [ArchivedChallenges] Found \(createdArchivedChallenges.count) created archived challenges")
            
            // Get archived challenges user is a member of (ended or inactive)
            var memberArchivedChallenges: [SupabaseChallenge] = []
            if !userChallengeIds.isEmpty {
                memberArchivedChallenges = try await supabase
                    .from("challenges")
                    .select()
                    .in("id", values: userChallengeIds)
                    .lt("end_date", value: ISO8601DateFormatter().string(from: Date()))
                    .execute()
                    .value
            }
            
            print("📊 [ArchivedChallenges] Found \(memberArchivedChallenges.count) member archived challenges")
            
            // Combine and deduplicate
            var allArchivedChallenges: [SupabaseChallenge] = createdArchivedChallenges
            for memberChallenge in memberArchivedChallenges {
                if !allArchivedChallenges.contains(where: { $0.id == memberChallenge.id }) {
                    allArchivedChallenges.append(memberChallenge)
                }
            }
            
            print("📊 [ArchivedChallenges] Total unique archived challenges: \(allArchivedChallenges.count)")
            
            // Sort by end date descending (most recently ended first)
            allArchivedChallenges.sort { $0.endDate > $1.endDate }
            
            // Convert to Challenge models
            archivedChallenges = try await convertToChallenges(allArchivedChallenges)
            print("📊 ChallengesViewModel: Loaded \(archivedChallenges.count) archived challenges for user")
            
            // Debug each archived challenge
            for challenge in archivedChallenges {
                print("📊 [ArchivedChallenge] '\(challenge.name)': \(challenge.participantIds.count) participants - IDs: \(challenge.participantIds)")
            }
            
        } catch {
            print("⚠️ Error loading archived challenges: \(error.localizedDescription)")
            // Keep existing archived challenges on error
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
            
            print("🔍 [convertToChallenges] Challenge '\(supabaseChallenge.name)' (ID: \(supabaseChallenge.id)): Found \(members.count) members in database")
            
            var participantIds = members.map { $0.userId }
            
            // If challenge_members is empty (common for archived challenges),
            // attempt to recover participants from snapshot or other sources
            if participantIds.isEmpty && supabaseChallenge.endDate < Date() {
                print("🔧 [convertToChallenges] No members found for archived challenge - attempting recovery...")
                
                // Try 1: Check challenge_snapshots (most reliable for archived challenges)
                do {
                    let snapshots: [ChallengeSnapshot] = try await supabase
                        .from("challenge_snapshots")
                        .select()
                        .eq("challenge_id", value: supabaseChallenge.id)
                        .execute()
                        .value
                    
                    if !snapshots.isEmpty {
                        participantIds = snapshots.map { $0.userId }
                        print("✅ [convertToChallenges] Recovered \(participantIds.count) participants from challenge_snapshots")
                    } else {
                        // No snapshot exists - try to create one
                        print("📸 [convertToChallenges] No snapshot found - attempting to create one...")
                        
                        struct SnapshotResult: Codable {
                            let userId: String
                            enum CodingKeys: String, CodingKey {
                                case userId = "user_id"
                            }
                        }
                        
                        let snapshotResults: [SnapshotResult] = try await supabase
                            .rpc("snapshot_challenge_results", params: ["p_challenge_id": supabaseChallenge.id])
                            .execute()
                            .value
                        
                        participantIds = snapshotResults.map { $0.userId }
                        print("✅ [convertToChallenges] Created snapshot with \(participantIds.count) participants")
                    }
                } catch {
                    print("⚠️ [convertToChallenges] Snapshot recovery failed: \(error.localizedDescription)")
                    
                    // Try 2: Check challenge_invites for accepted invitations
                    do {
                        struct InviteRow: Codable {
                            let inviteeId: String
                            enum CodingKeys: String, CodingKey {
                                case inviteeId = "invitee_id"
                            }
                        }
                        
                        let acceptedInvites: [InviteRow] = try await supabase
                            .from("challenge_invites")
                            .select("invitee_id")
                            .eq("challenge_id", value: supabaseChallenge.id)
                            .eq("status", value: "accepted")
                            .execute()
                            .value
                        
                        participantIds = acceptedInvites.map { $0.inviteeId }
                        print("✅ [convertToChallenges] Recovered \(participantIds.count) participants from challenge_invites")
                    } catch {
                        print("⚠️ [convertToChallenges] Failed to recover from challenge_invites: \(error.localizedDescription)")
                    }
                }
                
                if participantIds.isEmpty {
                    print("⚠️ [convertToChallenges] No recovery method succeeded - only creator will be shown")
                }
            }
            
            // Ensure creator is in participantIds (they should be, but double-check)
            // Use case-insensitive comparison since UUIDs might have different casing
            let normalizedCreatorId = supabaseChallenge.createdBy.lowercased()
            let creatorExists = participantIds.contains { $0.lowercased() == normalizedCreatorId }
            if !creatorExists {
                participantIds.append(supabaseChallenge.createdBy)
                print("⚠️ [ChallengesViewModel] Creator \(supabaseChallenge.createdBy) not in participantIds for challenge \(supabaseChallenge.name), adding them")
            }
            
            // Debug: Log participant count for this challenge
            print("🔍 [ChallengesViewModel] Challenge '\(supabaseChallenge.name)': \(participantIds.count) participants (including creator)")
            print("🔍 [ChallengesViewModel] Participant IDs: \(participantIds)")
            
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

