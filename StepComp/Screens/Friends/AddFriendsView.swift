//
//  AddFriendsView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine
#if canImport(Supabase)
import Supabase
#endif

struct AddFriendsView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AddFriendsViewModel
    
    @State private var searchText: String = ""
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    init(sessionViewModel: SessionViewModel) {
        self.sessionViewModel = sessionViewModel
        let userId = sessionViewModel.currentUser?.id ?? ""
        _viewModel = StateObject(
            wrappedValue: AddFriendsViewModel(
                currentUserId: userId
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    
                    TextField("Search by username...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { oldValue, newValue in
                            if !newValue.isEmpty {
                                viewModel.searchUsers(query: newValue)
                            } else {
                                viewModel.clearSearch()
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: { 
                            searchText = ""
                            viewModel.clearSearch()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Search Results
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .padding()
                } else if searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Search for friends by username")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else if viewModel.searchResults.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No users found")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Try a different username")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.searchResults) { user in
                                SearchResultRow(
                                    user: user,
                                    friendStatus: viewModel.getFriendStatus(for: user.id),
                                    onAddFriend: {
                                        viewModel.sendFriendRequest(to: user.id)
                                    },
                                    onCancelRequest: {
                                        viewModel.cancelFriendRequest(to: user.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationTitle("Add Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .dismissKeyboardOnTap()
    }
}

// MARK: - Friend Status

enum FriendStatus {
    case notFriends
    case pending
    case accepted
    case currentUser
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let user: User
    let friendStatus: FriendStatus
    let onAddFriend: () -> Void
    let onCancelRequest: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            AvatarView(
                displayName: user.displayName,
                avatarURL: user.avatarURL,
                size: 56
            )
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.system(size: 18, weight: .semibold))
                
                Text("@\(user.username)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action Button
            Group {
                switch friendStatus {
                case .notFriends:
                    Button(action: onAddFriend) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Add")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(primaryYellow)
                        .cornerRadius(20)
                    }
                case .pending:
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text("Request Sent")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .overlay(
                        // Make the entire area tappable to cancel
                        Button(action: onCancelRequest) {
                            Color.clear
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    )
                case .accepted:
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        Text("Friends")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                case .currentUser:
                    Text("You")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - ViewModel

@MainActor
final class AddFriendsViewModel: ObservableObject {
    @Published var searchResults: [User] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var friendRequests: [String: FriendRequestStatus] = [:] // userId: status
    
    private let currentUserId: String
    
    enum FriendRequestStatus {
        case pending
        case accepted
    }
    
    init(currentUserId: String) {
        self.currentUserId = currentUserId
        loadFriendRequests()
    }
    
    func searchUsers(query: String) {
        guard !query.isEmpty else {
            clearSearch()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            #if canImport(Supabase)
            do {
                // Search profiles by username (primary search method)
                // Using ilike for case-insensitive pattern matching
                // Select all fields needed for UserProfile
                let profiles: [UserProfile] = try await supabase
                    .from("profiles")
                    .select()
                    .ilike("username", pattern: "%\(query)%")
                    .limit(20)
                    .execute()
                    .value
                
                // Convert to User model
                let users = profiles.compactMap { profile -> User? in
                    // Skip current user
                    guard profile.id != currentUserId else { return nil }
                    
                    return User(
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
                
                searchResults = users
                isLoading = false
            } catch {
                print("⚠️ Error searching users: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                searchResults = []
                isLoading = false
            }
            #else
            // Mock implementation
            searchResults = []
            isLoading = false
            #endif
        }
    }
    
    func clearSearch() {
        searchResults = []
        isLoading = false
        errorMessage = nil
    }
    
    func loadFriendRequests() {
        Task {
            #if canImport(Supabase)
            do {
                // Load friend requests where current user is requester
                struct FriendRequest: Codable {
                    let requester_id: String
                    let addressee_id: String
                    let status: String
                }
                
                let requests: [FriendRequest] = try await supabase
                    .from("friendships")
                    .select()
                    .eq("requester_id", value: currentUserId)
                    .execute()
                    .value
                
                // Store request statuses
                for request in requests {
                    if request.status == "pending" {
                        friendRequests[request.addressee_id] = .pending
                    } else if request.status == "accepted" {
                        friendRequests[request.addressee_id] = .accepted
                    }
                }
                
                // Also load requests where current user is addressee (accepted friendships)
                let received: [FriendRequest] = try await supabase
                    .from("friendships")
                    .select()
                    .eq("addressee_id", value: currentUserId)
                    .eq("status", value: "accepted")
                    .execute()
                    .value
                
                for request in received {
                    friendRequests[request.requester_id] = .accepted
                }
            } catch {
                print("⚠️ Error loading friend requests: \(error.localizedDescription)")
            }
            #endif
        }
    }
    
    func getFriendStatus(for userId: String) -> FriendStatus {
        if userId == currentUserId {
            return .currentUser
        }
        
        if let status = friendRequests[userId] {
            switch status {
            case .pending:
                return .pending
            case .accepted:
                return .accepted
            }
        }
        
        return .notFriends
    }
    
    func sendFriendRequest(to userId: String) {
        // Update local state immediately for instant UI feedback
        // Button will change from "Add" to "Request Sent" right away
        friendRequests[userId] = .pending
        
        Task {
            #if canImport(Supabase)
            do {
                // Insert friend request into friends table
                // INSERT INTO friends (requester_id, addressee_id, status)
                // VALUES (auth.uid(), :target_user_id, 'pending')
                struct FriendRequest: Codable {
                    let requester_id: String
                    let addressee_id: String
                    let status: String
                }
                
                let request = FriendRequest(
                    requester_id: currentUserId,
                    addressee_id: userId,
                    status: "pending"
                )
                
                try await supabase
                    .from("friendships")
                    .insert(request)
                    .execute()
                
                print("✅ Friend request sent to \(userId)")
            } catch {
                print("⚠️ Error sending friend request: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                // Revert local state on error so user can try again
                friendRequests.removeValue(forKey: userId)
            }
            #endif
        }
    }
    
    func cancelFriendRequest(to userId: String) {
        Task {
            #if canImport(Supabase)
            do {
                try await supabase
                    .from("friendships")
                    .delete()
                    .eq("requester_id", value: currentUserId)
                    .eq("addressee_id", value: userId)
                    .execute()
                
                // Update local state
                friendRequests.removeValue(forKey: userId)
                
                print("✅ Friend request cancelled")
            } catch {
                print("⚠️ Error cancelling friend request: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
            #endif
        }
    }
}

