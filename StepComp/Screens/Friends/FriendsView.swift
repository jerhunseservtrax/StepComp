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
    @EnvironmentObject var friendsService: FriendsService
    @StateObject private var vm: FriendsViewModel

    init(sessionViewModel: SessionViewModel) {
        self.sessionViewModel = sessionViewModel
        let myUserId = sessionViewModel.currentUser?.id ?? ""
        // Create temporary service for initialization, will be updated in onAppear
        _vm = StateObject(wrappedValue: FriendsViewModel(service: FriendsService(), myUserId: myUserId))
    }

    var body: some View {
        ZStack {
            // Background
            StepCompColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header matching ChallengesView
                FriendsHeader(
                    user: sessionViewModel.currentUser,
                    selectedTab: $vm.selectedTab,
                    isEditing: $vm.isEditing
                )
                
                // TabView without swipe gesture to avoid conflict with swipe-to-delete
                TabView(selection: $vm.selectedTab) {
                    friendsTab
                        .tag(FriendsViewModel.Tab.friends)
                    
                    discoverTab
                        .tag(FriendsViewModel.Tab.discover)
                }
                .tabViewStyle(.automatic) // Use automatic style - no page swipe, controlled by header buttons
                .onChange(of: vm.selectedTab) { oldValue, newValue in
                    // #region agent log
                    let logData = "{\"location\":\"FriendsView.swift:42\",\"message\":\"TabView selection changed\",\"data\":{\"oldTab\":\"\(oldValue)\",\"newTab\":\"\(newValue)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"post-fix\",\"hypothesisId\":\"FIX_APPLIED\"}\n"
                    if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") { fileHandle.seekToEndOfFile(); fileHandle.write(logData.data(using: .utf8)!); fileHandle.closeFile() }
                    // #endregion
                }
            }
            
            // Profile card overlay
            if vm.selectedProfileUserId != nil {
                // #region agent log
                let _ = {
                    let logData = "{\"location\":\"FriendsView.swift:51\",\"message\":\"Profile card should be visible\",\"data\":{\"userId\":\"\(vm.selectedProfileUserId ?? "nil")\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"profile-tap\",\"hypothesisId\":\"H3,H4\"}\n"
                    if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") { fileHandle.seekToEndOfFile(); fileHandle.write(logData.data(using: .utf8)!); fileHandle.closeFile() }
                }()
                // #endregion
                
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
                            // #region agent log
                            let logData = "{\"location\":\"FriendsView.swift:113\",\"message\":\"FriendRow onRemove tapped\",\"data\":{\"friendId\":\"\(item.id)\",\"username\":\"\(item.profile.username)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"swipe-debug\",\"hypothesisId\":\"C\"}\n"
                            if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") { fileHandle.seekToEndOfFile(); fileHandle.write(logData.data(using: .utf8)!); fileHandle.closeFile() }
                            // #endregion
                            Task { await vm.remove(friendshipId: item.id) }
                        } onAccept: {
                            Task { await vm.accept(friendshipId: item.id) }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // #region agent log
                            let logData = "{\"location\":\"FriendsView.swift:127\",\"message\":\"FriendRow tapped - showing profile\",\"data\":{\"userId\":\"\(item.profile.id)\",\"username\":\"\(item.profile.username)\",\"hasButtons\":\(item.isIncomingRequest || item.isOutgoingRequest)},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"profile-tap\",\"hypothesisId\":\"A,B\"}\n"
                            if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") { fileHandle.seekToEndOfFile(); fileHandle.write(logData.data(using: .utf8)!); fileHandle.closeFile() }
                            // #endregion
                            
                            // #region agent log
                            let logDataBeforeSet = "{\"location\":\"FriendsView.swift:135\",\"message\":\"About to set selectedProfileUserId\",\"data\":{\"currentValue\":\"\(vm.selectedProfileUserId ?? "nil")\",\"newValue\":\"\(item.profile.id)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"profile-tap\",\"hypothesisId\":\"A,H3\"}\n"
                            if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") { fileHandle.seekToEndOfFile(); fileHandle.write(logDataBeforeSet.data(using: .utf8)!); fileHandle.closeFile() }
                            // #endregion
                            
                            vm.selectedProfileUserId = item.profile.id
                            
                            // #region agent log
                            let logDataAfterSet = "{\"location\":\"FriendsView.swift:143\",\"message\":\"After setting selectedProfileUserId\",\"data\":{\"selectedValue\":\"\(vm.selectedProfileUserId ?? "nil")\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"profile-tap\",\"hypothesisId\":\"A,H3\"}\n"
                            if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") { fileHandle.seekToEndOfFile(); fileHandle.write(logDataAfterSet.data(using: .utf8)!); fileHandle.closeFile() }
                            // #endregion
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                // #region agent log
                                let logData = "{\"location\":\"FriendsView.swift:120\",\"message\":\"Swipe action Remove button tapped\",\"data\":{\"friendId\":\"\(item.id)\",\"username\":\"\(item.profile.username)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"swipe-debug\",\"hypothesisId\":\"A,C\"}\n"
                                if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") { fileHandle.seekToEndOfFile(); fileHandle.write(logData.data(using: .utf8)!); fileHandle.closeFile() }
                                // #endregion
                                Task { await vm.remove(friendshipId: item.id) }
                            } label: {
                                Label("Remove", systemImage: "person.badge.minus")
                            }
                            .tint(.red)
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
        .background(StepCompColors.background)
        .environment(\.editMode, .constant(.inactive)) // Disable iPad edit mode toggle
    }

    private var discoverTab: some View {
        VStack(spacing: 10) {
            TextField("Search profiles…", text: $vm.discoverQuery)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .onChange(of: vm.discoverQuery) { _, _ in
                    Task { 
                        try? await Task.sleep(nanoseconds: 350_000_000)
                        try? await vm.refreshDiscover() 
                    }
                }

            List {
                ForEach(vm.discoverResults) { profile in
                    DiscoverProfileRow(
                        profile: profile,
                        friendshipStatus: vm.getFriendshipStatus(for: profile.id)
                    ) {
                        Task { await vm.sendRequest(to: profile) }
                    }
                    .listRowBackground(StepCompColors.background)
                    .onTapGesture {
                        // #region agent log
                        let logData = "{\"location\":\"FriendsView.swift:183\",\"message\":\"DiscoverProfileRow tapped - showing profile\",\"data\":{\"userId\":\"\(profile.id)\",\"username\":\"\(profile.username)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"profile-tap\",\"hypothesisId\":\"B\"}\n"
                        if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") { fileHandle.seekToEndOfFile(); fileHandle.write(logData.data(using: .utf8)!); fileHandle.closeFile() }
                        // #endregion
                        vm.selectedProfileUserId = profile.id
                    }
                }

                if vm.discoverResults.isEmpty && !vm.discoverQuery.isEmpty {
                    Text("No public profiles found.")
                        .foregroundStyle(.secondary)
                        .listRowBackground(StepCompColors.background)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(StepCompColors.background)
        }
        .background(StepCompColors.background)
        .dismissKeyboardOnTap()
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

    var body: some View {
        HStack(spacing: 12) {
            AvatarCircle(url: item.profile.avatarUrl, fallback: String(item.profile.username.prefix(1)).uppercased())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.profile.username)
                    .font(.headline)
                Text("@\(item.profile.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if item.isIncomingRequest {
                Button("Accept") { 
                    // #region agent log
                    let logData = "{\"location\":\"FriendsView.swift:291\",\"message\":\"Accept button tapped in FriendRow\",\"data\":{\"userId\":\"\(item.profile.id)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"button-tap\",\"hypothesisId\":\"H2\"}\n"
                    if let fileHandle = FileHandle(forWritingAtPath: "/Users/jefferyerhunse/GitRepos/StepComp/.cursor/debug.log") { fileHandle.seekToEndOfFile(); fileHandle.write(logData.data(using: .utf8)!); fileHandle.closeFile() }
                    // #endregion
                    onAccept() 
                }
                .buttonStyle(.borderedProminent)
                .allowsHitTesting(true) // Ensure button is tappable but doesn't consume parent taps
            } else if item.isOutgoingRequest {
                Text("Requested")
                    .foregroundStyle(.secondary)
            } else {
                Text("Friend")
                    .foregroundStyle(.secondary)
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

    var body: some View {
        HStack(spacing: 12) {
            AvatarCircle(url: profile.avatarUrl, fallback: String(profile.username.prefix(1)).uppercased())

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName ?? profile.username)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("@\(profile.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: {
                onAdd()
            }) {
                Group {
                    switch friendshipStatus {
                    case .none:
                        Text("Add")
                            .foregroundColor(StepCompColors.buttonTextOnPrimary)
                            .font(.system(size: 15, weight: .bold))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(StepCompColors.coral)
                            .cornerRadius(20)
                    case .pending:
                        Text("Pending")
                            .foregroundColor(StepCompColors.textSecondary)
                            .font(.system(size: 15, weight: .medium))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(StepCompColors.surfaceElevated)
                            .cornerRadius(20)
                    case .accepted:
                        Text("Friend")
                            .foregroundColor(StepCompColors.textPrimary)
                            .font(.system(size: 15, weight: .semibold))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(StepCompColors.primary.opacity(0.2))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(StepCompColors.primary, lineWidth: 2)
                            )
                    }
                }
            }
            .disabled(friendshipStatus == .accepted || friendshipStatus == .pending)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            // Make entire row clickable to add friend
            if friendshipStatus == .none {
                onAdd()
            }
        }
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
                    .foregroundColor(StepCompColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(StepCompColors.primary)
                    .cornerRadius(10)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Avatar Circle

struct AvatarCircle: View {
    let url: String?
    let fallback: String
    
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
            Circle().fill(.thinMaterial)
                .frame(width: 42, height: 42)

            if let url = url, !url.isEmpty {
                if isEmoji {
                    // Display emoji directly
                    Text(url)
                        .font(.system(size: 24))
                } else if let validURL = URL(string: url), url.hasPrefix("http") {
                    // Valid URL - load image
                    AsyncImage(url: validURL) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Text(fallback).font(.headline)
                    }
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                } else {
                    // Invalid URL - show fallback
                    Text(fallback).font(.headline)
                }
            } else {
                // No URL - show fallback
                Text(fallback).font(.headline)
            }
        }
    }
}

// MARK: - Friends Header

struct FriendsHeader: View {
    let user: User?
    @Binding var selectedTab: FriendsViewModel.Tab
    @Binding var isEditing: Bool  // Keep for compatibility, but won't be used
    
    var body: some View {
        VStack(spacing: 0) {
            // Top section with avatar and title
            HStack(spacing: 16) {
                // Avatar with online indicator
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(
                        displayName: user?.displayName ?? "User",
                        avatarURL: user?.avatarURL,
                        size: 48
                    )
                    .overlay(
                        Circle()
                            .stroke(StepCompColors.primary, lineWidth: 2)
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
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedTab == .friends ? "Friends" : "Discover")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text(selectedTab == .friends ? "Your circle" : "Find new friends")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.620, green: 0.616, blue: 0.278))
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            // Tab Selector
            HStack(spacing: 0) {
                FriendsTabButton(
                    title: "Friends",
                    isSelected: selectedTab == .friends,
                    action: {
                        withAnimation {
                            selectedTab = .friends
                        }
                    }
                )
                
                FriendsTabButton(
                    title: "Discover",
                    isSelected: selectedTab == .discover,
                    action: {
                        withAnimation {
                            selectedTab = .discover
                        }
                    }
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .background(StepCompColors.surface)
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
                    .fill(isSelected ? StepCompColors.primary : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

