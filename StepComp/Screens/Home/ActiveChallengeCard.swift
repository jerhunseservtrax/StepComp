//
//  ActiveChallengeCard.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI
import Combine

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

