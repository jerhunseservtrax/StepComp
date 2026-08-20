import Foundation

/// Decides when a restored or long-running workout should be paused instead of
/// silently finished. Wall-clock time minus explicit pauses includes overnight
/// suspension, so a 6-hour threshold must never persist/sync a completed session.
enum AbandonedWorkoutPolicy {
    static let threshold: TimeInterval = 6 * 3600

    static func shouldAutoPause(
        elapsed: TimeInterval,
        isPaused: Bool,
        alreadyAutoPaused: Bool,
        threshold: TimeInterval = Self.threshold
    ) -> Bool {
        !isPaused && !alreadyAutoPaused && elapsed >= threshold
    }
}
