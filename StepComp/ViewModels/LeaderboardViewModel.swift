//
//  LeaderboardViewModel.swift
//  StepComp
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
}

