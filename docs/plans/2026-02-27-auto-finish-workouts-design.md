# Auto-Finish Workouts After 6 Hours Design

**Date:** February 27, 2026  
**Status:** Approved

## Overview

Automatically finish and save a workout when active time (excluding paused time) reaches 6 hours. Prevents abandoned workouts from staying "in progress" indefinitely and avoids stale session state.

## Requirements

- **Trigger:** 6 hours of active time (elapsed time excluding pauses)
- **Action:** Call existing `finishWorkout()` — save session, update metadata, clear state
- **No extra UI:** Silent auto-finish, same behavior as manual finish

## Design Decision

### Selected Approach
Check in the existing 1-second timer callback. When `elapsedTime >= 6 * 3600`, call `finishWorkout()`.

- **Pros:** Simple, no new timers, minimal code
- **Cons:** Only runs while app is foregrounded; if user backgrounds for hours, check happens when they return

### Alternative Approaches Considered
1. **Timer + foreground check** — Rejected; user preferred simpler approach
2. **BGAppRefreshTask** — Rejected; overkill, iOS doesn't guarantee execution timing

## Technical Implementation

### File to Modify
- **`StepComp/ViewModels/WorkoutViewModel.swift`**

### Changes
1. Add private constant: `private let autoFinishThreshold: TimeInterval = 6 * 3600`
2. In `startTimer()`, after updating `elapsedTime`, add:
   ```swift
   if self.elapsedTime >= self.autoFinishThreshold {
       self.finishWorkout()
   }
   ```

### Edge Cases
- **Paused:** Timer stops when paused; `elapsedTime` doesn't increase — no change needed
- **App backgrounded:** Timer suspended; check runs on next tick when app returns
- **App killed:** Session in-memory only, lost — nothing to auto-finish

## Testing

- Start workout, advance system clock (or mock time) so active time exceeds 6 hours; verify workout auto-finishes and saves correctly
