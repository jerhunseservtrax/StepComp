//
//  ChallengeService.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import Combine
#if canImport(Supabase)
import Supabase
#endif

@MainActor
final class ChallengeService: ObservableObject {
    static let shared = ChallengeService()
    @Published var challenges: [Challenge] = []
    @Published var leaderboardEntries: [String: [LeaderboardEntry]] = [:] // challengeId: entries
    @Published var lastErrorMessage: String?
    
    private let challengesKey = "challenges"
    private let leaderboardKey = "leaderboard"
    private let useSupabase: Bool
    
    init(useSupabase: Bool = true) {
        self.useSupabase = useSupabase
        #if canImport(Supabase)
        if !useSupabase {
            loadChallenges()
            loadLeaderboards()
        }
        #else
        loadChallenges()
        loadLeaderboards()
        #endif
    }
    
    // MARK: - Challenges
    
    func createChallenge(_ challenge: Challenge, isPublic: Bool = false) async throws {
        #if canImport(Supabase)
        if useSupabase {
            try await createChallengeInSupabase(challenge, isPublic: isPublic)
        } else {
            challenges.append(challenge)
            saveChallenges()
        }
        #else
        challenges.append(challenge)
        saveChallenges()
        #endif
    }
    
    #if canImport(Supabase)
    private func createChallengeInSupabase(_ challenge: Challenge, isPublic: Bool) async throws {
        // Generate invite code if not provided (only for private challenges)
        // For public challenges, invite code is nil
        var inviteCode: String? = nil
        if !isPublic {
            inviteCode = challenge.inviteCode ?? generateInviteCode()
        }
        
        // Convert Challenge to SupabaseChallenge
        // isPublic = true means anyone can join, false means private (only invited can join)
        let supabaseChallenge = SupabaseChallenge(
            id: challenge.id,
            name: challenge.name,
            description: challenge.description.isEmpty ? nil : challenge.description,
            startDate: challenge.startDate,
            endDate: challenge.endDate,
            createdBy: challenge.creatorId,
            isPublic: isPublic,
            inviteCode: inviteCode,
            category: challenge.category?.rawValue,
            imageUrl: challenge.imageUrl,
            createdAt: challenge.createdAt,
            updatedAt: Date()
        )
        
        // Insert challenge into database with retry logic for invite code collision
        print("📤 Inserting challenge into database...")
        var retryCount = 0
        let maxRetries = 3
        
        while retryCount < maxRetries {
            do {
                try await supabase
                    .from("challenges")
                    .insert(supabaseChallenge)
                    .execute()
                print("✅ Challenge inserted into database")
                break // Success - exit retry loop
            } catch {
                let errorMsg = error.localizedDescription
                print("❌ Failed to insert challenge: \(errorMsg)")
                
                // Check if it's an invite code collision for private challenges
                if !isPublic && errorMsg.contains("invite_code") && errorMsg.contains("unique") && retryCount < maxRetries - 1 {
                    print("⚠️ Invite code collision detected - generating new code and retrying...")
                    retryCount += 1
                    // Generate a new invite code and update the challenge
                    let newInviteCode = generateInviteCode()
                    let updatedChallenge = SupabaseChallenge(
                        id: supabaseChallenge.id,
                        name: supabaseChallenge.name,
                        description: supabaseChallenge.description,
                        startDate: supabaseChallenge.startDate,
                        endDate: supabaseChallenge.endDate,
                        createdBy: supabaseChallenge.createdBy,
                        isPublic: supabaseChallenge.isPublic,
                        inviteCode: newInviteCode,
                        createdAt: supabaseChallenge.createdAt,
                        updatedAt: Date()
                    )
                    // Try again with new code in next iteration
                    try await supabase
                        .from("challenges")
                        .insert(updatedChallenge)
                        .execute()
                    print("✅ Challenge inserted with new invite code")
                    break
                } else {
                    // Not an invite code issue, or max retries reached
                    throw error
                }
            }
        }
        
        // Add creator as challenge member
        print("👤 Adding creator as challenge member...")
        
        do {
            try await addChallengeMember(challengeId: challenge.id, userId: challenge.creatorId)
            print("✅ Creator added as challenge member")
            
            // Verify the creator was actually added
            let verifyCreator: [ChallengeMember] = try await supabase
                .from("challenge_members")
                .select()
                .eq("challenge_id", value: challenge.id)
                .eq("user_id", value: challenge.creatorId)
                .execute()
                .value
            
            if verifyCreator.isEmpty {
                print("❌ CRITICAL: Creator insertion claimed success but member not found in database!")
            } else {
                print("✅ Creator verified in database: \(verifyCreator.count) record(s)")
            }
        } catch {
            let errorDetails = "\(error)"
            print("❌ CRITICAL ERROR: Failed to add creator as member: \(errorDetails)")
            throw error
        }
        
        // Add selected participants
        var successCount = 0
        var failedParticipants: [(String, String)] = []
        
        for participantId in challenge.participantIds where participantId != challenge.creatorId {
            do {
                try await addChallengeMember(challengeId: challenge.id, userId: participantId)
                
                // Verify the participant was actually added
                let verifyMember: [ChallengeMember] = try await supabase
                    .from("challenge_members")
                    .select()
                    .eq("challenge_id", value: challenge.id)
                    .eq("user_id", value: participantId)
                    .execute()
                    .value
                
                if verifyMember.isEmpty {
                    print("❌ WARNING: Participant \(participantId) insertion claimed success but not found in database!")
                    failedParticipants.append((participantId, "Verification failed - not in database"))
                } else {
                    successCount += 1
                    print("✅ Participant \(participantId) verified in database")
                }
            } catch {
                let errorDetails = "\(error)"
                print("❌ Failed to add participant \(participantId): \(errorDetails)")
                failedParticipants.append((participantId, errorDetails))
            }
        }
        
        // Log summary
        print("📊 Member addition summary: \(successCount) succeeded, \(failedParticipants.count) failed")
        if !failedParticipants.isEmpty {
            print("❌ Failed participants:")
            for (participantId, error) in failedParticipants {
                print("  - \(participantId): \(error)")
            }
        }
        
        // Refresh challenges from database to ensure consistency
        // This ensures the challenge appears immediately in the UI
        // Add a small delay to ensure database transaction is committed
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        await loadChallengesFromSupabase()
        print("✅ Challenge created in Supabase: \(challenge.id)")
        print("✅ Total challenges loaded: \(challenges.count)")
    }
    
