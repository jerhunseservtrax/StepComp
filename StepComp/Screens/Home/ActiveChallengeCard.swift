//
//  ActiveChallengeCard.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine
#if canImport(Supabase)
import Supabase
#endif

struct ActiveChallengeCard: View {
    let challenge: Challenge
    let currentSteps: Int
    let onTap: () -> Void
    let onViewLeaderboard: () -> Void
    
    // Primary yellow color matching design (#f9f506)
    
    @State private var memberProfiles: [MemberProfile] = []
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Left side - Challenge name and member avatars
                VStack(alignment: .leading, spacing: 12) {
                    Text(challenge.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    // Overlapping member avatars
                    // Use challenge.participantIds.count for accurate participant count
                    // memberProfiles is limited to 4 for display purposes only
                    OverlappingAvatars(
                        profiles: memberProfiles,
                        totalCount: challenge.participantIds.count
                    )
                }
                
                Spacer()
                
                // Right side - Days remaining
                VStack(spacing: 4) {
                    Text("\(challenge.daysRemaining)")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.primary)
                    
                    Text("days left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .task {
            await loadMemberProfiles()
        }
    }
    
    private func loadMemberProfiles() async {
        #if canImport(Supabase)
        do {
            // Debug: Log participant IDs to verify count
            print("🔍 [ActiveChallengeCard] Loading profiles for challenge: \(challenge.name)")
            print("  → Participant IDs count: \(challenge.participantIds.count)")
            print("  → Participant IDs: \(challenge.participantIds)")
            
            // Fetch profiles for participant IDs
            struct ProfileRow: Codable {
                let id: String
                let username: String?
                let displayName: String?
                let avatarUrl: String?
                
                enum CodingKeys: String, CodingKey {
                    case id
                    case username
                    case displayName = "display_name"
                    case avatarUrl = "avatar_url"
                }
            }
            
            // Don't limit the query - fetch all profiles first, then limit display
            let profiles: [ProfileRow] = try await supabase
                .from("profiles")
                .select()
                .in("id", values: challenge.participantIds)
                .execute()
                .value
            
            print("  → Loaded \(profiles.count) profiles from database")
            
            memberProfiles = profiles.map { profile in
                MemberProfile(
                    id: profile.id,
                    displayName: profile.displayName ?? profile.username ?? "User",
                    avatarUrl: profile.avatarUrl
                )
            }
            
            print("  → Member profiles count: \(memberProfiles.count)")
        } catch {
            print("❌ [ActiveChallengeCard] Failed to load member profiles: \(error)")
            if let nsError = error as NSError? {
                print("  → Error domain: \(nsError.domain), code: \(nsError.code)")
                print("  → Error userInfo: \(nsError.userInfo)")
            }
        }
        #endif
    }
}

// MARK: - Overlapping Avatars Component

struct OverlappingAvatars: View {
    let profiles: [MemberProfile]
    let totalCount: Int
    private let avatarSize: CGFloat = 40
    private let overlap: CGFloat = 12
    
    var body: some View {
        HStack(spacing: -overlap) {
            ForEach(Array(profiles.prefix(4).enumerated()), id: \.element.id) { index, profile in
                AsyncImage(url: URL(string: profile.avatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Text(profile.displayName.prefix(1).uppercased())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                        )
                }
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color(.systemBackground), lineWidth: 2)
                )
                .zIndex(Double(profiles.count - index))
            }
            
            // "+X more" indicator if there are more members than shown
            if totalCount > 4 {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay(
                        Text("+\(max(0, totalCount - 4))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    )
                    .zIndex(0)
            }
        }
    }
}

// MARK: - Member Profile Model

struct MemberProfile: Identifiable {
    let id: String
    let displayName: String
    let avatarUrl: String?
}

// Keep the hero card for backward compatibility
struct ActiveChallengeHeroCard: View {
    let challenge: Challenge
    let currentSteps: Int
    let onViewLeaderboard: () -> Void
    
    // Primary yellow color matching design (#f9f506)
    
    private var progress: Double {
        min(Double(currentSteps) / Double(challenge.targetSteps), 1.0)
    }
    
    private var progressPercentage: Int {
        Int(progress * 100)
    }
    
    var body: some View {
        ZStack {
            // Background decoration
            Circle()
                .fill(StepCompColors.primary.opacity(0.1))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: 100, y: -100)
            
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .top) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(StepCompColors.primary.opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "trophy.fill")
                                .foregroundColor(StepCompColors.primary)
                                .font(.system(size: 20))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ACTIVE CHALLENGE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(1)
                            
                            Text(challenge.name)
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    
                    Spacer()
                    
                    // Timer badge
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 12))
                        Text("\(challenge.daysRemaining)d left")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(StepCompColors.primary)
                    .cornerRadius(20)
                }
                
                // Progress Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(currentSteps.formatted())")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        
                        Text("/ \(challenge.targetSteps.formatted()) steps")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                                .frame(height: 16)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(StepCompColors.primary)
                                .frame(width: geometry.size.width * progress, height: 16)
                                .shadow(color: StepCompColors.primary.opacity(0.5), radius: 8, x: 0, y: 0)
                        }
                    }
                    .frame(height: 16)
                    
                    Text("You're in the top 10%! Keep pushing! 🔥")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                // CTA Button
                Button(action: onViewLeaderboard) {
                    HStack {
                        Text("View Leaderboard")
                            .fontWeight(.bold)
                        Spacer()
                        Image(systemName: "arrow.forward")
                    }
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(StepCompColors.primary)
                    .cornerRadius(12)
                    .shadow(color: StepCompColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding(24)
        }
        .background(Color(.systemBackground))
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.04), radius: 24, x: 0, y: 4)
    }
}
