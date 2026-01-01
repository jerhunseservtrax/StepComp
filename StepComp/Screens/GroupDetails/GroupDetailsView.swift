//
//  GroupDetailsView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

struct GroupDetailsView: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    let challengeId: String
    @StateObject private var viewModel: GroupViewModel
    @EnvironmentObject var challengeService: ChallengeService
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTab: GroupDetailTab = .leaderboard
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    init(sessionViewModel: SessionViewModel, challengeId: String) {
        self.sessionViewModel = sessionViewModel
        self.challengeId = challengeId
        let userId = sessionViewModel.currentUser?.id ?? ""
        _viewModel = StateObject(
            wrappedValue: GroupViewModel(
                challengeService: ChallengeService(),
                challengeId: challengeId,
                currentUserId: userId
            )
        )
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Top Navigation
                    GroupDetailsHeader(
                        challengeName: viewModel.challenge?.name ?? "Challenge",
                        onBack: { dismiss() },
                        onInvite: {}
                    )
                    
                    // Main Content
                    VStack(spacing: 24) {
                        // Hero Status Section
                        if let challenge = viewModel.challenge {
                            HeroStatusSection(challenge: challenge)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                        
                        // Dashboard Card
                        if let challenge = viewModel.challenge {
                            DashboardCard(
                                challenge: challenge,
                                leaderboardEntries: viewModel.leaderboardEntries,
                                currentUserId: sessionViewModel.currentUser?.id ?? "",
                                currentUserName: sessionViewModel.currentUser?.displayName ?? "You"
                            )
                            .padding(.horizontal)
                        }
                        
                        // Segmented Control Tabs
                        SegmentedTabControl(selectedTab: $selectedTab)
                            .padding(.horizontal)
                        
                        // Content based on selected tab
                        Group {
                            switch selectedTab {
                            case .leaderboard:
                                LeaderboardTabView(
                                    entries: viewModel.leaderboardEntries,
                                    currentUserId: sessionViewModel.currentUser?.id ?? ""
                                )
                            case .members:
                                MembersTabView(members: viewModel.members)
                            case .settings:
                                SettingsTabView(
                                    viewModel: viewModel,
                                    challenge: viewModel.challenge
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Spacer for bottom button
                        Spacer()
                            .frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            
            // Fixed Bottom Action
            GroupChatButton()
        }
        .onAppear {
            // Update ViewModel with the actual environment object
            viewModel.updateService(challengeService)
            viewModel.updateService(challengeService)
        }
    }
}

enum GroupDetailTab: String, CaseIterable {
    case leaderboard
    case members
    case settings
    
    var displayName: String {
        switch self {
        case .leaderboard: return "Leaderboard"
        case .members: return "Members"
        case .settings: return "Settings"
        }
    }
}

// MARK: - Header

struct GroupDetailsHeader: View {
    let challengeName: String
    let onBack: () -> Void
    let onInvite: () -> Void
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemBackground))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            
            Spacer()
            
            Text(challengeName)
                .font(.system(size: 18, weight: .bold))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            Button(action: onInvite) {
                HStack(spacing: 4) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 16))
                    Text("Invite")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(primaryYellow)
                .cornerRadius(999)
                .shadow(color: primaryYellow.opacity(0.4), radius: 8, x: 0, y: 2)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(
            Color(.systemBackground)
                .opacity(0.9)
                .background(.ultraThinMaterial)
        )
    }
}

// MARK: - Hero Status Section

struct HeroStatusSection: View {
    let challenge: Challenge
    
    var daysElapsed: Int {
        let calendar = Calendar.current
        let now = Date()
        guard now >= challenge.startDate else { return 0 }
        let components = calendar.dateComponents([.day], from: challenge.startDate, to: now)
        return (components.day ?? 0) + 1
    }
    
