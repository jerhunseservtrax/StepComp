# Weight Tracking & Fitness Transformation Photos - Design Document

**Date:** February 23, 2026  
**Status:** Approved  
**Features:** Weight Tracking with Graph, Transformation Photo Gallery

---

## Overview

This design adds two new features to the Workouts page to help users track their fitness journey:

1. **Weight Tracking Card** - Replaces the Steps card, allows users to log weight entries and view trends over time
2. **Transformation Photo Card** - New card for users to document their fitness transformation with timestamped photos

Both features use local storage (UserDefaults + Documents directory) to maintain architectural consistency with existing workout data patterns.

---

## Architecture

### Data Models

**WeightEntry.swift** (new file)
```swift
struct WeightEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let weightKg: Double  // Store in kg internally
    let source: WeightSource
    
    enum WeightSource: String, Codable {
        case manual      // User entered manually
        case healthKit   // Synced from HealthKit
    }
}
```

**TransformationPhoto.swift** (new file)
```swift
struct TransformationPhoto: Identifiable, Codable {
    let id: UUID
    let date: Date
    let filename: String  // Stored in Documents/transformation_photos/
    var note: String?     // Optional note about progress
}
```

### View Models

**WeightViewModel.swift** (new file)
- Singleton pattern (like WorkoutViewModel.shared)
- Manages weight entries array
- Handles UserDefaults persistence (key: `weight_entries`)
- Integrates with HealthKitService for bidirectional sync
- Provides latest weight for card display
- Generates graph data for past 90 days

**TransformationPhotoViewModel.swift** (new file)
- Singleton pattern
- Manages photo metadata array
- Handles UserDefaults persistence (key: `transformation_photos`)
- Saves photos to Documents/transformation_photos/
- Compresses images (JPEG 0.8 quality, max 1200px)
- Provides latest photo for card display

### UI Components

**Modified Files:**
- `WorkoutsView.swift`: Remove Steps card (lines 93-101), add Weight + Photo cards

**New Files:**
- `WeightTrackingCard.swift` - Card component for WorkoutsView
- `WeightEntryView.swift` - Sheet for weight entry/viewing with graph
- `TransformationPhotoCard.swift` - Card component for WorkoutsView  
- `TransformationPhotoGalleryView.swift` - Sheet for photo gallery/timeline

---

## Data Flow

### Weight Tracking Flow

```
User enters weight → WeightViewModel
    ↓
    ├─→ Save to UserDefaults (weight_entries)
    └─→ Write to HealthKit (if authorized)

On app launch:
    Load from UserDefaults → Check HealthKit for updates → Merge & display
```

### Photo Storage Flow

```
User selects photo → PHPickerViewController
    ↓
TransformationPhotoViewModel
    ↓
    ├─→ Compress image (JPEG, 0.8 quality, max 1200px)
    ├─→ Save to Documents/transformation_photos/{uuid}.jpg
    └─→ Save metadata to UserDefaults (transformation_photos)
```

---

## UI/UX Design

### WorkoutsView Changes

**Current Layout (line 82-103):**
```swift
HStack(spacing: 12) {
    PersonalBestCard(icon: "scalemass.fill", label: "Weight", ...)
    PersonalBestCard(icon: "figure.walk", label: "Steps Today", ...)
}
```

**New Layout:**
```swift
HStack(spacing: 12) {
    WeightTrackingCard(viewModel: weightViewModel, unitManager: unitManager)
    TransformationPhotoCard(viewModel: photoViewModel)
}
// Steps card removed entirely
```

### Weight Tracking Card

**Visual Design:**
- Icon: `scalemass.fill` with circular background
- Background: `StepCompColors.primary` (yellow)
- Display: Latest weight value + unit (from UnitPreferenceManager)
- Empty state: "Add Weight" text
- Tap action: Opens WeightEntryView sheet

**Matches existing PersonalBestCard style** (lines 622-675)

### Transformation Photo Card

