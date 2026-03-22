//
//  LeaderboardRow.swift
//  FitComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            Text("\(entry.rank)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(rankColor)
                .frame(width: 40)
            
            // Avatar
            AvatarView(
                displayName: entry.displayName,
                avatarURL: entry.avatarURL,
                size: 50
            )
            
            // Name and Steps
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(entry.steps.formatted()) steps")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Medal icon for top 3
            if entry.rank <= 3 {
                Image(systemName: medalIcon)
                    .font(.title2)
                    .foregroundColor(medalColor)
            }
        }
        .padding()
        .background(isCurrentUser ? Color.blue.opacity(0.1) : PlatformColor.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return .primary
        }
    }
    
    private var medalIcon: String {
        switch entry.rank {
        case 1: return "medal.fill"
        case 2: return "medal.fill"
        case 3: return "medal.fill"
        default: return ""
        }
    }
    
    private var medalColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .clear
        }
    }
}

