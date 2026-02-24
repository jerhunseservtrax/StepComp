//
//  GroupDetailsView.swift
//  StepComp
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
                challengeService: ChallengeService(),
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
            // Show loading state if challenge is nil (prevents black screen)
            if viewModel.challenge == nil && viewModel.isLoading {
                StepCompColors.background.ignoresSafeArea()
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading challenge...")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.secondary)
                }
            } else if !isMember {
                // Non-member preview view
                ChallengePreviewView(
                    challenge: viewModel.challenge,
                    highestSteps: viewModel.leaderboardEntries.first?.steps ?? 0,
                    onBack: { dismiss() },
                    onJoin: {
                        Task { @MainActor in
                            await viewModel.joinCurrentChallenge()
                            if viewModel.errorMessage.isEmpty {
                                // Successfully joined - show success alert
                                showingJoinSuccess = true
                                
                                // Refresh challenge data to update participant list
                                await viewModel.refresh()
                                
                                // Ensure challenge is loaded before view switch
                                // Wait a brief moment for state to update
                                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                            }
                        }
                    },
                    isLoading: viewModel.isLoading,
                    errorMessage: viewModel.errorMessage
                )
            } else {
                // Member view - full access
                fullMemberView
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
            // Update ViewModel with the actual environment object
            viewModel.updateService(challengeService)
            // Resume auto-refresh when view appears
            viewModel.resumeAutoRefresh()
        }
        .onDisappear {
            // Pause auto-refresh when view disappears to save resources
            viewModel.pauseAutoRefresh()
        }
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh leaderboard when app comes to foreground
            Task {
                await viewModel.refresh()
            }
        }
        #endif
        .alert("Success! 🎉", isPresented: $showingJoinSuccess) {
            Button("OK", role: .cancel) {
                // View will automatically switch to member view after state updates
            }
        } message: {
            Text("You successfully joined this challenge!")
        }
    }
    
    private var fullMemberView: some View {
        ZStack {
            StepCompColors.background.ignoresSafeArea()
            
            // Challenge image background header (if available)
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
                        
                        // Dark overlay for header readability
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
                    // Top Navigation
                    GroupDetailsHeader(
                        challengeName: viewModel.challenge?.name ?? "Challenge",
                        onBack: { dismiss() },
                        onInvite: {
                            showingInvite = true
                        },
                        onChat: {
                            showingChat = true
                        }
                    )
                    
                    // Main Content
                    VStack(spacing: 24) {
                        // Countdown Timer
                        if let challenge = viewModel.challenge {
                            ChallengeCountdownTimer(endDate: challenge.endDate)
                                .padding(.horizontal)
                                .padding(.top, 8)
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
                                    onDismiss: { dismiss() }
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
            .refreshable {
                // Pull to refresh leaderboard
                await viewModel.refresh()
            }
            .navigationBarHidden(true)
            
            // Floating rank display (only show on leaderboard tab)
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
    let onChat: () -> Void
    
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18))
                    .foregroundColor(StepCompColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(StepCompColors.surface)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
            
            Spacer()
            
            Text(challengeName)
                .font(.system(size: 18, weight: .bold))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            HStack(spacing: 8) {
                // Chat button - white with pill shape and glow
                Button(action: onChat) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(999)
                        .shadow(color: Color.white.opacity(0.5), radius: 8, x: 0, y: 2)
                }
                
                // Invite button
                Button(action: onInvite) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16))
                        Text("Invite")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(StepCompColors.buttonTextOnPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(StepCompColors.primary)
                    .cornerRadius(999)
                    .shadow(color: StepCompColors.primary.opacity(0.4), radius: 8, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(
            StepCompColors.surface
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
                                    colors: [StepCompColors.primary, StepCompColors.primary.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * challengeProgress, height: 8)
                            .shadow(color: StepCompColors.primary.opacity(0.5), radius: 4, x: 0, y: 0)
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
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                Text("\(challenge.daysRemaining) days left in challenge")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.secondary)
        }
    }
}

// MARK: - Challenge Countdown Timer

struct ChallengeCountdownTimer: View {
    let endDate: Date
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    
    private var hasEnded: Bool {
        Date() >= endDate
    }
    