**Visual Design:**
- Icon: `camera.fill` with circular background
- Background: Dark card (colorScheme-aware)
- Display: Thumbnail of latest photo OR camera icon
- Date stamp below thumbnail
- Empty state: "Add Photos" text
- Tap action: Opens TransformationPhotoGalleryView sheet

**Follows PersonalBestCard pattern for consistency**

### Weight Entry View (Sheet)

**Layout Sections:**

1. **Header**
   - Title: "Weight Tracking"
   - Close button (top-right)

2. **Date Picker**
   - Horizontal date selector (similar to workout date selector)
   - Defaults to today
   - Cannot select future dates

3. **Weight Input**
   - Large number input with decimal pad
   - Unit toggle button (kg/lbs from UnitPreferenceManager)
   - Save button (prominent, StepCompColors.primary)

4. **Line Graph** (SwiftUI Charts)
   - X-axis: Last 90 days
   - Y-axis: Weight values
   - Simple line with dots for each entry
   - Dots are tappable to show exact value
   - Empty state: "Add weight entries to see trends"

5. **Recent Entries List**
   - Last 10 entries
   - Shows: Date, Weight + unit, Source badge (HealthKit/Manual)
   - Swipe to delete
   - Empty state: "No weight entries yet"

### Transformation Photo Gallery View (Sheet)

**Layout Sections:**

1. **Header**
   - Title: "Transformation Photos"
   - Close button (top-left)
   - Add photo button (top-right, camera icon)

2. **Timeline View**
   - Vertical ScrollView
   - Full-width photo cards
   - Each card shows:
     - Photo (aspect-fill, rounded corners)
     - Date overlay (top-left)
     - Optional note below photo
     - Delete button (top-right, trash icon)
   - Sorted by date (newest first)

3. **Empty State**
   - Camera icon illustration
   - "No transformation photos yet"
   - "Document your fitness journey" subtitle
   - "Add First Photo" button

4. **Add Photo Flow**
   - PHPickerViewController for photo selection
   - Optional note text field
   - Auto-saves with current date

---

## Data Persistence

### Weight Entries
- **Storage**: UserDefaults
- **Key**: `weight_entries`
- **Format**: JSON array of WeightEntry objects
- **HealthKit Integration**:
  - Read: On app launch, check for latest HealthKit weight
  - Write: Every manual entry saved to HealthKit (if authorized)
  - Merge strategy: If HealthKit has newer data, add to local entries

### Transformation Photos
- **Metadata Storage**: UserDefaults
  - **Key**: `transformation_photos`
  - **Format**: JSON array of TransformationPhoto objects
- **Photo Storage**: File system
  - **Path**: `Documents/transformation_photos/`
  - **Naming**: `{uuid}.jpg`
  - **Compression**: JPEG quality 0.8, max dimension 1200px

---

## Error Handling

### Weight Tracking
- **HealthKit not authorized**: Show inline prompt, continue with manual entry
- **HealthKit unavailable**: Gracefully degrade to manual-only mode
- **Invalid weight**: Validate range (20-500 kg / 44-1100 lbs), show error
- **No entries**: Show empty state with "Add your first weight" prompt
- **Duplicate dates**: Allow multiple entries per day

### Photo Storage
- **Picker cancelled**: No action, sheet remains open
- **Compression fails**: Show error alert, don't save
- **Disk space full**: Alert user, suggest deleting old photos
- **Load failure**: Show placeholder with retry button
- **No camera permission**: Alert user to enable in Settings
- **Empty gallery**: Show friendly empty state

---

## Integration with Existing Code

### HealthKitService.swift
- Already has `getWeight()` function (lines 358-394)
- Need to add: `saveWeight(weight: Double, date: Date)` function
- Already requests weight permissions (lines 153-154)

### UnitPreferenceManager.swift
- Already handles weight unit conversion
- Use `formatWeight()` for display
- Use `convertWeightFromStorage()` and `convertWeightToStorage()` for unit handling

### WorkoutsView.swift
- Remove Steps card (lines 93-101)
- Add state variables for sheets:
  ```swift
  @State private var showingWeightEntry = false
  @State private var showingPhotoGallery = false
  ```
