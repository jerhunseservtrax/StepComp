//
//  GroupDetailsChallengePreviewView.swift
//  FitComp
//

import SwiftUI

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
            FitCompColors.background
                .ignoresSafeArea()
            
            ScrollView {
            VStack(spacing: 0) {
                    // Header with back button and title
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(FitCompColors.textPrimary)
                                .frame(width: 48, height: 48)
                                .background(Color.clear)
                        }
                        
                        Spacer()
                        
                        Text("Join Challenge")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(FitCompColors.textPrimary)
                        
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
                                .fill(FitCompColors.primary.opacity(0.4))
                                .frame(width: 80, height: 80)
                                .blur(radius: 20)
                            
                            // Trophy icon
                            Circle()
                                .fill(FitCompColors.primary)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.black)
                                )
                                .shadow(color: FitCompColors.primary.opacity(0.5), radius: 20, x: 0, y: 10)
                        }
                        .padding(.top, 24)
                        
                        // Heading
                        Text("Ready to Step Up?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(FitCompColors.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        // Subtitle
                        Text("Enter your invite code below or review the shared challenge details.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FitCompColors.textSecondary)
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
                                        .background(FitCompColors.primary)
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
                                            .fill(FitCompColors.primary.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "trophy.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color(red: 0.8, green: 0.7, blue: 0))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("HIGHEST STEP")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(FitCompColors.textSecondary)
                                            .tracking(1)
                                        
                                        Text("\(highestSteps.formatted()) steps")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(FitCompColors.textPrimary)
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
                                .foregroundColor(FitCompColors.textSecondary)
                                .tracking(1)
                                        
                                        Text("\(challengeDuration(in: challenge)) Days")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(FitCompColors.textPrimary)
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
                                                .stroke(FitCompColors.surface, lineWidth: 2)
                                        )
                                }
                                
                                    if participantCount > 3 {
                                    Circle()
                                        .fill(FitCompColors.primary)
                                            .frame(width: 40, height: 40)
                                        .overlay(
                                                Text("+\(participantCount - 3)")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.black)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(FitCompColors.surface, lineWidth: 2)
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
                                        .foregroundColor(FitCompColors.textPrimary)
                                    
                                    Text("Waiting for you!")
                                        .font(.system(size: 12))
                                    .foregroundColor(FitCompColors.textSecondary)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                    .background(FitCompColors.surface)
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
                        .background(FitCompColors.primary)
                        .cornerRadius(28)
                        .shadow(color: FitCompColors.primary.opacity(0.5), radius: 14, x: 0, y: 4)
                }
                .disabled(isLoading)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
                .background(
                    LinearGradient(
                        colors: [
                            FitCompColors.background.opacity(0),
                            FitCompColors.background,
                            FitCompColors.background
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
            FitCompColors.background.ignoresSafeArea()
            
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
        case .fun: return FitCompColors.primary
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
