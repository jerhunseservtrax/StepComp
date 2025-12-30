//
//  FriendsViewModel.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import Foundation
import SwiftUI
import Combine // Required for @Published and ObservableObject

@MainActor
final class FriendsViewModel: ObservableObject {
    @Published var friends: [User] = []
    @Published var todaySteps: [String: Int] = [:] // userId: todaySteps
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var friendsService: FriendsService
    private var healthKitService: HealthKitService
    private let currentUserId: String
    
    init(
        friendsService: FriendsService,
        healthKitService: HealthKitService,
        currentUserId: String
    ) {
        self.friendsService = friendsService
        self.healthKitService = healthKitService
        self.currentUserId = currentUserId
        
        loadFriends()
    }
    
    func updateServices(friendsService: FriendsService, healthKitService: HealthKitService) {
        self.friendsService = friendsService
        self.healthKitService = healthKitService
        loadFriends()
    }
    
    func loadFriends() {
        isLoading = true
        errorMessage = nil
        
        Task {
            friends = friendsService.friends
            
            // Load today's steps for each friend
            // In a real app, this would come from a backend API
            // For now, we'll use mock data based on their totalSteps
            for friend in friends {
                // Mock: Use a portion of totalSteps as today's steps
                let mockTodaySteps = Int(Double(friend.totalSteps) * 0.1)
                todaySteps[friend.id] = mockTodaySteps
            }
            
            isLoading = false
        }
    }
    
    func getTodaySteps(for userId: String) -> Int {
        return todaySteps[userId] ?? 0
    }
    
    func refresh() {
        loadFriends()
    }
    
    func removeFriend(_ userId: String) {
        friendsService.removeFriend(userId)
        loadFriends()
    }
}

