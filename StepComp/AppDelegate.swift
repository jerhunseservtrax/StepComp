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
        // Register for remote notifications to enable app icon in notifications
        // Even if not using push notifications yet, this ensures the app icon appears
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Notification authorization granted")
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("⚠️ Notification authorization error: \(error.localizedDescription)")
            } else {
                print("⚠️ Notification authorization denied by user")
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
        // Notifications will still work, but app icon may not appear in Simulator
    }
}