    var totalDays: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: challenge.startDate, to: challenge.endDate)
        return (components.day ?? 0) + 1
    }
    
    var challengeProgress: Double {
        guard totalDays > 0 else { return 0 }
        return min(Double(daysElapsed) / Double(totalDays), 1.0)
    }
    
    var hoursRemaining: Int {
        let calendar = Calendar.current
        let now = Date()
        let endOfDay = calendar.startOfDay(for: now).addingTimeInterval(24 * 3600)
        let components = calendar.dateComponents([.hour], from: now, to: endOfDay)
        return components.hour ?? 0
    }
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Challenge Status")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(2)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(999)
            
            Text("Day \(daysElapsed) of \(totalDays)")
                .font(.system(size: 32, weight: .bold))
            
            // Animated Progress Bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(height: 8)
                        
                        // Progress fill with animation
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [primaryYellow, primaryYellow.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * challengeProgress, height: 8)
                            .shadow(color: primaryYellow.opacity(0.5), radius: 4, x: 0, y: 0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: challengeProgress)
                    }
                }
                .frame(height: 8)
                
                // Progress label
                Text("\(Int(challengeProgress * 100))% Complete")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16))
                Text("\(hoursRemaining)h remaining in this round")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.secondary)
        }
    }
}

// MARK: - Dashboard Card

struct DashboardCard: View {
    let challenge: Challenge
    let leaderboardEntries: [LeaderboardEntry]
    let currentUserId: String
    let currentUserName: String
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var currentUserEntry: LeaderboardEntry? {
        leaderboardEntries.first { $0.userId == currentUserId }
    }
    
    var currentUserRank: Int {
        currentUserEntry?.rank ?? 0
    }
    
    var currentUserSteps: Int {
        currentUserEntry?.steps ?? 0
    }
    
    var stepsToNext: Int {
        guard let currentRank = currentUserEntry?.rank,
              currentRank > 1,
              let nextEntry = leaderboardEntries.first(where: { $0.rank == currentRank - 1 }) else {
            return 0
        }
        return max(nextEntry.steps - currentUserSteps, 0)
    }
    
    var progress: Double {
        guard challenge.targetSteps > 0 else { return 0 }
        return min(Double(currentUserSteps) / Double(challenge.targetSteps), 1.0)
    }
    
    var body: some View {
        ZStack {
            // Background pattern overlay
            LinearGradient(
                colors: [Color.black.opacity(0.4), Color.clear, primaryYellow.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 16) {
                // Avatar stack and rank badge
                HStack {
                    // Avatar stack
                    HStack(spacing: -12) {
                        ForEach(Array(leaderboardEntries.prefix(3))) { entry in
                            AvatarView(
                                displayName: entry.displayName,
                                avatarURL: entry.avatarURL,
                                size: 40
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                        }
                        
                        if leaderboardEntries.count > 3 {
                            Circle()
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.1))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text("+\(leaderboardEntries.count - 3)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(primaryYellow)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.black, lineWidth: 2)
                                )
                        }
                    }
                    
                    Spacer()
                    
                    // Rank badge
                    Text("Your Rank: #\(currentUserRank)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(primaryYellow)
                        .cornerRadius(8)
                }
                
                // Motivational message
                VStack(alignment: .leading, spacing: 4) {
                    Text("Keep up the pace, \(currentUserName)!")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    if stepsToNext > 0 {
                        Text("You're only **\(stepsToNext.formatted()) steps** behind \(currentUserRank > 1 ? "#\(currentUserRank - 1)" : "the leader").")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.7))
                    } else {
                        Text("You're leading the pack! 🏆")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
                
                // Progress bar
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 12)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(primaryYellow)
                                .frame(width: geometry.size.width * progress, height: 12)
                                .shadow(color: primaryYellow.opacity(0.6), radius: 10, x: 0, y: 0)
                        }
                    }
                    .frame(height: 12)
                    
                    HStack {
                        Text("0 steps")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text("Goal: \(challenge.targetSteps.formatted())")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                }
            }
            .padding(24)
        }
        .background(Color.black)
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 8)
    }
}

// MARK: - Segmented Tab Control

struct SegmentedTabControl: View {
    @Binding var selectedTab: GroupDetailTab
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(GroupDetailTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    Text(tab.displayName)
                        .font(.system(size: 14, weight: selectedTab == tab ? .bold : .medium))
                        .foregroundColor(selectedTab == tab ? .black : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedTab == tab ? primaryYellow : Color.clear)
                        .cornerRadius(999)
                }
            }
        }
        .padding(6)
        .background(Color(.systemBackground))
        .cornerRadius(999)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 999)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

