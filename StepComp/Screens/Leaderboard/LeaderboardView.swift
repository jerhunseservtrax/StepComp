//
//  LeaderboardView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

struct LeaderboardView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    let challengeId: String
    @StateObject private var viewModel: LeaderboardViewModel
    @EnvironmentObject var challengeService: ChallengeService
    @Environment(\.dismiss) var dismiss
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    init(sessionViewModel: SessionViewModel, challengeId: String) {
        self.sessionViewModel = sessionViewModel
        self.challengeId = challengeId
        let userId = sessionViewModel.currentUser?.id ?? ""
        // Initialize with placeholder - will be updated in onAppear
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
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    LeaderboardHeader(onBack: { dismiss() })
                    
                    // Segmented Control
                    VStack(spacing: 16) {
                        AnimatedSegmentedControl(
                            selectedIndex: Binding(
                                get: { 
                                    switch viewModel.selectedScope {
                                    case .daily: return 0
                                    case .weekly: return 1 // Map weekly to Overall for now
                                    case .allTime: return 1
                                    }
                                },
                                set: { index in
                                    switch index {
                                    case 0: viewModel.updateScope(.daily)
                                    case 1: viewModel.updateScope(.allTime)
                                    default: break
                                    }
                                }
                            ),
                            options: ["Today", "Overall"]
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                        
                        // Loading State
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.vertical, 40)
                        } else if viewModel.entries.isEmpty {
                            // Empty State
                            VStack(spacing: 16) {
                                Image(systemName: "trophy")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                                Text("No entries yet")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 60)
                        } else {
                            // Podium Section (Top 3)
                            PodiumView(
                                entries: Array(viewModel.entries.prefix(3)),
                                currentUserId: sessionViewModel.currentUser?.id ?? ""
                            )
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                            
                            // List Section (Rank 4+)
                            if viewModel.entries.count > 3 {
                                VStack(spacing: 12) {
                                    ForEach(Array(viewModel.entries.dropFirst(3))) { entry in
                                        LeaderboardListItem(
                                            entry: entry,
                                            isCurrentUser: entry.userId == sessionViewModel.currentUser?.id ?? "",
                                            maxSteps: viewModel.entries.first?.steps ?? 1
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Spacer for sticky footer
                        Spacer()
                            .frame(height: 120)
                    }
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                viewModel.refresh()
            }
            
            // Sticky Footer
            if let currentUserEntry = viewModel.currentUserEntry {
                StickyUserFooter(
                    entry: currentUserEntry,
                    nextEntry: viewModel.entries.first { $0.rank == currentUserEntry.rank - 1 },
                    challengeService: challengeService
                )
            }
        }
        .onAppear {
            viewModel.updateService(challengeService)
        }
    }
}

// MARK: - Header

struct LeaderboardHeader: View {
    let onBack: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            
            Spacer()
            
            Text("Leaderboard")
                .font(.system(size: 20, weight: .bold))
                .tracking(-0.5)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Color(.systemBackground)
                .opacity(0.9)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5).opacity(0.2)),
            alignment: .bottom
        )
    }
}

// MARK: - Animated Segmented Control

struct AnimatedSegmentedControl: View {
    @Binding var selectedIndex: Int
    let options: [String]
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    private let subtleLight = Color(red: 0.914, green: 0.906, blue: 0.808)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 999)
                    .fill(subtleLight)
                    .frame(height: 40)
                
                // Animated indicator
                RoundedRectangle(cornerRadius: 999)
                    .fill(primaryYellow)
                    .frame(width: geometry.size.width / CGFloat(options.count), height: 32)
                    .padding(4)
                    .offset(x: CGFloat(selectedIndex) * (geometry.size.width / CGFloat(options.count)))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIndex)
                    .shadow(color: primaryYellow.opacity(0.3), radius: 2, x: 0, y: 1)
                
                // Buttons
                HStack(spacing: 0) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                        Button(action: {
                            withAnimation {
                                selectedIndex = index
                            }
                        }) {
                            Text(option)
                                .font(.system(size: 14, weight: selectedIndex == index ? .bold : .medium))
                                .foregroundColor(selectedIndex == index ? .black : Color(red: 0.620, green: 0.616, blue: 0.278))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .frame(height: 40)
    }
}

