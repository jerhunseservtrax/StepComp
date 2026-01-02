//
//  InviteFriendsToChallengeView.swift
//  StepComp
//
//  Select friends to invite to a challenge
//

import SwiftUI

struct InviteFriendsToChallengeView: View {
    let challengeId: String
    let challengeName: String
    let currentUserId: String
    
    @Environment(\.dismiss) var dismiss
    @State private var friends: [FriendForInvite] = []
    @State private var isLoading = true
    @State private var selectedFriendIds: Set<String> = []
    @State private var isSending = false
    @State private var errorMessage: String?
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: primaryYellow))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if friends.isEmpty {
                    EmptyFriendsView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(friends) { friend in
                                FriendInviteRow(
                                    friend: friend,
                                    isSelected: selectedFriendIds.contains(friend.id),
                                    onTap: {
                                        if friend.isAlreadyMember {
                                            return
                                        }
                                        if selectedFriendIds.contains(friend.id) {
                                            selectedFriendIds.remove(friend.id)
                                        } else {
                                            selectedFriendIds.insert(friend.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
                
                // Bottom button
                if !friends.isEmpty {
                    VStack(spacing: 0) {
                        Divider()
                        
                        Button(action: sendInvites) {
                            HStack {
                                if isSending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text("Send Invites (\(selectedFriendIds.count))")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedFriendIds.isEmpty ? Color.gray : primaryYellow)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                            .padding()
                        }
                        .disabled(selectedFriendIds.isEmpty || isSending)
                    }
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
        .task {
            await loadFriends()
        }
    }
    
    private func loadFriends() async {
        isLoading = true
        
        // TODO: Implement actual friend loading from database
        // For now, show empty state
        friends = []
        
        isLoading = false
    }
    
    private func sendInvites() {
        isSending = true
        
        Task {
            // TODO: Implement actual invite sending
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            dismiss()
        }
    }
}

// MARK: - Friend Invite Row

struct FriendInviteRow: View {
    let friend: FriendForInvite
    let isSelected: Bool
    let onTap: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                AvatarView(
                    displayName: friend.displayName,
                    avatarURL: friend.avatarURL,
                    size: 48
                )
                
                // Name
                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let username = friend.username {
                        Text("@\(username)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status indicator
                if friend.isAlreadyMember {
                    Text("In Challenge")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                } else {
                    ZStack {
                        Circle()
                            .stroke(isSelected ? primaryYellow : Color(.systemGray4), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Circle()
                                .fill(primaryYellow)
                                .frame(width: 16, height: 16)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(friend.isAlreadyMember)
        .opacity(friend.isAlreadyMember ? 0.6 : 1.0)
    }
}

// MARK: - Empty Friends View

struct EmptyFriendsView: View {
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 60))
                .foregroundColor(primaryYellow)
            
            Text("No Friends to Invite")
                .font(.system(size: 20, weight: .bold))
            
            Text("Add some friends first to invite them to challenges!")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

