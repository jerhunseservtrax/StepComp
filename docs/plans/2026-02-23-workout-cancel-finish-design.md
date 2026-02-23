# Workout Cancel/Finish Feature Design

**Date:** February 23, 2026  
**Status:** Approved

## Overview

Add the ability for users to either finish and save a workout or cancel it without logging any data. This provides flexibility for users who start a workout but need to abandon it for various reasons (injury, time constraints, equipment issues, etc.).

## User Requirements

- Users need a way to end a workout session and save their progress
- Users need a way to abandon a workout without logging any data
- Both actions should require confirmation to prevent accidental data loss
- The interface should be clear about which action saves data and which discards it

## Design Decision

### Selected Approach
Rename the current "FINISH WORKOUT" button to "END WORKOUT" and present both finish and cancel options in a confirmation dialog. This approach:
- Keeps all workout-ending actions in one intuitive location
- Requires minimal UI changes
- Prevents accidental cancellations through confirmation
- Accurately reflects that the button ends the workout (regardless of method)

### Alternative Approaches Considered
1. **Keep "FINISH WORKOUT" text, add cancel to dialog** - Rejected because the button name would be misleading
2. **Separate cancel button in header** - Rejected because it requires two separate confirmation flows and adds UI complexity

## UI Specification

### Bottom Action Button
- **Current text:** "FINISH WORKOUT"
- **New text:** "END WORKOUT"
- **Icon:** Keep `"flag.checkered.2.crossed"` or change to `"flag.fill"`
- **Styling:** No changes (primary color, same dimensions)

### Confirmation Dialog
- **Title:** "End Workout"
- **Message:** "Would you like to finish and save this workout, or cancel without saving?"
- **Buttons (in order):**
  1. **"Finish Workout"** - Primary action, saves the session
  2. **"Cancel Workout"** - Destructive role (red), discards session
  3. **"Keep Training"** - Cancel role, dismisses dialog and continues workout

## Behavior Specification

### Finish Workout Action
When user selects "Finish Workout" in the dialog:
1. Calls `viewModel.finishWorkout()`
2. Creates a `CompletedWorkoutSession` with all exercise/set data
3. Saves to persistent storage (`completedSessions` array)
4. Updates the workout's `lastCompletedAt` timestamp
5. Clears widget state via `WorkoutWidgetStore.clear()`
6. Stops timer and resets all session state
7. Navigation automatically returns to previous screen

### Cancel Workout Action
When user selects "Cancel Workout" in the dialog:
1. Calls `viewModel.cancelWorkout()`
2. Discards current session (no data saved anywhere)
3. Clears widget state via `WorkoutWidgetStore.clear()`
4. Stops timer and resets all session state (`currentSession`, `sessionStartTime`, `elapsedTime`, `totalPausedTime`, `isPaused`)
5. Navigation automatically returns to previous screen

### Keep Training Action
When user selects "Keep Training":
1. Dialog dismisses
2. Workout session continues unchanged
3. Timer continues running (or remains paused if it was paused)

## Technical Implementation

### Files to Modify
- **`StepComp/Screens/Workouts/ActiveWorkoutView.swift`**

### Changes Required

1. **Line 177** - Update button text:
   ```swift
   Text("END WORKOUT")
   ```

2. **Lines 80-87** - Replace confirmation dialog:
   ```swift
   .confirmationDialog("End Workout", isPresented: $showingFinishConfirmation, titleVisibility: .visible) {
       Button("Finish Workout") {
           viewModel.finishWorkout()
       }
       Button("Cancel Workout", role: .destructive) {
           viewModel.cancelWorkout()
       }
       Button("Keep Training", role: .cancel) {}
   } message: {
       Text("Would you like to finish and save this workout, or cancel without saving?")
   }
   ```

### No ViewModel Changes Needed
The `WorkoutViewModel` already has both methods fully implemented:
- `finishWorkout()` - Saves session, updates workout metadata, clears state
- `cancelWorkout()` - Discards session, clears state

Both methods properly handle timer cleanup and widget state management.

## Error Handling

No special error handling required:
- Both actions are final (no server sync to fail)
- Local storage operations use standard UserDefaults encoding
- Navigation is automatic via SwiftUI's environment dismissal

## Testing Checklist

1. **Finish Workout Flow:**
   - Start a workout, complete some sets
   - Tap "END WORKOUT"
   - Select "Finish Workout"
   - Verify session appears in completed sessions
   - Verify workout's last completed date updates
   - Verify navigation returns to workouts list

2. **Cancel Workout Flow:**
   - Start a workout, complete some sets
   - Tap "END WORKOUT"
   - Select "Cancel Workout" (destructive/red button)
   - Verify session does NOT appear in completed sessions
   - Verify no data was saved
   - Verify navigation returns to workouts list

3. **Keep Training Flow:**
   - Start a workout
   - Tap "END WORKOUT"
   - Select "Keep Training"
   - Verify dialog dismisses
   - Verify workout continues (timer still running, data intact)

4. **Widget State:**
   - Verify widget clears after finishing workout
   - Verify widget clears after canceling workout
   - Verify widget remains active when selecting "Keep Training"

## User Impact

### Positive Impacts
- Users can abandon workouts without polluting their history
- Prevents incomplete workouts from affecting progress metrics
- Provides clear, intentional workflow for ending workouts

### Potential Issues
- Existing users may need to adjust to "END WORKOUT" button text (minor)
- Users must remember to actually tap a button (destructive is red, which helps)

## Future Enhancements (Out of Scope)

- Auto-save draft workouts for later resumption
- Partial save option (save completed sets only)
- Undo/restore recently canceled workouts
- Statistics on canceled vs completed workouts
