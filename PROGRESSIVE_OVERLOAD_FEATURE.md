# Progressive Overload & Auto-Population Feature

## Overview
Implemented intelligent workout auto-population and progressive overload suggestions to help users consistently improve their strength training performance week over week.

## What Was Changed

### 1. Model Updates (`Exercise.swift`)
**Added to `WorkoutSet` struct:**
- `suggestedWeight: Int?` - Calculated progressive overload weight target
- `suggestedReps: Int?` - Calculated progressive overload rep target

These fields store intelligent suggestions based on the user's previous performance.

### 2. ViewModel Enhancements (`WorkoutViewModel.swift`)

#### New Method: `getLastCompletedSession(for:)`
- Finds the most recent completed session for a given workout
- Matches by `workoutId` first, falls back to `workoutName` for resilience
- Returns `nil` if no previous sessions exist

#### New Method: `calculateProgressiveOverload(previousWeight:previousReps:)`
**Progressive Overload Strategy:**

| Previous Reps | Suggested Action | Reasoning |
|--------------|------------------|-----------|
| ≥ 12 reps | Increase weight by 5-10 lbs, reduce reps to 8-10 | User has built volume, ready for intensity increase |
| 8-11 reps | Add 2 more reps | Build volume in optimal hypertrophy range |
| < 8 reps | Add 3 more reps | Ensure minimum effective volume |

**Weight increment logic:**
- Weights < 50 lbs: +5 lbs increment (more manageable for isolation exercises)
- Weights ≥ 50 lbs: +10 lbs increment (appropriate for compound movements)

#### Updated: `startWorkout(_:targetDate:)`
**Now includes auto-population:**
1. Finds last completed session for the workout
2. For each exercise:
   - Matches by exercise ID or name
   - Retrieves previous weight and reps for each set
   - Auto-fills current workout with last session's data
   - Calculates progressive overload suggestions
   - Populates `previousWeight`, `previousReps`, `suggestedWeight`, `suggestedReps`

**Result:** Users start with their last performance pre-filled, plus intelligent next targets.

#### Updated: `addSet(exerciseId:)`
When dynamically adding sets during a workout:
- Uses the last set's data as baseline
- Calculates suggestions based on that set
- Ensures progressive recommendations even for extra sets

### 3. UI Enhancements (`ActiveWorkoutView.swift`)

#### Updated Exercise Card Header
**New visual indicators:**
- "Progressive" badge appears when suggestions are available
- Badge includes upward arrow icon and primary color
- Only shows for exercises with active suggestions

#### Enhanced Sets Header Row
**Changed columns:**
- ❌ Old: `SET | PREV | LBS | REPS`
- ✅ New: `SET | PREV | TARGET | LBS | REPS`

The new **TARGET** column displays progressive overload goals in the brand's primary color.

#### Redesigned `SetRow` Component

**New Features:**

1. **Tappable Suggestion Button**
   - When suggestions exist: Shows as interactive button with `→ XXlbs×XXreps`
   - Includes upward arrow icon
   - Styled with primary color and background
   - One tap applies both weight and reps
   - Provides haptic feedback on tap

2. **Target Achievement Feedback**
   - Green border on input fields when target is met or exceeded
   - "Target achieved! 🎯" message appears below the set
   - Green background tint on the entire set row
   - Visual celebration motivates continued progress

3. **Smart Border Colors**
   - Default: Light gray
   - Focused: Primary yellow color
   - Target met: Green highlight
   - Completed: Muted gray

4. **One-Tap Suggestion Application**
   ```swift
   applySuggestion() {
       // Applies both weight and reps
       // Updates text fields
       // Provides haptic feedback
   }
   ```

## User Experience Flow

### First Time Using a Workout
1. User creates a new workout with exercises and default sets
2. Starts the workout
3. All fields are empty (no previous data)
4. No suggestions shown (no baseline yet)
5. User enters their performance
6. Workout is saved as baseline

### Subsequent Workouts
1. User starts the same workout again
2. **Auto-population occurs:**
   - Weight fields pre-filled with last session's values
   - Rep fields pre-filled with last session's values
   - Previous performance shown in "PREV" column
   - Suggested improvements shown in "TARGET" column
3. User can:
   - **Option A:** Keep pre-filled values (maintain current level)
   - **Option B:** Tap suggestion button (follow progressive overload)
   - **Option C:** Manually adjust (customize as needed)
