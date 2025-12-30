//
//  FriendsViewModel.swift
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
final class FriendsViewModel: ObservableObject {
    @Published var friends: [User] = [] // Accepted friendships
    @Published var incomingRequests: [User] = [] // Requests where user is addressee
    @Published var outgoingRequests: [User] = [] // Requests where user is requester (pending)
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
            #if canImport(Supabase)
            await loadFriendsFromSupabase()
            #else
            // Fallback to local service
            friends = friendsService.friends
            incomingRequests = []
            outgoingRequests = []
            #endif
            
            // Load today's steps for each friend
            for friend in friends {
                // Mock: Use a portion of totalSteps as today's steps
                let mockTodaySteps = Int(Double(friend.totalSteps) * 0.1)
                todaySteps[friend.id] = mockTodaySteps
            }
            
            isLoading = false
        }
    }
    
    #if canImport(Supabase)
    private func loadFriendsFromSupabase() async {
        do {
            // Friend request structure
            struct FriendRequest: Codable {
                let id: String
                let requester_id: String
                let addressee_id: String
                let status: String
            }
            
            // Load all friend relationships where user is involved
            let requests: [FriendRequest] = try await supabase
                .from("friends")
                .select()
                .or("requester_id.eq.\(currentUserId),addressee_id.eq.\(currentUserId)")
                .execute()
                .value
            
            // Separate into categories
            var acceptedFriends: [String] = []
            var incoming: [String] = []
            var outgoing: [String] = []
            
            for request in requests {
                if request.status == "accepted" {
                    // Determine friend ID (the other person)
                    let friendId = request.requester_id == currentUserId 
                        ? request.addressee_id 
                        : request.requester_id
                    acceptedFriends.append(friendId)
                } else if request.status == "pending" {
                    if request.addressee_id == currentUserId {
                        // Incoming request
                        incoming.append(request.requester_id)
                    } else if request.requester_id == currentUserId {
                        // Outgoing request
                        outgoing.append(request.addressee_id)
                    }
                }
            }
            
            // Load user profiles for accepted friends
            if !acceptedFriends.isEmpty {
                let profiles: [UserProfile] = try await supabase
                    .from("profiles")
                    .select()
                    .in("id", values: acceptedFriends)
                    .execute()
                    .value
                
                friends = profiles.map { profile in
                    User(
                        id: profile.id,
                        username: profile.username,
                        firstName: profile.firstName ?? "",
                        lastName: profile.lastName ?? "",
                        avatarURL: profile.avatar,
                        email: profile.email,
                        totalSteps: 0,
                        totalChallenges: 0
                    )
                }
            } else {
                friends = []
            }
            
            // Load user profiles for incoming requests
            if !incoming.isEmpty {
                let profiles: [UserProfile] = try await supabase
                    .from("profiles")
                    .select()
                    .in("id", values: incoming)
                    .execute()
                    .value
                
                incomingRequests = profiles.map { profile in
                    User(
                        id: profile.id,
                        username: profile.username,
                        firstName: profile.firstName ?? "",
                        lastName: profile.lastName ?? "",
                        avatarURL: profile.avatar,
                        email: profile.email,
                        totalSteps: 0,
                        totalChallenges: 0
                    )
                }
            } else {
                incomingRequests = []
            }
            
            // Load user profiles for outgoing requests
            if !outgoing.isEmpty {
                let profiles: [UserProfile] = try await supabase
                    .from("profiles")
                    .select()
                    .in("id", values: outgoing)
                    .execute()
                    .value
                
                outgoingRequests = profiles.map { profile in
                    User(
                        id: profile.id,
                        username: profile.username,
                        firstName: profile.firstName ?? "",
                        lastName: profile.lastName ?? "",
                        avatarURL: profile.avatar,
                        email: profile.email,
                        totalSteps: 0,
                        totalChallenges: 0
                    )
                }
            } else {
                outgoingRequests = []
            }
            
        } catch {
            print("⚠️ Error loading friends from Supabase: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            friends = []
            incomingRequests = []
            outgoingRequests = []
        }
    }
    #endif
    
    func acceptFriendRequest(from userId: String) {
        Task {
            #if canImport(Supabase)
            do {
                // Update friend request status to accepted
                // WHERE requester_id = userId AND addressee_id = currentUserId AND status = 'pending'
                try await supabase
                    .from("friends")
                    .update(["status": "accepted"])
                    .eq("requester_id", value: userId)
                    .eq("addressee_id", value: currentUserId)
                    .eq("status", value: "pending")
                    .execute()
                
                print("✅ Friend request accepted from \(userId)")
                
                // Reload friends to update UI
                loadFriends()
            } catch {
                print("⚠️ Error accepting friend request: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
            #endif
        }
    }
    
    func declineFriendRequest(from userId: String) {
        Task {
            #if canImport(Supabase)
            do {
                // Delete the friend request (decline = delete pending request)
                try await supabase
                    .from("friends")
                    .delete()
                    .eq("requester_id", value: userId)
                    .eq("addressee_id", value: currentUserId)
                    .eq("status", value: "pending")
                    .execute()
                
                print("✅ Friend request declined from \(userId)")
                
                // Reload friends to update UI
                loadFriends()
            } catch {
                print("⚠️ Error declining friend request: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
            #endif
        }
    }
    
    func cancelFriendRequest(to userId: String) {
        Task {
            #if canImport(Supabase)
            do {
                // Delete the friend request
                try await supabase
                    .from("friends")
                    .delete()
                    .eq("requester_id", value: currentUserId)
                    .eq("addressee_id", value: userId)
                    .eq("status", value: "pending")
                    .execute()
                
                // Reload friends
                loadFriends()
            } catch {
                print("⚠️ Error cancelling friend request: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
            #endif
        }
    }
    
    func getTodaySteps(for userId: String) -> Int {
        return todaySteps[userId] ?? 0
    }
    
    func refresh() {
        loadFriends()
    }
    
    func removeFriend(_ userId: String) {
        Task {
            #if canImport(Supabase)
            do {
                // Delete the friendship (either direction)
                try await supabase
                    .from("friends")
                    .delete()
                    .or("and(requester_id.eq.\(currentUserId),addressee_id.eq.\(userId)),and(requester_id.eq.\(userId),addressee_id.eq.\(currentUserId))")
                    .eq("status", value: "accepted")
                    .execute()
                
                // Reload friends
                loadFriends()
            } catch {
                print("⚠️ Error removing friend: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
            #endif
        }
    }
}

