//
//  LeaderboardViewModel.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import SwiftUI
import Combine // Required for @Published and ObservableObject

@MainActor
final class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var selectedScope: LeaderboardScope = .allTime
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var challengeService: ChallengeService
    private let challengeId: String
    private let userId: String
    private var previousUserRank: Int?
    
    init(
        challengeService: ChallengeService,
        challengeId: String,
        userId: String
    ) {
        self.challengeService = challengeService
        self.challengeId = challengeId
        self.userId = userId
        
        loadLeaderboard()
    }
    
    func updateService(_ service: ChallengeService) {
        self.challengeService = service
        loadLeaderboard()
    }
    
    func loadLeaderboard() {
        isLoading = true
        errorMessage = nil
        
        Task {
            let loadedEntries = await challengeService.getLeaderboard(for: challengeId, scope: selectedScope)
            // Ensure entries are sorted by rank
            entries = loadedEntries.sorted { $0.rank < $1.rank }
            isLoading = false
            
            // Check for rank changes and send notifications
            checkForRankChange()
        }
    }
    
    func updateScope(_ scope: LeaderboardScope) {
        selectedScope = scope
        loadLeaderboard()
    }
    
    var currentUserEntry: LeaderboardEntry? {
        entries.first { $0.userId == userId }
    }
    
    func refresh() {
        loadLeaderboard()
    }
    
    // MARK: - Leaderboard Notifications
    
    private func checkForRankChange() {
        guard let currentEntry = currentUserEntry else { return }
        
        // Check if rank changed
        if let previousRank = previousUserRank, previousRank != currentEntry.rank {
            let rankDifference = previousRank - currentEntry.rank
            
            if rankDifference > 0 {
                // Moved up
                NotificationManager.shared.sendLeaderboardAlert(
                    message: "You moved up \(rankDifference) place\(rankDifference > 1 ? "s" : "")! You're now rank #\(currentEntry.rank) 🔥",
                    rank: currentEntry.rank
                )
            } else if rankDifference < 0 {
                // Moved down
                NotificationManager.shared.sendLeaderboardAlert(
                    message: "Your rank changed to #\(currentEntry.rank). Keep pushing! 💪",
                    rank: currentEntry.rank
                )
            }
        }
        
        // Update previous rank for next comparison
        previousUserRank = currentEntry.rank
    }
}

