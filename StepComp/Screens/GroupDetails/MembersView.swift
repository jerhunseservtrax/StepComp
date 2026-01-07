//
//  MembersView.swift
//  StepComp
//
//  Challenge members list view (no podium, just clean list)
//

import SwiftUI

struct MembersView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    let challengeId: String
    @StateObject private var viewModel: LeaderboardViewModel
    @EnvironmentObject var challengeService: ChallengeService
    @Environment(\.dismiss) var dismiss
    
    private let backgroundLight = Color(red: 0.973, green: 0.973, blue: 0.961)
    
    init(sessionViewModel: SessionViewModel, challengeId: String) {
        self.sessionViewModel = sessionViewModel
        self.challengeId = challengeId
        let userId = sessionViewModel.currentUser?.id ?? ""
        _viewModel = StateObject(
            wrappedValue: LeaderboardViewModel(
                challengeService: ChallengeService(),
                challengeId: challengeId,
                userId: userId
            )
        )
    }
    
    var body: some View {
        ZStack {
            backgroundLight
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top App Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                    }
                    
                    Spacer()
                    
                    Text("Members")
                        .font(.system(size: 20, weight: .bold))
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                // Segmented Toggle
                SegmentedToggle(
                    selectedTab: Binding(
                        get: { viewModel.selectedScope == .daily ? 0 : 1 },
                        set: { index in
                            viewModel.updateScope(index == 0 ? .daily : .allTime)
                        }
                    )
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                // Scrollable Content - NO PODIUM, just list
                ScrollView {
                    VStack(spacing: 12) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: StepCompColors.primary))
                                .padding(.vertical, 60)
                        } else if viewModel.entries.isEmpty {
                            EmptyMembersView()
                                .padding(.vertical, 60)
                        } else {
                            // All members in list format (including top 3)
                            ForEach(viewModel.entries) { entry in
                                LeaderboardListRow(
                                    entry: entry,
                                    isCurrentUser: entry.userId == sessionViewModel.currentUser?.id ?? ""
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100) // Space for sticky footer
                }
                .refreshable {
                    viewModel.refresh()
                }
            }
            
            // Sticky Footer (User Stats)
            if let currentUserEntry = viewModel.currentUserEntry {
                VStack {
                    Spacer()
                    UserStatsFooter(entry: currentUserEntry)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.updateService(challengeService)
        }
    }
}

// MARK: - Empty State

struct EmptyMembersView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No members yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

