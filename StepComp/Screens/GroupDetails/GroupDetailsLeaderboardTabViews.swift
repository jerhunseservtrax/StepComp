//
//  GroupDetailsLeaderboardTabViews.swift
//  FitComp
//

import SwiftUI

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
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(FitCompColors.primary)

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
                        .fill(FitCompColors.primary.opacity(0.1))
                )

                if !topThree.isEmpty {
                    ModernPodiumView(
                        entries: topThree,
                        currentUserId: currentUserId,
                        onTapUser: { userId in
                            selectedUserId = userId
                        }
                    )
                }

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

struct FloatingRankDisplay: View {
    let rank: Int
    let todaySteps: Int

    @State private var opacity: Double = 0.5
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

                VStack(alignment: .leading, spacing: 2) {
                    Text("You")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)

                    Text(motivationalMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(todaySteps.formatted())")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(FitCompColors.primary)

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
            .padding(.bottom, 16)
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
        fadeTimer?.invalidate()

        withAnimation(.easeInOut(duration: 0.3)) {
            opacity = 1.0
        }

        fadeTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                opacity = 0.5
            }
            fadeTimer?.invalidate()
            fadeTimer = nil
        }

        if let timer = fadeTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
}

struct ModernPodiumView: View {
    let entries: [LeaderboardEntry]
    let currentUserId: String
    let onTapUser: (String) -> Void

    private let gradientEnd = Color(red: 0.902, green: 0.761, blue: 0.0)

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
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

struct ModernPodiumCard: View {
    let entry: LeaderboardEntry
    let rank: Int
    let isCurrentUser: Bool
    let isWinner: Bool

    private let gradientEnd = Color(red: 0.902, green: 0.761, blue: 0.0)

    @State private var glowScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            if isWinner {
                Text("👑")
                    .font(.system(size: 32))
                    .offset(y: 16)
                    .zIndex(10)
            }

            ZStack {
                if isWinner {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(FitCompColors.primary.opacity(0.3))
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
                                colors: [FitCompColors.primary, gradientEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: FitCompColors.primary.opacity(0.4), radius: 15, x: 0, y: 8)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                }

                VStack(spacing: 12) {
                    ZStack {
                        if isWinner {
                            Circle()
                                .fill(FitCompColors.primary.opacity(0.4))
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

                        ZStack {
                            Circle()
                                .fill(isWinner ? Color.white : FitCompColors.primary)
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

                    Text(isCurrentUser ? "You" : formatName(entry.displayName))
                        .font(.system(size: isWinner ? 14 : 12, weight: .bold))
                        .foregroundColor(isWinner ? .black : .primary)
                        .lineLimit(1)

                    Text(entry.steps.formatted())
                        .font(.system(size: isWinner ? 16 : 13, weight: .bold, design: .monospaced))
                        .foregroundColor(isWinner ? .black.opacity(0.7) : FitCompColors.primary)
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

struct ModernLeaderboardRow: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text("\(entry.rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(.systemGray))
                .frame(width: 24, alignment: .center)

            AvatarView(
                displayName: entry.displayName,
                avatarURL: entry.avatarURL,
                size: 44
            )
            .overlay(
                Circle()
                    .stroke(isCurrentUser ? FitCompColors.primary : Color(.systemGray5), lineWidth: isCurrentUser ? 2 : 1)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(isCurrentUser ? "You" : entry.displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

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

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.steps.formatted())
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(isCurrentUser ? FitCompColors.primary : .primary)

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
                .stroke(isCurrentUser ? FitCompColors.primary.opacity(0.5) : Color(.systemGray6), lineWidth: isCurrentUser ? 2 : 1)
        )
    }
}
