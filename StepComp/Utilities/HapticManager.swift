//
//  HapticManager.swift
//  FitComp
//
//  Haptic feedback for premium app feel
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

final class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    /// Light impact - for minor interactions (tab switches, toggles)
    func light() {
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        #endif
    }
    
    /// Soft impact - for card taps, selections
    func soft() {
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred()
        #endif
    }
    
    /// Medium impact - for important actions (start challenge, send message)
    func medium() {
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        #endif
    }
    
    /// Heavy impact - for major actions (goal completion, challenge win)
    func heavy() {
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
        #endif
    }
    
    /// Rigid impact - for dramatic moments (leveling up, milestone)
    func rigid() {
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .rigid)
        impact.impactOccurred()
        #endif
    }
    
    // MARK: - Notification Feedback
    
    /// Success feedback - for completing goals, syncing data
    func success() {
        #if canImport(UIKit)
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        #endif
    }
    
    /// Warning feedback - for approaching limits, reminders
    func warning() {
        #if canImport(UIKit)
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.warning)
        #endif
    }
    
    /// Error feedback - for failed actions, errors
    func error() {
        #if canImport(UIKit)
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.error)
        #endif
    }
    
    // MARK: - Selection Feedback
    
    /// Selection changed - for pickers, sliders, segmented controls
    func selection() {
        #if canImport(UIKit)
        let selection = UISelectionFeedbackGenerator()
        selection.selectionChanged()
        #endif
    }
    
    // MARK: - Custom Patterns
    
    /// Double tap feedback - for "like" or favorite actions
    func doubleTap() {
        soft()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.soft()
        }
    }
    
    /// Achievement unlocked - dramatic celebration
    func achievement() {
        heavy()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.medium()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.light()
        }
    }
    
    /// Goal completed - satisfying completion
    func goalComplete() {
        medium()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.success()
        }
    }

    /// Rest timer completion - short, clear completion cue.
    func restTimerComplete() {
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .rigid)
        impact.prepare()
        impact.impactOccurred()

        let notification = UINotificationFeedbackGenerator()
        notification.prepare()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            notification.notificationOccurred(.success)
        }
        #endif
    }
    
    /// Sync success - quick confirmation
    func syncSuccess() {
        light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.success()
        }
    }
    
    /// Level up - exciting progression
    func levelUp() {
        rigid()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.heavy()
        }
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Add haptic feedback on tap
    func hapticFeedback(_ style: HapticStyle = .soft) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                switch style {
                case .light: HapticManager.shared.light()
                case .soft: HapticManager.shared.soft()
                case .medium: HapticManager.shared.medium()
                case .heavy: HapticManager.shared.heavy()
                case .rigid: HapticManager.shared.rigid()
                case .selection: HapticManager.shared.selection()
                }
            }
        )
    }
}

enum HapticStyle {
    case light
    case soft
    case medium
    case heavy
    case rigid
    case selection
}