    private func generateInviteCode() -> String {
        // Generate an 8-character alphanumeric code for better uniqueness
        // 36^8 = 2.8 trillion possible codes - virtually no collision risk
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
    
    private func addChallengeMember(challengeId: String, userId: String) async throws {
        let member = ChallengeMember(
            id: UUID().uuidString,
            challengeId: challengeId,
            userId: userId,
            totalSteps: 0,
            dailySteps: [:],
            joinedAt: Date(),
            lastUpdated: Date()
        )
        
        do {
            try await supabase
                .from("challenge_members")
                .insert(member)
                .execute()
            
            print("✅ User \(userId) added to challenge \(challengeId)")
        } catch {
            throw error
        }
    }
    #endif
    
    func updateChallenge(_ challenge: Challenge) async throws {
        guard let index = challenges.firstIndex(where: { $0.id == challenge.id }) else {
            throw ChallengeError.notFound
        }
        challenges[index] = challenge
        saveChallenges()
    }
    
    func deleteChallenge(_ challengeId: String) async throws {
        #if canImport(Supabase)
        if useSupabase {
            print("🗑️ Deleting challenge from Supabase: \(challengeId)")
            do {
                // Delete from Supabase database
                // RLS policy ensures only the creator can delete
                try await supabase
                    .from("challenges")
                    .delete()
                    .eq("id", value: challengeId)
                    .execute()
                
                print("✅ Challenge deleted from Supabase")
                
                // Remove from local cache
                challenges.removeAll { $0.id == challengeId }
                leaderboardEntries.removeValue(forKey: challengeId)
                
                // Refresh from database to ensure consistency
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await loadChallengesFromSupabase()
            } catch {
                print("❌ Failed to delete challenge from Supabase: \(error.localizedDescription)")
                throw error
            }
            return
        }
        #endif
        
        // Local storage fallback
        challenges.removeAll { $0.id == challengeId }
        leaderboardEntries.removeValue(forKey: challengeId)
        saveChallenges()
        saveLeaderboards()
    }
    
    func getChallenge(_ challengeId: String) -> Challenge? {
        return challenges.first { $0.id == challengeId }
    }
    
    // Invalidate cached challenge (forces fresh fetch from database)
    func invalidateChallengeCache(_ challengeId: String) {
        challenges.removeAll { $0.id == challengeId }
    }
    
    // New async version that fetches from Supabase if not in cache
    func getChallengeAsync(_ challengeId: String) async -> Challenge? {
        // First check local cache
        if let cached = challenges.first(where: { $0.id == challengeId }) {
            return cached
        }
        
        // If not in cache, fetch from Supabase
        #if canImport(Supabase)
        if useSupabase {
            do {
                // Fetch challenge from Supabase
                let supabaseChallenges: [SupabaseChallenge] = try await supabase
                    .from("challenges")
                    .select()
                    .eq("id", value: challengeId)
                    .execute()
                    .value
                
                guard let supabaseChallenge = supabaseChallenges.first else {
                    return nil
                }
                
                // Get challenge members
                let members: [ChallengeMember] = try await supabase
                    .from("challenge_members")
                    .select()
                    .eq("challenge_id", value: supabaseChallenge.id)
                    .execute()
                    .value
                
                let participantIds = members.map { $0.userId }
                
                // Ensure creator is in participantIds
                var finalParticipantIds = participantIds
                if !finalParticipantIds.contains(supabaseChallenge.createdBy) {
                    finalParticipantIds.append(supabaseChallenge.createdBy)
                }
                
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
                    targetSteps: 10000, // Default - could add to schema later
                    creatorId: supabaseChallenge.createdBy,
                    participantIds: finalParticipantIds,
                    isActive: true,
                    createdAt: supabaseChallenge.createdAt,
                    inviteCode: supabaseChallenge.inviteCode,
                    category: category,
                    imageUrl: supabaseChallenge.imageUrl
                )
                
                // Add to cache for future use
                if !challenges.contains(where: { $0.id == challenge.id }) {
                    challenges.append(challenge)
                }
                
                return challenge
            } catch {
                return nil
            }
        }
        #endif
        
        return nil
    }
    
