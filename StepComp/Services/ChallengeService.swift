//
//  ChallengeService.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import Combine // Required for @Published and ObservableObject
#if canImport(Supabase)
import Supabase
#endif

@MainActor
final class ChallengeService: ObservableObject {
    @Published var challenges: [Challenge] = []
    @Published var leaderboardEntries: [String: [LeaderboardEntry]] = [:] // challengeId: entries
    
    private let challengesKey = "challenges"
    private let leaderboardKey = "leaderboard"
    private let useSupabase: Bool
    
    init(useSupabase: Bool = true) {
        self.useSupabase = useSupabase
        #if canImport(Supabase)
        if useSupabase {
            Task {
                await loadChallengesFromSupabase()
            }
        } else {
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
        let inviteCode = isPublic ? nil : (challenge.inviteCode ?? generateInviteCode())
        
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
            createdAt: challenge.createdAt,
            updatedAt: Date()
        )
        
        // Insert challenge into database
        print("📤 Inserting challenge into database...")
        do {
            try await supabase
                .from("challenges")
                .insert(supabaseChallenge)
                .execute()
            print("✅ Challenge inserted into database")
        } catch {
            print("❌ Failed to insert challenge: \(error.localizedDescription)")
            throw error
        }
        
        // Add creator as challenge member
        print("👤 Adding creator as challenge member...")
        do {
            try await addChallengeMember(challengeId: challenge.id, userId: challenge.creatorId)
            print("✅ Creator added as challenge member")
        } catch {
            print("⚠️ Failed to add creator as member: \(error.localizedDescription)")
            // Don't throw - challenge was created, we can try to add member later
        }
        
        // Add selected participants
        for participantId in challenge.participantIds where participantId != challenge.creatorId {
            try? await addChallengeMember(challengeId: challenge.id, userId: participantId)
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
        // Generate a 6-character alphanumeric code
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
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
        
        try await supabase
            .from("challenge_members")
            .insert(member)
            .execute()
        
        print("✅ User \(userId) added to challenge \(challengeId)")
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
        challenges.removeAll { $0.id == challengeId }
        leaderboardEntries.removeValue(forKey: challengeId)
        saveChallenges()
        saveLeaderboards()
    }
    
    func getChallenge(_ challengeId: String) -> Challenge? {
        challenges.first { $0.id == challengeId }
    }
    
    func getUserChallenges(userId: String) -> [Challenge] {
        #if canImport(Supabase)
        if useSupabase {
            // Return cached challenges (loaded from Supabase)
            let userChallenges = challenges.filter { challenge in
                challenge.creatorId == userId || challenge.participantIds.contains(userId)
            }
            print("🔍 getUserChallenges for userId \(userId): Found \(userChallenges.count) challenges out of \(challenges.count) total")
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
        // Use server-side RPC function (secure, validated, computed from daily_steps)
        do {
            let serverEntries: [ServerLeaderboardEntry] = try await supabase
                .rpc("get_challenge_leaderboard", params: ["p_challenge_id": challengeId])
                .execute()
                .value
            
            // Convert to client model
            let entries = serverEntries.map { $0.toLeaderboardEntry(challengeId: challengeId) }
            
            // Cache for offline access
            leaderboardEntries[challengeId] = entries
            
            print("✅ Loaded \(entries.count) leaderboard entries from RPC")
            return entries
        } catch {
            print("⚠️ Error loading leaderboard from Supabase: \(error.localizedDescription)")
            // Fallback to cached entries
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
            let today = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let todayString = dateFormatter.string(from: today)
            
            // Get all members for this challenge
            let members: [ChallengeMember] = try await supabase
                .from("challenge_members")
                .select()
                .eq("challenge_id", value: challengeId)
                .execute()
                .value
            
            // Extract today's steps from daily_steps JSONB
            var dailyEntries: [(userId: String, steps: Int)] = []
            
            for member in members {
                let todaySteps = member.dailySteps[todayString] ?? 0
                dailyEntries.append((userId: member.userId, steps: todaySteps))
            }
            
            // Sort by steps descending
            dailyEntries.sort { $0.steps > $1.steps }
            
            // Get user profiles for display names
            let userIds = dailyEntries.map { $0.userId }
            let profiles: [UserProfile] = try await supabase
                .from("profiles")
                .select()
                .in("id", values: userIds)
                .execute()
                .value
            
            // Create leaderboard entries
            var entries: [LeaderboardEntry] = []
            for (index, dailyEntry) in dailyEntries.enumerated() {
                let profile = profiles.first { $0.id == dailyEntry.userId }
                let entry = LeaderboardEntry(
                    id: UUID().uuidString,
                    userId: dailyEntry.userId,
                    challengeId: challengeId,
                    displayName: profile?.username ?? "User",
                    avatarURL: profile?.avatar,
                    steps: dailyEntry.steps,
                    rank: index + 1,
                    lastUpdated: Date()
                )
                entries.append(entry)
            }
            
            return entries
        } catch {
            print("⚠️ Error loading daily leaderboard: \(error.localizedDescription)")
            return []
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
                    displayName: profile?.username ?? "User",
                    avatarURL: profile?.avatar,
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
            // Get current user ID from session
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString
            
            // Load challenges where user is creator
            let createdChallenges: [SupabaseChallenge] = try await supabase
                .from("challenges")
                .select()
                .eq("created_by", value: userId)
                .execute()
                .value
            
            // Load challenges where user is a member
            let memberRecords: [ChallengeMember] = try await supabase
                .from("challenge_members")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            let memberChallengeIds = memberRecords.map { $0.challengeId }
            
            // Only query if there are member challenge IDs
            var memberChallenges: [SupabaseChallenge] = []
            if !memberChallengeIds.isEmpty {
                memberChallenges = try await supabase
                    .from("challenges")
                    .select()
                    .in("id", values: memberChallengeIds)
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
            
            // Convert to app Challenge model
            var loadedChallenges: [Challenge] = []
            
            for supabaseChallenge in allChallenges {
                // Get challenge members to build participantIds
                let members: [ChallengeMember] = try await supabase
                    .from("challenge_members")
                    .select()
                    .eq("challenge_id", value: supabaseChallenge.id)
                    .execute()
                    .value
                
                let participantIds = members.map { $0.userId }
                
                // Ensure creator is in participantIds (they should be, but double-check)
                var finalParticipantIds = participantIds
                if !finalParticipantIds.contains(supabaseChallenge.createdBy) {
                    finalParticipantIds.append(supabaseChallenge.createdBy)
                    print("⚠️ Creator \(supabaseChallenge.createdBy) not in participantIds, adding them")
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
                    inviteCode: supabaseChallenge.inviteCode
                )
                
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

