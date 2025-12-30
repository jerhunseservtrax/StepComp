//
//  DashboardHeader.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

struct DashboardHeader: View {
    let user: User?
    
    var displayName: String {
        user?.displayName ?? "User"
    }
    
    var body: some View {
        HStack {
            // Avatar with status
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    displayName: displayName,
                    avatarURL: user?.avatarURL,
                    size: 48
                )
                .overlay(
                    Circle()
                        .stroke(Color(.systemBackground), lineWidth: 3)
                )
                
                // Online status indicator
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 2)
                    )
            }
            
            // Greeting
            VStack(alignment: .leading, spacing: 2) {
                Text("Hi \(displayName) 👋")
                    .font(.system(size: 20, weight: .bold))
                
                Text("Let's crush today!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Notification button
            Button(action: {}) {
                Image(systemName: "bell")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
    }
}

