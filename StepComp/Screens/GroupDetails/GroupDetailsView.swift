//
//  GroupDetailsView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

struct GroupDetailsView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    let challengeId: String
    @StateObject private var viewModel: GroupViewModel
    @EnvironmentObject var challengeService: ChallengeService
    @Environment(\.dismiss) var dismiss

    @State private var selectedTab: GroupDetailTab = .leaderboard
    @State private var showingChat = false
    @State private var showingInvite = false
    @State private var showingJoinSuccess = false

    init(sessionViewModel: SessionViewModel, challengeId: String) {
        self.sessionViewModel = sessionViewModel
        self.challengeId = challengeId
        let userId = sessionViewModel.currentUser?.id ?? ""
        _viewModel = StateObject(
            wrappedValue: GroupViewModel(
                challengeService: ChallengeService.shared,
                challengeId: challengeId,
                currentUserId: userId
            )
        )
    }

    var body: some View {
        let currentUserId = sessionViewModel.currentUser?.id ?? ""
        let isMember = viewModel.challenge?.participantIds.contains(currentUserId) ?? false ||
            viewModel.challenge?.creatorId == currentUserId

        return ZStack {
            if viewModel.challenge == nil && viewModel.isLoading {
                FitCompColors.background.ignoresSafeArea()
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading challenge...")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)
                }
            } else if !isMember {
                ChallengePreviewView(
                    challenge: viewModel.challenge,
                    highestSteps: viewModel.leaderboardEntries.first?.steps ?? 0,
                    onBack: { dismiss() },
                    onJoin: {
                        Task { @MainActor in
                            await viewModel.joinCurrentChallenge()
                            if viewModel.errorMessage.isEmpty {
                                showingJoinSuccess = true
                                await viewModel.refresh()
                                try? await Task.sleep(nanoseconds: 100_000_000)
                            }
                        }
                    },
                    isLoading: viewModel.isLoading,
                    errorMessage: viewModel.errorMessage
                )
            } else {
                GroupDetailsMemberContentView(
                    viewModel: viewModel,
                    sessionViewModel: sessionViewModel,
                    selectedTab: $selectedTab,
                    onDismiss: { dismiss() },
                    onInvite: { showingInvite = true },
                    onChat: { showingChat = true }
                )
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingChat) {
            NavigationStack {
                ChallengeChatView(
                    challengeId: challengeId,
                    currentUserId: sessionViewModel.currentUser?.id ?? "",
                    challengeName: viewModel.challenge?.name ?? "Challenge"
                )
            }
        }
        .sheet(isPresented: $showingInvite) {
            InviteFriendsToChallengeView(
                challengeId: challengeId,
                challengeName: viewModel.challenge?.name ?? "Challenge",
                currentUserId: sessionViewModel.currentUser?.id ?? ""
            )
        }
        .onAppear {
            viewModel.updateService(challengeService)
            viewModel.resumeAutoRefresh()
        }
        .onDisappear {
            viewModel.pauseAutoRefresh()
        }
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await viewModel.refresh()
            }
        }
        #endif
        .alert("Success! 🎉", isPresented: $showingJoinSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You successfully joined this challenge!")
        }
    }
}
