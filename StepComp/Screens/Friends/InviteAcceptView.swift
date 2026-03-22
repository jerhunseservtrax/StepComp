//
//  InviteAcceptView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

@MainActor
final class InviteAcceptViewModel: ObservableObject {
    @Published var inviter: Profile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: FriendsService

    init(service: FriendsService) {
        self.service = service
    }

    func consume(token: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await service.consumeInviteRPC(token: token)
            inviter = Profile(
                id: result.inviterId,
                username: result.inviterUsername,
                displayName: result.inviterDisplayName,
                avatarUrl: result.inviterAvatarUrl,
                publicProfile: false
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct InviteAcceptView: View {
    let token: String
    @StateObject private var vm: InviteAcceptViewModel

    init(token: String, service: FriendsService) {
        self.token = token
        _vm = StateObject(wrappedValue: InviteAcceptViewModel(service: service))
    }

    var body: some View {
        VStack(spacing: 16) {
            if vm.isLoading {
                ProgressView("Loading invite…")
            } else if let inviter = vm.inviter {
                AvatarCircle(url: inviter.avatarUrl, fallback: String(inviter.username.prefix(1)).uppercased())
                Text("Friend request sent to")
                    .foregroundStyle(.secondary)
                Text(inviter.displayName ?? inviter.username)
                    .font(.title2).bold()
                Text("@\(inviter.username)")
                    .foregroundStyle(.secondary)
            } else {
                Text("Invalid invite")
                    .font(.title3)
                Text(vm.errorMessage ?? "This invite may be expired or already used.")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Friend Invite")
        .task { await vm.consume(token: token) }
    }
}

struct InviteTokenItem: Identifiable {
    let id = UUID()
    let token: String
}

