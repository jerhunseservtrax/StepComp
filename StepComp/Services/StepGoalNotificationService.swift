//
//  StepGoalNotificationService.swift
//  StepComp
//
//  Service to send notifications when users hit step goal milestones
//  Notifies at: 25%, 50%, 75%, 100%, and Above & Beyond (exceeding goal)
//

import Foundation
import UserNotifications

@MainActor
final class StepGoalNotificationService {
    static let shared = StepGoalNotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // Milestone configurations
    private let milestoneConfig: [(percentage: Int, threshold: Double, title: String, message: String, emoji: String)] = [
        (25, 0.25, "Quarter Way There! 🚶", "You've hit 25% of your daily goal!", "💪"),
        (50, 0.50, "Halfway Hero! 🔥", "50% complete! You're crushing it!", "⚡️"),
        (75, 0.75, "Almost There! 🏃", "75% done! The finish line is in sight!", "🎯"),
        (100, 1.0, "Goal Achieved! 🏆", "You smashed your daily step goal!", "🎉")
    ]
    
    private init() {
        requestAuthorization()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else if let error = error {
                print("⚠️ Notification permission error: \(error.localizedDescription)")
            } else {
                print("⚠️ Notification permission denied")
            }
        }
    }
    
    // MARK: - Milestone Tracking
    
    private func getMilestonesKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "stepMilestones_\(formatter.string(from: date))"
    }
    
    private func getHitMilestones(for date: Date) -> Set<Int> {
        let key = getMilestonesKey(for: date)
        if let data = UserDefaults.standard.data(forKey: key),
           let milestones = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            return milestones
        }
        return []
    }
    
    private func markMilestoneHit(_ percentage: Int, for date: Date) {
        var milestones = getHitMilestones(for: date)
        milestones.insert(percentage)
        
        let key = getMilestonesKey(for: date)
        if let data = try? JSONEncoder().encode(milestones) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func clearMilestones(for date: Date) {
        let key = getMilestonesKey(for: date)
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    // MARK: - Check and Send Notifications
    
    func checkMilestones(currentSteps: Int, dailyGoal: Int) {
        guard dailyGoal > 0, currentSteps > 0 else { return }
        
        let today = Date()
        
        // Clear milestones from previous days (cleanup old data)
        clearOldMilestones()
        
        let hitMilestones = getHitMilestones(for: today)
        let progress = Double(currentSteps) / Double(dailyGoal)
        
        // Check each milestone
        for milestone in milestoneConfig {
            // Check if we've crossed this threshold and haven't notified yet
            if progress >= milestone.threshold && !hitMilestones.contains(milestone.percentage) {
                sendMilestoneNotification(
                    percentage: milestone.percentage,
                    title: milestone.title,
                    message: milestone.message,
                    emoji: milestone.emoji,
                    steps: currentSteps,
                    goal: dailyGoal
                )
                markMilestoneHit(milestone.percentage, for: today)
            }
        }
        
        // Check for "above and beyond" (exceeds 100%)
        // Notify at different thresholds: 110%, 125%, 150%, 200%
        let aboveAndBeyondThresholds = [
            (110, 1.10, "Above & Beyond! 🌟", "110% - You're on fire!", "🔥"),
            (125, 1.25, "Overachiever! 💫", "125% - Incredible dedication!", "⭐️"),
            (150, 1.50, "Superstar! 🚀", "150% - You're unstoppable!", "💪"),
            (200, 2.0, "Legend! 👑", "200% - Absolutely legendary!", "🏅")
        ]
        
        for threshold in aboveAndBeyondThresholds {
            if progress >= threshold.1 && !hitMilestones.contains(threshold.0) {
                sendAboveAndBeyondNotification(
                    level: threshold.0,
                    title: threshold.2,
                    message: threshold.3,
                    emoji: threshold.4,
                    steps: currentSteps,
                    goal: dailyGoal
                )
                markMilestoneHit(threshold.0, for: today)
            }
        }
    }
    
    // MARK: - Notification Content
    
    private func sendMilestoneNotification(percentage: Int, title: String, message: String, emoji: String, steps: Int, goal: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "\(message) \(emoji)\n\(formatNumber(steps)) / \(formatNumber(goal)) steps"
        content.sound = percentage == 100 ? .defaultCritical : .default
        content.badge = NSNumber(value: 1)
        
        // Category for actions
        content.categoryIdentifier = "STEP_MILESTONE"
        
        // Custom data
        content.userInfo = [
            "type": "stepMilestone",
            "percentage": percentage,
            "steps": steps,
            "goal": goal
        ]
        
        // Send immediately
        let request = UNNotificationRequest(
            identifier: "stepMilestone_\(percentage)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // nil trigger = immediate
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("⚠️ Error sending \(percentage)% milestone notification: \(error.localizedDescription)")
            } else {
                print("✅ Sent \(percentage)% milestone notification: \(steps)/\(goal) steps")
            }
        }
    }
    
    private func sendAboveAndBeyondNotification(level: Int, title: String, message: String, emoji: String, steps: Int, goal: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        
        let extraSteps = steps - goal
        content.body = "\(message) \(emoji)\n+\(formatNumber(extraSteps)) extra steps today!"
        content.sound = .defaultCritical // More prominent sound for exceeding
        content.badge = NSNumber(value: 1)
        
        // Category for actions
        content.categoryIdentifier = "STEP_ABOVE_BEYOND"
        
        // Custom data
        content.userInfo = [
            "type": "stepAboveAndBeyond",
            "level": level,
            "steps": steps,
            "goal": goal,
            "extraSteps": extraSteps
        ]
        
        let request = UNNotificationRequest(
            identifier: "stepAboveAndBeyond_\(level)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // nil trigger = immediate
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("⚠️ Error sending above and beyond (\(level)%) notification: \(error.localizedDescription)")
            } else {
                print("✅ Sent above and beyond (\(level)%) notification: \(steps)/\(goal) steps (+\(extraSteps))")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    // MARK: - Cleanup
    
    func clearOldMilestones() {
        // Clear milestones older than 7 days
        let calendar = Calendar.current
        let today = Date()
        
        for i in 1...7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                clearMilestones(for: date)
            }
        }
    }
    
    // MARK: - Manual Testing (for debugging)
    
    #if DEBUG
    func sendTestNotification(percentage: Int) {
        let testGoal = 10000
        let testSteps = Int(Double(testGoal) * Double(percentage) / 100.0)
        
        if percentage <= 100 {
            if let config = milestoneConfig.first(where: { $0.percentage == percentage }) {
                sendMilestoneNotification(
                    percentage: config.percentage,
                    title: config.title,
                    message: config.message,
                    emoji: config.emoji,
                    steps: testSteps,
                    goal: testGoal
                )
            }
        } else {
            sendAboveAndBeyondNotification(
                level: percentage,
                title: "Test Above & Beyond",
                message: "\(percentage)% test notification",
                emoji: "🧪",
                steps: testSteps,
                goal: testGoal
            )
        }
    }
    
    func resetTodaysMilestones() {
        clearMilestones(for: Date())
        print("🔄 Reset today's milestone tracking")
    }
    #endif
}

