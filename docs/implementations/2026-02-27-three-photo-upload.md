# Transformation Photos: Three-Photo Upload Implementation

**Date**: 2026-02-27

## Overview
Modified the transformation photo system to require three photos (front, side, back) instead of a single photo upload.

## Changes Made

### 1. Model Changes (`TransformationPhoto.swift`)
- Added `PhotoAngle` enum with cases: `.front`, `.side`, `.back`
- Updated `TransformationPhoto` struct:
  - Changed from single `filename` to three filenames: `frontFilename`, `sideFilename`, `backFilename`
  - Updated initializer to accept all three filenames

### 2. ViewModel Changes (`TransformationPhotoViewModel.swift`)
- Replaced `addPhoto()` method with `addPhotoSet()`:
  - Now accepts three UIImage parameters (frontImage, sideImage, backImage)
  - Saves all three images with consistent naming: `{uuid}_front.jpg`, `{uuid}_side.jpg`, `{uuid}_back.jpg`
- Updated `deletePhoto()`:
  - Now deletes all three photo files
- Updated `loadImage()`:
  - Added `angle: PhotoAngle` parameter to specify which photo to load
- Updated `loadLatestPhotoImage()`:
  - Uses `.front` angle as the preview image

### 3. New Upload View (`AddTransformationPhotoSetView.swift`)
Created a new dedicated view for uploading all three photos:
- **Three upload cards**: One for each angle (front, side, back)
- **Each card shows**:
  - Title with angle name
  - Image preview or placeholder
  - Camera and Library buttons
  - Checkmark when photo is selected
- **Save button**: Only enabled when all three photos are selected
- **Photo sources**: Supports both camera capture and photo library selection

### 4. Gallery View Updates (`TransformationPhotoGalleryView.swift`)
- Removed single photo upload flow (PhotosPicker and camera)
- Added `showingAddPhotoSet` state to show the new upload view
- Updated toolbar button to launch `AddTransformationPhotoSetView`
- Updated `PhotoTimelineCard`:
  - Displays all three photos side-by-side in a horizontal layout
  - Each photo shows its angle label below
  - Delete button removes all three photos
- Updated `FullScreenPhotoView`:
  - Added angle selector tabs (Front, Side, Back)
  - Smooth transition animation when switching between angles
  - Active angle highlighted with primary color

### 5. Existing Code (Unchanged)
- `TransformationPhotoCard.swift`: Works with new system (uses front photo as preview)
- Photo storage: Still uses Documents/transformation_photos directory
- Photo processing: Still uses same compression and resizing logic

## User Experience

### Upload Flow
1. User taps camera+ button in gallery
2. "Add Transformation Photos" screen appears
3. User adds photos for each angle (front, side, back) via camera or library
4. Save button enables only when all three photos are selected
5. Photos saved as a set with consistent date/ID

### Gallery View
- Timeline shows all photo sets
- Each entry displays three photos side-by-side with labels
- Tapping any photo opens full-screen view
- Delete removes entire photo set

### Full-Screen View
- Swipe or tap angle tabs to switch between front/side/back
- Smooth transitions between angles
- Date and notes shown at bottom

## File Structure
```
StepComp/
├── Models/
│   └── TransformationPhoto.swift (updated)
├── ViewModels/
│   └── TransformationPhotoViewModel.swift (updated)
└── Screens/Workouts/
    ├── AddTransformationPhotoSetView.swift (new)
    ├── TransformationPhotoGalleryView.swift (updated)
    └── TransformationPhotoCard.swift (unchanged)
```

## Notes
- All three photos are required - partial sets cannot be saved
- Photo sets share the same date and notes
- Each angle is clearly labeled in all views
- Old single-photo data will need migration or will be incompatible