// MARK: - Podium View

struct PodiumView: View {
    let entries: [LeaderboardEntry]
    let currentUserId: String
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    private let bronzeColor = Color(red: 0.804, green: 0.498, blue: 0.196)
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            // Rank 2 (Left) - only show if we have at least 2 entries
            if entries.count >= 2 {
                PodiumPlace(
                    entry: entries[1],
                    rank: 2,
                    height: 96,
                    borderColor: .gray,
                    medal: "🥈"
                )
            } else {
                Spacer()
            }
            
            // Rank 1 (Center) - always show if we have entries
            if entries.count >= 1 {
                PodiumPlace(
                    entry: entries[0],
                    rank: 1,
                    height: 128,
                    borderColor: primaryYellow,
                    medal: "🥇",
                    isFirst: true
                )
            }
            
            // Rank 3 (Right) - only show if we have 3+ entries
            if entries.count >= 3 {
                PodiumPlace(
                    entry: entries[2],
                    rank: 3,
                    height: 80,
                    borderColor: bronzeColor,
                    medal: "🥉"
                )
            } else {
                Spacer()
            }
        }
    }
}

struct PodiumPlace: View {
    let entry: LeaderboardEntry
    let rank: Int
    let height: CGFloat
    let borderColor: Color
    let medal: String
    var isFirst: Bool = false
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    private let bronzeColor = Color(red: 0.804, green: 0.498, blue: 0.196)
    
    var body: some View {
        VStack(spacing: 12) {
            // Avatar with rank badge
            ZStack {
                if isFirst {
                    // Glow effect for first place
                    Circle()
                        .fill(primaryYellow.opacity(0.3))
                        .frame(width: 88, height: 88)
                        .blur(radius: 20)
                }
                
                AvatarView(
                    displayName: entry.displayName,
                    avatarURL: entry.avatarURL,
                    size: isFirst ? 80 : 64
                )
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 4)
                )
                .background(
                    Circle()
                        .fill(rank == 1 ? primaryYellow.opacity(0.2) : (rank == 3 ? Color.orange.opacity(0.1) : Color.gray.opacity(0.1)))
                )
                
                // Rank badge
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(rank == 1 ? "🥇 1st" : "\(medal) \(rank)")
                            .font(.system(size: rank == 1 ? 13 : 11, weight: .bold))
                            .foregroundColor(rank == 1 ? .black : .primary)
                            .padding(.horizontal, rank == 1 ? 12 : 8)
                            .padding(.vertical, rank == 1 ? 6 : 4)
                            .background(rank == 1 ? primaryYellow : Color(.systemBackground))
                            .cornerRadius(999)
                            .shadow(color: rank == 1 ? primaryYellow.opacity(0.5) : Color.clear, radius: 8, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 999)
                                    .stroke(rank == 1 ? Color.clear : Color(.systemGray5), lineWidth: 1)
                            )
                            .offset(y: rank == 1 ? 8 : 4)
                    }
                }
            }
            
            // Name and steps
            VStack(spacing: 4) {
                Text(entry.displayName)
                    .font(.system(size: isFirst ? 16 : 14, weight: .bold))
                    .lineLimit(1)
                    .frame(maxWidth: isFirst ? 96 : 80)
                    .foregroundColor(.primary)
                
                Text("\(entry.steps.formatted())")
                    .font(.system(size: isFirst ? 14 : 12, weight: isFirst ? .bold : .medium))
                    .foregroundColor(isFirst ? primaryYellow : Color(red: 0.620, green: 0.616, blue: 0.278))
            }
            .padding(.top, isFirst ? 4 : 0)
            
            // Podium base
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: rank == 1 ? 
                            [primaryYellow.opacity(0.4), primaryYellow.opacity(0.1)] :
                            rank == 3 ?
                            [bronzeColor.opacity(0.2), bronzeColor.opacity(0.05)] :
                            [Color(.systemGray5), Color(.systemGray6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: height)
                .opacity(rank == 1 ? 1.0 : 0.8)
        }
        .frame(maxWidth: .infinity)
        .offset(y: isFirst ? -24 : 0)
    }
}

