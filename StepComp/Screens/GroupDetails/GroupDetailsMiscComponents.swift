//
//  GroupDetailsMiscComponents.swift
//  FitComp
//

import SwiftUI

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
                        .foregroundColor(FitCompColors.textSecondary)
                    
                    Text(upperLabel)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(FitCompColors.textSecondary)
                }
                
                Spacer()
                
                // Decorative icon (faded)
                Image(systemName: showProgress ? "timer" : "flag")
                    .font(.system(size: 32))
                    .foregroundColor(FitCompColors.textSecondary.opacity(0.1))
            }
            .padding(.bottom, 12)
            
            Spacer()
            
            // Value
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(FitCompColors.textPrimary)
            
            // Label
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(FitCompColors.textSecondary)
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
        .background(FitCompColors.surface)
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
                    .foregroundColor(FitCompColors.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(FitCompColors.textSecondary)
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
                    .foregroundColor(FitCompColors.textTertiary)
            }
            
            Spacer()
            
            // Value
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(FitCompColors.textPrimary)
            
            // Label
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .tracking(0.5)
                .foregroundColor(FitCompColors.textSecondary)
            
            // Progress indicator
            if showProgress {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(FitCompColors.surfaceElevated)
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
                            .fill(index == 0 ? iconColor : FitCompColors.textTertiary)
                            .frame(width: 8, height: 8)
                    }
                    
                    Spacer()
                    
                    // Progress line with flag
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(FitCompColors.textTertiary)
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
        .background(FitCompColors.surface)
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
                    .foregroundColor(FitCompColors.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(FitCompColors.textSecondary)
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
                                FitCompColors.primary.opacity(0.8),
                                FitCompColors.primary.opacity(0.4)
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
                .foregroundColor(FitCompColors.primary)
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
                .background(FitCompColors.primary)
                .cornerRadius(999)
                .shadow(color: FitCompColors.primary.opacity(0.4), radius: 20, x: 0, y: 8)
            }
            .disabled(isLoading)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
}
