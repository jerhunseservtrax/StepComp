//
//  ChallengeSummaryView.swift
//  StepComp
//
//  Challenge summary with metrics and final standings
//

import SwiftUI

struct ChallengeSummaryView: View {
    let challengeId: String
    let challengeName: String
    @ObservedObject var sessionViewModel: SessionViewModel
    @StateObject private var viewModel: LeaderboardViewModel
    @EnvironmentObject var challengeService: ChallengeService
    @Environment(\.dismiss) var dismiss
    
    @State private var challenge: Challenge?
    
    
    init(challengeId: String, challengeName: String, sessionViewModel: SessionViewModel) {
        self.challengeId = challengeId
        self.challengeName = challengeName
        self.sessionViewModel = sessionViewModel
        let userId = sessionViewModel.currentUser?.id ?? ""
        _viewModel = StateObject(
            wrappedValue: LeaderboardViewModel(
                challengeService: ChallengeService(),
                challengeId: challengeId,
                userId: userId
            )
        )
    }
    
    // Current user's total steps during the challenge
    var totalSteps: Int {
        guard let userEntry = viewModel.currentUserEntry else { return 0 }
        return userEntry.steps
    }
    
    var challengeDurationDays: Int {
        guard let challenge = challenge else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 0
        return max(days, 1) // Ensure at least 1 day to avoid division by zero
    }
    
    // Current user's average steps per day = total steps / challenge duration
    var averageSteps: Int {
        guard challengeDurationDays > 0 else { return 0 }
        return totalSteps / challengeDurationDays
    }
    
    var challengeDuration: String {
        return "\(challengeDurationDays) days"
    }
    
    var endDateFormatted: String {
        guard let challenge = challenge else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: challenge.endDate)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("🏆")
                            .font(.system(size: 60))
                        
                        Text(challengeName)
                            .font(.system(size: 26, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        // Status Badge for Ended Challenge
                        if let challenge = challenge, challenge.endDate < Date() {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                Text("Challenge Ended")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Text("Challenge Summary")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 24)
                    
                    // Challenge Metrics
                    VStack(spacing: 16) {
                        Text("Challenge Metrics")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Stats Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            MetricCard(
                                icon: "figure.walk",
                                value: formatLargeNumber(totalSteps),
                                label: "Total Steps\n(Challenge Duration)",
                                color: .blue
                            )
                            
                            MetricCard(
                                icon: "person.2.fill",
                                value: "\(viewModel.entries.count)",
                                label: "Participants",
                                color: .green
                            )
                            
                            MetricCard(
                                icon: "chart.bar.fill",
                                value: formatLargeNumber(averageSteps),
                                label: "Avg Steps\n(Per Day)",
                                color: .orange
                            )
                            
                            MetricCard(
                                icon: "calendar",
                                value: challengeDuration,
                                label: "Duration",
                                color: .purple
                            )
                            
                            // End Date Card (only show if challenge has ended)
                            if let challenge = challenge, challenge.endDate < Date() {
                                MetricCard(
                                    icon: "checkmark.circle.fill",
                                    value: endDateFormatted,
                                    label: "Ended On",
                                    color: .secondary
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Final Standings
                    VStack(spacing: 16) {
                        Text("Final Standings")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.entries.prefix(10)) { entry in
                                SummaryLeaderboardRow(
                                    entry: entry,
                                    isCurrentUser: entry.userId == sessionViewModel.currentUser?.id ?? "",
                                    isWinner: entry.rank == 1
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Personal Performance (if user participated)
                    if let userEntry = viewModel.currentUserEntry {
                        VStack(spacing: 16) {
                            Text("Your Performance")
                                .font(.system(size: 18, weight: .bold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            PersonalPerformanceCard(
                                entry: userEntry,
                                totalParticipants: viewModel.entries.count,
                                averageSteps: averageSteps
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
            }
        }
        .onAppear {
            viewModel.updateService(challengeService)
            loadChallenge()
        }
    }
    
    private func loadChallenge() {
        challenge = challengeService.challenges.first { $0.id == challengeId }
    }
    
    private func formatLargeNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fk", Double(number) / 1_000)
        }
        return "\(number)"
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Summary Leaderboard Row

struct SummaryLeaderboardRow: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    let isWinner: Bool
    
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank with medal for top 3
            ZStack {
                if isWinner {
                    Circle()
                        .fill(StepCompColors.primary)
                        .frame(width: 32, height: 32)
                    Text("🏆")
                        .font(.system(size: 16))
                } else {
                    Text("\(entry.rank)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 32)
                }
            }
            
            // Avatar
            AvatarView(
                displayName: entry.displayName,
                avatarURL: entry.avatarURL,
                size: 44
            )
            .overlay(
                Circle()
                    .stroke(isWinner ? StepCompColors.primary : Color.clear, lineWidth: 2)
            )
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(isCurrentUser ? "You" : entry.displayName)
                    .font(.system(size: 15, weight: isWinner ? .bold : .semibold))
                    .foregroundColor(.primary)
                
                if isWinner {
                    Text("Winner")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(StepCompColors.primary)
                }
            }
            
            Spacer()
            
            // Steps
            Text(entry.steps.formatted())
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(isWinner ? StepCompColors.primary : .primary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isWinner ? StepCompColors.primary.opacity(0.1) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isWinner ? StepCompColors.primary : Color.clear, lineWidth: isWinner ? 2 : 0)
        )
        .shadow(color: Color.black.opacity(isWinner ? 0.08 : 0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Personal Performance Card

struct PersonalPerformanceCard: View {
    let entry: LeaderboardEntry
    let totalParticipants: Int
    let averageSteps: Int
    
    
    var percentile: Int {
        let position = Double(totalParticipants - entry.rank + 1)
        return Int((position / Double(totalParticipants)) * 100)
    }
    
    var vsAverage: String {
        let diff = entry.steps - averageSteps
        if diff > 0 {
            return "+\(diff.formatted()) above avg"
        } else if diff < 0 {
            return "\(diff.formatted()) below avg"
        }
        return "At average"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Your rank
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Rank")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text("#\(entry.rank)")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(entry.rank == 1 ? StepCompColors.primary : .primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Top \(percentile)%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(StepCompColors.primary)
                    
                    Text("of \(totalParticipants) people")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Performance metrics
            VStack(spacing: 12) {
                PerformanceMetricRow(
                    icon: "figure.walk",
                    label: "Total Steps",
                    value: entry.steps.formatted()
                )
                
                PerformanceMetricRow(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "vs Average",
                    value: vsAverage
                )
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct PerformanceMetricRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .frame(width: 28)
            
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
        }
    }
}

// Preview requires complex dependencies (SessionViewModel needs authService/healthKitService)
// Use live app testing instead

