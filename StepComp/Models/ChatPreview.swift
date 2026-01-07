//
//  ChatPreview.swift
//  StepComp
//
//  Model for displaying chat previews in the chat list
//

import Foundation

struct ChatPreview: Identifiable, Equatable {
    let id: String // Challenge ID
    let challengeName: String
    let lastMessage: String?
    let lastMessageTime: Date?
    let unreadCount: Int
    let challengeAvatarURL: String? // Could use challenge image or first participant's avatar
    
    var displayTime: String? {
        guard let time = lastMessageTime else { return nil }
        
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day], from: time, to: now)
        
        if let day = components.day, day >= 1 {
            if day == 1 {
                return "Yesterday"
            } else if day < 7 {
                return "\(day)d ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                return formatter.string(from: time)
            }
        } else if let hour = components.hour, hour >= 1 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute >= 1 {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }
    
    var hasUnread: Bool {
        unreadCount > 0
    }
}