    func getUserChallenges(userId: String) -> [Challenge] {
        #if canImport(Supabase)
        if useSupabase {
            // Return cached challenges (loaded from Supabase)
            let userChallenges = challenges.filter { challenge in
                challenge.creatorId == userId || challenge.participantIds.contains(userId)
            }
            for challenge in userChallenges {
                print("  - \(challenge.name): creator=\(challenge.creatorId == userId), participant=\(challenge.participantIds.contains(userId))")
            }
            return userChallenges
        } else {
            return challenges.filter { challenge in
                challenge.creatorId == userId || challenge.participantIds.contains(userId)
            }
        }
        #else
        return challenges.filter { challenge in
            challenge.creatorId == userId || challenge.participantIds.contains(userId)
        }
        #endif
    }
    
    func getActiveChallenges(userId: String) -> [Challenge] {
        // Show challenges that are ongoing OR haven't started yet (user is part of them)
        // This ensures users see challenges they've created/joined even if they start in the future
        let userChallenges = getUserChallenges(userId: userId)
        let now = Date()
        return userChallenges.filter { challenge in
            // Show if ongoing (started and not ended)
            if challenge.isOngoing {
                return true
            }
            // Also show if it hasn't started yet (future challenge)
            if challenge.isActive && challenge.startDate > now {
                return true
            }
            // Don't show if it's ended
            return false
        }
    }
    
