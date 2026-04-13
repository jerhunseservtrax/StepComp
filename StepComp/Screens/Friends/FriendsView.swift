//
//  FriendsView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

struct FriendsView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @EnvironmentObject var friendsService: FriendsService
    @StateObject private var vm: FriendsViewModel
    @State private var discoverSearchTask: Task<Void, Never>?

    init(sessionViewModel: SessionViewModel) {
        self.sessionViewModel = sessionViewModel
        let myUserId = sessionViewModel.currentUser?.id ?? ""
        // Create temporary service for initialization, will be updated in onAppear
        _vm = StateObject(wrappedValue: FriendsViewModel(service: FriendsService(), myUserId: myUserId))
    }

    var body: some View {
        ZStack {
            // Background
            FitCompColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header matching ChallengesView
                FriendsHeader(
                    user: sessionViewModel.currentUser,
                    selectedTab: $vm.selectedTab,
                    searchText: $vm.discoverQuery
                )
                
                // TabView without swipe gesture to avoid conflict with swipe-to-delete
                TabView(selection: $vm.selectedTab) {
                    friendsTab
                        .tag(FriendsViewModel.Tab.friends)
                    
                    discoverTab
                        .tag(FriendsViewModel.Tab.discover)
                }
                .tabViewStyle(.page(indexDisplayMode: .never)) // Hide page indicator dots
            }
            
            // Profile card overlay
            if vm.selectedProfileUserId != nil {
                UserProfileCard(
                    userId: vm.selectedProfileUserId ?? "",
                    currentUserId: sessionViewModel.currentUser?.id ?? "",
                    isPresented: Binding(
                        get: { vm.selectedProfileUserId != nil },
                        set: { if !$0 { vm.selectedProfileUserId = nil } }
                    )
                )
                .transition(.opacity)
                .zIndex(1000)
            }
        }
        .navigationBarHidden(true)
        .task { await vm.load() }
        .onAppear {
            // Update ViewModel with the environment service
            let myUserId = sessionViewModel.currentUser?.id ?? ""
            vm.updateService(service: friendsService, myUserId: myUserId)
            // Refresh friends list when view appears to get latest usernames
            Task {
                try? await vm.refreshFriendships()
            }
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { _ in vm.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private var friendsTab: some View {
        List {
            // Pending Friend Requests Section
            if !vm.pendingRequests.isEmpty {
                Section {
                    ForEach(vm.pendingRequests) { item in
                        PendingRequestRow(item: item) {
                            Task { await vm.accept(friendshipId: item.id) }
                        } onDecline: {
                            Task { await vm.remove(friendshipId: item.id) }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await vm.remove(friendshipId: item.id) }
                            } label: {
                                Label("Decline", systemImage: "xmark.circle")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                Task { await vm.accept(friendshipId: item.id) }
                            } label: {
                                Label("Accept", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                    }
                } header: {
                    HStack {
                        Text("Pending Requests")
                        Spacer()
                        Text("\(vm.pendingRequests.count)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
            }
            
            Section {
                if vm.friendItems.isEmpty {
                    Text("No friends yet. Switch to Discover or share an invite link.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(vm.friendItems) { item in
                        FriendRow(item: item, isEditing: vm.isEditing) {
                            Task { await vm.remove(friendshipId: item.id) }
                        } onAccept: {
                            Task { await vm.accept(friendshipId: item.id) }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            vm.selectedProfileUserId = item.profile.id
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { await vm.remove(friendshipId: item.id) }
                            } label: {
                                Label("Remove", systemImage: "person.badge.minus")
                            }
                            .tint(.red)
                        }
                        .onAppear {
                            Task {
                                await vm.loadMoreFriendshipsIfNeeded(currentItemId: item.id)
                            }
                        }
                    }
                }
            } header: {
                Text("Your Friends")
            }

            Section {
                PrivateDiscoveryCard(onShareInvite: {
                    Task {
                        if let url = await vm.createInviteLink() {
                            share(url: url)
                        }
                    }
                })
            } header: {
                Text("Invite Link")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(FitCompColors.background)
        .environment(\.editMode, .constant(.inactive)) // Disable iPad edit mode toggle
    }

    private var discoverTab: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Recommended Profiles List
                ForEach(vm.discoverResults) { profile in
                    DiscoverProfileRow(
                        profile: profile,
                        friendshipStatus: vm.getFriendshipStatus(for: profile.id),
                        onAdd: {
                            Task { await vm.sendRequest(to: profile) }
                        },
                        onCancel: {
                            Task { await vm.cancelFriendRequest(to: profile.id) }
                        }
                    )
                    .padding(.horizontal, 24)
                    .onTapGesture {
                        vm.selectedProfileUserId = profile.id
                    }
                    .onAppear {
                        if profile.id == vm.discoverResults.last?.id {
                            Task {
                                await vm.loadMoreDiscover()
                            }
                        }
                    }
                }
                
                if vm.discoverResults.isEmpty && !vm.discoverQuery.isEmpty {
                    Text("No public profiles found.")
                        .foregroundColor(FitCompColors.textSecondary)
                        .padding(.top, 40)
                }
            }
            .padding(.bottom, 100) // Space for bottom navigation
        }
        .background(FitCompColors.background)
        .onChange(of: vm.discoverQuery) { _, _ in
            discoverSearchTask?.cancel()
            discoverSearchTask = Task {
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                try? await vm.refreshDiscover()
            }
        }
        .dismissKeyboardOnTap()
        .onDisappear {
            discoverSearchTask?.cancel()
        }
    }

    // MARK: - Sharing helper

    private func share(url: URL) {
        #if os(iOS)
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // Find the topmost presented view controller
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              var rootVC = window.rootViewController else {
            print("❌ Unable to find root view controller for sharing")
            return
        }
        
        // Traverse to find the topmost presented view controller
        while let presented = rootVC.presentedViewController {
            rootVC = presented
        }
        
        // For iPad, we need to set the popover source
        if let popover = av.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootVC.present(av, animated: true) {
            print("✅ Share sheet presented successfully")
        }
        #endif
    }
}

// MARK: - Friend Row

struct FriendRow: View {
    let item: FriendListItem
    let isEditing: Bool
    let onRemove: () -> Void
    let onAccept: () -> Void

    private var fullName: String {
        if let firstName = item.profile.firstName, let lastName = item.profile.lastName {
            return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        } else if let displayName = item.profile.displayName, !displayName.isEmpty {
            return displayName
        } else {
            return item.profile.username
        }
    }
    
    private var avatarFallback: String {
        String(item.profile.username.prefix(1)).uppercased()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Group {
                AvatarCircle(url: item.profile.avatarUrl, fallback: avatarFallback)

                VStack(alignment: .leading, spacing: 2) {
                    Text(fullName)
                        .font(.headline)
                        .foregroundColor(FitCompColors.textPrimary)
                    Text("@\(item.profile.username)")
                        .font(.subheadline)
                        .foregroundColor(FitCompColors.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(fullName), @\(item.profile.username)")
            .accessibilityHint("Double tap to open profile")

            Spacer()

            if item.isIncomingRequest {
                Button("Accept") { 
                    onAccept() 
                }
                .buttonStyle(.borderedProminent)
                .allowsHitTesting(true) // Ensure button is tappable but doesn't consume parent taps
                .accessibilityLabel("Accept friend request")
                .accessibilityHint("Adds this person to your friends")
            } else if item.isOutgoingRequest {
                Text("Requested")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Friend request pending")
                    .accessibilityValue("Awaiting their response")
            } else {
                Text("Friend")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Friend")
                    .accessibilityValue("Connected")
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Discover Profile Row

struct DiscoverProfileRow: View {
    let profile: Profile
    let friendshipStatus: DiscoverFriendshipStatus
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    // Check if this is a test account
    private var isTestAccount: Bool {
        // Test account IDs from CREATE_AUTH_TEST_ACCOUNTS.sql
        let testAccountIds: Set<String> = [
            "11111111-1111-1111-1111-111111111111",
            "22222222-2222-2222-2222-222222222222",
            "33333333-3333-3333-3333-333333333333",
            "44444444-4444-4444-4444-444444444444",
            "55555555-5555-5555-5555-555555555555"
        ]
        return testAccountIds.contains(profile.id)
    }

    private var avatarFallback: String {
        let firstChar = profile.username.first.map { String($0) } ?? "?"
        return firstChar.uppercased()
    }

    var body: some View {
        cardContent
            .padding(16)
            .background(FitCompColors.surface)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(FitCompColors.textSecondary.opacity(0.05), lineWidth: 0.5)
            )
    }
    
    private var cardContent: some View {
        HStack(spacing: 16) {
            Group {
                avatarSection
                nameSection
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(profile.displayName ?? profile.username), @\(profile.username)")
            .accessibilityHint("Double tap to open profile")
            Spacer()
            actionButton
        }
    }
    
    private var avatarSection: some View {
        AvatarCircle(url: profile.avatarUrl, fallback: avatarFallback)
            .frame(width: 56, height: 56)
    }
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(profile.displayName ?? profile.username)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(FitCompColors.textPrimary)
                .lineLimit(1)
            
            Text("@\(profile.username)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(FitCompColors.textSecondary)
                .lineLimit(1)
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        switch friendshipStatus {
        case .none:
            addButton
        case .pending:
            pendingButton
        case .accepted:
            friendButton
        }
    }
    
    private var addButton: some View {
        Button(action: onAdd) {
            Text("Add")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(FitCompColors.buttonTextOnPrimary)
                .frame(minWidth: 80)
                .frame(height: 40)
                .padding(.horizontal, 20)
                .background(FitCompColors.primary)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add friend")
        .accessibilityHint("Sends a friend request")
    }
    
    private var pendingButton: some View {
        Button(action: onCancel) {
            HStack(spacing: 4) {
                Text("Pending")
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(FitCompColors.textSecondary)
            .frame(minWidth: 80)
            .frame(height: 40)
            .padding(.horizontal, 20)
            .background(FitCompColors.surfaceElevated)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Cancel friend request")
        .accessibilityValue("Pending")
        .accessibilityHint("Withdraws your outgoing request")
    }
    
    private var friendButton: some View {
        Text("Friend")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(FitCompColors.textSecondary)
            .frame(minWidth: 80)
            .frame(height: 40)
            .padding(.horizontal, 20)
            .background(FitCompColors.surfaceElevated)
            .cornerRadius(20)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Already friends")
            .accessibilityValue("Connected")
    }
}

enum DiscoverFriendshipStatus {
    case none
    case pending
    case accepted
}

// MARK: - Private Discovery Card

struct PrivateDiscoveryCard: View {
    let onShareInvite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Keep your profile private")
                .font(.headline)

            Text("If your Public Profile toggle is OFF, people can only add you using your invite link.")
                .foregroundStyle(.secondary)

            Button(action: {
                onShareInvite()
            }) {
                Label("Share Friend Invite Link", systemImage: "link")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(FitCompColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(FitCompColors.primary)
                    .cornerRadius(10)
            }
            .accessibilityHint("Opens the share sheet with your personal invite link")
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Avatar Circle

struct AvatarCircle: View {
    let url: String?
    let fallback: String
    var size: CGFloat = 42
    
    /// Checks if the string is an emoji
    private var isEmoji: Bool {
        guard let url = url, !url.isEmpty else { return false }
        if url.hasPrefix("http") { return false }
        return url.unicodeScalars.allSatisfy { scalar in
            scalar.properties.isEmoji && scalar.properties.isEmojiPresentation ||
            scalar.properties.isEmoji && scalar.value > 0x238C
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(FitCompColors.surfaceElevated)
                .frame(width: size, height: size)

            if let url = url, !url.isEmpty {
                if isEmoji {
                    // Display emoji directly
                    Text(url)
                        .font(.system(size: size * 0.5))
                } else if let validURL = URL(string: url), url.hasPrefix("http") {
                    // Valid URL - load image
                    CachedAsyncImage(url: validURL) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Text(fallback)
                            .font(.system(size: size * 0.4, weight: .bold))
                            .foregroundColor(FitCompColors.textSecondary)
                    }
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                } else {
                    // Invalid URL - show fallback
                    Text(fallback)
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundColor(FitCompColors.textSecondary)
                }
            } else {
                // No URL - show fallback
                Text(fallback)
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(FitCompColors.textSecondary)
            }
        }
    }
}

// MARK: - Friends Header

struct FriendsHeader: View {
    let user: User?
    @Binding var selectedTab: FriendsViewModel.Tab
    @Binding var searchText: String
    
    var body: some View {
        VStack(spacing: 0) {
            // Top section with avatar and title
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedTab == .friends ? "Friends" : "Discover")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(FitCompColors.textPrimary)
                    
                    Text(selectedTab == .friends ? "Your circle" : "Find new friends")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(FitCompColors.textSecondary)
                }
                
                Spacer()
                
                // Avatar with online indicator on the right
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(
                        displayName: user?.displayName ?? "User",
                        avatarURL: user?.avatarURL,
                        size: 48
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    
                    // Online indicator
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 48)
            .padding(.bottom, 16)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(FitCompColors.textSecondary)
                    .font(.system(size: 20))
                
                TextField("Search profiles...", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(FitCompColors.textPrimary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(FitCompColors.surface)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(FitCompColors.textSecondary.opacity(0.1), lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Search profiles")
            .accessibilityValue(searchText.isEmpty ? "Empty" : searchText)
            .accessibilityHint("Type a name or username to find people")
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            
            // Segmented Control (Pill-shaped toggle)
            HStack(spacing: 4) {
                Button(action: {
                    withAnimation {
                        selectedTab = .friends
                    }
                }) {
                    Text("My Friends")
                        .font(.system(size: 14, weight: selectedTab == .friends ? .bold : .bold))
                        .foregroundColor(selectedTab == .friends ? FitCompColors.textPrimary : FitCompColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(selectedTab == .friends ? FitCompColors.surface : Color.clear)
                        .cornerRadius(24)
                        .shadow(color: selectedTab == .friends ? Color.black.opacity(0.05) : Color.clear, radius: 1, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(selectedTab == .friends ? Color.black.opacity(0.05) : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("My Friends")
                .accessibilityHint("Shows people you are friends with")
                .accessibilityAddTraits(selectedTab == .friends ? .isSelected : [])
                
                Button(action: {
                    withAnimation {
                        selectedTab = .discover
                    }
                }) {
                    Text("Discover")
                        .font(.system(size: 14, weight: selectedTab == .discover ? .bold : .bold))
                        .foregroundColor(selectedTab == .discover ? FitCompColors.textPrimary : FitCompColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(selectedTab == .discover ? FitCompColors.surface : Color.clear)
                        .cornerRadius(24)
                        .shadow(color: selectedTab == .discover ? Color.black.opacity(0.05) : Color.clear, radius: 1, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(selectedTab == .discover ? Color.black.opacity(0.05) : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Discover")
                .accessibilityHint("Search and add new friends")
                .accessibilityAddTraits(selectedTab == .discover ? .isSelected : [])
            }
            .padding(4)
            .background(Color.black.opacity(0.04))
            .cornerRadius(26)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(
            FitCompColors.surface.opacity(0.8)
                .background(.ultraThinMaterial)
        )
    }
}

struct FriendsTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .black : .secondary)
                
                Rectangle()
                    .fill(isSelected ? FitCompColors.primary : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

