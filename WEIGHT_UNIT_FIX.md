# Weight Unit Conversion Fix

## Problem
The app was displaying workout weights incorrectly. When users entered 155 lbs during a workout, it would display as 342 lbs in the workout history and progress views.

### Root Cause
The issue was a mismatch between how weights were stored and displayed:

1. **Storage**: Workout weights were being stored as raw integers (e.g., 155) without any unit metadata
2. **Display**: The `UnitPreferenceManager.formatWeight()` method assumed all weights were stored in kilograms and converted them to the user's preferred unit
3. **Result**: When displaying, 155 (stored as lbs) was treated as 155 kg and converted to 342 lbs (155 × 2.20462)

## Solution
Standardized weight storage to use **kilograms** as the base unit throughout the app, matching the existing pattern for body weight storage.

### Changes Made

#### 1. UnitPreferenceManager.swift
Added two new methods for converting workout weights:
- `convertWeightToStorage(_:)` - Converts from user's display unit (lbs/kg) to storage unit (kg)
- `convertWeightFromStorage(_:)` - Converts from storage unit (kg) to user's display unit (lbs/kg)

These are separate from the existing `formatWeight()` method which is used for body weight display.

#### 2. ActiveWorkoutView.swift
- Added `unitManager` as an observed object
- Updated weight input fields to convert entered values from display unit to kg before saving
- Updated weight display to convert stored kg values to user's preferred unit
- Changed hardcoded "LBS" label to use `unitManager.weightUnit` for proper metric/imperial support
- Updated previous set and suggested weight displays to use proper conversions

#### 3. WorkoutProgressView.swift
- Added `unitManager` as an observed object
- Updated estimated 1RM display to convert stored kg values to user's preferred unit
- Changed hardcoded "lbs" label to use `unitManager.weightUnit.lowercased()`

#### 4. EditCompletedSessionView.swift
- Added `unitManager` as an observed object
- Updated weight input/display to properly convert between storage (kg) and display units
- Added weight unit label in the UI to show current unit (LBS/KG)

#### 5. WorkoutViewModel.swift
- Added `migrateWeightsToKgIfNeeded()` method that runs once on app launch
- Migration converts all existing workout data from lbs to kg
- Migration is tracked via UserDefaults key `"weights_migrated_to_kg_v1"`
- Migration handles:
  - Completed workout sessions
  - Current active workout session (if any)
  - All weight fields: weight, previousWeight, suggestedWeight

### Data Flow

#### Input (During Workout)
1. User enters weight in their preferred unit (e.g., 155 lbs)
2. Value is converted to kg: 155 / 2.20462 = 70 kg
3. Stored as 70 (integer, in kg)

#### Display (Workout History/Progress)
1. Retrieve stored weight: 70 (in kg)
2. Convert to user's preferred unit: 70 × 2.20462 = 154 lbs
3. Display: "154 lbs"

### Migration Details
The migration runs automatically on the first app launch after this update:
- Assumes existing data was entered in imperial units (lbs)
- Converts all weights by dividing by 2.20462 (lbs to kg)
- Only runs once per installation
- Logs migration progress for debugging

### Files Modified
1. `/StepComp/Services/UnitPreferenceManager.swift`
2. `/StepComp/ViewModels/WorkoutViewModel.swift`
3. `/StepComp/Screens/Workouts/ActiveWorkoutView.swift`
4. `/StepComp/Screens/Workouts/WorkoutProgressView.swift`
5. `/StepComp/Screens/Workouts/EditCompletedSessionView.swift`

### Testing Recommendations
1. **New Users**: Enter weights and verify they display correctly
2. **Existing Users**: Check that historical workout data displays correctly after migration
3. **Unit Switching**: Test switching between imperial and metric in settings
4. **Progressive Overload**: Verify suggested weights are calculated and displayed correctly
5. **Estimated 1RM**: Confirm 1RM calculations display proper values

### Notes
- All workout weights are now stored in kg (base unit)
- Body weight was already stored in kg, so no changes needed there
- The `formatWeight()` method continues to work as before for body weight
- New conversion methods keep workout weight logic separate and clear
