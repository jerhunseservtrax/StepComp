//
//  DashboardHeader.swift
//  StepComp
//
//  Created by Jeffery Erhunse on 12/24/25.
//

import SwiftUI

struct DashboardHeader: View {
    let user: User?
    @State private var showingInbox = false
    @State private var unreadCount: Int = 0
    
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
            
            // Inbox/Notification button with badge
            Button(action: {
                showingInbox = true
            }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                    
                    // Badge indicator
                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .sheet(isPresented: $showingInbox) {
                InboxView(userId: user?.id ?? "")
            }
        }
        .padding(.horizontal)
        .task {
            // Load unread count
            await loadUnreadCount()
        }
    }
    
    private func loadUnreadCount() async {
        // TODO: Implement actual unread count from database
        // For now, just set to 0
        unreadCount = 0
    }
}