    var body: some View {
        if !hasEnded {
            VStack(spacing: 0) {
                // Timer card
                VStack(spacing: 12) {
                    // Header
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(StepCompColors.primary)
                        
                        Text("Challenge ends in")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(1.5)
                    }
                    
                    // Countdown display
                    HStack(spacing: 8) {
                        // Days
                        CountdownUnit(
                            value: days,
                            label: "Days"
                        )
                        
                        // Separator
                        Text(":")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(StepCompColors.primary)
                            .padding(.top, 8)
                        
                        // Hours
                        CountdownUnit(
                            value: hours,
                            label: "Hours"
                        )
                        
                        // Separator
                        Text(":")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(StepCompColors.primary)
                            .padding(.top, 8)
                        
                        // Minutes
                        CountdownUnit(
                            value: minutes,
                            label: "Mins"
                        )
                        
                        // Separator
                        Text(":")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(StepCompColors.primary)
                            .padding(.top, 8)
                        
                        // Seconds
                        CountdownUnit(
                            value: seconds,
                            label: "Secs"
                        )
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(StepCompColors.primary.opacity(0.2), lineWidth: 1)
                )
            }
            .onAppear {
                updateTimeRemaining()
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
        }
    }
    
    private var days: Int {
        Int(timeRemaining) / 86400
    }
    
    private var hours: Int {
        (Int(timeRemaining) % 86400) / 3600
    }
    
    private var minutes: Int {
        (Int(timeRemaining) % 3600) / 60
    }
    
    private var seconds: Int {
        Int(timeRemaining) % 60
    }
    
    private func updateTimeRemaining() {
        let now = Date()
        if endDate > now {
            timeRemaining = endDate.timeIntervalSince(now)
        } else {
            timeRemaining = 0
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                updateTimeRemaining()
            }
        }
        // Ensure timer runs on main run loop
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Countdown Unit

struct CountdownUnit: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            // Value box
            Text(String(format: "%02d", value))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(minWidth: 56)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    StepCompColors.primary.opacity(0.1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(StepCompColors.primary.opacity(0.2), lineWidth: 1)
                        )
                )
                .cornerRadius(12)
            
            // Label
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

// MARK: - Segmented Tab Control

struct SegmentedTabControl: View {
    @Binding var selectedTab: GroupDetailTab
    
    
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
                        .background(selectedTab == tab ? StepCompColors.primary : Color.clear)
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

// MARK: - Leaderboard Tab (Modern Design)

struct LeaderboardTabView: View {
    let entries: [LeaderboardEntry]
    let dailyEntries: [LeaderboardEntry]
    let currentUserId: String
    
    @State private var selectedUserId: String?
    
    private let gradientEnd = Color(red: 0.902, green: 0.761, blue: 0.0)
    
    var sortedEntries: [LeaderboardEntry] {
        entries.sorted(by: { $0.rank < $1.rank })
    }
    
    var topThree: [LeaderboardEntry] {
        Array(sortedEntries.prefix(3))
    }
    
    var restOfLeaderboard: [LeaderboardEntry] {
        Array(sortedEntries.dropFirst(3))
    }
    
    var currentUserEntry: LeaderboardEntry? {
        entries.first { $0.userId == currentUserId }
    }
    
    var currentUserTodayEntry: LeaderboardEntry? {
        dailyEntries.first { $0.userId == currentUserId }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                // Info header explaining what's shown
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(StepCompColors.primary)
                    
                    Text("Showing total steps accumulated since challenge started")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(StepCompColors.primary.opacity(0.1))
                )
                
                // Top 3 Podium Display (Modern Design)
                if !topThree.isEmpty {
                    ModernPodiumView(
                        entries: topThree,
                        currentUserId: currentUserId,
                        onTapUser: { userId in
                            selectedUserId = userId
                        }
                    )
                }
                
                // Full leaderboard list (including top 3)
                if !sortedEntries.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(sortedEntries) { entry in
                            ModernLeaderboardRow(
                                entry: entry,
                                isCurrentUser: entry.userId == currentUserId
                            )
                            .onTapGesture {
                                selectedUserId = entry.userId
                            }
                        }
                    }
                }
            }
            
            // Profile card overlay
            if selectedUserId != nil {
                UserProfileCard(
                    userId: selectedUserId ?? "",
                    currentUserId: currentUserId,
                    isPresented: Binding(
                        get: { selectedUserId != nil },
                        set: { if !$0 { selectedUserId = nil } }
                    )
                )
                .transition(.opacity)
                .zIndex(1000)
            }
        }
    }
}

// MARK: - Floating Rank Display

struct FloatingRankDisplay: View {
    let rank: Int
    let todaySteps: Int
    
    @State private var opacity: Double = 0.5 // Default 50% opacity
    @State private var fadeTimer: Timer?
    
