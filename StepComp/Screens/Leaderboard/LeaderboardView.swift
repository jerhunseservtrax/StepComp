//
//  LeaderboardView.swift
//  FitComp
//
//  Modern leaderboard with podium design
//

import SwiftUI
import Combine

struct LeaderboardView: View {
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
                challengeService: ChallengeService.shared,
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
                    .accessibilityLabel("Back")
                    .accessibilityHint("Return to the previous screen.")
                    
                    Spacer()
                    
                    Text("Leaderboard")
                        .font(.system(size: 20, weight: .bold))
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                    }
                    .accessibilityLabel("More options")
                    .accessibilityHint("Additional leaderboard actions.")
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
                .padding(.bottom, 8)
                
                // Scrollable Content
                ScrollView {
                    VStack(spacing: 0) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: FitCompColors.primary))
                                .padding(.vertical, 60)
                        } else if viewModel.entries.isEmpty {
                            EmptyLeaderboardView()
                                .padding(.vertical, 60)
                        } else {
                            // Podium Section (Top 3)
                            PodiumView(
                                entries: Array(viewModel.visibleEntries.prefix(3)),
                                currentUserId: sessionViewModel.currentUser?.id ?? ""
                            )
                            .padding(.top, 32)
                            .padding(.bottom, 32)
                            .padding(.horizontal, 16)
                            
                            // List Section (Ranks 4+)
                            if viewModel.visibleEntries.count > 3 {
                                VStack(spacing: 12) {
                                    ForEach(Array(viewModel.visibleEntries.dropFirst(3))) { entry in
                                        LeaderboardListRow(
                                            entry: entry,
                                            isCurrentUser: entry.userId == sessionViewModel.currentUser?.id ?? ""
                                        )
                                    }
                                    if viewModel.canLoadMore {
                                        Button("Load more") {
                                            viewModel.loadMore()
                                        }
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(FitCompColors.textSecondary)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 100) // Space for sticky footer
                            }
                        }
                    }
                }
                .refreshable {
                    viewModel.refresh()
                }
            }
            
            // Sticky Footer (User Stats)
            if let currentUserEntry = viewModel.currentUserEntry {
                VStack {
                    Spacer()
                    UserStatsFooter(
                        entry: currentUserEntry,
                        scope: viewModel.selectedScope
                    )
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

// MARK: - Segmented Toggle

struct SegmentedToggle: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ToggleButton(title: "Today", isSelected: selectedTab == 0) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 0
                }
            }
            
            ToggleButton(title: "Since Start", isSelected: selectedTab == 1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 1
                }
            }
        }
        .frame(height: 48)
        .background(Color(.systemGray6))
        .cornerRadius(24)
        .padding(6)
    }
}

struct ToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? .black : Color(.systemGray))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isSelected ? FitCompColors.primary : Color.clear)
                .cornerRadius(24)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Podium View

struct PodiumView: View {
    let entries: [LeaderboardEntry]
    let currentUserId: String
    
    private let gradientEnd = Color(red: 0.902, green: 0.761, blue: 0.0)
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // #2 (Left)
            if entries.count >= 2 {
                PodiumCard(
                    entry: entries[1],
                    rank: 2,
                    isCurrentUser: entries[1].userId == currentUserId,
                    isWinner: false
                )
                .frame(maxWidth: .infinity)
            } else {
                Spacer()
            }
            
            // #1 (Center) - Winner with crown
            if entries.count >= 1 {
                PodiumCard(
                    entry: entries[0],
                    rank: 1,
                    isCurrentUser: entries[0].userId == currentUserId,
                    isWinner: true
                )
                .frame(maxWidth: .infinity)
                .scaleEffect(1.1)
                .zIndex(1)
            }
            
            // #3 (Right)
            if entries.count >= 3 {
                PodiumCard(
                    entry: entries[2],
                    rank: 3,
                    isCurrentUser: entries[2].userId == currentUserId,
                    isWinner: false
                )
                .frame(maxWidth: .infinity)
            } else {
                Spacer()
            }
        }
    }
}

struct PodiumCard: View {
    let entry: LeaderboardEntry
    let rank: Int
    let isCurrentUser: Bool
    let isWinner: Bool
    
    private let gradientEnd = Color(red: 0.902, green: 0.761, blue: 0.0)
    
