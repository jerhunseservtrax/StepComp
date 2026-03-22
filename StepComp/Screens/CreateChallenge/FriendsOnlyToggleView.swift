//
//  FriendsOnlyToggleView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine
import Foundation
#if canImport(Supabase)
import Supabase
#endif

struct FriendsOnlyToggleView: View {
    @Binding var isFriendsOnly: Bool
    
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(FitCompColors.primary.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "person.2.fill")
                        .foregroundColor(FitCompColors.primary)
                        .font(.system(size: 16))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Friends Only")
                        .font(.system(size: 14, weight: .bold))
                    
                    Text("Only your friends can join")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isFriendsOnly)
                .toggleStyle(SwitchToggleStyle(tint: FitCompColors.primary))
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Friends Loader ViewModel

@MainActor
final class FriendsLoaderViewModel: ObservableObject {
    @Published var friends: [User] = []
    @Published var isLoading: Bool = false
    
    func loadFriends() {
        Task {
            #if canImport(Supabase)
            await loadFriendsFromSupabase()
            #endif
        }
    }
    
    #if canImport(Supabase)
    private func loadFriendsFromSupabase() async {
        isLoading = true
        
        do {
            // Get current user ID
            let session = try await supabase.auth.session
            let currentUserId = session.user.id.uuidString
            
            print("🔍 [FriendsLoader] Loading friends for user: \(currentUserId)")
            
            // Load accepted friendships using the same pattern as FriendsService
            // This ensures consistency with how friends are loaded elsewhere
            struct FriendRequest: Codable {
                let requester_id: String
                let addressee_id: String
                let status: String
            }
            
            // Use .or() query pattern (same as FriendsService.listMyFriendships)
            // Then filter for accepted status
            let allFriendships: [FriendRequest] = try await supabase
                .from("friendships")
                .select()
                .or("requester_id.eq.\(currentUserId),addressee_id.eq.\(currentUserId))")
                .execute()
                .value
            
            print("🔍 [FriendsLoader] Found \(allFriendships.count) total friendships (all statuses)")
            
            // Filter for accepted friendships only
            let acceptedFriendships = allFriendships.filter { $0.status == "accepted" }
            
            print("✅ [FriendsLoader] Found \(acceptedFriendships.count) accepted friendships")
            
            // Get friend IDs (the other person in each friendship)
            // Use a Set to avoid duplicates
            // Normalize IDs to lowercase for case-insensitive comparison
            let normalizedCurrentUserId = currentUserId.lowercased()
            var friendIds: Set<String> = []
            for friendship in acceptedFriendships {
                let friendId = friendship.requester_id.lowercased() == normalizedCurrentUserId 
                    ? friendship.addressee_id.lowercased() 
                    : friendship.requester_id.lowercased()
                // Ensure we don't include the current user (case-insensitive comparison)
                if friendId != normalizedCurrentUserId {
                    friendIds.insert(friendId)
                    print("  → Friend ID: \(friendId)")
                } else {
                    print("  ⚠️ Skipping self: \(friendId) (matches current user)")
                }
            }
            
            print("✅ [FriendsLoader] Found \(friendIds.count) unique friend IDs (excluding self)")
            
            // Load friend profiles
            // Note: Supabase .in() can handle up to 1000 values, but we'll batch if needed
            // for very large friend lists (unlikely but safe)
            if !friendIds.isEmpty {
                var allProfiles: [UserProfile] = []
                let batchSize = 1000
                let friendIdsArray = Array(friendIds)
                
                print("🔍 [FriendsLoader] Loading profiles for \(friendIdsArray.count) friends...")
                
                // Process in batches if needed (though unlikely to exceed 1000 friends)
                for i in stride(from: 0, to: friendIdsArray.count, by: batchSize) {
                    let endIndex = min(i + batchSize, friendIdsArray.count)
                    let batch = Array(friendIdsArray[i..<endIndex])
                    
                    print("  → Loading batch \(i/batchSize + 1): \(batch.count) profiles")
                    
                    let profiles: [UserProfile] = try await supabase
                        .from("profiles")
                        .select()
                        .in("id", values: batch)
                        .execute()
                        .value
                    
                    print("  → Loaded \(profiles.count) profiles from batch")
                    allProfiles.append(contentsOf: profiles)
                }
                
                print("✅ [FriendsLoader] Loaded \(allProfiles.count) total friend profiles")
                
                // Convert to User model and filter out current user (safety check)
                // Use case-insensitive comparison since UUIDs might have different casing
                let users = allProfiles
                    .filter { $0.id.lowercased() != normalizedCurrentUserId } // Double-check: exclude current user
                    .map { profile in
                        User(
                            id: profile.id,
                            username: profile.username,
                            firstName: profile.firstName ?? "",
                            lastName: profile.lastName ?? "",
                            avatarURL: profile.avatar ?? profile.avatarUrl,
                            email: profile.email,
                            totalSteps: profile.totalSteps ?? 0,
                            totalChallenges: 0
                        )
                    }
                
                friends = users.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
                
                print("✅ [FriendsLoader] Final friends list contains \(friends.count) friends:")
                for friend in friends {
                    print("  → \(friend.displayName) (@\(friend.username))")
                }
            } else {
                friends = []
                print("ℹ️ [FriendsLoader] No friends found")
            }
            
            isLoading = false
        } catch {
            print("⚠️ [FriendsLoader] Error loading friends: \(error.localizedDescription)")
            print("⚠️ [FriendsLoader] Error details: \(error)")
            if let nsError = error as NSError? {
                print("⚠️ [FriendsLoader] Error domain: \(nsError.domain), code: \(nsError.code)")
                print("⚠️ [FriendsLoader] Error userInfo: \(nsError.userInfo)")
            }
            friends = []
            isLoading = false
        }
    }
    #endif
}