    private var motivationalMessage: String {
        switch rank {
        case 1:
            return "You're #1! 🏆"
        case 2...3:
            return "You're crushing it! 🔥"
        case 4...10:
            return "Keep going! 🔥"
        case 11...20:
            return "You're moving up! 💪"
        default:
            return "Keep pushing! 💪"
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 16) {
                // Left side - Rank indicator
                VStack(spacing: 4) {
                    Text("Rank")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(rank)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(width: 40)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                
                // Middle - User name and motivational message
                VStack(alignment: .leading, spacing: 2) {
                    Text("You")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(motivationalMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Right side - Today's steps
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(todaySteps.formatted())")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(StepCompColors.primary)
                    
                    Text("Steps Today")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
            }
            .padding(16)
            .background(
                Color.black
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 8)
            .padding(.horizontal, 16)
            .padding(.bottom, 16) // Position below the chat button
            .opacity(opacity)
            .onTapGesture {
                handleTap()
            }
        }
        .onDisappear {
            fadeTimer?.invalidate()
            fadeTimer = nil
        }
    }
    
    private func handleTap() {
        // Cancel any existing timer
        fadeTimer?.invalidate()
        
        // Immediately increase opacity to 100%
        withAnimation(.easeInOut(duration: 0.3)) {
            opacity = 1.0
        }
        
        // Set timer to fade back to 50% after 10 seconds
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                opacity = 0.5
            }
            fadeTimer?.invalidate()
            fadeTimer = nil
        }
        
        // Ensure timer runs on main run loop
        if let timer = fadeTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
}

// MARK: - Modern Podium View

struct ModernPodiumView: View {
    let entries: [LeaderboardEntry]
    let currentUserId: String
    let onTapUser: (String) -> Void
    
    private let gradientEnd = Color(red: 0.902, green: 0.761, blue: 0.0)
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // #2 (Left)
            if entries.count >= 2 {
                ModernPodiumCard(
                    entry: entries[1],
                    rank: 2,
                    isCurrentUser: entries[1].userId == currentUserId,
                    isWinner: false
                )
                .frame(maxWidth: .infinity)
                .onTapGesture { onTapUser(entries[1].userId) }
            } else {
                Spacer().frame(maxWidth: .infinity)
            }
            
            // #1 (Center) - Winner with crown
            if entries.count >= 1 {
                ModernPodiumCard(
                    entry: entries[0],
                    rank: 1,
                    isCurrentUser: entries[0].userId == currentUserId,
                    isWinner: true
                )
                .frame(maxWidth: .infinity)
                .scaleEffect(1.05)
                .zIndex(1)
                .onTapGesture { onTapUser(entries[0].userId) }
            }
            
            // #3 (Right)
            if entries.count >= 3 {
                ModernPodiumCard(
                    entry: entries[2],
                    rank: 3,
                    isCurrentUser: entries[2].userId == currentUserId,
                    isWinner: false
                )
                .frame(maxWidth: .infinity)
                .onTapGesture { onTapUser(entries[2].userId) }
            } else {
                Spacer().frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 32)
    }
}

// MARK: - Modern Podium Card

struct ModernPodiumCard: View {
    let entry: LeaderboardEntry
    let rank: Int
    let isCurrentUser: Bool
    let isWinner: Bool
    
    private let gradientEnd = Color(red: 0.902, green: 0.761, blue: 0.0)
    
    @State private var glowScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Crown for winner - positioned above card
            if isWinner {
                Text("👑")
                    .font(.system(size: 32))
                    .offset(y: 16)
                    .zIndex(10) // Ensure crown is on top
            }
            
            ZStack {
                // Background card
                if isWinner {
                    // Glow effect
                    RoundedRectangle(cornerRadius: 20)
                        .fill(StepCompColors.primary.opacity(0.3))
                        .blur(radius: 20)
                        .scaleEffect(glowScale)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: glowScale
                        )
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [StepCompColors.primary, gradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: StepCompColors.primary.opacity(0.4), radius: 15, x: 0, y: 8)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                }
                
                VStack(spacing: 12) {
                    // Avatar with ring
                    ZStack {
                        // Glow for winner
                        if isWinner {
                            Circle()
                                .fill(StepCompColors.primary.opacity(0.4))
                                .frame(width: 76, height: 76)
                                .blur(radius: 10)
                        }
                        
                        AvatarView(
                            displayName: entry.displayName,
                            avatarURL: entry.avatarURL,
                            size: isWinner ? 70 : 56
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    isWinner ? Color.white.opacity(0.6) : Color(.systemGray4),
                                    lineWidth: isWinner ? 4 : 2
                                )
                        )
                        
                        // Rank badge at bottom
                        ZStack {
                            Circle()
                                .fill(isWinner ? Color.white : StepCompColors.primary)
                                .frame(width: 24, height: 24)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            
                            Text("\(rank)")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(isWinner ? .black : .black)
                        }
                        .offset(y: isWinner ? 32 : 26)
                    }
                    .padding(.top, 8)
                    
