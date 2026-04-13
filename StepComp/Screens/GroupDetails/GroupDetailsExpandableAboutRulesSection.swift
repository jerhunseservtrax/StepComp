//
//  GroupDetailsExpandableAboutRulesSection.swift
//  FitComp
//

import SwiftUI

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
                        .foregroundColor(FitCompColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(FitCompColors.textSecondary)
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
                                .foregroundColor(colorScheme == .dark ? FitCompColors.primary : Color(red: 0.9, green: 0.8, blue: 0))
                            
                            Text("About Challenge")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(FitCompColors.textPrimary)
                        }
                        
                        Text(challenge.description.isEmpty ? defaultChallengeDescription(challenge) : challenge.description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(FitCompColors.textSecondary)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(FitCompColors.textSecondary.opacity(colorScheme == .dark ? 0.1 : 0.15))
                        .frame(height: 1)
                    
                    // Challenge Rules Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("CHALLENGE RULES")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(FitCompColors.textSecondary)
                        
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
        .background(FitCompColors.surface)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func defaultChallengeDescription(_ challenge: Challenge) -> String {
        let categoryName = challenge.category?.displayName ?? "challenge"
        return "Welcome to the **\(challenge.name)**! This \(categoryName.lowercased()) challenge is designed to push your limits and help you achieve your step goals. Join now to compete with other participants and track your progress on the leaderboard."
    }
}
