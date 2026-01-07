//
//  ChallengeNotificationService.swift
//  StepComp
//
//  Service to send notifications for challenge-related events
//

import Foundation
import UserNotifications
#if canImport(Supabase)
import Supabase
#endif

@MainActor
final class ChallengeNotificationService {
    static let shared = ChallengeNotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {}
    
    // MARK: - Local Notifications
    
    /// Send a local notification when someone joins a challenge
    func sendLocalNotification(title: String, body: String, challengeId: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if let challengeId = challengeId {
            content.userInfo = ["challengeId": challengeId]
        }
        
        // Deliver immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("⚠️ Error sending notification: \(error.localizedDescription)")
            } else {
                print("✅ Local notification sent: \(title)")
            }
        }
    }
    
    // MARK: - Database Notifications
    
    /// Create a notification record in the database
    func createNotification(
        userId: String,
        type: InboxNotification.NotificationType,
        title: String,
        message: String,
        relatedId: String?
    ) async throws {
        #if canImport(Supabase)
        let notification = InboxNotification(
            id: UUID().uuidString,
            userId: userId,
            type: type,
            title: title,
            message: message,
            relatedId: relatedId,
            isRead: false,
            createdAt: Date()
        )
        
        try await supabase
            .from("notifications")
            .insert(notification)
            .execute()
        
        print("✅ Notification created in database for user \(userId)")
        
        // Post notification to update badge count
        NotificationCenter.default.post(name: .newNotificationReceived, object: nil)
        #endif
    }
    
    // MARK: - Challenge Join Notification
    
    /// Notify challenge creator when someone joins their challenge
    func notifyChallengeCreator(
        creatorId: String,
        joinerUsername: String,
        challengeName: String,
        challengeId: String
    ) async {
        // 1. Create notification in database
        do {
            try await createNotification(
                userId: creatorId,
                type: .challengeJoined,
                title: "New Member!",
                message: "\(joinerUsername) joined your challenge '\(challengeName)'",
                relatedId: challengeId
            )
            print("✅ Database notification sent to creator \(creatorId)")
        } catch {
            print("⚠️ Failed to create database notification: \(error.localizedDescription)")
        }
        
        // 2. Send local push notification (if user is creator viewing the app)
        sendLocalNotification(
            title: "New Member! 🎉",
            body: "\(joinerUsername) joined your challenge '\(challengeName)'",
            challengeId: challengeId
        )
    }
}

