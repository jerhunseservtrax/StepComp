//
//  StackedChallengesView.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 01/05/26.
//

import SwiftUI

struct StackedChallengesView: View {
    let challenges: [Challenge]
    let currentSteps: Int
    let onChallengeTap: (Challenge) -> Void
    
    @State private var isExpanded: Bool = false
    @State private var selectedChallengeId: String? = nil
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with expand/collapse
            HStack {
                Text("Active Challenges")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                if challenges.count > 1 {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text(isExpanded ? "Stack" : "View All")
                                .font(.system(size: 14, weight: .semibold))
                            
                            Image(systemName: isExpanded ? "rectangle.stack.fill" : "square.stack.3d.up.fill")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(999)
                    }
                }
            }
            .padding(.horizontal)
            
            // Challenges display
            if challenges.count == 1 {
                // Single challenge - just show the card
                ActiveChallengeCard(
                    challenge: challenges[0],
                    currentSteps: currentSteps,
                    onTap: { onChallengeTap(challenges[0]) },
                    onViewLeaderboard: { onChallengeTap(challenges[0]) }
                )
            } else if isExpanded {
                // Expanded view - show all cards
                ExpandedChallengesView(
                    challenges: challenges,
                    currentSteps: currentSteps,
                    onChallengeTap: onChallengeTap
                )
            } else {
                // Stacked view
                StackedCardsView(
                    challenges: challenges,
                    currentSteps: currentSteps,
                    onTap: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            isExpanded = true
                        }
                    },
                    onChallengeTap: onChallengeTap
                )
            }
        }
    }
}

// MARK: - Stacked Cards View

struct StackedCardsView: View {
    let challenges: [Challenge]
    let currentSteps: Int
    let onTap: () -> Void
    let onChallengeTap: (Challenge) -> Void
    
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .top) {
                // Background stacked cards (showing depth)
                ForEach(Array(challenges.prefix(3).enumerated().reversed()), id: \.element.id) { index, challenge in
                    StackedCardPreview(
                        challenge: challenge,
                        index: index,
                        totalCount: min(challenges.count, 3)
                    )
                }
                
                // Front card (main visible card)
                MainStackedCard(
                    challenge: challenges[0],
                    totalChallenges: challenges.count,
                    currentSteps: currentSteps
                )
            }
            .frame(height: stackHeight)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
    
    private var stackHeight: CGFloat {
        let baseHeight: CGFloat = 140
        let stackOffset: CGFloat = CGFloat(min(challenges.count - 1, 2)) * 12
        return baseHeight + stackOffset
    }
}

// MARK: - Stacked Card Preview (Background cards)

struct StackedCardPreview: View {
    let challenge: Challenge
    let index: Int
    let totalCount: Int
    
    
    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(cardColor)
            .frame(height: 140)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            .offset(y: CGFloat(index) * 12)
            .scaleEffect(1.0 - CGFloat(index) * 0.03, anchor: .top)
            .opacity(1.0 - Double(index) * 0.15)
    }
    
    private var cardColor: Color {
        switch index {
        case 0: return Color(.systemBackground)
        case 1: return Color(.systemGray6)
        default: return Color(.systemGray5)
        }
    }
}

// MARK: - Main Stacked Card (Front card with content)

struct MainStackedCard: View {
    let challenge: Challenge
    let totalChallenges: Int
    let currentSteps: Int
    
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Left side - Challenge info
                VStack(alignment: .leading, spacing: 8) {
                    // Challenge count badge
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 12))
                        
                        Text("\(totalChallenges) Active Challenges")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(FitCompColors.primary)
                    .cornerRadius(999)
                    
                    // First challenge name
                    Text(challenge.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Tap hint
                    HStack(spacing: 4) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 11))
                        
                        Text("Tap to expand")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Right side - Days remaining for first challenge
                VStack(spacing: 4) {
                    Text("\(challenge.daysRemaining)")
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(.primary)
                    
                    Text("days left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
        }
        .frame(height: 140)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 4)
    }
}

// MARK: - Expanded Challenges View

struct ExpandedChallengesView: View {
    let challenges: [Challenge]
    let currentSteps: Int
    let onChallengeTap: (Challenge) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(challenges.enumerated()), id: \.element.id) { index, challenge in
                ExpandedChallengeCard(
                    challenge: challenge,
                    index: index,
                    currentSteps: currentSteps,
                    onTap: { onChallengeTap(challenge) }
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.95)),
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Expanded Challenge Card

struct ExpandedChallengeCard: View {
    let challenge: Challenge
    let index: Int
    let currentSteps: Int
    let onTap: () -> Void
    
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Left side - Index badge and challenge info
                HStack(spacing: 14) {
                    // Index badge
                    ZStack {
                        Circle()
                            .fill(badgeColor)
                            .frame(width: 36, height: 36)
                        
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(index == 0 ? .black : .white)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(challenge.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        // Category and participants
                        HStack(spacing: 8) {
                            if let category = challenge.category {
                                HStack(spacing: 4) {
                                    Image(systemName: category.icon)
                                        .font(.system(size: 10))
                                    Text(category.displayName)
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 10))
                                Text("\(challenge.participantIds.count)")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Right side - Days remaining
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(challenge.daysRemaining)")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.primary)
                    
                    Text("days")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(index == 0 ? FitCompColors.primary.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var badgeColor: Color {
        switch index {
        case 0: return FitCompColors.primary
        case 1: return Color(.systemGray3)
        case 2: return Color(.systemGray4)
        default: return Color(.systemGray5)
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleChallenges = [
        Challenge(
            name: "Morning Warriors",
            description: "Early bird challenge",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            targetSteps: 10000,
            creatorId: "1",
            participantIds: ["1", "2", "3"],
            category: .shortTerm
        ),
        Challenge(
            name: "Office Champions",
            description: "Corporate challenge",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 14, to: Date())!,
            targetSteps: 15000,
            creatorId: "1",
            participantIds: ["1", "2"],
            category: .corporate
        ),
        Challenge(
            name: "Weekend Walkers",
            description: "Weekend step challenge",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
            targetSteps: 8000,
            creatorId: "1",
            participantIds: ["1", "2", "3", "4"],
            category: .friends
        )
    ]
    
    return ScrollView {
        VStack {
            StackedChallengesView(
                challenges: sampleChallenges,
                currentSteps: 5432,
                onChallengeTap: { _ in }
            )
        }
        .padding(.vertical)
    }
    .background(Color(.systemGray6))
}

