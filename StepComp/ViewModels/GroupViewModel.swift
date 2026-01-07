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
    @Published var dailyLeaderboardEntries: [LeaderboardEntry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    private var challengeService: ChallengeService
    private let challengeId: String
    private let currentUserId: String
    private var refreshTimer: Timer?
    #if canImport(Supabase)
    private var realtimeChannel: RealtimeChannelV2?
    #endif
    
    init(
        challengeService: ChallengeService,
        challengeId: String,
        currentUserId: String
    ) {
        self.challengeService = challengeService
        self.challengeId = challengeId
        self.currentUserId = currentUserId
        
        loadGroupData()
        startAutoRefresh()
        #if canImport(Supabase)
        subscribeToRealtime()
        #endif
    }
    
    // Note: Cleanup is handled by pauseAutoRefresh() in onDisappear
    // We don't use deinit with Task as it causes "capture of self outlives deinit" crashes
    
    func updateService(_ service: ChallengeService) {
        self.challengeService = service
        loadGroupData()
    }
    
    func loadGroupData() {
        isLoading = true
        errorMessage = ""
        
        Task {
            challenge = await challengeService.getChallengeAsync(challengeId)
            
            // Load all-time leaderboard to get all members
            leaderboardEntries = await challengeService.getLeaderboard(for: challengeId, scope: .allTime)
            
            // Also load daily leaderboard for current day's steps
            dailyLeaderboardEntries = await challengeService.getLeaderboard(for: challengeId, scope: .daily)
            
            // Create User objects from all-time leaderboard entries (ensures all members show)
            members = leaderboardEntries.map { entry in
                User(
                    id: entry.userId,
                    username: entry.username,
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
        errorMessage = ""
        
        #if canImport(Supabase)
        do {
            // Delete from challenge_members table
            try await supabase
                .from("challenge_members")
                .delete()
                .eq("challenge_id", value: challengeId)
                .eq("user_id", value: currentUserId)
                .execute()
            
            // CRITICAL FIX: Remove the challenge from cache so next fetch gets fresh data
            challengeService.invalidateChallengeCache(challengeId)
            
            print("✅ Successfully left challenge \(challengeId)")
            
        } catch {
            print("⚠️ Error leaving challenge: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        #endif
        
        isLoading = false
    }
    
    func joinCurrentChallenge() async {
        guard let challenge = challenge else {
            errorMessage = "Challenge not found"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        #if canImport(Supabase)
        do {
            // Add user to challenge_members table
            let member = ChallengeMember(
                id: UUID().uuidString,
                challengeId: challengeId,
                userId: currentUserId,
                totalSteps: 0,
                dailySteps: [:],
                joinedAt: Date(),
                lastUpdated: Date()
            )
            
            try await supabase
                .from("challenge_members")
                .insert(member)
                .execute()
            
            // CRITICAL FIX: Invalidate cache so next fetch gets updated participant list
            challengeService.invalidateChallengeCache(challengeId)
            
            // Get current user's username for notification
            let profiles: [Profile] = try await supabase
                .from("profiles")
                .select("id, username, display_name, avatar_url, public_profile")
                .eq("id", value: currentUserId)
                .execute()
                .value
            
            let username = profiles.first?.username ?? "Someone"
            
            // Send notification to challenge creator
            await ChallengeNotificationService.shared.notifyChallengeCreator(
                creatorId: challenge.creatorId,
                joinerUsername: username,
                challengeName: challenge.name,
                challengeId: challengeId
            )
            
            // Refresh challenge data to update participant list
            await loadGroupDataAsync()
            
            print("✅ Successfully joined challenge \(challengeId)")
            
        } catch {
            print("⚠️ Error joining challenge: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        #endif
        
        isLoading = false
    }
    
    func deleteChallenge() async {
        isLoading = true
        errorMessage = ""
        
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
    
    func refresh() async {
        await loadGroupDataAsync()
    }
    
    private func loadGroupDataAsync() async {
        isLoading = true
        errorMessage = ""
        
        challenge = challengeService.getChallenge(challengeId)
        
        // Load all-time leaderboard to get all members
        leaderboardEntries = await challengeService.getLeaderboard(for: challengeId, scope: .allTime)
        
        // Also load daily leaderboard for current day's steps
        dailyLeaderboardEntries = await challengeService.getLeaderboard(for: challengeId, scope: .daily)
        
        // Create User objects from all-time leaderboard entries (ensures all members show)
        members = leaderboardEntries.map { entry in
            User(
                id: entry.userId,
                username: entry.username,
                displayName: entry.displayName,
                avatarURL: entry.avatarURL
            )
        }
        
        isLoading = false
    }
    
    // MARK: - Auto Refresh
    
    private func startAutoRefresh() {
        // Refresh leaderboard every 15 seconds to show real-time step updates
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.refreshLeaderboard()
            }
        }
        // Ensure timer runs on main thread and continues during scrolling
        if let timer = refreshTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func pauseAutoRefresh() {
        stopAutoRefresh()
    }
    
    func resumeAutoRefresh() {
        if refreshTimer == nil {
            startAutoRefresh()
        }
    }
    
    private func refreshLeaderboard() async {
        // Refresh both all-time and daily leaderboards
        leaderboardEntries = await challengeService.getLeaderboard(for: challengeId, scope: .allTime)
        dailyLeaderboardEntries = await challengeService.getLeaderboard(for: challengeId, scope: .daily)
    }
    
    #if canImport(Supabase)
    // MARK: - Realtime Subscription
    
    private func subscribeToRealtime() {
        #if canImport(Supabase)
        let channelName = "challenge-leaderboard-\(challengeId)"
        
        realtimeChannel = supabase.channel(channelName)
        
        // Note: Realtime subscriptions in Supabase Swift use a different API
        // For now, we'll use polling (every 30 seconds) for reliable updates
        // TODO: Update to proper postgres_changes when API is confirmed
        
        Task {
            do {
                try await realtimeChannel?.subscribeWithError()
                print("✅ Subscribed to realtime leaderboard channel for challenge \(challengeId)")
            } catch {
                print("⚠️ Error subscribing to realtime leaderboard: \(error.localizedDescription)")
            }
        }
        #endif
    }
    
    private func unsubscribeFromRealtime() {
        #if canImport(Supabase)
        Task {
            await realtimeChannel?.unsubscribe()
            realtimeChannel = nil
            print("✅ Unsubscribed from realtime leaderboard")
        }
        #endif
    }
    #endif
}

