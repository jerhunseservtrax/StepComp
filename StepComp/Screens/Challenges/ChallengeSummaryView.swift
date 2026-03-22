//
//  ChallengeSummaryView.swift
//  FitComp
//
//  Challenge summary with metrics and final standings
//

import SwiftUI
#if canImport(Supabase)
import Supabase
#endif
import Foundation

struct ChallengeSummaryView: View {
    let challengeId: String
    let challengeName: String
    @ObservedObject var sessionViewModel: SessionViewModel
    @Environment(\.dismiss) var dismiss
    
    private let providedChallenge: Challenge?
    
    @State private var challenge: Challenge?
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = true
    
    init(challengeId: String, challengeName: String, sessionViewModel: SessionViewModel, challenge: Challenge? = nil) {
        self.challengeId = challengeId
        self.challengeName = challengeName
        self.sessionViewModel = sessionViewModel
        self.providedChallenge = challenge
    }
    
    private var currentUserId: String {
        sessionViewModel.currentUser?.id ?? ""
    }
    
    private var currentUserEntry: LeaderboardEntry? {
        entries.first { $0.userId == currentUserId }
    }
    
    var totalSteps: Int {
        currentUserEntry?.steps ?? 0
    }
    
    var challengeDurationDays: Int {
        guard let challenge = challenge else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: challenge.startDate, to: challenge.endDate).day ?? 0
        return max(days, 1)
    }
    
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
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: FitCompColors.primary))
                            .padding(.vertical, 40)
                    } else {
                        // Challenge Metrics
                        VStack(spacing: 16) {
                            Text("Challenge Metrics")
                                .font(.system(size: 18, weight: .bold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                MetricCard(
                                    icon: "figure.walk",
                                    value: formatLargeNumber(totalSteps),
                                    label: "Your Total Steps",
                                    color: .blue
                                )
                                
                                MetricCard(
                                    icon: "person.2.fill",
                                    value: "\(entries.count)",
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
                            HStack {
                                Text("Final Standings")
                                    .font(.system(size: 18, weight: .bold))
                                Spacer()
                                Text("\(entries.count) participants")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            if entries.isEmpty {
                                Text("No participant data available")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 20)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(entries) { entry in
                                        SummaryLeaderboardRow(
                                            entry: entry,
                                            isCurrentUser: entry.userId == currentUserId,
                                            isWinner: entry.rank == 1
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Personal Performance
                        if let userEntry = currentUserEntry {
                            VStack(spacing: 16) {
                                Text("Your Performance")
                                    .font(.system(size: 18, weight: .bold))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                PersonalPerformanceCard(
                                    entry: userEntry,
                                    totalParticipants: entries.count,
                                    averageSteps: averageSteps
                                )
                            }
                            .padding(.horizontal, 24)
                        }
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
        .task {
            challenge = providedChallenge
            await loadLeaderboardData()
        }
    }
    
    private func loadLeaderboardData() async {
        isLoading = true
        
        #if canImport(Supabase)
        // PRIORITY 1: Try to load from challenge_snapshots (for archived challenges)
        do {
            let snapshots: [ChallengeSnapshot] = try await supabase
                .from("challenge_snapshots")
                .select()
                .eq("challenge_id", value: challengeId)
                .order("rank", ascending: true)
                .execute()
                .value
            
            if !snapshots.isEmpty {
                entries = snapshots.map { $0.toLeaderboardEntry() }
                print("✅ [ChallengeSummary] Loaded \(entries.count) entries from snapshot")
                isLoading = false
                return
            }
            
            print("ℹ️ [ChallengeSummary] No snapshot found, will try RPC...")
        } catch {
            print("⚠️ [ChallengeSummary] Snapshot query failed: \(error.localizedDescription), trying RPC...")
        }
        
        // PRIORITY 2: Try the RPC (computes from daily_steps table)
        do {
            let serverEntries: [ServerLeaderboardEntry] = try await supabase
                .rpc("get_challenge_leaderboard", params: ["p_challenge_id": challengeId])
                .execute()
                .value
            
            if !serverEntries.isEmpty {
                entries = serverEntries
                    .map { $0.toLeaderboardEntry(challengeId: challengeId) }
                    .sorted { $0.rank < $1.rank }
                print("✅ [ChallengeSummary] Loaded \(entries.count) entries via RPC")
                isLoading = false
                return
            }
            print("⚠️ [ChallengeSummary] RPC returned 0 entries, trying snapshot creation...")
        } catch {
            print("⚠️ [ChallengeSummary] RPC failed: \(error.localizedDescription), trying snapshot creation...")
        }
        
        // PRIORITY 3: Create snapshot for archived challenge (if it has ended)
        if let challenge = challenge, challenge.endDate < Date() {
            print("📸 [ChallengeSummary] Challenge has ended - creating snapshot...")
            
            struct SnapshotResult: Codable {
                let userId: String
                let username: String
                let displayName: String
                let avatarUrl: String?
                let totalSteps: Int
                let rank: Int
                
                enum CodingKeys: String, CodingKey {
                    case userId = "user_id"
                    case username
                    case displayName = "display_name"
                    case avatarUrl = "avatar_url"
                    case totalSteps = "total_steps"
                    case rank
                }
            }
            
            do {
                let results: [SnapshotResult] = try await supabase
                    .rpc("snapshot_challenge_results", params: ["p_challenge_id": challengeId])
                    .execute()
                    .value
                
                entries = results.map { result in
                    LeaderboardEntry(
                        id: UUID().uuidString,
                        userId: result.userId,
                        challengeId: challengeId,
                        username: result.username,
                        displayName: result.displayName,
                        avatarURL: result.avatarUrl,
                        steps: result.totalSteps,
                        rank: result.rank,
                        lastUpdated: Date()
                    )
                }
                print("✅ [ChallengeSummary] Created snapshot with \(entries.count) participants")
                isLoading = false
                return
            } catch {
                print("⚠️ [ChallengeSummary] Snapshot creation failed: \(error.localizedDescription), trying fallback...")
            }
        }
        
        // PRIORITY 4: Fallback - query challenge_members directly
        do {
            let members: [ChallengeMember] = try await supabase
                .from("challenge_members")
                .select()
                .eq("challenge_id", value: challengeId)
                .execute()
                .value
            
            if members.isEmpty {
                print("⚠️ [ChallengeSummary] No challenge_members found for \(challengeId)")
                isLoading = false
                return
            }
            
            let userIds = members.map { $0.userId }
            
            struct ProfileRow: Codable {
                let id: String
                let username: String?
                let displayName: String?
                let avatarUrl: String?
                
                enum CodingKeys: String, CodingKey {
                    case id, username
                    case displayName = "display_name"
                    case avatarUrl = "avatar_url"
                }
            }
            
            let profiles: [ProfileRow] = try await supabase
                .from("profiles")
                .select("id, username, display_name, avatar_url")
                .in("id", values: userIds)
                .execute()
                .value
            
            let profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
            
            // Build entries from challenge_members total_steps
            var unsorted: [(userId: String, steps: Int, profile: ProfileRow?)] = []
            for member in members {
                let profile = profileMap[member.userId]
                unsorted.append((userId: member.userId, steps: member.totalSteps, profile: profile))
            }
            unsorted.sort { $0.steps > $1.steps }
            
            var builtEntries: [LeaderboardEntry] = []
            for (index, item) in unsorted.enumerated() {
                let entry = LeaderboardEntry(
                    id: UUID().uuidString,
                    userId: item.userId,
                    challengeId: challengeId,
                    username: item.profile?.username ?? "",
                    displayName: item.profile?.displayName ?? item.profile?.username ?? "User",
                    avatarURL: item.profile?.avatarUrl,
                    steps: item.steps,
                    rank: index + 1,
                    lastUpdated: Date()
                )
                builtEntries.append(entry)
            }
            
            entries = builtEntries
            print("✅ [ChallengeSummary] Loaded \(entries.count) entries via fallback (challenge_members)")
        } catch {
            print("❌ [ChallengeSummary] Fallback also failed: \(error.localizedDescription)")
        }
        #endif
        
        isLoading = false
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
    
    private var isTopThree: Bool { entry.rank <= 3 }
    
    private var rankEmoji: String? {
        switch entry.rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return nil
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                if let emoji = rankEmoji {
                    Circle()
                        .fill(isWinner ? FitCompColors.primary.opacity(0.15) : Color.secondary.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Text(emoji)
                        .font(.system(size: 18))
                } else {
                    Circle()
                        .fill(Color.secondary.opacity(0.08))
                        .frame(width: 36, height: 36)
                    Text("#\(entry.rank)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
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
                    .stroke(isWinner ? FitCompColors.primary : Color.clear, lineWidth: 2)
            )
            
            // Name and position label
            VStack(alignment: .leading, spacing: 2) {
                Text(isCurrentUser ? "You" : entry.displayName)
                    .font(.system(size: 15, weight: isTopThree ? .bold : .semibold))
                    .foregroundColor(.primary)
                
                if isWinner {
                    Text("Winner")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(FitCompColors.primary)
                } else {
                    Text(ordinalPosition(entry.rank))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Steps with label
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.steps.formatted())
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(isWinner ? FitCompColors.primary : .primary)
                Text("steps")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser ? FitCompColors.primary.opacity(0.08) : (isWinner ? FitCompColors.primary.opacity(0.1) : Color(.systemBackground)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isWinner ? FitCompColors.primary : (isCurrentUser ? FitCompColors.primary.opacity(0.3) : Color.clear), lineWidth: isWinner ? 2 : (isCurrentUser ? 1 : 0))
        )
        .shadow(color: Color.black.opacity(isWinner ? 0.08 : 0.04), radius: 8, x: 0, y: 2)
    }
    
    private func ordinalPosition(_ rank: Int) -> String {
        let suffix: String
        let ones = rank % 10
        let tens = rank % 100
        if tens >= 11 && tens <= 13 {
            suffix = "th"
        } else {
            switch ones {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(rank)\(suffix) place"
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
                        .foregroundColor(entry.rank == 1 ? FitCompColors.primary : .primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Top \(percentile)%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(FitCompColors.primary)
                    
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

