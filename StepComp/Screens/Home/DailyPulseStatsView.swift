//
//  DailyPulseStatsView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

struct DailyPulseStatsView: View {
    let calories: Int
    let distanceMiles: Double
    let steps: Int
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1_000_000 {
            return String(format: "%.1fM", Double(steps) / 1_000_000.0)
        } else if steps >= 1_000 {
            return String(format: "%.1fK", Double(steps) / 1_000.0)
        }
        return "\(steps)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Pulse")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                Text("Today")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.976, green: 0.961, blue: 0.024))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 4)
            
            // Stats Grid - All three cards in one row
            HStack(spacing: 12) {
                DailyStatCard(
                    icon: "figure.walk",
                    value: formatSteps(steps),
                    label: "steps",
                    color: .green
                )
                
                DailyStatCard(
                    icon: "figure.walk",
                    value: String(format: "%.1f", distanceMiles),
                    label: "miles",
                    color: .blue
                )
                
                DailyStatCard(
                    icon: "flame.fill",
                    value: "\(calories)",
                    label: "kcal",
                    color: .orange
                )
            }
        }
    }
}

// StatCard is defined in ProfileView.swift - using DailyStatCard here for different layout
struct DailyStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
    }
}

struct StepsCard: View {
    let steps: Int
    
    var formattedSteps: String {
        if steps >= 1_000_000 {
            return String(format: "%.1fM", Double(steps) / 1_000_000.0)
        } else if steps >= 1_000 {
            return String(format: "%.1fK", Double(steps) / 1_000.0)
        }
        return "\(steps)"
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "figure.walk")
                        .foregroundColor(.green)
                        .font(.system(size: 18))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedSteps)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    
                    Text("Steps Today")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
    }
}

