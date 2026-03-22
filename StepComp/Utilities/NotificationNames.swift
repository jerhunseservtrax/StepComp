//
//  NotificationNames.swift
//  FitComp
//
//  Centralized notification name definitions
//

import Foundation

extension Notification.Name {
    /// Posted when a new chat message is received
    static let chatMessageReceived = Notification.Name("chatMessageReceived")
    
    /// Posted when user navigates away from a chat view
    static let chatViewDismissed = Notification.Name("chatViewDismissed")
    
    /// Posted when a new notification is created (e.g., someone joins a challenge)
    static let newNotificationReceived = Notification.Name("newNotificationReceived")
    
    /// Posted when notifications are marked as read and badge needs to refresh
    static let notificationBadgeNeedsRefresh = Notification.Name("notificationBadgeNeedsRefresh")
}

