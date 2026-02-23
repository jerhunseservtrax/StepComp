# Workout Cancel/Finish Feature Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add cancel and finish options to workout sessions via a confirmation dialog, allowing users to either save or discard their workout data.

**Architecture:** Update the existing ActiveWorkoutView confirmation dialog to present three options: Finish Workout (saves session), Cancel Workout (discards session), and Keep Training (continues workout). The ViewModel already has both finishWorkout() and cancelWorkout() methods implemented.

**Tech Stack:** SwiftUI, existing WorkoutViewModel

---

## Task 1: Update ActiveWorkoutView Button and Dialog

**Files:**
- Modify: `StepComp/Screens/Workouts/ActiveWorkoutView.swift:177` (button text)
- Modify: `StepComp/Screens/Workouts/ActiveWorkoutView.swift:80-87` (confirmation dialog)

**Step 1: Update the button text from "FINISH WORKOUT" to "END WORKOUT"**

In `ActiveWorkoutView.swift`, locate line 177 and change:

```swift
Text("END WORKOUT")
```

**Step 2: Update the confirmation dialog to include both finish and cancel options**

Replace lines 80-87 with:

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

**Step 3: Build the project to verify no compilation errors**

Run: Build the project in Xcode (Cmd+B) or via command line
Expected: Build succeeds with no errors

**Step 4: Manual testing - Test the finish workflow**

1. Start a workout from WorkoutsView
2. Complete at least one set
3. Tap "END WORKOUT" button
4. Verify dialog shows with three options
5. Tap "Finish Workout"
6. Verify workout is saved and appears in completed sessions
7. Verify navigation returns to WorkoutsView

Expected: Workout is saved to completedSessions and visible in workout history

**Step 5: Manual testing - Test the cancel workflow**

1. Start a workout from WorkoutsView
2. Complete at least one set
3. Tap "END WORKOUT" button
4. Tap "Cancel Workout" (red/destructive button)
5. Verify workout is NOT saved to completed sessions
6. Verify navigation returns to WorkoutsView

Expected: Workout is discarded, no data saved

**Step 6: Manual testing - Test the keep training workflow**

1. Start a workout from WorkoutsView
2. Complete at least one set
3. Note the timer value
4. Tap "END WORKOUT" button
5. Tap "Keep Training"
6. Verify dialog dismisses
7. Verify workout continues (timer still running, data intact)
8. Verify can still edit sets and complete workout normally

Expected: Dialog dismisses, workout continues unchanged

**Step 7: Commit the changes**

```bash
git add StepComp/Screens/Workouts/ActiveWorkoutView.swift
git commit -m "feat: add cancel workout option to end workout dialog

Users can now choose to either finish and save their workout or cancel
it without logging any data. The END WORKOUT button presents a
confirmation dialog with three options: Finish Workout (saves), Cancel
Workout (discards), or Keep Training (continues)."
```

---

## Testing Notes

This feature requires manual testing since it involves UI interaction and data persistence verification. Key test scenarios:

1. **Finish preserves data:** Completed sets should appear in workout history
2. **Cancel discards data:** No session should be saved when canceling
3. **Keep Training maintains state:** Timer, sets, and all data should remain intact
4. **Widget state:** Verify widget clears after finish/cancel, stays active during "Keep Training"
5. **Navigation:** All three paths should properly return to/stay on correct screen

## No Additional Files Needed

The ViewModel methods (`finishWorkout()` and `cancelWorkout()`) are already fully implemented with proper state management, timer cleanup, and widget state handling. No backend changes required.
