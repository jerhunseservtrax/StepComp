//
//  AppDelegate.swift
//  FitComp
//
//  Handles APNs registration for showing app icon in notifications
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Avoid duplicate authorization prompts; request flow is centralized in NotificationManager.
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                return
            }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
        return true
    }
    
    // Called when APNs registration succeeds
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 APNs Device Token: \(token)")
        
        // Store the token for future use (push notifications, etc.)
        UserDefaults.standard.set(token, forKey: "apnsDeviceToken")
        print("✅ Registered for remote notifications - app icon will now appear in notifications")
    }
    
    // Called when APNs registration fails
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("⚠️ Failed to register for remote notifications: \(error)")
        print("ℹ️  This is normal in Simulator - test on a real device for APNs")
        CrashReportingService.capture(error: error, context: "apns_registration")
        // Notifications will still work, but app icon may not appear in Simulator
    }
}

