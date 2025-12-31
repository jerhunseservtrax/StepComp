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
        NavigationStack {
            VStack(spacing: 12) {
                // Tabs
                Picker("", selection: $vm.selectedTab) {
                    Text("Friends").tag(FriendsViewModel.Tab.friends)
                    Text("Discover").tag(FriendsViewModel.Tab.discover)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch vm.selectedTab {
                case .friends:
                    friendsTab
                case .discover:
                    discoverTab
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(vm.isEditing ? "Done" : "Edit") {
                        vm.isEditing.toggle()
                    }
                }
            }
            .task { await vm.load() }
            .onAppear {
                // Update ViewModel with the environment service
                let myUserId = sessionViewModel.currentUser?.id ?? ""
                vm.updateService(service: friendsService, myUserId: myUserId)
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
    }

    private var friendsTab: some View {
        List {
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
                }

                if vm.discoverResults.isEmpty && !vm.discoverQuery.isEmpty {
                    Text("No public profiles found.")
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.plain)
        }
        .dismissKeyboardOnTap()
    }

    // MARK: - Sharing helper

    private func share(url: URL) {
        #if os(iOS)
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
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
                Text(item.profile.displayName ?? item.profile.username)
                    .font(.headline)
                Text("@\(item.profile.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if item.isIncomingRequest {
                Button("Accept") { onAccept() }
                    .buttonStyle(.borderedProminent)
            } else if item.isOutgoingRequest {
                Text("Requested")
                    .foregroundStyle(.secondary)
            } else {
                Text("Friend")
                    .foregroundStyle(.secondary)
            }

            if isEditing, item.status == .accepted {
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Image(systemName: "minus.circle.fill")
                }
                .buttonStyle(.plain)
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
                            .foregroundColor(.black)
                            .font(.system(size: 15, weight: .medium))
                    case .pending:
                        Text("Pending")
                            .foregroundColor(.secondary)
                            .font(.system(size: 15, weight: .medium))
                    case .accepted:
                        Text("Friend")
                            .foregroundColor(.secondary)
                            .font(.system(size: 15, weight: .medium))
                    }
                }
            }
            .buttonStyle(.bordered)
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

            Button {
                onShareInvite()
            } label: {
                Label("Share Friend Invite Link", systemImage: "link")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Avatar Circle

struct AvatarCircle: View {
    let url: String?
    let fallback: String

    var body: some View {
        ZStack {
            Circle().fill(.thinMaterial)
                .frame(width: 42, height: 42)

            if let url, let u = URL(string: url) {
                AsyncImage(url: u) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Text(fallback).font(.headline)
                }
                .frame(width: 42, height: 42)
                .clipShape(Circle())
            } else {
                Text(fallback).font(.headline)
            }
        }
    }
}