    func joinChallenge(_ challengeId: String, userId: String) async throws {
        #if canImport(Supabase)
        if useSupabase {
            try await joinChallengeInSupabase(challengeId: challengeId, userId: userId)
        } else {
            guard var challenge = getChallenge(challengeId) else {
                throw ChallengeError.notFound
            }
            
            guard !challenge.participantIds.contains(userId) else {
                throw ChallengeError.alreadyParticipating
            }
            
            challenge.participantIds.append(userId)
            try await updateChallenge(challenge)
        }
        #else
        guard var challenge = getChallenge(challengeId) else {
            throw ChallengeError.notFound
        }
        
        guard !challenge.participantIds.contains(userId) else {
            throw ChallengeError.alreadyParticipating
        }
        
        challenge.participantIds.append(userId)
        try await updateChallenge(challenge)
        #endif
    }
    
    #if canImport(Supabase)
    private func joinChallengeInSupabase(challengeId: String, userId: String) async throws {
        // Check if already a member
        let existing: [ChallengeMember] = try await supabase
            .from("challenge_members")
            .select()
            .eq("challenge_id", value: challengeId)
            .eq("user_id", value: userId)
            .execute()
            .value
        
        if !existing.isEmpty {
            throw ChallengeError.alreadyParticipating
        }
        
        // Add as challenge member
        try await addChallengeMember(challengeId: challengeId, userId: userId)
        
        // Update local cache
        if var challenge = getChallenge(challengeId) {
            if !challenge.participantIds.contains(userId) {
                challenge.participantIds.append(userId)
                challenges = challenges.map { $0.id == challengeId ? challenge : $0 }
            }
        }
        
        print("✅ User \(userId) joined challenge \(challengeId)")
    }
    #endif
    
    // MARK: - Leaderboard
    
    func updateLeaderboardEntry(_ entry: LeaderboardEntry) {
        let challengeId = entry.challengeId
        var entries = leaderboardEntries[challengeId] ?? []
        
        if let index = entries.firstIndex(where: { $0.userId == entry.userId }) {
            entries[index] = entry
        } else {
            entries.append(entry)
        }
        
        // Sort by steps descending and update ranks
        entries.sort { $0.steps > $1.steps }
        for (index, _) in entries.enumerated() {
            entries[index].rank = index + 1
        }
        
        leaderboardEntries[challengeId] = entries
        saveLeaderboards()
    }
    
    func getLeaderboard(for challengeId: String) async -> [LeaderboardEntry] {
        #if canImport(Supabase)
        if useSupabase {
            return await getLeaderboardFromSupabase(challengeId: challengeId)
        } else {
            return leaderboardEntries[challengeId] ?? []
        }
        #else
        return leaderboardEntries[challengeId] ?? []
        #endif
    }
    
    func getLeaderboard(for challengeId: String, scope: LeaderboardScope) async -> [LeaderboardEntry] {
        let allEntries = await getLeaderboard(for: challengeId)
        
        switch scope {
        case .daily:
            return await filterEntriesForToday(allEntries, challengeId: challengeId)
        case .weekly:
            return await filterEntriesForWeek(allEntries, challengeId: challengeId)
        case .allTime:
            return allEntries
        }
    }
    
    #if canImport(Supabase)
    private func getLeaderboardFromSupabase(challengeId: String) async -> [LeaderboardEntry] {
        let cacheKey = "leaderboard_\(challengeId)"
        do {
            let serverEntries: [ServerLeaderboardEntry] = try await SupabaseRequestExecutor.executeWithAuthRetry(context: "get_leaderboard") {
                try await supabase
                    .rpc("get_challenge_leaderboard", params: ["p_challenge_id": challengeId])
                    .execute()
                    .value
            }

            let entries = serverEntries.map { $0.toLeaderboardEntry(challengeId: challengeId) }
            leaderboardEntries[challengeId] = entries
            OfflineCacheService.save(entries, key: cacheKey)
            return entries
        } catch {
            if let cached = OfflineCacheService.load([LeaderboardEntry].self, key: cacheKey) {
                leaderboardEntries[challengeId] = cached
                return cached
            }
            return leaderboardEntries[challengeId] ?? []
        }
    }
    #endif
    