// MARK: - Leaderboard Tab

struct LeaderboardTabView: View {
    let entries: [LeaderboardEntry]
    let currentUserId: String
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    private let goldColor = Color(red: 1.0, green: 0.843, blue: 0.0)
    private let silverColor = Color(red: 0.753, green: 0.753, blue: 0.753)
    private let bronzeColor = Color(red: 0.804, green: 0.498, blue: 0.196)
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(entries.sorted(by: { $0.rank < $1.rank })) { entry in
                LeaderboardRankRow(
                    entry: entry,
                    isCurrentUser: entry.userId == currentUserId,
                    rankColor: rankColor(for: entry.rank),
                    borderColor: borderColor(for: entry.rank)
                )
            }
        }
    }
    
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return goldColor
        case 2: return silverColor
        case 3: return bronzeColor
        default: return .secondary
        }
    }
    
    private func borderColor(for rank: Int) -> Color {
        switch rank {
        case 1: return goldColor
        case 2: return silverColor
        case 3: return bronzeColor
        default: return .clear
        }
    }
}

struct LeaderboardRankRow: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    let rankColor: Color
    let borderColor: Color
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var statusMessage: String {
        switch entry.rank {
        case 1: return "🔥 \(entry.steps.formatted()) steps today"
        case 2: return "On a streak! ⚡️"
        case 3: return "Avg. 15k / day"
        default: return isCurrentUser ? "Keep pushing! 🚀" : "Looking to catch up..."
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank indicator bar
            Rectangle()
                .fill(rankColor)
                .frame(width: 4)
            
            // Rank number
            Text("\(entry.rank)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(rankColor)
                .frame(width: 32)
            
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    displayName: entry.displayName,
                    avatarURL: entry.avatarURL,
                    size: 48
                )
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 2)
                )
                
                if entry.rank == 1 {
                    Text("👑")
                        .font(.system(size: 12))
                        .padding(4)
                        .background(rankColor)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                        .offset(x: 4, y: 4)
                }
            }
            
            // Name and status
            VStack(alignment: .leading, spacing: 4) {
                Text(isCurrentUser ? "\(entry.displayName) (You)" : entry.displayName)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                
                Text(statusMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Steps count
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.steps.formatted())")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isCurrentUser ? primaryYellow : .primary)
                
                Text("Steps")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
            }
        }
        .padding(12)
        .background(
            Group {
                if isCurrentUser {
                    Color(.systemBackground)
                        .background(primaryYellow.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(primaryYellow.opacity(0.5), lineWidth: 1)
                        )
                } else {
                    Color(.systemBackground)
                }
            }
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .opacity(entry.rank > 4 ? 0.8 : 1.0)
    }
}

// MARK: - Members Tab

struct MembersTabView: View {
    let members: [User]
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(members) { member in
                HStack {
                    AvatarView(
                        displayName: member.displayName,
                        avatarURL: member.avatarURL,
                        size: 48
                    )
                    
                    Text(member.displayName)
                        .font(.system(size: 15, weight: .medium))
                    
                    Spacer()
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Settings Tab

struct SettingsTabView: View {
    @ObservedObject var viewModel: GroupViewModel
    let challenge: Challenge?
    
    var body: some View {
        VStack(spacing: 12) {
            if viewModel.canDelete {
                Button(role: .destructive, action: {
                    Task {
                        await viewModel.deleteChallenge()
                    }
                }) {
                    HStack {
                        Text("Delete Challenge")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundColor(.red)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                }
            } else {
                Button(role: .destructive, action: {
                    Task {
                        await viewModel.leaveChallenge()
                    }
                }) {
                    HStack {
                        Text("Leave Challenge")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundColor(.red)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                }
            }
        }
    }
}

// MARK: - Group Chat Button

struct GroupChatButton: View {
    @State private var unreadCount = 3
    
    var body: some View {
        VStack {
            Spacer()
            
            Button(action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 18))
                    
                    Text("Group Chat")
                        .font(.system(size: 16, weight: .bold))
                    
                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(Color.black)
                .cornerRadius(999)
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 8)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}
