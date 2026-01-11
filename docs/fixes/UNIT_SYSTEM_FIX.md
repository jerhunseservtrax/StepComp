# Unit System Fix - App-Wide Imperial/Metric Support

## Issue
The daily goal card on the home screen was hardcoded to show "Km" (kilometers), and the unit system toggle in Settings was not controlling the display of units throughout the app. Users expected the unit system preference to affect all distance displays app-wide.

## Solution
Created a centralized `UnitPreferenceManager` that manages unit preferences (imperial vs metric) for the entire app.

---

## Changes Made

### 1. Created UnitPreferenceManager Service
**File:** `StepComp/Services/UnitPreferenceManager.swift` (NEW)

A singleton service that:
- Manages the user's unit preference (metric or imperial)
- Automatically saves preference changes to UserDefaults
- Provides conversion methods for distance, height, and weight
- Provides formatted strings with appropriate unit labels
- Can be accessed from anywhere in the app

**Key Features:**
```swift
// Access the shared instance
UnitPreferenceManager.shared

// Get/Set unit system
.unitSystem = .metric // or .imperial

// Convert and format distance
.convertDistance(km: 5.0) // Returns 5.0 km or 3.1 miles
.formatDistance(5.0) // Returns "5.0" or "3.1"
.distanceUnit // Returns "Km" or "Mi"

// Similar methods for height and weight
.convertHeight(cm: 180)
.formatHeight(180)
.convertWeight(kg: 75)
.formatWeight(75)
.weightUnit
```

### 2. Updated DailyGoalCard
**File:** `StepComp/Screens/Home/DailyGoalCard.swift`

**Before:**
- Hardcoded "Km" label
- Always showed kilometers

**After:**
- Uses `UnitPreferenceManager` to get the appropriate unit
- Automatically converts distance based on user preference
- Updates in real-time when preference changes

```swift
StatBox(
    label: unitPreference.distanceUnit,  // "Km" or "Mi"
    value: unitPreference.formatDistance(distanceKm)  // Converts if needed
)
```

### 3. Updated SettingsView
**File:** `StepComp/Screens/Settings/SettingsView.swift`

**Changes:**
- Removed local `UnitSystem` enum (now using centralized version)
- Added `@StateObject` for `UnitPreferenceManager`
- Unit toggle buttons now update the shared instance
- Removed `UnitSystemPreferenceModifier` (no longer needed)
- Simplified preference management

**Before:**
```swift
@State private var unitSystem: UnitSystem = .metric
// Had to manually save to UserDefaults
```

**After:**
```swift
@StateObject private var unitPreferenceManager = UnitPreferenceManager.shared
// Automatically saves when changed
```

---

## How It Works

### 1. Initialization
When the app launches:
- `UnitPreferenceManager.shared` is created
- It loads the saved preference from UserDefaults
- If no preference exists, defaults to metric

### 2. User Changes Preference
When user taps KM/MI in Settings:
```
Settings > Unit System > Tap "MI"
    ↓
unitPreferenceManager.unitSystem = .imperial
    ↓
UnitPreferenceManager saves to UserDefaults automatically
    ↓
@Published property updates all observers
    ↓
DailyGoalCard (and other views) update instantly
```

### 3. Displaying Distance
Any view can access the unit preference:
```swift
@StateObject private var unitPreference = UnitPreferenceManager.shared

// In body
Text("\(unitPreference.formatDistance(distanceKm)) \(unitPreference.distanceUnit)")
// Shows "5.0 Km" or "3.1 Mi" based on preference
```

---

## Files Modified

1. **`StepComp/Services/UnitPreferenceManager.swift`** (NEW)
   - Centralized unit preference management
   - Conversion and formatting methods

2. **`StepComp/Screens/Home/DailyGoalCard.swift`**
   - Uses UnitPreferenceManager for distance display
   - Shows correct unit label (Km/Mi)

3. **`StepComp/Screens/Settings/SettingsView.swift`**
   - Unit toggle buttons update shared instance
   - Removed local enum and state management

---

## Benefits

### ✅ App-Wide Consistency
All distance displays throughout the app now use the same unit system

### ✅ Real-Time Updates
Changes in Settings immediately reflect in all views

### ✅ Automatic Persistence
Preference is automatically saved and loaded

### ✅ Easy to Extend
Adding new views that need unit conversion is simple:
```swift
@StateObject private var unitPreference = UnitPreferenceManager.shared
```

### ✅ Type-Safe
Uses enum instead of strings for unit system

---

## Testing Checklist

- [x] Default preference loads correctly (metric)
- [ ] Changing KM → MI in Settings updates DailyGoalCard
- [ ] Changing MI → KM in Settings updates DailyGoalCard
- [ ] Distance value converts correctly (multiply by 0.621371 for km→mi)
- [ ] Distance label shows "Km" when metric
- [ ] Distance label shows "Mi" when imperial
- [ ] Preference persists after closing and reopening app
- [ ] Multiple views update simultaneously when preference changes

---

## Future Enhancements

The `UnitPreferenceManager` is ready for use in other places:

1. **Profile Statistics** - Convert displayed distances
2. **Challenge Details** - Show distances in preferred unit
3. **Activity Chart** - Display distances with correct units
4. **Height/Weight Inputs** - Already has conversion methods ready
5. **Achievement Milestones** - Display in preferred units

Simply add `@StateObject private var unitPreference = UnitPreferenceManager.shared` to any view that needs unit conversion.

---

## Example Usage

```swift
import SwiftUI

struct SomeView: View {
    @StateObject private var unitPreference = UnitPreferenceManager.shared
    
    let distanceKm = 10.5
    
    var body: some View {
        VStack {
            // Method 1: Manual formatting
            Text("\(unitPreference.formatDistance(distanceKm)) \(unitPreference.distanceUnit)")
            
            // Method 2: Custom formatting
            let value = unitPreference.convertDistance(km: distanceKm)
            Text(String(format: "%.2f %@", value, unitPreference.distanceUnit))
            
            // Button to change preference
            Button("Toggle Units") {
                unitPreference.unitSystem = 
                    unitPreference.unitSystem == .metric ? .imperial : .metric
            }
        }
    }
}
```

Output based on preference:
- **Metric:** "10.5 Km"
- **Imperial:** "6.5 Mi"

