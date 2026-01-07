//
//  InviteFriendsToChallengeView.swift
//  StepComp
//
//  Select friends to invite to a challenge
//

import SwiftUI
#if canImport(Supabase)
import Supabase
#endif

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
    @State private var successMessage: String?
    
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: StepCompColors.primary))
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
                            .background(selectedFriendIds.isEmpty ? Color.gray : StepCompColors.primary)
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
            .alert("Success", isPresented: .constant(successMessage != nil)) {
                Button("OK") {
                    successMessage = nil
                    dismiss()
                }
            } message: {
                if let success = successMessage {
                    Text(success)
                }
            }
        }
        .task {
            await loadFriends()
        }
    }
    
    private func loadFriends() async {
        // #region agent log
        let logData = "{\"location\":\"InviteFriendsToChallengeView.swift:110\",\"message\":\"Loading friends for challenge invite\",\"data\":{\"challengeId\":\"\(challengeId)\",\"currentUserId\":\"\(currentUserId)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"challenge-invite\",\"hypothesisId\":\"A\"}\n"
        if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") {
            fileHandle.seekToEndOfFile()
            if let data = logData.data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        }
        // #endregion
        
        isLoading = true
        
        #if canImport(Supabase)
        do {
            // #region agent log
            let logBeforeFriendships = "{\"location\":\"InviteFriendsToChallengeView.swift:115\",\"message\":\"Fetching friendships from database\",\"data\":{},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"challenge-invite\",\"hypothesisId\":\"B\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") {
                fileHandle.seekToEndOfFile()
                if let data = logBeforeFriendships.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            // #endregion
            
            // Get all accepted friendships
            struct FriendRequest: Codable {
                let requester_id: String
                let addressee_id: String
                let status: String
            }
            
            let requests: [FriendRequest] = try await supabase
                .from("friendships")
                .select()
                .or("requester_id.eq.\(currentUserId),addressee_id.eq.\(currentUserId)")
                .eq("status", value: "accepted")
                .execute()
                .value
            
            // #region agent log
            let logAfterFriendships = "{\"location\":\"InviteFriendsToChallengeView.swift:130\",\"message\":\"Friendships loaded\",\"data\":{\"count\":\(requests.count)},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"challenge-invite\",\"hypothesisId\":\"B\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") {
                fileHandle.seekToEndOfFile()
                if let data = logAfterFriendships.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            // #endregion
            
            // Get friend IDs
            var friendIds: [String] = []
            for request in requests {
                let friendId = request.requester_id == currentUserId 
                    ? request.addressee_id 
                    : request.requester_id
                friendIds.append(friendId)
            }
            
            if friendIds.isEmpty {
                friends = []
                isLoading = false
                return
            }
            
            // Get challenge members to check who's already in
            struct ChallengeMember: Codable {
                let user_id: String
            }
            
            let members: [ChallengeMember] = try await supabase
                .from("challenge_members")
                .select("user_id")
                .eq("challenge_id", value: challengeId)
                .execute()
                .value
            
            let memberIds = Set(members.map { $0.user_id })
            
            // #region agent log
            let logMembers = "{\"location\":\"InviteFriendsToChallengeView.swift:160\",\"message\":\"Challenge members loaded\",\"data\":{\"memberCount\":\(memberIds.count)},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"challenge-invite\",\"hypothesisId\":\"C\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") {
                fileHandle.seekToEndOfFile()
                if let data = logMembers.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            // #endregion
            
            // Load friend profiles
            struct FriendProfile: Codable {
                let id: String
                let display_name: String
                let username: String?
                let avatar_url: String?
            }
            
            let profiles: [FriendProfile] = try await supabase
                .from("profiles")
                .select("id,display_name,username,avatar_url")
                .in("id", values: friendIds)
                .execute()
                .value
            
            // #region agent log
            let logProfiles = "{\"location\":\"InviteFriendsToChallengeView.swift:180\",\"message\":\"Friend profiles loaded\",\"data\":{\"profileCount\":\(profiles.count)},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"challenge-invite\",\"hypothesisId\":\"D\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") {
                fileHandle.seekToEndOfFile()
                if let data = logProfiles.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            // #endregion
            
            // Map to FriendForInvite
            friends = profiles.map { profile in
                FriendForInvite(
                    id: profile.id,
                    displayName: profile.display_name,
                    username: profile.username,
                    avatarURL: profile.avatar_url,
                    isAlreadyMember: memberIds.contains(profile.id)
                )
            }
            
        } catch {
            // #region agent log
            let logError = "{\"location\":\"InviteFriendsToChallengeView.swift:200\",\"message\":\"Error loading friends\",\"data\":{\"error\":\"\(error.localizedDescription)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"challenge-invite\",\"hypothesisId\":\"E\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") {
                fileHandle.seekToEndOfFile()
                if let data = logError.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            // #endregion
            
            errorMessage = "Failed to load friends: \(error.localizedDescription)"
            friends = []
        }
        #else
        friends = []
        #endif
        
        isLoading = false
    }
    
    private func sendInvites() {
        Task<Void, Never> { @MainActor in
            self.isSending = true
            
            #if canImport(Supabase)
            do {
                // #region agent log
                let selectedCount = self.selectedFriendIds.count
                let challenge = self.challengeId
                let logStart = "{\"location\":\"InviteFriendsToChallengeView.swift:220\",\"message\":\"Sending challenge invites\",\"data\":{\"selectedCount\":\(selectedCount),\"challengeId\":\"\(challenge)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"challenge-invite\",\"hypothesisId\":\"F\"}\n"
                if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") {
                    fileHandle.seekToEndOfFile()
                    if let data = logStart.data(using: .utf8) {
                        fileHandle.write(data)
                    }
                    fileHandle.closeFile()
                }
                // #endregion
                
                // Convert Set to Array for RPC call
                let friendIdsArray = Array(self.selectedFriendIds)
                
                // #region agent log
                let logRPC = "{\"location\":\"InviteFriendsToChallengeView.swift:297\",\"message\":\"Calling send_challenge_invites RPC\",\"data\":{\"challengeId\":\"\(self.challengeId)\",\"friendIds\":\(friendIdsArray)},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"challenge-invite\",\"hypothesisId\":\"F,H1\"}\n"
                if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") {
                    fileHandle.seekToEndOfFile()
                    if let data = logRPC.data(using: .utf8) {
                        fileHandle.write(data)
                    }
                    fileHandle.closeFile()
                }
                // #endregion
                
                // Call the RPC function - it returns INTEGER directly
                let inviteCount: Int = try await supabase
                    .rpc("send_challenge_invites", params: [
                        "p_challenge_id": AnyJSON.string(self.challengeId),
                        "p_friend_ids": AnyJSON.array(friendIdsArray.map { AnyJSON.string($0) })
                    ] as [String: AnyJSON])
                    .execute()
                    .value
                
                // #region agent log
                let logSuccess = "{\"location\":\"InviteFriendsToChallengeView.swift:245\",\"message\":\"Invites sent successfully\",\"data\":{\"inviteCount\":\(inviteCount)},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"challenge-invite\",\"hypothesisId\":\"F\"}\n"
                if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") {
                    fileHandle.seekToEndOfFile()
                    if let data = logSuccess.data(using: .utf8) {
                        fileHandle.write(data)
                    }
                    fileHandle.closeFile()
                }
                // #endregion
                
                self.isSending = false
                self.successMessage = "Sent \(inviteCount) invite\(inviteCount == 1 ? "" : "s")!"
                
            } catch {
                // #region agent log
                let errorDesc = error.localizedDescription
                let logError = "{\"location\":\"InviteFriendsToChallengeView.swift:260\",\"message\":\"Error sending invites\",\"data\":{\"error\":\"\(errorDesc)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"challenge-invite\",\"hypothesisId\":\"G\"}\n"
                if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") {
                    fileHandle.seekToEndOfFile()
                    if let data = logError.data(using: .utf8) {
                        fileHandle.write(data)
                    }
                    fileHandle.closeFile()
                }
                // #endregion
                
                self.isSending = false
                self.errorMessage = "Failed to send invites: \(error.localizedDescription)"
            }
            #else
            self.isSending = false
            self.errorMessage = "Supabase not available"
            #endif
        }
    }
}

// MARK: - Friend Invite Row

struct FriendInviteRow: View {
    let friend: FriendForInvite
    let isSelected: Bool
    let onTap: () -> Void
    
    
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
                            .stroke(isSelected ? StepCompColors.primary : Color(.systemGray4), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Circle()
                                .fill(StepCompColors.primary)
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
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 60))
                .foregroundColor(StepCompColors.primary)
            
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

