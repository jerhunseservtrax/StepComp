//
//  ActiveChallengeCard.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

struct ActiveChallengeCard: View {
    let challenge: Challenge
    let currentSteps: Int
    let onTap: () -> Void
    let onViewLeaderboard: () -> Void
    
    // Primary yellow color matching design (#f9f506)
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    private var progress: Double {
        min(Double(currentSteps) / Double(challenge.targetSteps), 1.0)
    }
    
    private var progressPercentage: Int {
        Int(progress * 100)
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background decoration
                Circle()
                    .fill(primaryYellow.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .blur(radius: 40)
                    .offset(x: 80, y: -60)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack(alignment: .top) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(primaryYellow.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(primaryYellow)
                                    .font(.system(size: 18))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ACTIVE CHALLENGE")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .tracking(1)
                                
                                Text(challenge.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Spacer()
                        
                        // Timer badge
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 11))
                            Text("\(challenge.daysRemaining)d")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(primaryYellow)
                        .cornerRadius(16)
                    }
                    
                    // Progress Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(currentSteps.formatted())")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            
                            Text("/ \(challenge.targetSteps.formatted()) steps")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.systemGray6))
                                    .frame(height: 12)
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(primaryYellow)
                                    .frame(width: geometry.size.width * progress, height: 12)
                            }
                        }
                        .frame(height: 12)
                        
                        Text("\(progressPercentage)% complete")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                    
                    // Participants count
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("\(challenge.participantIds.count) participants")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: {
                            onViewLeaderboard()
                        }) {
                            HStack(spacing: 4) {
                                Text("Leaderboard")
                                    .font(.system(size: 12, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(primaryYellow)
                            .cornerRadius(16)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

// Keep the hero card for backward compatibility
struct ActiveChallengeHeroCard: View {
    let challenge: Challenge
    let currentSteps: Int
    let onViewLeaderboard: () -> Void
    
    // Primary yellow color matching design (#f9f506)
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
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
                .fill(primaryYellow.opacity(0.1))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: 100, y: -100)
            
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .top) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(primaryYellow.opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "trophy.fill")
                                .foregroundColor(primaryYellow)
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
                    .background(primaryYellow)
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
                                .fill(primaryYellow)
                                .frame(width: geometry.size.width * progress, height: 16)
                                .shadow(color: primaryYellow.opacity(0.5), radius: 8, x: 0, y: 0)
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
                    .background(primaryYellow)
                    .cornerRadius(12)
                    .shadow(color: primaryYellow.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding(24)
        }
        .background(Color(.systemBackground))
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.04), radius: 24, x: 0, y: 4)
    }
}