4. As user enters values meeting/exceeding targets:
   - Input borders turn green
   - "Target achieved! 🎯" appears
   - Positive reinforcement encourages progress
5. Workout completion saves new baseline for next time

## Benefits

### For Users
1. **Zero Memory Required** - Never need to remember last week's weights
2. **Clear Progression Path** - Always know what to aim for
3. **Motivation Boost** - Visual feedback rewards improvement
4. **Flexibility** - Can follow suggestions or adjust freely
5. **Consistency** - Ensures progressive training over time

### For Training Effectiveness
1. **Progressive Overload** - Core principle of strength training automated
2. **Smart Adaptation** - Algorithm adjusts to current performance level
3. **Volume Management** - Balances weight increases with rep adjustments
4. **Injury Prevention** - Incremental progressions reduce risk

## Technical Implementation

### Data Flow
```
1. User taps "Start Workout"
   ↓
2. WorkoutViewModel.startWorkout() called
   ↓
3. getLastCompletedSession() finds previous workout
   ↓
4. For each exercise/set:
   - Extract previous weight & reps
   - Calculate progressive suggestions
   - Create WorkoutSet with all data
   ↓
5. UI renders with:
   - Pre-filled inputs
   - Previous performance shown
   - Suggestions displayed
   - Target button enabled
```

### Progressive Overload Algorithm
```swift
if previousReps >= 12 {
    // User can handle more weight
    newWeight = previousWeight + (previousWeight < 50 ? 5 : 10)
    newReps = max(8, previousReps - 2)  // Drop reps with weight increase
} else if previousReps >= 8 {
    // Build volume in hypertrophy range
    newWeight = previousWeight
    newReps = previousReps + 2
} else {
    // Increase volume first
    newWeight = previousWeight
    newReps = previousReps + 3
}
```

## Examples

### Example 1: Bench Press Progression
**Week 1:**
- Set 1: 135 lbs × 10 reps ✓

**Week 2 (Auto-populated):**
- Previous: 135 × 10
- Current: 135 × 10 (pre-filled)
- Target: → 135 × 12 (build volume)
- User taps target button → now 135 × 12

**Week 3 (Auto-populated):**
- Previous: 135 × 12
- Current: 135 × 12 (pre-filled)
- Target: → 145 × 10 (increase weight)
- User achieves → green feedback appears

### Example 2: Bicep Curls Progression
**Week 1:**
- Set 1: 25 lbs × 6 reps ✓

**Week 2 (Auto-populated):**
- Previous: 25 × 6
- Current: 25 × 6 (pre-filled)
- Target: → 25 × 9 (low reps, build volume)
- User does 25 × 8 → still good progress

**Week 3 (Auto-populated):**
- Previous: 25 × 8
- Current: 25 × 8 (pre-filled)
- Target: → 25 × 10 (continue volume building)

## Code Quality

✅ **No Compilation Errors** - Build succeeds completely
✅ **No Linter Warnings** - Clean code passes all checks
✅ **Follows Existing Patterns** - Consistent with app architecture
✅ **Maintains Design System** - Uses StepCompColors throughout
✅ **Preserves User Experience** - Enhances without disrupting existing flows

## Future Enhancements

Potential additions to consider:
1. **Custom Progression Rules** - Let users set their own overload preferences
2. **Exercise-Specific Strategies** - Different rules for compound vs. isolation exercises
3. **Plateau Detection** - Suggest deload weeks when progress stalls
4. **1RM Tracking** - Calculate and display estimated one-rep max improvements
5. **Volume Tracking** - Show total weekly/monthly volume trends
6. **Strength Standards** - Compare performance to beginner/intermediate/advanced benchmarks

## Testing Recommendations

To verify the feature works correctly:

1. **Create a new workout** with 2-3 exercises
2. **Complete the workout** with various weights/reps
3. **Wait a day** (or manually adjust date)
4. **Start the same workout again**
5. **Verify:**
   - Previous values appear in "PREV" column
   - Input fields are pre-filled
   - "TARGET" column shows suggestions
   - Tapping suggestion button applies values
   - Meeting targets shows green feedback
6. **Complete and repeat** to see continued progression

## Summary

This feature transforms StepComp's workout tracking from simple logging to an intelligent training partner that:
- Remembers every workout
- Suggests progressive improvements
- Motivates with visual feedback
- Ensures consistent strength gains

Users no longer need notebooks or memory - the app automatically guides them toward their fitness goals with scientifically-backed progressive overload.
