//
//  InboxView.swift
//  FitComp
//
//  Inbox for notifications and invites
//

import SwiftUI
#if canImport(Supabase)
import Supabase
#endif

struct InboxView: View {
    let userId: String
    
    @Environment(\.dismiss) var dismiss
    @State private var notifications: [InboxNotification] = []
    @State private var isLoading = true
    @State private var processingInviteId: String?
    @State private var errorMessage: String?
    
    // Filter to show only unread notifications
    private var unreadNotifications: [InboxNotification] {
        notifications.filter { !$0.isRead }
    }
    
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: FitCompColors.primary))
                        .accessibilityLabel("Loading notifications")
                } else if unreadNotifications.isEmpty {
                    EmptyInboxView()
                } else {
                    List {
                        ForEach(unreadNotifications) { notification in
                            InboxNotificationRowWrapper(
                                notification: notification,
                                isProcessing: processingInviteId == notification.id,
                                onAccept: {
                                    await acceptChallengeInvite(notification: notification)
                                },
                                onDecline: {
                                    await declineChallengeInvite(notification: notification)
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Mark notification as read when tapped
                                Task {
                                    await markNotificationAsRead(notification: notification)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityHint("Dismisses the inbox")
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .refreshable {
                await loadNotifications()
            }
        }
        .task {
            await loadNotifications()
        }
        .onDisappear {
            // Refresh badge count when inbox is dismissed
            NotificationCenter.default.post(name: .notificationBadgeNeedsRefresh, object: nil)
        }
    }
    
    private func loadNotifications() async {
        let logStart = "{\"location\":\"InboxView.swift:60\",\"message\":\"Loading notifications\",\"data\":{\"userId\":\"\(userId)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"inbox-load\",\"hypothesisId\":\"H\"}\n"
        if let fileHandle = FileHandle(forWritingAtPath: DebugLog.filePath) {
            fileHandle.seekToEndOfFile()
            if let data = logStart.data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        }
        
        isLoading = true
        
        #if canImport(Supabase)
        do {
            let fetchedNotifications: [InboxNotification] = try await supabase
                .from("notifications")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value
            
            notifications = fetchedNotifications
            
            let logSuccess = "{\"location\":\"InboxView.swift:75\",\"message\":\"Notifications loaded\",\"data\":{\"count\":\(notifications.count)},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"inbox-load\",\"hypothesisId\":\"H\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: DebugLog.filePath) {
                fileHandle.seekToEndOfFile()
                if let data = logSuccess.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            
            print("✅ Loaded \(notifications.count) notifications")
        } catch {
            let logError = "{\"location\":\"InboxView.swift:85\",\"message\":\"Error loading notifications\",\"data\":{\"error\":\"\(error.localizedDescription)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"inbox-load\",\"hypothesisId\":\"I\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: DebugLog.filePath) {
                fileHandle.seekToEndOfFile()
                if let data = logError.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            
            print("⚠️ Error loading notifications: \(error.localizedDescription)")
            notifications = []
        }
        #else
        // Local fallback - no notifications
        notifications = []
        #endif
        
        isLoading = false
    }
    
    private func acceptChallengeInvite(notification: InboxNotification) async {
        guard let challengeId = notification.relatedId else { return }
        
        processingInviteId = notification.id
        
        #if canImport(Supabase)
        do {
            let logStart = "{\"location\":\"InboxView.swift:110\",\"message\":\"Accepting challenge invite\",\"data\":{\"notificationId\":\"\(notification.id)\",\"challengeId\":\"\(challengeId)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"accept-invite\",\"hypothesisId\":\"J\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: DebugLog.filePath) {
                fileHandle.seekToEndOfFile()
                if let data = logStart.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            
            // Find the challenge invite ID
            struct ChallengeInviteRecord: Codable {
                let id: String
                let challenge_id: String
                let invitee_id: String
                let status: String
            }
            
            let invites: [ChallengeInviteRecord] = try await supabase
                .from("challenge_invites")
                .select()
                .eq("challenge_id", value: challengeId)
                .eq("invitee_id", value: userId)
                .eq("status", value: "pending")
                .execute()
                .value
            
            guard let invite = invites.first else {
                errorMessage = "Invite not found or already processed"
                processingInviteId = nil
                return
            }
            
            // Call accept RPC - returns BOOLEAN directly
            let _: Bool = try await supabase
                .rpc("accept_challenge_invite", params: ["p_invite_id": invite.id])
                .execute()
                .value
            
            let logSuccess = "{\"location\":\"InboxView.swift:145\",\"message\":\"Challenge invite accepted\",\"data\":{\"inviteId\":\"\(invite.id)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"accept-invite\",\"hypothesisId\":\"J\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: DebugLog.filePath) {
                fileHandle.seekToEndOfFile()
                if let data = logSuccess.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            
            // Reload notifications
            await loadNotifications()
            processingInviteId = nil
            
            // Notify badge to refresh
            NotificationCenter.default.post(name: .notificationBadgeNeedsRefresh, object: nil)
            
        } catch {
            let logError = "{\"location\":\"InboxView.swift:160\",\"message\":\"Error accepting invite\",\"data\":{\"error\":\"\(error.localizedDescription)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"accept-invite\",\"hypothesisId\":\"K\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: DebugLog.filePath) {
                fileHandle.seekToEndOfFile()
                if let data = logError.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            
            errorMessage = "Failed to accept invite: \(error.localizedDescription)"
            processingInviteId = nil
        }
        #else
        processingInviteId = nil
        #endif
    }
    
    private func declineChallengeInvite(notification: InboxNotification) async {
        guard let challengeId = notification.relatedId else { return }
        
        processingInviteId = notification.id
        
        #if canImport(Supabase)
        do {
            let logStart = "{\"location\":\"InboxView.swift:185\",\"message\":\"Declining challenge invite\",\"data\":{\"notificationId\":\"\(notification.id)\",\"challengeId\":\"\(challengeId)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"decline-invite\",\"hypothesisId\":\"L\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: DebugLog.filePath) {
                fileHandle.seekToEndOfFile()
                if let data = logStart.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            
            // Find the challenge invite ID
            struct ChallengeInviteRecord: Codable {
                let id: String
                let challenge_id: String
                let invitee_id: String
                let status: String
            }
            
            let invites: [ChallengeInviteRecord] = try await supabase
                .from("challenge_invites")
                .select()
                .eq("challenge_id", value: challengeId)
                .eq("invitee_id", value: userId)
                .eq("status", value: "pending")
                .execute()
                .value
            
            guard let invite = invites.first else {
                errorMessage = "Invite not found or already processed"
                processingInviteId = nil
                return
            }
            
            // Call decline RPC - returns BOOLEAN directly
            let _: Bool = try await supabase
                .rpc("decline_challenge_invite", params: ["p_invite_id": invite.id])
                .execute()
                .value
            
            let logSuccess = "{\"location\":\"InboxView.swift:220\",\"message\":\"Challenge invite declined\",\"data\":{\"inviteId\":\"\(invite.id)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"decline-invite\",\"hypothesisId\":\"L\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: DebugLog.filePath) {
                fileHandle.seekToEndOfFile()
                if let data = logSuccess.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            
            // Reload notifications
            await loadNotifications()
            processingInviteId = nil
            
            // Notify badge to refresh
            NotificationCenter.default.post(name: .notificationBadgeNeedsRefresh, object: nil)
            
        } catch {
            let logError = "{\"location\":\"InboxView.swift:235\",\"message\":\"Error declining invite\",\"data\":{\"error\":\"\(error.localizedDescription)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"decline-invite\",\"hypothesisId\":\"M\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: DebugLog.filePath) {
                fileHandle.seekToEndOfFile()
                if let data = logError.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            
            errorMessage = "Failed to decline invite: \(error.localizedDescription)"
            processingInviteId = nil
        }
        #else
        processingInviteId = nil
        #endif
    }
    
    private func markNotificationAsRead(notification: InboxNotification) async {
        // Don't mark as read if already processing this notification
        guard processingInviteId != notification.id else { return }
        
        #if canImport(Supabase)
        do {
            let logStart = "{\"location\":\"InboxView.swift:320\",\"message\":\"Marking notification as read\",\"data\":{\"notificationId\":\"\(notification.id)\",\"type\":\"\(notification.type.rawValue)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"mark-read\",\"hypothesisId\":\"N1\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: DebugLog.filePath) {
                fileHandle.seekToEndOfFile()
                if let data = logStart.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            
            // Update notification to mark as read
            struct NotificationUpdate: Encodable {
                let is_read: Bool
            }
            
            try await supabase
                .from("notifications")
                .update(NotificationUpdate(is_read: true))
                .eq("id", value: notification.id)
                .execute()
            
            let logSuccess = "{\"location\":\"InboxView.swift:345\",\"message\":\"Notification marked as read\",\"data\":{\"notificationId\":\"\(notification.id)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"mark-read\",\"hypothesisId\":\"N1\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: DebugLog.filePath) {
                fileHandle.seekToEndOfFile()
                if let data = logSuccess.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            
            // Update local state - mark this notification as read
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].isRead = true
            }
            
            // Notify the badge to refresh
            NotificationCenter.default.post(name: .notificationBadgeNeedsRefresh, object: nil)
            
        } catch {
            let logError = "{\"location\":\"InboxView.swift:360\",\"message\":\"Error marking notification as read\",\"data\":{\"notificationId\":\"\(notification.id)\",\"error\":\"\(error.localizedDescription)\"},\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000)),\"sessionId\":\"debug-session\",\"runId\":\"mark-read\",\"hypothesisId\":\"N2\"}\n"
            if let fileHandle = FileHandle(forWritingAtPath: DebugLog.filePath) {
                fileHandle.seekToEndOfFile()
                if let data = logError.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
            
            print("⚠️ Error marking notification as read: \(error.localizedDescription)")
            // Don't show error to user for marking as read - it's not critical
        }
        #endif
    }
}

// MARK: - Empty Inbox View

struct EmptyInboxView: View {
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundColor(FitCompColors.primary)
            
            Text("No Notifications")
                .font(.system(size: 22, weight: .bold))
            
            Text("You're all caught up! 🎉\nWe'll notify you about friend requests,\nchallenge invites, and more.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No notifications")
        .accessibilityValue("Inbox is empty")
    }
}

// MARK: - Inbox Notification Row

struct InboxNotificationRow: View {
    let notification: InboxNotification
    let isProcessing: Bool
    let onAccept: (() async -> Void)?
    let onDecline: (() async -> Void)?
    
    private var rowAccessibilityValue: String {
        var parts = [notification.message, timeAgo]
        if !notification.isRead {
            parts.append("Unread")
        }
        return parts.joined(separator: ", ")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                        .fill(FitCompColors.primary)
                        .frame(width: 10, height: 10)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(notification.title)
            .accessibilityValue(rowAccessibilityValue)
            
            // Action buttons for challenge invites
            if notification.type == .challengeInvite && !notification.isRead {
                HStack(spacing: 12) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: FitCompColors.primary))
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel("Processing invite")
                    } else {
                        Button(action: {
                            Task {
                                await onDecline?()
                            }
                        }) {
                            Text("Decline")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .accessibilityLabel("Decline")
                        .accessibilityHint("Declines this challenge invitation")
                        
                        Button(action: {
                            Task {
                                await onAccept?()
                            }
                        }) {
                            Text("Accept")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(FitCompColors.primary)
                                .cornerRadius(8)
                        }
                        .accessibilityLabel("Accept")
                        .accessibilityHint("Joins this challenge")
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var iconName: String {
        switch notification.type {
        case .friendRequest:
            return "person.fill.badge.plus"
        case .friendRequestAccepted:
            return "person.2.fill"
        case .challengeInvite:
            return "trophy.fill"
        case .challengeUpdate:
            return "bell.fill"
        case .challengeJoined:
            return "person.2.fill"
        case .achievement:
            return "star.fill"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .friendRequest:
            return .blue
        case .friendRequestAccepted:
            return .green
        case .challengeInvite:
            return FitCompColors.primary
        case .challengeUpdate:
            return .purple
        case .challengeJoined:
            return .green
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

// MARK: - Inbox Notification Row Wrapper

struct InboxNotificationRowWrapper: View {
    let notification: InboxNotification
    let isProcessing: Bool
    let onAccept: () async -> Void
    let onDecline: () async -> Void
    
    var body: some View {
        if notification.type == .challengeInvite {
            InboxNotificationRow(
                notification: notification,
                isProcessing: isProcessing,
                onAccept: onAccept,
                onDecline: onDecline
            )
        } else {
            InboxNotificationRow(
                notification: notification,
                isProcessing: false,
                onAccept: nil,
                onDecline: nil
            )
        }
    }
}

