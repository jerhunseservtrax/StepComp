//
//  FriendsSection.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

struct ProfileFriendsSection: View {
    let onAddFriends: () -> Void
    
    @EnvironmentObject var friendsService: FriendsService
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
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
                    .background(primaryYellow)
                    .cornerRadius(20)
                }
            }
            
            if friendsService.friends.isEmpty {
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
                        ForEach(friendsService.friends.prefix(10)) { friend in
                            FriendAvatarCard(friend: friend)
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
    }
}

struct FriendAvatarCard: View {
    let friend: User
    
    var body: some View {
        VStack(spacing: 8) {
            AvatarView(
                displayName: friend.displayName,
                avatarURL: friend.avatarURL,
                size: 56
            )
            
            Text(friend.displayName)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .frame(width: 60)
        }
    }
}

