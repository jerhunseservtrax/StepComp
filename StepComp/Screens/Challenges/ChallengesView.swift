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
    
    @State private var selectedTab: ChallengeTab = .private
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    enum ChallengeTab {
        case `private`
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
                selectedTab: $selectedTab
            )
            
            // Tab Content
            Group {
                if selectedTab == .private {
                    PrivateChallengesTab(
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
        .onAppear {
            viewModel.updateService(challengeService)
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
                    Text(selectedTab == .private ? "Private" : "Discover")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text(selectedTab == .private ? "Your active challenges" : "Find your next battle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.620, green: 0.616, blue: 0.278))
                }
                
                Spacer()
                
                // Filter button
                Button(action: {}) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            // Tab Selector
            HStack(spacing: 0) {
                TabButton(
                    title: "Private",
                    isSelected: selectedTab == .private,
                    action: {
                        withAnimation {
                            selectedTab = .private
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

