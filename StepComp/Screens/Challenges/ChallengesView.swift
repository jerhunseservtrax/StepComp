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
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
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
            
            // Tab Content
            Group {
                if selectedTab == .active {
                    ActiveChallengesTab(
                        sessionViewModel: sessionViewModel,
                        viewModel: viewModel
                    )
                    .transition(.opacity)
                } else {
                    DiscoverChallengesTab(
                        sessionViewModel: sessionViewModel,
                        viewModel: viewModel
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
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
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
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
                            .stroke(primaryYellow, lineWidth: 2)
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
                    Text(selectedTab == .active ? "Active" : "Discover")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text(selectedTab == .active ? "Your active challenges" : "Find your next battle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.620, green: 0.616, blue: 0.278))
                }
                
                Spacer()
                
                // Create Challenge button
                Button(action: onCreateChallenge) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(primaryYellow)
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
        .background(
            Color(.systemBackground)
                .opacity(0.95)
                .background(.ultraThinMaterial)
        )
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .black : .secondary)
                
                Rectangle()
                    .fill(isSelected ? primaryYellow : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