                    Spacer().frame(height: 12)
                    
                    // Name
                    Text(isCurrentUser ? "You" : formatName(entry.displayName))
                        .font(.system(size: isWinner ? 14 : 12, weight: .bold))
                        .foregroundColor(isWinner ? .black : .primary)
                        .lineLimit(1)
                    
                    // Steps
                    Text(entry.steps.formatted())
                        .font(.system(size: isWinner ? 16 : 13, weight: .bold, design: .monospaced))
                        .foregroundColor(isWinner ? .black.opacity(0.7) : StepCompColors.primary)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 8)
            }
            .frame(height: isWinner ? 180 : 160)
            .onAppear {
                if isWinner {
                    glowScale = 1.1
                }
            }
        }
    }
    
    private func formatName(_ name: String) -> String {
        let components = name.components(separatedBy: " ")
        if let firstName = components.first, let lastInitial = components.dropFirst().first?.first {
            return "\(firstName) \(lastInitial)."
        }
        return name
    }
}

// MARK: - Modern Leaderboard Row

struct ModernLeaderboardRow: View {
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
                size: 44
            )
            .overlay(
                Circle()
                    .stroke(isCurrentUser ? StepCompColors.primary : Color(.systemGray5), lineWidth: isCurrentUser ? 2 : 1)
            )
            
            // Name and rank change
            VStack(alignment: .leading, spacing: 4) {
                Text(isCurrentUser ? "You" : entry.displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Show rank change if available
                if let rankChange = entry.rankChange, rankChange != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: rankChange > 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(rankChange > 0 ? .green : .red)
                        
                        Text(rankChange > 0 ? "Up \(abs(rankChange))" : "Down \(abs(rankChange))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Competing")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Steps
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.steps.formatted())
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(isCurrentUser ? StepCompColors.primary : .primary)
                
                Text("STEPS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrentUser ? StepCompColors.primary.opacity(0.5) : Color(.systemGray6), lineWidth: isCurrentUser ? 2 : 1)
        )
    }
}

// MARK: - Members Tab (Modern List Design)

struct MembersTabView: View {
    let members: [User]
    let leaderboardEntries: [LeaderboardEntry]
    @State private var selectedUserId: String?
    
    
    // Create a sorted list of members with their steps and rank
    private var membersWithSteps: [(user: User, steps: Int, rank: Int)] {
        let sortedEntries = leaderboardEntries.sorted { $0.rank < $1.rank }
        return members.compactMap { member in
            if let entry = sortedEntries.first(where: { $0.userId == member.id }) {
                return (user: member, steps: entry.steps, rank: entry.rank)
            }
            return (user: member, steps: 0, rank: members.count)
        }
        .sorted { $0.rank < $1.rank }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                // Member count header with description
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(members.count) Members")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Total steps accumulated since challenge started")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
                
                // Info card explaining what's being shown
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(StepCompColors.primary)
                    
                    Text("Step counts update daily and represent the total steps accumulated in this challenge.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(StepCompColors.primary.opacity(0.1))
                )
                .padding(.bottom, 8)
                
                // Members list (no podium, just clean list)
                ForEach(membersWithSteps, id: \.user.id) { item in
                    HStack(spacing: 12) {
                        // Rank number
                        Text("\(item.rank)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(item.rank <= 3 ? StepCompColors.primary : Color(.systemGray))
                            .frame(width: 24, alignment: .center)
                        
                        // Avatar
                        AvatarView(
                            displayName: item.user.displayName,
                            avatarURL: item.user.avatarURL,
                            size: 48
                        )
                        .overlay(
                            Circle()
                                .stroke(item.rank == 1 ? StepCompColors.primary : Color(.systemGray5), lineWidth: item.rank == 1 ? 2 : 1)
                        )
                        
                        // Name and username
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.user.displayName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            if !item.user.username.isEmpty {
                                Text("@\(item.user.username)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Steps section - emphasize total steps
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(formatSteps(item.steps))
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(item.rank == 1 ? StepCompColors.primary : .primary)
                            
                            Text("TOTAL STEPS")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.5)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(item.rank == 1 ? StepCompColors.primary.opacity(0.3) : Color(.systemGray6), lineWidth: 1)
                    )
                    .onTapGesture {
                        selectedUserId = item.user.id
                    }
                }
            }
            
            // Profile card overlay
            if selectedUserId != nil {
                UserProfileCard(
                    userId: selectedUserId ?? "",
                    currentUserId: members.first?.id ?? "",
                    isPresented: Binding(
                        get: { selectedUserId != nil },
                        set: { if !$0 { selectedUserId = nil } }
                    )
                )
                .transition(.opacity)
                .zIndex(1000)
            }
        }
    }
    
    private func formatSteps(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
}

