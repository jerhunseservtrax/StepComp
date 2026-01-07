//
//  NotificationManager.swift
//  StepComp
//
//  Manages push notifications for the app
//

import Foundation
import UserNotifications
import SwiftUI
import Combine

final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isAuthorized: Bool = false
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // Notification identifiers
    private enum NotificationID {
        static let dailyRecap = "dailyRecap"
        static let leaderboardAlert = "leaderboardAlert"
        static let motivationalNudge = "motivationalNudge"
    }
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized
                
                if settings.authorizationStatus == .authorized {
                    print("✅ Notifications authorized")
                    self?.scheduleAllNotifications()
                } else {
                    print("⚠️ Notifications not authorized: \(settings.authorizationStatus.rawValue)")
                }
            }
        }
    }
    
    func requestAuthorization() async throws {
        let granted = try await notificationCenter.requestAuthorization(
            options: [.alert, .badge, .sound]
        )
        
        await MainActor.run {
            self.isAuthorized = granted
            self.authorizationStatus = granted ? .authorized : .denied
            
            if granted {
                print("✅ Notification permission granted")
                scheduleAllNotifications()
            } else {
                print("❌ Notification permission denied")
            }
        }
    }
    
    // MARK: - Schedule All Notifications
    
    func scheduleAllNotifications() {
        let dailyRecapEnabled = UserDefaults.standard.bool(forKey: "notif_dailyRecap")
        let leaderboardAlertsEnabled = UserDefaults.standard.bool(forKey: "notif_leaderboardAlerts")
        let motivationalNudgesEnabled = UserDefaults.standard.bool(forKey: "notif_motivationalNudges")
        
        // Cancel existing notifications first
        notificationCenter.removeAllPendingNotificationRequests()
        
        // Schedule based on user preferences
        if dailyRecapEnabled {
            scheduleDailyRecap()
        }
        
        if motivationalNudgesEnabled {
            scheduleMotivationalNudges()
        }
        
        // Note: Leaderboard alerts are triggered dynamically, not scheduled
        print("📅 Notifications scheduled - Recap: \(dailyRecapEnabled), Nudges: \(motivationalNudgesEnabled), Leaderboard: \(leaderboardAlertsEnabled)")
    }
    
    // MARK: - Daily Recap (8 PM every day)
    
    private func scheduleDailyRecap() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Recap 📊"
        content.body = "Check out your step summary for today!"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "dailyRecap"
        
        // Trigger at 8 PM every day
        var dateComponents = DateComponents()
        dateComponents.hour = 20 // 8 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.dailyRecap,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Error scheduling daily recap: \(error.localizedDescription)")
            } else {
                print("✅ Daily recap scheduled for 8 PM daily")
            }
        }
    }
    
    // MARK: - Motivational Nudges (10 AM, 2 PM, 6 PM)
    
    private func scheduleMotivationalNudges() {
        let nudgeTimes: [(hour: Int, minute: Int, id: String)] = [
            (10, 0, "nudge_morning"),   // 10 AM
            (14, 0, "nudge_afternoon"), // 2 PM
            (18, 0, "nudge_evening")    // 6 PM
        ]
        
        let motivationalMessages = [
            ("Morning Motivation! 🌅", "Time to get those steps in! Let's crush today's goal!"),
            ("Afternoon Boost! ⚡️", "Keep it up! You're doing great today!"),
            ("Evening Push! 🌙", "Finish strong! A few more steps before bed!")
        ]
        
        for (index, time) in nudgeTimes.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = motivationalMessages[index].0
            content.body = motivationalMessages[index].1
            content.sound = .default
            content.badge = 1  // Show badge for app icon in notification
            content.categoryIdentifier = "motivationalNudge"
            
            var dateComponents = DateComponents()
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: time.id,
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("❌ Error scheduling nudge at \(time.hour):00 - \(error.localizedDescription)")
                } else {
                    print("✅ Motivational nudge scheduled for \(time.hour):00")
                }
            }
        }
    }
    
    // MARK: - Leaderboard Alert (Triggered dynamically)
    
    func sendLeaderboardAlert(message: String, rank: Int) {
        guard UserDefaults.standard.bool(forKey: "notif_leaderboardAlerts") else {
            print("⏭️ Leaderboard alerts disabled, skipping notification")
            return
        }
        
        guard isAuthorized else {
            print("⚠️ Notifications not authorized, can't send leaderboard alert")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Leaderboard Update! 🏆"
        content.body = message
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "leaderboardAlert"
        content.userInfo = ["rank": rank]
        
        // Trigger immediately (with 1 second delay to ensure it delivers)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(NotificationID.leaderboardAlert)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Error sending leaderboard alert: \(error.localizedDescription)")
            } else {
                print("✅ Leaderboard alert sent: \(message)")
            }
        }
    }
    
    // MARK: - Instant Notification (for testing)
    
    func sendTestNotification() {
        print("🧪 sendTestNotification() called")
        print("🔐 Authorization status: \(authorizationStatus.rawValue)")
        print("✅ Is authorized: \(isAuthorized)")
        
        guard isAuthorized else {
            print("❌ Cannot send test notification - not authorized")
            print("💡 Please enable notifications in Settings")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Test Notification 🧪"
        content.body = "StepComp notifications are working!"
        content.sound = .default
        content.badge = 1
        
        // Trigger immediately (1 second delay)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "test_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        print("📤 Adding test notification request...")
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Error sending test notification: \(error.localizedDescription)")
            } else {
                print("✅ Test notification scheduled - should appear in 1 second")
                print("📱 If you don't see it, check:")
                print("   1. System Settings > StepComp > Notifications")
                print("   2. Do Not Disturb is OFF")
                print("   3. Focus mode is not blocking")
            }
        }
    }
    
    // MARK: - Update Preferences
    
    func updateNotificationPreferences(
        dailyRecap: Bool? = nil,
        leaderboardAlerts: Bool? = nil,
        motivationalNudges: Bool? = nil
    ) {
        if let dailyRecap = dailyRecap {
            UserDefaults.standard.set(dailyRecap, forKey: "notif_dailyRecap")
        }
        if let leaderboardAlerts = leaderboardAlerts {
            UserDefaults.standard.set(leaderboardAlerts, forKey: "notif_leaderboardAlerts")
        }
        if let motivationalNudges = motivationalNudges {
            UserDefaults.standard.set(motivationalNudges, forKey: "notif_motivationalNudges")
        }
        
        // Reschedule notifications with new preferences
        scheduleAllNotifications()
    }
    
    // MARK: - Clear Badge
    
    func clearBadge() {
        #if canImport(UIKit)
        if #available(iOS 16.0, *) {
            Task {
                try? await UNUserNotificationCenter.current().setBadgeCount(0)
            }
        } else {
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
        #endif
    }
    
    // MARK: - Cancel All
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        clearBadge()
        print("🗑️ All notifications cancelled")
    }
    
    // MARK: - Debug: Check Pending Notifications
    
    func checkPendingNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            print("📋 Pending notifications: \(requests.count)")
            for request in requests {
                print("   - \(request.identifier): \(request.content.title)")
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    print("     Trigger: \(trigger.dateComponents)")
                } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                    print("     Trigger: \(trigger.timeInterval) seconds")
                }
            }
        }
        
        notificationCenter.getDeliveredNotifications { notifications in
            print("📬 Delivered notifications: \(notifications.count)")
            for notification in notifications {
                print("   - \(notification.request.identifier): \(notification.request.content.title)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("📬 Notification received in foreground: \(notification.request.content.title)")
        // Show notification even when app is open
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let _ = response.notification.request.content.userInfo
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        
        print("👆 Notification tapped: \(categoryIdentifier)")
        
        // Handle different notification types
        switch categoryIdentifier {
        case "dailyRecap":
            // Navigate to home/stats
            NotificationCenter.default.post(name: .navigateToHome, object: nil)
            
        case "leaderboardAlert":
            // Navigate to challenges/leaderboard
            NotificationCenter.default.post(name: .navigateToChallenges, object: nil)
            
        case "motivationalNudge":
            // Navigate to home
            NotificationCenter.default.post(name: .navigateToHome, object: nil)
            
        default:
            break
        }
        
        completionHandler()
    }
}

// MARK: - Navigation Notification Names

extension Notification.Name {
    static let navigateToHome = Notification.Name("navigateToHome")
    static let navigateToChallenges = Notification.Name("navigateToChallenges")
}