    var body: some View {
        VStack(spacing: 0) {
            // Crown for winner
            if isWinner {
                Text("👑")
                    .font(.system(size: 40))
                    .offset(y: -20)
            }
            
            ZStack {
                // Background
                if isWinner {
                    LinearGradient(
                        colors: [FitCompColors.primary, gradientEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .shadow(color: FitCompColors.primary.opacity(0.3), radius: 15, x: 0, y: 0)
                } else {
                    Color(.systemBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 8)
                }
                
                VStack(spacing: 12) {
                    // Rank badge at top
                    Text("#\(rank)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isWinner ? .black : Color(.systemGray))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            isWinner ? Color.white : Color(.systemGray6)
                        )
                        .cornerRadius(12)
                        .offset(y: -12)
                    
                    // Avatar
                    AvatarView(
                        displayName: entry.displayName,
                        avatarURL: entry.avatarURL,
                        size: isWinner ? 80 : 60
                    )
                    .overlay(
                        Circle()
                            .stroke(isWinner ? Color.white.opacity(0.4) : Color(.systemGray5), lineWidth: isWinner ? 4 : 2)
                    )
                    
                    // Name
                    Text(formatName(entry.displayName))
                        .font(.system(size: isWinner ? 16 : 14, weight: .bold))
                        .foregroundColor(isWinner ? .black : .primary)
                        .lineLimit(1)
                    
                    // Steps
                    Text(formatSteps(entry.steps))
                        .font(.system(size: isWinner ? 14 : 12, weight: isWinner ? .bold : .semibold))
                        .foregroundColor(isWinner ? Color.black.opacity(0.7) : Color(.systemGray))
                }
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
            .aspectRatio(0.8, contentMode: .fit)
            .cornerRadius(16)
            
            // Rank badge at bottom for winner
            if isWinner {
                Text("#\(rank)")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .offset(y: -12)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(podiumAccessibilityLabel)
        .accessibilityValue(podiumAccessibilityValue)
    }
    
    private func formatName(_ name: String) -> String {
        let components = name.components(separatedBy: " ")
        if let firstName = components.first, let lastInitial = components.dropFirst().first?.first {
            return "\(firstName) \(lastInitial)."
        }
        return name
    }
    
    private func formatSteps(_ steps: Int) -> String {
        return steps.formatted()
    }
    
    private var podiumAccessibilityLabel: String {
        let place: String
        switch rank {
        case 1: place = "First place"
        case 2: place = "Second place"
        case 3: place = "Third place"
        default: place = "Rank \(rank)"
        }
        return "\(place), \(formatName(entry.displayName))"
    }
    
    private var podiumAccessibilityValue: String {
        var value = "\(formatSteps(entry.steps)) steps"
        if isCurrentUser {
            value += ", you"
        }
        if isWinner {
            value += ", leader"
        }
        return value
    }
}

// MARK: - List Row

struct LeaderboardListRow: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank number
            Text("\(entry.rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(.systemGray))
                .frame(width: 24, alignment: .center)
            
            // Avatar
            AvatarView(
                displayName: entry.displayName,
                avatarURL: entry.avatarURL,
                size: 40
            )
            .overlay(
                Circle()
                    .stroke(Color(.systemGray6), lineWidth: 1)
            )
            
            // Name and rank change
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Show rank change if available
                if let rankChange = entry.rankChange, rankChange != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: rankChange > 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(rankChange > 0 ? .green : .red)
                        
                        Text(rankChange > 0 ? "Up \(abs(rankChange)) place\(abs(rankChange) > 1 ? "s" : "")" : "Down \(abs(rankChange)) place\(abs(rankChange) > 1 ? "s" : "")")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Steps
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.steps.formatted())
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                
                Text("STEPS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemBackground), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.displayName), rank \(entry.rank)")
        .accessibilityValue("\(entry.steps.formatted()) steps")
    }
}

// MARK: - User Stats Footer

struct UserStatsFooter: View {
    let entry: LeaderboardEntry
    let scope: LeaderboardScope
    
    var stepsLabel: String {
        switch scope {
        case .daily:
            return "STEPS TODAY"
        case .weekly:
            return "STEPS THIS WEEK"
        case .allTime:
            return "TOTAL STEPS"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank box
            VStack(spacing: 2) {
                Text("Rank")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("\(entry.rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 40, height: 40)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            
            // User info
            VStack(alignment: .leading, spacing: 2) {
                Text("You")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Keep going! 🔥")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Steps
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.steps.formatted())
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(FitCompColors.primary)
                
                Text(stepsLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your leaderboard stats")
        .accessibilityValue("Rank \(entry.rank), \(entry.steps.formatted()) steps, \(stepsLabel)")
    }
}

// MARK: - Empty State

struct EmptyLeaderboardView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No entries yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}
