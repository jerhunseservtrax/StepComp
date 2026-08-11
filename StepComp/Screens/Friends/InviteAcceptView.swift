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
    @Published var didConsume = false
    @Published var errorMessage: String?

    private let service: FriendsService

    init(service: FriendsService) {
        self.service = service
    }

    /// Consumes the one-time invite token. Must only be called after explicit user confirmation.
    func confirmAndConsume(token: String) async {
        guard !didConsume, !isLoading else { return }
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
            didConsume = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct InviteAcceptView: View {
    let token: String
    @StateObject private var vm: InviteAcceptViewModel
    @Environment(\.dismiss) private var dismiss

    init(token: String, service: FriendsService) {
        self.token = token
        _vm = StateObject(wrappedValue: InviteAcceptViewModel(service: service))
    }

    var body: some View {
        VStack(spacing: 16) {
            if vm.isLoading {
                ProgressView("Sending friend request…")
            } else if let inviter = vm.inviter, vm.didConsume {
                AvatarCircle(url: inviter.avatarUrl, fallback: String(inviter.username.prefix(1)).uppercased())
                Text("Friend request sent to")
                    .foregroundStyle(.secondary)
                Text(inviter.displayName ?? inviter.username)
                    .font(.title2).bold()
                Text("@\(inviter.username)")
                    .foregroundStyle(.secondary)

                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
            } else {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)

                Text("Friend Invite")
                    .font(.title2).bold()

                Text("This will send a friend request using your currently signed-in account. Confirm only if this is the account you want to connect.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let errorMessage = vm.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button("Send Friend Request") {
                    Task { await vm.confirmAndConsume(token: token) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isLoading)

                Button("Not Now") { dismiss() }
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Friend Invite")
        // Intentionally no .task auto-consume: one-time tokens must not burn on appear.
    }
}

struct InviteTokenItem: Identifiable {
    let id = UUID()
    let token: String
}