    private func filterEntriesForToday(_ entries: [LeaderboardEntry], challengeId: String) async -> [LeaderboardEntry] {
        #if canImport(Supabase)
        if useSupabase {
            return await getDailyLeaderboardFromSupabase(challengeId: challengeId)
        } else {
            return entries
        }
        #else
        return entries
        #endif
    }
    
    private func filterEntriesForWeek(_ entries: [LeaderboardEntry], challengeId: String) async -> [LeaderboardEntry] {
        #if canImport(Supabase)
        if useSupabase {
            return await getWeeklyLeaderboardFromSupabase(challengeId: challengeId)
        } else {
            return entries
        }
        #else
        return entries
        #endif
    }
    
    #if canImport(Supabase)
    private func getDailyLeaderboardFromSupabase(challengeId: String) async -> [LeaderboardEntry] {
        do {
            let serverEntries: [ServerLeaderboardEntry] = try await SupabaseRequestExecutor.executeWithAuthRetry(context: "get_daily_leaderboard") {
                try await supabase
                    .rpc("get_challenge_leaderboard_today", params: ["p_challenge_id": challengeId])
                    .execute()
                    .value
            }
            
            // Convert to client model
            let entries = serverEntries.map { $0.toLeaderboardEntry(challengeId: challengeId) }
            
            print("✅ Loaded \(entries.count) daily leaderboard entries from RPC")
            return entries
        } catch {
            print("⚠️ Error loading daily leaderboard: \(error.localizedDescription)")
            // Fallback to all-time leaderboard (better than empty)
            return await getLeaderboardFromSupabase(challengeId: challengeId)
        }
    }
    
    private func getWeeklyLeaderboardFromSupabase(challengeId: String) async -> [LeaderboardEntry] {
        do {
            let calendar = Calendar.current
            let now = Date()
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            // Get all members for this challenge
            let members: [ChallengeMember] = try await supabase
                .from("challenge_members")
                .select()
                .eq("challenge_id", value: challengeId)
                .execute()
                .value
            
            // Calculate weekly steps from daily_steps JSONB
            var weeklyEntries: [(userId: String, steps: Int)] = []
            
            for member in members {
                var weeklySteps = 0
                var currentDate = weekAgo
                while currentDate <= now {
                    let dateString = dateFormatter.string(from: currentDate)
                    weeklySteps += member.dailySteps[dateString] ?? 0
                    currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                }
                weeklyEntries.append((userId: member.userId, steps: weeklySteps))
            }
            
            // Sort by steps descending
            weeklyEntries.sort { $0.steps > $1.steps }
            
            // Get user profiles
            let userIds = weeklyEntries.map { $0.userId }
            let profiles: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .in("id", values: userIds)
                .execute()
                .value
            
            // Create leaderboard entries
            var entries: [LeaderboardEntry] = []
            for (index, weeklyEntry) in weeklyEntries.enumerated() {
                let profile = profiles.first { $0.id == weeklyEntry.userId }
                let entry = LeaderboardEntry(
                    id: UUID().uuidString,
                    userId: weeklyEntry.userId,
                    challengeId: challengeId,
                    username: profile?.username ?? "",
                    displayName: profile?.displayName ?? profile?.username ?? "User",
                    avatarURL: profile?.avatarUrl ?? profile?.avatar,
                    steps: weeklyEntry.steps,
                    rank: index + 1,
                    lastUpdated: Date()
                )
                entries.append(entry)
            }
            
            return entries
        } catch {
            print("⚠️ Error loading weekly leaderboard: \(error.localizedDescription)")
            return []
        }
    }
    #endif
    
    // MARK: - Supabase Methods
    
    #if canImport(Supabase)
    func refreshChallenges() async {
        await loadChallengesFromSupabase()
    }
    
