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
            friend.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    FriendsHeader()
                    
                    // Search Bar
                    if !viewModel.friends.isEmpty {
                        SearchBar(text: $searchText)
                            .padding(.horizontal)
                            .padding(.top, 16)
                    }
                    
                    // Friends List
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if filteredFriends.isEmpty {
                        EmptyFriendsView(hasSearchText: !searchText.isEmpty)
                            .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredFriends) { friend in
                                FriendRow(
                                    friend: friend,
                                    todaySteps: viewModel.getTodaySteps(for: friend.id)
                                )
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
    }
}

// MARK: - Header

struct FriendsHeader: View {
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
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasSearchText ? "magnifyingglass" : "person.2.fill")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text(hasSearchText ? "No friends found" : "No friends yet")
                .font(.system(size: 20, weight: .bold))
            
            Text(hasSearchText ? "Try a different search term" : "Add friends to see their daily step progress")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}

