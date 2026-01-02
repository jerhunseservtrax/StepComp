//
//  InboxView.swift
//  StepComp
//
//  Inbox for notifications and invites
//

import SwiftUI

struct InboxView: View {
    let userId: String
    
    @Environment(\.dismiss) var dismiss
    @State private var notifications: [InboxNotification] = []
    @State private var isLoading = true
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: primaryYellow))
                } else if notifications.isEmpty {
                    EmptyInboxView()
                } else {
                    List {
                        ForEach(notifications) { notification in
                            InboxNotificationRow(notification: notification)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await loadNotifications()
        }
    }
    
    private func loadNotifications() async {
        isLoading = true
        // TODO: Load actual notifications from database
        // For now, show empty state
        notifications = []
        isLoading = false
    }
}

// MARK: - Empty Inbox View

struct EmptyInboxView: View {
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundColor(primaryYellow)
            
            Text("No Notifications")
                .font(.system(size: 22, weight: .bold))
            
            Text("You're all caught up! 🎉\nWe'll notify you about friend requests,\nchallenge invites, and more.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Inbox Notification Row

struct InboxNotificationRow: View {
    let notification: InboxNotification
    
    private let primaryYellow = Color(red: 0.976, green: 0.961, blue: 0.024)
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(notification.message)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(timeAgo)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(primaryYellow)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var iconName: String {
        switch notification.type {
        case .friendRequest:
            return "person.fill.badge.plus"
        case .challengeInvite:
            return "trophy.fill"
        case .challengeUpdate:
            return "bell.fill"
        case .achievement:
            return "star.fill"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .friendRequest:
            return .blue
        case .challengeInvite:
            return primaryYellow
        case .challengeUpdate:
            return .purple
        case .achievement:
            return .orange
        }
    }
    
    private var timeAgo: String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: notification.createdAt, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

