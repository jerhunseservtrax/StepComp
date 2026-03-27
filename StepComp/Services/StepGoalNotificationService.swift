//
//  StepGoalNotificationService.swift
//  FitComp
//
//  Service to send notifications when users hit step goal milestones
//  Notifies at: 50% and 100% only
//

import Foundation
import UserNotifications

@MainActor
final class StepGoalNotificationService {
    static let shared = StepGoalNotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // Milestone configurations (kept intentionally minimal to avoid notification fatigue)
    private let milestoneConfig: [(percentage: Int, threshold: Double, title: String, message: String, emoji: String)] = [
        (50, 0.50, "Halfway Hero! 🔥", "50% complete! You're crushing it!", "⚡️"),
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
        
        if let config = milestoneConfig.first(where: { $0.percentage == percentage }) {
            sendMilestoneNotification(
                percentage: config.percentage,
                title: config.title,
                message: config.message,
                emoji: config.emoji,
                steps: testSteps,
                goal: testGoal
            )
        } else {
            print("ℹ️ Unsupported test milestone: \(percentage). Supported values: \(milestoneConfig.map(\.percentage))")
        }
    }
    
    func resetTodaysMilestones() {
        clearMilestones(for: Date())
        print("🔄 Reset today's milestone tracking")
    }
    #endif
}

