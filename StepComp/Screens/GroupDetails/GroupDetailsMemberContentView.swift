//
//  GroupDetailsMemberContentView.swift
//  FitComp
//

import SwiftUI

struct GroupDetailsMemberContentView: View {
    @ObservedObject var viewModel: GroupViewModel
    @ObservedObject var sessionViewModel: SessionViewModel
    @Binding var selectedTab: GroupDetailTab
    let onDismiss: () -> Void
    let onInvite: () -> Void
    let onChat: () -> Void

    var body: some View {
        ZStack {
            FitCompColors.background.ignoresSafeArea()

            if let challenge = viewModel.challenge, isValidImageURL(challenge.imageUrl) {
                VStack(spacing: 0) {
                    ZStack {
                        AsyncImage(url: URL(string: challenge.imageUrl!)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Color.clear
                            case .empty:
                                Color.clear
                            @unknown default:
                                Color.clear
                            }
                        }
                        .clipped()

                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.4),
                                Color.black.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .frame(height: 120)
                    .ignoresSafeArea(edges: .top)

                    Spacer()
                }
            }

            ScrollView {
                VStack(spacing: 0) {
                    GroupDetailsHeader(
                        challengeName: viewModel.challenge?.name ?? "Challenge",
                        onBack: onDismiss,
                        onInvite: onInvite,
                        onChat: onChat
                    )

                    VStack(spacing: 24) {
                        if let challenge = viewModel.challenge {
                            ChallengeCountdownTimer(endDate: challenge.endDate)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }

                        SegmentedTabControl(selectedTab: $selectedTab)
                            .padding(.horizontal)

                        Group {
                            switch selectedTab {
                            case .leaderboard:
                                LeaderboardTabView(
                                    entries: viewModel.leaderboardEntries,
                                    dailyEntries: viewModel.dailyLeaderboardEntries,
                                    currentUserId: sessionViewModel.currentUser?.id ?? ""
                                )
                            case .members:
                                MembersTabView(
                                    members: viewModel.members,
                                    leaderboardEntries: viewModel.dailyLeaderboardEntries
                                )
                            case .settings:
                                SettingsTabView(
                                    viewModel: viewModel,
                                    challenge: viewModel.challenge,
                                    onDismiss: onDismiss
                                )
                            }
                        }
                        .padding(.horizontal)

                        Spacer()
                            .frame(height: 100)
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .navigationBarHidden(true)

            if let challenge = viewModel.challenge {
                let currentUserId = sessionViewModel.currentUser?.id ?? ""
                let isMember = challenge.participantIds.contains(currentUserId) || challenge.creatorId == currentUserId

                if isMember && selectedTab == .leaderboard {
                    if let userEntry = viewModel.leaderboardEntries.first(where: { $0.userId == currentUserId }) {
                        let todaySteps = viewModel.dailyLeaderboardEntries.first(where: { $0.userId == currentUserId })?.steps ?? 0
                        FloatingRankDisplay(
                            rank: userEntry.rank,
                            todaySteps: todaySteps
                        )
                    }
                }
            }
        }
    }
}
