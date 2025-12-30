//
//  FriendsOnlyToggleView.swift
//  StepComp
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
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(primaryYellow.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "person.2.fill")
                        .foregroundColor(primaryYellow)
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
                .toggleStyle(SwitchToggleStyle(tint: primaryYellow))
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
            
            // Load accepted friendships
            struct FriendRequest: Codable {
                let requester_id: String
                let addressee_id: String
                let status: String
            }
            
            // Get all accepted friendships where user is involved
            let requests: [FriendRequest] = try await supabase
                .from("friends")
                .select()
                .or("requester_id.eq.\(currentUserId),addressee_id.eq.\(currentUserId))")
                .eq("status", value: "accepted")
                .execute()
                .value
            
            // Get friend IDs (the other person in each friendship)
            var friendIds: [String] = []
            for request in requests {
                let friendId = request.requester_id == currentUserId 
                    ? request.addressee_id 
                    : request.requester_id
                friendIds.append(friendId)
            }
            
            // Load friend profiles
            if !friendIds.isEmpty {
                let profiles: [UserProfile] = try await supabase
                    .from("profiles")
                    .select()
                    .in("id", values: friendIds)
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
            
            isLoading = false
        } catch {
            print("⚠️ Error loading friends: \(error.localizedDescription)")
            friends = []
            isLoading = false
        }
    }
    #endif
}