// MARK: - Settings Tab

struct SettingsTabView: View {
    @ObservedObject var viewModel: GroupViewModel
    let challenge: Challenge?
    let onDismiss: () -> Void
    
    @State private var showingDeleteAlert = false
    @State private var showingLeaveAlert = false
    
    var body: some View {
        VStack(spacing: 12) {
            if viewModel.canDelete {
                Button(role: .destructive, action: {
                    showingDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete Challenge")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundColor(.red)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
            } else {
                Button(role: .destructive, action: {
                    showingLeaveAlert = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Leave Challenge")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundColor(.red)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
        .alert("Delete Challenge?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteChallenge()
                    await MainActor.run {
                        onDismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this challenge? All data including leaderboard and chat history will be permanently deleted. This action cannot be undone.")
        }
        .alert("Leave Challenge?", isPresented: $showingLeaveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                Task {
                    await viewModel.leaveChallenge()
                    await MainActor.run {
                        onDismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to leave this challenge? You will lose your progress and ranking in this challenge.")
        }
    }
}

// MARK: - Challenge Preview View (for non-members)

struct ChallengePreviewView: View {
    let challenge: Challenge?
    let highestSteps: Int
    let onBack: () -> Void
    let onJoin: () -> Void
    let isLoading: Bool
    let errorMessage: String
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAboutRules: Bool = false
    
    var body: some View {
        ZStack {
            if let challenge = challenge {
                challengePreviewContent(challenge: challenge)
            } else {
                loadingPlaceholder
            }
        }
    }
    
    @ViewBuilder
    private func challengePreviewContent(challenge: Challenge) -> some View {
        ZStack {
            // Background
            StepCompColors.background
                .ignoresSafeArea()
            
            ScrollView {
            VStack(spacing: 0) {
                    // Header with back button and title
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(StepCompColors.textPrimary)
                                .frame(width: 48, height: 48)
                                .background(Color.clear)
                        }
                        
                        Spacer()
                        
                        Text("Join Challenge")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(StepCompColors.textPrimary)
                        
                        Spacer()
                        
                        // Spacer for symmetry
                        Color.clear
                            .frame(width: 48, height: 48)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                    
                    // Trophy Icon Section
                    VStack(spacing: 16) {
                ZStack {
                            // Glow effect
                            Circle()
                                .fill(StepCompColors.primary.opacity(0.4))
                                .frame(width: 80, height: 80)
                                .blur(radius: 20)
                            
                            // Trophy icon
                            Circle()
                                .fill(StepCompColors.primary)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.black)
                                )
                                .shadow(color: StepCompColors.primary.opacity(0.5), radius: 20, x: 0, y: 10)
                        }
                        .padding(.top, 24)
                        
                        // Heading
                        Text("Ready to Step Up?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(StepCompColors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        // Subtitle
                        Text("Enter your invite code below or review the shared challenge details.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(StepCompColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 8)
                    }
                    .padding(.bottom, 24)
                    
                    // Challenge Preview Card
                    VStack(spacing: 0) {
                        // Image Section with Timer Badge
                        ZStack(alignment: .topTrailing) {
                            // Challenge Image
                            ZStack {
                    if isValidImageURL(challenge.imageUrl) {
                        AsyncImage(url: URL(string: challenge.imageUrl!)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                        case .failure, .empty:
                                            // Fallback gradient
                                LinearGradient(
                                    colors: [
                                                    categoryColor(challenge.category),
                                                    categoryColor(challenge.category).opacity(0.7)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                )
                            @unknown default:
                                LinearGradient(
                                    colors: [
                                                    categoryColor(challenge.category),
                                                    categoryColor(challenge.category).opacity(0.7)
                                    ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                )
                            }
                        }
                                } else {
                                    // Default gradient
                        LinearGradient(
                            colors: [
                                            categoryColor(challenge.category),
                                            categoryColor(challenge.category).opacity(0.7)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                }
                                
                                // Dark gradient overlay for text readability
                        LinearGradient(
                                    colors: [.clear, .black.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                            .frame(height: 192)
                            .clipped()
                            
                            // Timer Badge (Top Right)
                            ChallengeTimerBadge(startDate: challenge.startDate, endDate: challenge.endDate)
                                .padding(.top, 16)
                                .padding(.trailing, 16)
                            
                            // Content Overlay (Bottom)
                            VStack(alignment: .leading, spacing: 8) {
                                // Public Badge
                        HStack {
                                    Text("PUBLIC")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(StepCompColors.primary)
                                        .cornerRadius(4)
                            
                            Spacer()
                                }
                                
                                // Challenge Name
                                Text(challenge.name)
                                    .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Details Section
                    VStack(spacing: 20) {
                            // Stats Row
                            HStack(spacing: 24) {
                                // Highest Steps
                                HStack(spacing: 12) {
                        ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(StepCompColors.primary.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "trophy.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color(red: 0.8, green: 0.7, blue: 0))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("HIGHEST STEP")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(StepCompColors.textSecondary)
                                            .tracking(1)
                                        
                                        Text("\(highestSteps.formatted()) steps")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(StepCompColors.textPrimary)
                                    }
                                }
                                
                                Spacer()
                                
                                // Duration
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.purple.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "calendar")
                                            .font(.system(size: 18))
                                            .foregroundColor(.purple)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("DURATION")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(StepCompColors.textSecondary)
                                .tracking(1)
                                        
                                        Text("\(challengeDuration(in: challenge)) Days")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(StepCompColors.textPrimary)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Divider
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 1)
                                .padding(.horizontal, 20)
                            
                            // Friends Joined Section
                            HStack {
                                // Avatar stack
                                HStack(spacing: -12) {
                                    let participantCount = challenge.participantIds.count
                                    let maxAvatars = min(3, participantCount)
                                    
                                    ForEach(0..<maxAvatars, id: \.self) { index in
                                    Circle()
                                            .fill(LinearGradient(
                                                colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.4)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(StepCompColors.surface, lineWidth: 2)
                                        )
                                }
                                
                                    if participantCount > 3 {
                                    Circle()
                                        .fill(StepCompColors.primary)
                                            .frame(width: 40, height: 40)
                                        .overlay(
                                                Text("+\(participantCount - 3)")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.black)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(StepCompColors.surface, lineWidth: 2)
                                        )
                                    } else if participantCount == 0 {
                                        // Show placeholder when no participants
                                        Circle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Friends Joined")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(StepCompColors.textPrimary)
                                    
                                    Text("Waiting for you!")
                                        .font(.system(size: 12))
                                    .foregroundColor(StepCompColors.textSecondary)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                    .background(StepCompColors.surface)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    
                    // Expandable About/Rules Section
                    ExpandableAboutRulesSection(
                        challenge: challenge,
                        isExpanded: $showAboutRules,
                        colorScheme: colorScheme
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 140) // Space for buttons
                }
            }
            
            // Fixed Footer with Buttons
            VStack {
                Spacer()
                
                // Join Challenge Button
                Button(action: onJoin) {
                        HStack(spacing: 8) {
                        Text("Join Challenge")
                            .font(.system(size: 18, weight: .bold))
                        
                        if isLoading {
                            ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .bold))
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(StepCompColors.primary)
                        .cornerRadius(28)
                        .shadow(color: StepCompColors.primary.opacity(0.5), radius: 14, x: 0, y: 4)
                }
                .disabled(isLoading)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                .background(
                    LinearGradient(
                        colors: [
                            StepCompColors.background.opacity(0),
                            StepCompColors.background,
                            StepCompColors.background
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 140)
                    .ignoresSafeArea(edges: .bottom)
                )
            }
        }
    }
    
    private func challengeDuration(in challenge: Challenge) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: challenge.startDate, to: challenge.endDate)
        return max(1, components.day ?? 1)
    }
    
    // MARK: - Helper Functions (keeping existing ones)
    
    private var loadingPlaceholder: some View {
        ZStack {
            StepCompColors.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Loading challenge...")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // Helper functions
    private func categoryBadgeIcon(_ category: Challenge.ChallengeCategory?) -> String {
        guard let category = category else { return "flame.fill" }
        switch category {
        case .corporate: return "briefcase.fill"
        case .marathon: return "figure.run"
        case .friends: return "person.2.fill"
        case .shortTerm: return "bolt.fill"
        case .fun: return "party.popper.fill"
        }
    }
    
    private func categoryColor(_ category: Challenge.ChallengeCategory?) -> Color {
        guard let category = category else { return .orange }
        switch category {
        case .corporate: return .orange
        case .marathon: return .blue
        case .friends: return .purple
        case .shortTerm: return .green
        case .fun: return StepCompColors.primary
        }
    }
    
    private func challengeImageIcon(_ category: Challenge.ChallengeCategory?) -> String {
        guard let category = category else { return "mountain.2.fill" }
        switch category {
        case .corporate: return "building.2.fill"
        case .marathon: return "mountain.2.fill"
        case .friends: return "figure.2.and.child.holdinghands"
        case .shortTerm: return "bolt.circle.fill"
        case .fun: return "sparkles"
        }
    }
    
    private func challengeEmoji(_ category: Challenge.ChallengeCategory?) -> String {
        guard let category = category else { return "🏆" }
        switch category {
        case .corporate: return "💼"
        case .marathon: return "🏔️"
        case .friends: return "👫"
        case .shortTerm: return "⚡"
        case .fun: return "🎉"
        }
    }
    
    private func calculateProgress(_ challenge: Challenge) -> Double {
        let totalDays = Calendar.current.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 1
        let daysRemaining = challenge.daysRemaining
        guard totalDays > 0 else { return 0 }
        return Double(totalDays - daysRemaining) / Double(totalDays)
    }
    
    private func formatStepGoal(_ steps: Int) -> String {
        if steps >= 1_000_000 {
            return "\(steps / 1_000_000)M"
        } else if steps >= 1000 {
            return "\(steps / 1000)k"
        }
        return "\(steps)"
    }
    
    private func defaultDescription(_ challenge: Challenge) -> String {
        let categoryName = challenge.category?.displayName ?? "challenge"
        return "Welcome to the **\(challenge.name)**! This \(categoryName.lowercased()) challenge is designed to push your limits and help you achieve your step goals. Join now to compete with other participants and track your progress on the leaderboard."
    }
}

// MARK: - Challenge Timer Badge

struct ChallengeTimerBadge: View {
    let startDate: Date
    let endDate: Date
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    
    private var hasStarted: Bool {
        Date() >= startDate
    }
    
    private var hasEnded: Bool {
        Date() >= endDate
    }
    
    private var hours: Int {
        Int(timeRemaining) / 3600
    }
    
    private var minutes: Int {
        (Int(timeRemaining) % 3600) / 60
    }
    
    private var seconds: Int {
        Int(timeRemaining) % 60
    }
    
    var body: some View {
        if !hasEnded {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(StepCompColors.primary)
                
                Text(hasStarted ? "ENDS IN" : "STARTS IN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(0.5)
                
                Text(String(format: "%02d:%02d:%02d", hours, minutes, seconds))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.4))
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .onAppear {
                updateTimeRemaining()
                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    updateTimeRemaining()
                }
                if let timer = timer {
                    RunLoop.main.add(timer, forMode: .common)
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    private func updateTimeRemaining() {
        let now = Date()
        let targetDate = hasStarted ? endDate : startDate
        if targetDate > now {
            timeRemaining = targetDate.timeIntervalSince(now)
        } else {
            timeRemaining = 0
        }
    }
}

// MARK: - Expandable About/Rules Section

struct ExpandableAboutRulesSection: View {
    let challenge: Challenge
    @Binding var isExpanded: Bool
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("About Challenge & Rules")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(StepCompColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(StepCompColors.textSecondary)
                }
                .padding(20)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 24) {
                    // About Challenge Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(colorScheme == .dark ? StepCompColors.primary : Color(red: 0.9, green: 0.8, blue: 0))
                            
                            Text("About Challenge")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(StepCompColors.textPrimary)
                        }
                        
                        Text(challenge.description.isEmpty ? defaultChallengeDescription(challenge) : challenge.description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(StepCompColors.textSecondary)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(StepCompColors.textSecondary.opacity(colorScheme == .dark ? 0.1 : 0.15))
                        .frame(height: 1)
                    
                    // Challenge Rules Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("CHALLENGE RULES")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(StepCompColors.textSecondary)
                        
                        VStack(spacing: 16) {
                            ModernRuleRow(
                                icon: "checkmark",
                                iconBackground: Color.green.opacity(colorScheme == .dark ? 0.3 : 0.15),
                                iconColor: Color.green,
                                title: "Verified Sources Only",
                                subtitle: "Steps must come from a wearable device or phone pedometer. Manual entry is disabled."
                            )
                            
                            ModernRuleRow(
                                icon: "checkmark",
                                iconBackground: Color.green.opacity(colorScheme == .dark ? 0.3 : 0.15),
                                iconColor: Color.green,
                                title: "3-Day Sync Window",
                                subtitle: "Open the app at least once every 3 days to sync your progress."
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(StepCompColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func defaultChallengeDescription(_ challenge: Challenge) -> String {
        let categoryName = challenge.category?.displayName ?? "challenge"
        return "Welcome to the **\(challenge.name)**! This \(categoryName.lowercased()) challenge is designed to push your limits and help you achieve your step goals. Join now to compete with other participants and track your progress on the leaderboard."
    }
}

// MARK: - Modern Stat Card

struct ModernStatCard: View {
    let icon: String
    let iconBackground: Color
    let value: String
    let label: String
    let upperLabel: String
    let showProgress: Bool
    let progress: Double
    let progressColor: Color
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with icon and label
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(StepCompColors.textSecondary)
                    
                    Text(upperLabel)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(StepCompColors.textSecondary)
                }
                
                Spacer()
                
                // Decorative icon (faded)
                Image(systemName: showProgress ? "timer" : "flag")
                    .font(.system(size: 32))
                    .foregroundColor(StepCompColors.textSecondary.opacity(0.1))
            }
            .padding(.bottom, 12)
            
            Spacer()
            
            // Value
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(StepCompColors.textPrimary)
            
            // Label
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(StepCompColors.textSecondary)
                .padding(.bottom, 8)
            
            // Progress bar or dots
            if showProgress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(progressColor)
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            } else {
                HStack(spacing: 4) {
                    Circle()
                        .fill(progressColor)
                        .frame(width: 6, height: 6)
                    
                    Circle()
                        .fill(progressColor.opacity(0.3))
                        .frame(width: 6, height: 6)
                    
                    Circle()
                        .fill(progressColor.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
                .frame(height: 12)
            }
        }
        .padding(20)
        .frame(height: 128)
        .background(StepCompColors.surface)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Modern Rule Row

struct ModernRuleRow: View {
    let icon: String
    let iconBackground: Color
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Checkmark icon
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 24, height: 24)
                
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(iconColor)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(StepCompColors.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(StepCompColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Preview Stat Card (Legacy - keeping for other views)

struct PreviewStatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let showProgress: Bool
    let progress: Double
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                Spacer()
                
                // Calendar/flag icon (decorative)
                Image(systemName: showProgress ? "calendar" : "flag.fill")
                    .font(.system(size: 20))
                    .foregroundColor(StepCompColors.textTertiary)
            }
            
            Spacer()
            
            // Value
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(StepCompColors.textPrimary)
            
            // Label
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundColor(StepCompColors.textSecondary)
            
            // Progress indicator
            if showProgress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(StepCompColors.surfaceElevated)
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(iconColor)
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            } else {
                // Step progress dots
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == 0 ? iconColor : StepCompColors.textTertiary)
                            .frame(width: 8, height: 8)
                    }
                    
                    Spacer()
                    
                    // Progress line with flag
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(StepCompColors.textTertiary)
                            .frame(height: 2)
                        
                        Image(systemName: "flag.fill")
                            .font(.system(size: 10))
                            .foregroundColor(iconColor)
                    }
                    .frame(width: 60)
                }
            }
        }
        .padding(16)
        .frame(height: 160)
        .background(StepCompColors.surface)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Rule Row

struct RuleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(StepCompColors.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(StepCompColors.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Overlapping Avatars View

struct OverlappingAvatarsView: View {
    let participantCount: Int
    
    
    var body: some View {
        HStack(spacing: 0) {
            // Show up to 4 avatar circles (placeholder)
            ForEach(0..<min(4, participantCount), id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                StepCompColors.primary.opacity(0.8),
                                StepCompColors.primary.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 3)
                    )
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.black.opacity(0.6))
                    )
                    .offset(x: CGFloat(index * -12))
                    .zIndex(Double(4 - index))
            }
            
            // Participant count
            Text("\(participantCount) \(participantCount == 1 ? "participant" : "participants")")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.leading, min(4, participantCount) > 0 ? 4 : 0)
        }
        .padding(.leading, CGFloat(min(4, participantCount) * 12))
    }
}

// MARK: - Stats Card

struct StatsCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .frame(width: 32)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(StepCompColors.primary)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Group Chat Button

struct GroupChatButton: View {
    let challengeName: String
    let onTap: () -> Void
    @State private var unreadCount = 0 // Will be updated via ViewModel
    
    
    var body: some View {
        VStack {
            Spacer()
            
            Button(action: onTap) {
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

// MARK: - Join Challenge Button

struct JoinChallengeButton: View {
    let challengeName: String
    let isLoading: Bool
    let onJoin: () -> Void
    
    
    var body: some View {
        VStack {
            Spacer()
            
            Button(action: onJoin) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 18))
                        
                        Text("Join Challenge")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundColor(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(StepCompColors.primary)
                .cornerRadius(999)
                .shadow(color: StepCompColors.primary.opacity(0.4), radius: 20, x: 0, y: 8)
            }
            .disabled(isLoading)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}

