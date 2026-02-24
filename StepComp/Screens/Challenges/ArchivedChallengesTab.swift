//
//  ArchivedChallengesTab.swift
//  StepComp
//
//  Created by Jeffery Erhunse
//

import SwiftUI

struct ArchivedChallengesTab: View {
    @ObservedObject var sessionViewModel: SessionViewModel
    @ObservedObject var viewModel: ChallengesViewModel
    @State private var selectedChallengeId: String?
    @State private var showingChallengeSummary = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.archivedChallenges.isEmpty {
                    EmptyArchivedChallengesView()
                        .padding(.vertical, 60)
                } else {
                    // List View
                    VStack(spacing: 16) {
                        ForEach(viewModel.archivedChallenges) { challenge in
                            ArchivedChallengeListItem(
                                challenge: challenge,
                                onTap: {
                                    selectedChallengeId = challenge.id
                                    showingChallengeSummary = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 16)
        }
        .background(StepCompColors.background.ignoresSafeArea())
        .refreshable {
            await viewModel.loadChallenges()
        }
        .sheet(isPresented: $showingChallengeSummary) {
            if let challengeId = selectedChallengeId,
               let challenge = viewModel.archivedChallenges.first(where: { $0.id == challengeId }) {
                ChallengeSummaryView(
                    challengeId: challengeId,
                    challengeName: challenge.name,
                    sessionViewModel: sessionViewModel
                )
            }
        }
    }
}

// MARK: - Archived Challenge List Item

struct ArchivedChallengeListItem: View {
    let challenge: Challenge
    let onTap: () -> Void
    
    private var daysSinceEnded: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: challenge.endDate, to: Date())
        return max(0, components.day ?? 0)
    }
    
    private var endDateText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: challenge.endDate, relativeTo: Date())
    }
    
    var iconColor: Color {
        if let category = challenge.category {
            switch category {
            case .corporate: return Color.orange
            case .marathon: return Color.blue
            case .friends: return Color.purple
            case .shortTerm: return Color.green
            case .fun: return StepCompColors.primary
            }
        }
        let colors: [Color] = [Color.orange, Color.blue, StepCompColors.primary, Color.purple, Color.green]
        return colors[abs(challenge.name.hashValue) % colors.count]
    }
    
    var iconName: String {
        if let category = challenge.category {
            switch category {
            case .corporate: return "briefcase.fill"
            case .marathon: return "figure.run"
            case .friends: return "person.2.fill"
            case .shortTerm: return "bolt.fill"
            case .fun: return "party.popper.fill"
            }
        }
        let icons = ["figure.hiking", "drop.fill", "trophy.fill", "moon.fill", "tree.fill"]
        return icons[abs(challenge.name.hashValue) % icons.count]
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Left: Challenge Image/Icon (72x72)
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [iconColor.opacity(0.15), iconColor.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(iconColor.opacity(0.6))
                }
                
                // Middle: Challenge Info
                VStack(alignment: .leading, spacing: 4) {
                    // Badge and category
                    HStack(spacing: 6) {
                        Text("ENDED")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(6)
                        
                        if let category = challenge.category {
                            Text(category.displayName)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(StepCompColors.textTertiary)
                        }
                    }
                    
                    // Challenge name
                    Text(challenge.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(StepCompColors.textPrimary)
                        .lineLimit(1)
                    
                    // Participants count
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(StepCompColors.textSecondary)
                        
                        Text("\(challenge.participantIds.count) participated")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(StepCompColors.textSecondary)
                    }
                }
                
                Spacer()
                
                // Right: End date badge
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text("Ended")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(StepCompColors.textSecondary)
                    }
                    
                    Text(endDateText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(StepCompColors.textTertiary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(StepCompColors.surfaceElevated)
                .cornerRadius(12)
            }
            .padding(16)
            .background(
                ZStack {
                    // Subtle dot pattern background
                    StepCompColors.surface
                    
                    // Pattern overlay
                    GeometryReader { geometry in
                        Path { path in
                            let spacing: CGFloat = 10
                            let rows = Int(geometry.size.height / spacing) + 1
                            let cols = Int(geometry.size.width / spacing) + 1
                            
                            for row in 0..<rows {
                                for col in 0..<cols {
                                    let x = CGFloat(col) * spacing
                                    let y = CGFloat(row) * spacing
                                    path.addEllipse(in: CGRect(x: x, y: y, width: 1, height: 1))
                                }
                            }
                        }
                        .fill(StepCompColors.textPrimary.opacity(0.03))
                    }
                }
            )
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(StepCompColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: StepCompColors.shadowPrimary, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State

struct EmptyArchivedChallengesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Archived Challenges")
                .font(.system(size: 20, weight: .bold))
            
            Text("Challenges you've completed will appear here")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
}