    private func loadChallengesFromSupabase() async {
        do {
            // Check if user is authenticated before trying to load challenges
            do {
                _ = try await supabase.auth.session
            } catch {
                // No session - user not authenticated yet, skip loading challenges
                print("ℹ️ Skipping challenge load - user not authenticated yet")
                return
            }
            
            // Get current user ID from session
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString
            
            let pageSize = 200
            // Load challenges where user is creator
            let createdChallenges: [SupabaseChallenge] = try await RetryUtility.withExponentialBackoff {
                try await supabase
                    .from("challenges")
                    .select()
                    .eq("created_by", value: userId)
                    .range(from: 0, to: pageSize - 1)
                    .execute()
                    .value
            }
            
            // Load challenges where user is a member
            let memberRecords: [ChallengeMember] = try await RetryUtility.withExponentialBackoff {
                try await supabase
                    .from("challenge_members")
                    .select()
                    .eq("user_id", value: userId)
                    .execute()
                    .value
            }
            
            let memberChallengeIds = memberRecords.map { $0.challengeId }
            
            // Only query if there are member challenge IDs
            var memberChallenges: [SupabaseChallenge] = []
            if !memberChallengeIds.isEmpty {
                memberChallenges = try await supabase
                    .from("challenges")
                    .select()
                    .in("id", values: memberChallengeIds)
                    .range(from: 0, to: pageSize - 1)
                    .execute()
                    .value
            }
            
            // Combine and deduplicate
            var allChallenges = createdChallenges
            for challenge in memberChallenges {
                if !allChallenges.contains(where: { $0.id == challenge.id }) {
                    allChallenges.append(challenge)
                }
            }
            
            // Batch-load challenge members to avoid N+1 queries.
            let challengeIds = allChallenges.map(\.id)
            var membersByChallengeId: [String: [ChallengeMember]] = [:]
            if !challengeIds.isEmpty {
                let allMembers: [ChallengeMember] = try await supabase
                    .from("challenge_members")
                    .select()
                    .in("challenge_id", values: challengeIds)
                    .execute()
                    .value

                membersByChallengeId = Dictionary(grouping: allMembers, by: \.challengeId)
            }

            // Convert to app Challenge model
            var loadedChallenges: [Challenge] = []
            
            for supabaseChallenge in allChallenges {
                let members = membersByChallengeId[supabaseChallenge.id] ?? []
                
                let participantIds = members.map { $0.userId }
                
                // Ensure creator is in participantIds (they should be, but double-check)
                var finalParticipantIds = participantIds
                if !finalParticipantIds.contains(supabaseChallenge.createdBy) {
                    finalParticipantIds.append(supabaseChallenge.createdBy)
                    print("⚠️ Creator \(supabaseChallenge.createdBy) not in participantIds, adding them")
                }
                
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
                    targetSteps: 10000, // Default - could add to schema later
                    creatorId: supabaseChallenge.createdBy,
                    participantIds: finalParticipantIds,
                    isActive: true,
                    createdAt: supabaseChallenge.createdAt,
                    inviteCode: supabaseChallenge.inviteCode,
                    category: category,
                    imageUrl: supabaseChallenge.imageUrl
                )
                
                // Debug logging for challenge loading
                if challenge.name == "Test group" || challenge.name.contains("Test group") {
                    print("🔍 [ChallengeService] Loaded 'Test group': participants=\(finalParticipantIds.count), startDate=\(supabaseChallenge.startDate), endDate=\(supabaseChallenge.endDate), daysRemaining=\(challenge.daysRemaining)")
                }
                
                loadedChallenges.append(challenge)
            }
            
            challenges = loadedChallenges
            print("✅ Loaded \(challenges.count) challenges from Supabase")
            // Log challenge details for debugging
            for challenge in challenges {
                print("  - Challenge: \(challenge.name) (ID: \(challenge.id), Creator: \(challenge.creatorId), Participants: \(challenge.participantIds.count), Start: \(challenge.startDate), End: \(challenge.endDate))")
            }
        } catch {
            print("⚠️ Error loading challenges from Supabase: \(error.localizedDescription)")
            lastErrorMessage = error.localizedDescription
            // Fallback to local storage
            loadChallenges()
        }
    }
    #endif
    
    // MARK: - Persistence
    
    private func saveChallenges() {
        if let encoded = try? JSONEncoder().encode(challenges) {
            UserDefaults.standard.set(encoded, forKey: challengesKey)
        }
    }
    
    private func loadChallenges() {
        guard let data = UserDefaults.standard.data(forKey: challengesKey),
              let decoded = try? JSONDecoder().decode([Challenge].self, from: data) else {
            return
        }
        challenges = decoded
    }
    
    private func saveLeaderboards() {
        if let encoded = try? JSONEncoder().encode(leaderboardEntries) {
            UserDefaults.standard.set(encoded, forKey: leaderboardKey)
        }
    }
    
    private func loadLeaderboards() {
        guard let data = UserDefaults.standard.data(forKey: leaderboardKey),
              let decoded = try? JSONDecoder().decode([String: [LeaderboardEntry]].self, from: data) else {
            return
        }
        leaderboardEntries = decoded
    }
    
    // MARK: - Challenge Snapshots
    
    #if canImport(Supabase)
    /// Ensures a snapshot exists for an archived challenge
    /// Returns snapshot data as LeaderboardEntry array
    func ensureChallengeSnapshot(challengeId: String) async throws -> [LeaderboardEntry] {
        print("📸 [ChallengeService] Checking snapshot for challenge \(challengeId)")
        
        // First, check if snapshot already exists
        let existingSnapshots: [ChallengeSnapshot] = try await supabase
            .from("challenge_snapshots")
            .select()
            .eq("challenge_id", value: challengeId)
            .order("rank", ascending: true)
            .execute()
            .value
        
        if !existingSnapshots.isEmpty {
            print("✅ [ChallengeService] Found existing snapshot with \(existingSnapshots.count) participants")
            return existingSnapshots.map { $0.toLeaderboardEntry() }
        }
        
        // No snapshot exists - trigger RPC to create one
        print("📸 [ChallengeService] No snapshot found - creating snapshot via RPC...")
        
        struct SnapshotResult: Codable {
            let userId: String
            let username: String
            let displayName: String
            let avatarUrl: String?
            let totalSteps: Int
            let rank: Int
            
            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case username
                case displayName = "display_name"
                case avatarUrl = "avatar_url"
                case totalSteps = "total_steps"
                case rank
            }
        }
        
        let results: [SnapshotResult] = try await supabase
            .rpc("snapshot_challenge_results", params: ["p_challenge_id": challengeId])
            .execute()
            .value
        
        print("✅ [ChallengeService] Snapshot created with \(results.count) participants")
        
        // Convert to LeaderboardEntry
        return results.map { result in
            LeaderboardEntry(
                id: UUID().uuidString,
                userId: result.userId,
                challengeId: challengeId,
                username: result.username,
                displayName: result.displayName,
                avatarURL: result.avatarUrl,
                steps: result.totalSteps,
                rank: result.rank,
                lastUpdated: Date()
            )
        }
    }
    #endif
    
    // MARK: - Step Syncing
    // NOTE: Step syncing is now handled entirely by the Edge Function + sync_daily_steps() RPC
    // These methods are kept for backwards compatibility but are no longer the primary sync path
    
    func syncStepsToChallenge(challengeId: String, userId: String, steps: Int, date: Date = Date()) async throws {
        // ⚠️ DEPRECATED: Steps are now synced automatically via Edge Function
        // The sync_daily_steps() RPC automatically updates challenge_members
        print("ℹ️ syncStepsToChallenge is deprecated - steps are synced via Edge Function")
    }
    
    func syncTodayStepsToAllChallenges(healthKitService: HealthKitService) async {
        // ⚠️ DEPRECATED: Steps are now synced automatically via Edge Function
        // The sync_daily_steps() RPC automatically updates all challenge_members
        print("ℹ️ syncTodayStepsToAllChallenges is deprecated - steps are synced via Edge Function")
    }
}

enum ChallengeError: LocalizedError {
    case notFound
    case alreadyParticipating
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Challenge not found"
        case .alreadyParticipating:
            return "You are already participating in this challenge"
        case .invalidData:
            return "Invalid challenge data"
        }
    }
}

