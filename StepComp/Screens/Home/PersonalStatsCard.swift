//
//  PersonalStatsCard.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

struct PersonalStatsCard: View {
    let todaySteps: Int
    let weeklySteps: Int
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Your Stats")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            HStack(spacing: 32) {
                StatItem(
                    title: "Today",
                    value: "\(todaySteps.formatted())",
                    icon: "figure.walk",
                    color: .blue
                )
                
                StatItem(
                    title: "This Week",
                    value: "\(weeklySteps.formatted())",
                    icon: "calendar",
                    color: .green
                )
            }
        }
        .padding()
        .cardStyle()
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