- Add view model references:
  ```swift
  @ObservedObject var weightViewModel = WeightViewModel.shared
  @ObservedObject var photoViewModel = TransformationPhotoViewModel.shared
  ```

---

## File Structure

### New Files to Create

**Models:**
- `StepComp/Models/WeightEntry.swift`
- `StepComp/Models/TransformationPhoto.swift`

**View Models:**
- `StepComp/ViewModels/WeightViewModel.swift`
- `StepComp/ViewModels/TransformationPhotoViewModel.swift`

**Views:**
- `StepComp/Screens/Workouts/WeightTrackingCard.swift`
- `StepComp/Screens/Workouts/WeightEntryView.swift`
- `StepComp/Screens/Workouts/TransformationPhotoCard.swift`
- `StepComp/Screens/Workouts/TransformationPhotoGalleryView.swift`

**Modified Files:**
- `StepComp/Screens/Workouts/WorkoutsView.swift` (remove Steps card, add new cards)
- `StepComp/Services/HealthKitService.swift` (add saveWeight function)

---

## Technical Decisions

### Why UserDefaults + Documents?
- Consistent with existing workout data storage pattern
- No network dependency
- Simple implementation
- Works offline
- Matches user's preference for local storage

### Why HealthKit Integration?
- Leverages existing weight data if user tracks it
- Provides seamless two-way sync
- Native iOS experience
- No duplicate data entry needed

### Why SwiftUI Charts?
- Native, modern charting solution
- Lightweight (no third-party dependencies)
- Smooth animations
- Accessible by default

### Why Local Photo Storage?
- Privacy-first approach
- No cloud storage costs
- Fast loading
- Works offline
- User controls the data

---

## Future Enhancements (Out of Scope)

- Export photos to Photos app
- Share transformation photos
- Weight goal setting with progress tracking
- Body measurements tracking (waist, chest, etc.)
- Photo comparison view (before/after slider)
- Supabase sync option for cloud backup
- BMI calculation and tracking
- Weight prediction based on trends

---

## Testing Checklist

### Weight Tracking
- [ ] Save weight entry to UserDefaults
- [ ] Load weight entries on app launch
- [ ] Display latest weight on card
- [ ] Graph renders correctly with various data ranges
- [ ] Unit conversion works (kg ↔ lbs)
- [ ] HealthKit sync (read existing weight)
- [ ] HealthKit sync (write new weight)
- [ ] HealthKit unauthorized state (graceful degradation)
- [ ] Date validation (prevent future dates)
- [ ] Delete weight entry
- [ ] Empty state displays correctly

### Transformation Photos
- [ ] Select photo from library
- [ ] Compress and save photo to Documents
- [ ] Save metadata to UserDefaults
- [ ] Load photos on gallery open
- [ ] Display latest photo thumbnail on card
- [ ] Delete photo (removes file + metadata)
- [ ] Add optional note to photo
- [ ] Empty state displays correctly
- [ ] Photo picker cancellation handling
- [ ] Disk space error handling

### UI/UX
- [ ] Weight card matches design system
- [ ] Photo card matches design system
- [ ] Cards are tappable with proper feedback
- [ ] Sheets open/close smoothly
- [ ] Graph is interactive (tap dots for values)
- [ ] Photo gallery scrolls smoothly
- [ ] Dark mode support
- [ ] Unit preference persistence

---

## Success Metrics

**User Engagement:**
- Users log weight at least once per week
- Users upload transformation photos at least once per month
- Weight tracking used by 60%+ of active users
- Photo feature used by 40%+ of active users

**Technical:**
- Graph renders in <100ms for 90 days of data
- Photo gallery loads in <500ms with 50+ photos
- No crashes related to photo storage
- HealthKit sync success rate >95%

---

## Summary

This design adds two powerful features to help users track their fitness journey. Weight tracking provides data-driven insights into progress, while transformation photos offer visual motivation. Both features maintain architectural consistency with existing patterns, prioritize user privacy, and integrate seamlessly with the current workout-focused UI.
