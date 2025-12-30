//
//  DailyPulseStatsView.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

struct DailyPulseStatsView: View {
    let calories: Int
    let distance: Double
    let streak: Int
    
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
            
            // Stats Grid
            VStack(spacing: 12) {
                // Top row: Calories and Distance
                HStack(spacing: 12) {
                    DailyStatCard(
                        icon: "flame.fill",
                        value: "\(calories)",
                        label: "kcal burned",
                        color: .orange
                    )
                    
                    DailyStatCard(
                        icon: "figure.walk",
                        value: String(format: "%.1f", distance),
                        label: "km distance",
                        color: .blue
                    )
                }
                
                // Streak card (full width)
                StreakCard(days: streak)
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

struct StreakCard: View {
    let days: Int
    
    private let weekDays = ["M", "T", "W", "T", "F", "S", "S"]
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.purple)
                        .font(.system(size: 18))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(days) Days")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    
                    Text("Current Streak")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Week day indicators
            HStack(spacing: -4) {
                ForEach(Array(weekDays.prefix(4).enumerated()), id: \.offset) { index, day in
                    Circle()
                        .fill(index < 3 ? Color(red: 0.976, green: 0.961, blue: 0.024) : Color(.systemGray5))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text(day)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(index < 3 ? .black : .secondary)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
    }
}

