//
//  SettingsLayoutViews.swift
//  FitComp
//
//  Settings header, sidebar, and profile section extracted from SettingsView.swift.
//

import SwiftUI

// MARK: - Mobile Header

struct SettingsMobileHeader: View {
    var body: some View {
        HStack {
            Spacer()
            
            Text("Settings")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(FitCompColors.textPrimary)
            
            Spacer()
        }
        .padding()
        .background(FitCompColors.background)
    }
}

// MARK: - Sidebar

struct SettingsSidebar: View {
    let user: User?
    let totalSteps: Int
    let currentStreak: Int
    let totalDistanceMiles: Double
    let averageStepsThisMonth: Int
    
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Section
                    SettingsProfileSection(
                        user: user,
                        totalSteps: totalSteps,
                        currentStreak: currentStreak,
                        totalDistanceMiles: totalDistanceMiles,
                        averageStepsThisMonth: averageStepsThisMonth
                    )
                    .padding(32)
                    
                    // Version Info
                    Text("v2.4.0 (Build 390)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.top, 32)
                }
            }
        }
        .background(FitCompColors.background)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(FitCompColors.cardBorder),
            alignment: .trailing
        )
    }
}

// MARK: - Profile Section

struct SettingsProfileSection: View {
    let user: User?
    let totalSteps: Int
    let currentStreak: Int
    let totalDistanceMiles: Double
    let averageStepsThisMonth: Int
    
    @State private var showingProfileEditor = false
    @ObservedObject private var unitPreferenceManager = UnitPreferenceManager.shared
    
    
    var displayName: String {
        user?.displayName ?? "User"
    }
    
    var formattedSteps: String {
        if totalSteps >= 1_000_000 {
            return String(format: "%.1fM", Double(totalSteps) / 1_000_000.0)
        } else if totalSteps >= 1_000 {
            return String(format: "%.1fK", Double(totalSteps) / 1_000.0)
        }
        return "\(totalSteps)"
    }
    
    var formattedDistance: String {
        let totalDistanceKm = totalDistanceMiles * 1.60934
        return "\(unitPreferenceManager.formatDistance(totalDistanceKm)) \(unitPreferenceManager.distanceUnit.lowercased())"
    }
    
    var formattedAverageSteps: String {
        if averageStepsThisMonth >= 1_000 {
            return String(format: "%.1fK", Double(averageStepsThisMonth) / 1_000.0)
        }
        return "\(averageStepsThisMonth)"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    displayName: displayName,
                    avatarURL: user?.avatarURL,
                    size: 128
                )
                .overlay(
                    Circle()
                        .stroke(FitCompColors.primary, lineWidth: 4)
                )
                .shadow(color: FitCompColors.primary.opacity(0.1), radius: 10, x: 0, y: 4)
                
                // Edit button
                Button(action: {
                    showingProfileEditor = true
                }) {
                    ZStack {
                        Circle()
                            .fill(FitCompColors.primary)
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 4)
                    )
                }
            }
            .sheet(isPresented: $showingProfileEditor) {
                if let user = user {
                    ProfileSettingsView(user: user)
                }
            }
            
            // User Info
            VStack(spacing: 8) {
                Text(displayName)
                    .font(.system(size: 24, weight: .bold))
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                    Text("Step Master")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(FitCompColors.buttonTextOnPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(FitCompColors.primary.opacity(0.2))
                .cornerRadius(999)
            }
            
            // Mini Stats - 2x2 Grid
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    MiniStatCard(
                        label: "Total Steps",
                        value: formattedSteps
                    )
                    
                    MiniStatCard(
                        label: "Total Distance",
                        value: formattedDistance
                    )
                }
                
                HStack(spacing: 12) {
                    MiniStatCard(
                        label: "Current Streak",
                        value: "\(currentStreak) Days"
                    )
                    
                    MiniStatCard(
                        label: "Avg Steps/Month",
                        value: formattedAverageSteps
                    )
                }
            }
        }
    }
}

struct MiniStatCard: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(2)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(FitCompColors.surfaceElevated)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(FitCompColors.cardBorder, lineWidth: 1)
        )
    }
}
