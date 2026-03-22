//
//  FriendsSection.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

struct ProfileFriendsSection: View {
    let onAddFriends: () -> Void
    let sessionViewModel: SessionViewModel
    
    @StateObject private var friendsViewModel: FriendsViewModel
    @EnvironmentObject var friendsService: FriendsService
    
    
    init(sessionViewModel: SessionViewModel, onAddFriends: @escaping () -> Void) {
        self.sessionViewModel = sessionViewModel
        self.onAddFriends = onAddFriends
        let myUserId = sessionViewModel.currentUser?.id ?? ""
        _friendsViewModel = StateObject(wrappedValue: FriendsViewModel(service: FriendsService(), myUserId: myUserId))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Friends")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                Button(action: onAddFriends) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add Friends")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(FitCompColors.primary)
                    .cornerRadius(20)
                }
            }
            
            if friendsViewModel.friendItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No friends yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text("Add friends to compete together")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(friendsViewModel.friendItems.prefix(10).filter { $0.status == .accepted }) { item in
                            FriendAvatarCard(profile: item.profile)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
        .onAppear {
            friendsViewModel.updateService(service: friendsService, myUserId: sessionViewModel.currentUser?.id ?? "")
            Task {
                try? await friendsViewModel.refreshFriendships()
            }
        }
    }
}

struct FriendAvatarCard: View {
    let profile: Profile
    
    var body: some View {
        VStack(spacing: 8) {
            AvatarView(
                displayName: profile.displayName ?? profile.username,
                avatarURL: profile.avatarUrl,
                size: 56
            )
            
            Text(profile.displayName ?? profile.username)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .frame(width: 60)
        }
    }
}

