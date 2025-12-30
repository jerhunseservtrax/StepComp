//
//  FriendsView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

struct FriendsView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @StateObject private var viewModel: FriendsViewModel
    @EnvironmentObject var friendsService: FriendsService
    @EnvironmentObject var healthKitService: HealthKitService
    
    @State private var searchText: String = ""
    @State private var showingAddFriends = false
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    init(sessionViewModel: SessionViewModel) {
        self.sessionViewModel = sessionViewModel
        let userId = sessionViewModel.currentUser?.id ?? ""
        _viewModel = StateObject(
            wrappedValue: FriendsViewModel(
                friendsService: FriendsService(),
                healthKitService: HealthKitService(),
                currentUserId: userId
            )
        )
    }
    
    var filteredFriends: [User] {
        if searchText.isEmpty {
            return viewModel.friends
        }
        return viewModel.friends.filter { friend in
            friend.displayName.localizedCaseInsensitiveContains(searchText) ||
            friend.username.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    FriendsHeader(onAddFriends: {
                        showingAddFriends = true
                    })
                    
                    // Search Bar (if there are any friends)
                    if !viewModel.friends.isEmpty || !viewModel.incomingRequests.isEmpty || !viewModel.outgoingRequests.isEmpty {
                        SearchBar(text: $searchText)
                            .padding(.horizontal)
                            .padding(.top, 16)
                    }
                    
                    // Content
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if viewModel.friends.isEmpty && viewModel.incomingRequests.isEmpty && viewModel.outgoingRequests.isEmpty && searchText.isEmpty {
                        EmptyFriendsView(
                            hasSearchText: false,
                            onAddFriends: {
                                showingAddFriends = true
                            }
                        )
                        .padding(.top, 60)
                    } else {
                        VStack(spacing: 24) {
                            // Friends Section
                            if !filteredFriends.isEmpty {
                                FriendsSection(
                                    title: "Friends",
                                    friends: filteredFriends,
                                    viewModel: viewModel
                                )
                            }
                            
                            // Incoming Requests Section
                            if !viewModel.incomingRequests.isEmpty {
                                IncomingRequestsSection(
                                    requests: viewModel.incomingRequests,
                                    viewModel: viewModel
                                )
                            }
                            
                            // Outgoing Requests Section
                            if !viewModel.outgoingRequests.isEmpty {
                                OutgoingRequestsSection(
                                    requests: viewModel.outgoingRequests,
                                    viewModel: viewModel
                                )
                            }
                            
                            // No results for search
                            if searchText.isEmpty == false && filteredFriends.isEmpty && viewModel.incomingRequests.isEmpty && viewModel.outgoingRequests.isEmpty {
                                EmptyFriendsView(
                                    hasSearchText: true,
                                    onAddFriends: {
                                        showingAddFriends = true
                                    }
                                )
                                .padding(.top, 20)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                viewModel.refresh()
            }
        }
        .onAppear {
            viewModel.updateServices(friendsService: friendsService, healthKitService: healthKitService)
        }
        .sheet(isPresented: $showingAddFriends) {
            AddFriendsView(sessionViewModel: sessionViewModel)
        }
    }
}

// MARK: - Header

struct FriendsHeader: View {
    let onAddFriends: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Friends")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("See how your friends are doing today")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Add Friends Button
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
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 16))
            
            TextField("Search friends...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
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
    }
}

// MARK: - Friend Row

struct FriendRow: View {
    let friend: User
    let todaySteps: Int
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            AsyncImage(url: URL(string: friend.avatarURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                    Text(friend.displayName.prefix(1).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color(.systemBackground), lineWidth: 2)
            )
            
            // Friend Info
            VStack(alignment: .leading, spacing: 6) {
                Text(friend.displayName)
                    .font(.system(size: 18, weight: .semibold))
                
                HStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("\(todaySteps.formatted()) steps today")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Steps Badge
            VStack(spacing: 4) {
                Text("\(todaySteps.formatted())")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                
                Text("steps")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.black.opacity(0.6))
                    .textCase(.uppercase)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(primaryYellow)
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Empty State

struct EmptyFriendsView: View {
    let hasSearchText: Bool
    let onAddFriends: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: hasSearchText ? "magnifyingglass" : "person.2.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(hasSearchText ? "No friends found" : "No friends yet")
                    .font(.system(size: 20, weight: .bold))
                
                Text(hasSearchText ? "Try a different search term" : "Add friends to see their daily step progress")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if !hasSearchText {
                Button(action: onAddFriends) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Add Friends")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(primaryYellow)
                    .cornerRadius(24)
                }
            }
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Friends Section

struct FriendsSection: View {
    let title: String
    let friends: [User]
    let viewModel: FriendsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 4)
            
            LazyVStack(spacing: 12) {
                ForEach(friends) { friend in
                    FriendRow(
                        friend: friend,
                        todaySteps: viewModel.getTodaySteps(for: friend.id)
                    )
                }
            }
        }
    }
}

// MARK: - Incoming Requests Section

struct IncomingRequestsSection: View {
    let requests: [User]
    let viewModel: FriendsViewModel
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Requests")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 4)
            
            LazyVStack(spacing: 12) {
                ForEach(requests) { user in
                    FriendRequestRow(
                        user: user,
                        isIncoming: true,
                        onAccept: {
                            viewModel.acceptFriendRequest(from: user.id)
                        },
                        onDecline: {
                            viewModel.declineFriendRequest(from: user.id)
                        },
                        onCancel: nil
                    )
                }
            }
        }
    }
}

// MARK: - Outgoing Requests Section

struct OutgoingRequestsSection: View {
    let requests: [User]
    let viewModel: FriendsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 4)
            
            LazyVStack(spacing: 12) {
                ForEach(requests) { user in
                    FriendRequestRow(
                        user: user,
                        isIncoming: false,
                        onAccept: nil,
                        onDecline: nil,
                        onCancel: {
                            viewModel.cancelFriendRequest(to: user.id)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Friend Request Row

struct FriendRequestRow: View {
    let user: User
    let isIncoming: Bool
    let onAccept: (() -> Void)?
    let onDecline: (() -> Void)?
    let onCancel: (() -> Void)?
    
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
                
                if isIncoming {
                    Text("Wants to be friends")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                } else {
                    Text("Waiting")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Action Buttons
            if isIncoming {
                // Accept/Decline buttons
                HStack(spacing: 8) {
                    Button(action: {
                        onAccept?()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Accept")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(primaryYellow)
                        .cornerRadius(20)
                    }
                    
                    Button(action: {
                        onDecline?()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Decline")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    }
                }
            } else {
                // Cancel button for outgoing requests
                Button(action: {
                    onCancel?()
                }) {
                    Text("Cancel")
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