// MARK: - List Item

struct LeaderboardListItem: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    let maxSteps: Int
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    private let subtleLight = Color(red: 0.914, green: 0.906, blue: 0.808)
    private let reactions = ["🔥", "👏", "😎", "💪"]
    
    var progress: Double {
        guard maxSteps > 0 else { return 0 }
        return min(Double(entry.steps) / Double(maxSteps), 1.0)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank number
            Text("\(entry.rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 0.620, green: 0.616, blue: 0.278))
                .frame(width: 20)
            
            // Avatar
            AvatarView(
                displayName: entry.displayName,
                avatarURL: entry.avatarURL,
                size: 40
            )
            
            // Name, steps, and progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(isCurrentUser ? "You" : entry.displayName)
                        .font(.system(size: 14, weight: isCurrentUser ? .bold : .medium))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(entry.steps.formatted())")
                        .font(.system(size: isCurrentUser ? 14 : 12, weight: isCurrentUser ? .bold : .medium))
                        .foregroundColor(isCurrentUser ? primaryYellow : Color(red: 0.620, green: 0.616, blue: 0.278))
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 999)
                            .fill(subtleLight)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 999)
                            .fill(isCurrentUser ? primaryYellow : Color(.systemGray4))
                            .frame(width: geometry.size.width * progress, height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            // Reaction button
            Button(action: {}) {
                Text(reactions[(entry.rank - 1) % reactions.count])
                    .font(.system(size: 18))
                    .frame(width: 32, height: 32)
                    .background(subtleLight.opacity(0.5))
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .background(
            Group {
                if isCurrentUser {
                    Color(.systemBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(primaryYellow.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: primaryYellow.opacity(0.3), radius: 12, x: 0, y: -4)
                } else {
                    Color(.systemBackground)
                }
            }
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrentUser ? primaryYellow.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Sticky User Footer

struct StickyUserFooter: View {
    let entry: LeaderboardEntry
    let nextEntry: LeaderboardEntry?
    let challengeService: ChallengeService
    @EnvironmentObject var healthKitService: HealthKitService
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    @State private var isSyncing = false
    
    var stepsToNext: Int {
        guard let next = nextEntry else { return 0 }
        return max(next.steps - entry.steps, 0)
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 16) {
                // Rank badge
                VStack(spacing: 2) {
                    Text("RANK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black.opacity(0.6))
                        .tracking(1)
                    
                    Text("\(entry.rank)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                }
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.3))
                .cornerRadius(20)
                
                // Message
                VStack(alignment: .leading, spacing: 2) {
                    Text("Keep going!")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    
                    if stepsToNext > 0 {
                        Text("\(stepsToNext.formatted()) steps to #\(entry.rank - 1)")
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.8))
                    } else {
                        Text("You're at the top!")
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Sync button
                Button(action: {
                    syncSteps()
                }) {
                    HStack(spacing: 4) {
                        if isSyncing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: primaryYellow))
                                .scaleEffect(0.8)
                        } else {
                            Text("Sync")
                                .font(.system(size: 14, weight: .bold))
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                        }
                    }
                    .foregroundColor(primaryYellow)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black)
                    .cornerRadius(999)
                }
                .disabled(isSyncing)
            }
            .padding(16)
            .background(
                primaryYellow
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    )
            )
            .cornerRadius(24)
            .shadow(color: primaryYellow.opacity(0.3), radius: 16, x: 0, y: 8)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
    
    private func syncSteps() {
        guard !isSyncing else { return }
        isSyncing = true
        
        Task {
            // Sync steps for all active challenges
            await challengeService.syncTodayStepsToAllChallenges(healthKitService: healthKitService)
            
            // Wait a bit for UI feedback
            try? await Task.sleep(nanoseconds: 500_000_000)
            isSyncing = false
        }
    }
}

