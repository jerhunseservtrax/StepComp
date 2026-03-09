# Auto-Finish Workouts After 6 Hours Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Automatically finish and save a workout when active time (excluding pauses) reaches 6 hours.

**Architecture:** Add a threshold check in the existing 1-second timer callback in `WorkoutViewModel`. When `elapsedTime >= 6 * 3600`, call `finishWorkout()`. No new timers or observers.

**Tech Stack:** Swift, SwiftUI, Foundation (Timer)

---

### Task 1: Add auto-finish threshold and check in timer

**Files:**
- Modify: `StepComp/ViewModels/WorkoutViewModel.swift`

**Step 1: Add the constant**

Add near the top of the class (after other private properties, around line 24):

```swift
private let autoFinishThreshold: TimeInterval = 6 * 3600
```

**Step 2: Add the check in startTimer()**

In `startTimer()` (around lines 317–322), add the auto-finish check after updating `elapsedTime`:

```swift
private func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
        guard let self = self, let startTime = self.sessionStartTime else { return }
        self.elapsedTime = Date().timeIntervalSince(startTime) - self.totalPausedTime

        if self.elapsedTime >= self.autoFinishThreshold {
            self.finishWorkout()
        }
    }
}
```

**Step 3: Build and verify**

Run: `xcodebuild -scheme StepComp -destination 'platform=iOS Simulator,name=iPhone 16' build`

Expected: Build succeeds

**Step 4: Commit**

```bash
git add StepComp/ViewModels/WorkoutViewModel.swift docs/plans/2026-02-27-auto-finish-workouts-design.md docs/plans/2026-02-27-auto-finish-workouts.md
git commit -m "feat: auto-finish workouts after 6 hours of active time"
```
