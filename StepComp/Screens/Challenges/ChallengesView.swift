//
//  ChallengesView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

struct ChallengesView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @StateObject private var viewModel: ChallengesViewModel
    @EnvironmentObject var challengeService: ChallengeService
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab: ChallengeTab = .active
    @State private var showingCreateChallenge = false
    
    
    enum ChallengeTab {
        case active
        case discover
    }
    
    init(sessionViewModel: SessionViewModel) {
        self.sessionViewModel = sessionViewModel
        let userId = sessionViewModel.currentUser?.id ?? ""
        _viewModel = StateObject(
            wrappedValue: ChallengesViewModel(
                challengeService: ChallengeService(),
                userId: userId
            )
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ChallengesHeader(
                user: sessionViewModel.currentUser,
                selectedTab: $selectedTab,
                onCreateChallenge: {
                    showingCreateChallenge = true
                }
            )
            
            // TabView with swipe gesture between tabs
            TabView(selection: $selectedTab) {
                ActiveChallengesTab(
                    sessionViewModel: sessionViewModel,
                    viewModel: viewModel
                )
                .tag(ChallengeTab.active)
                
                DiscoverChallengesTab(
                    sessionViewModel: sessionViewModel,
                    viewModel: viewModel
                )
                .tag(ChallengeTab.discover)
            }
            .tabViewStyle(.page(indexDisplayMode: .never)) // Enable swipe, hide page dots
        }
        .background(StepCompColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCreateChallenge) {
            CreateChallengeView(sessionViewModel: sessionViewModel)
        }
        .onChange(of: showingCreateChallenge) { oldValue, newValue in
            // Refresh challenges when sheet is dismissed
            if oldValue == true && newValue == false {
                Task {
                    #if canImport(Supabase)
                    // Refresh challenge service first
                    await challengeService.refreshChallenges()
                    // Small delay to ensure database is updated
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    #endif
                    // Then reload challenges in view model
                    await viewModel.loadChallenges()
                }
            }
        }
        .onAppear {
            viewModel.updateService(challengeService)
            Task {
                await viewModel.loadChallenges()
            }
        }
        .onChange(of: challengeService.challenges.count) { oldValue, newValue in
            // Refresh when challenges change (e.g., after creating a new one)
            Task {
                await viewModel.loadChallenges()
            }
        }
    }
}

// MARK: - Header

struct ChallengesHeader: View {
    let user: User?
    @Binding var selectedTab: ChallengesView.ChallengeTab
    let onCreateChallenge: () -> Void
    
    
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
                        .fill(StepCompColors.primary)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(StepCompColors.background, lineWidth: 2)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedTab == .active ? "Active" : "Discover")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(StepCompColors.textPrimary)
                    
                    Text(selectedTab == .active ? "Your active challenges" : "Find your next battle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(StepCompColors.textSecondary)
                }
                
                Spacer()
                
                // Create Challenge button
                Button(action: onCreateChallenge) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(StepCompColors.primary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            // Tab Selector
            HStack(spacing: 0) {
                TabButton(
                    title: "Active",
                    isSelected: selectedTab == .active,
                    action: {
                        withAnimation {
                            selectedTab = .active
                        }
                    }
                )
                
                TabButton(
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
        .background(StepCompColors.background)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? StepCompColors.textPrimary : StepCompColors.textSecondary)
                
                Rectangle()
                    .fill(isSelected ? StepCompColors.primary : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

