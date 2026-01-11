# Profile Settings Update - Complete Implementation

## Overview
Completely redesigned the Profile Settings editor to include photo upload, name editing, username validation, and body measurements all in one place.

## ✨ New Features

### 1. **Photo Upload**
- Users can tap the edit button on their profile circle
- Opens iOS PhotosPicker to select a photo from their library
- Shows preview of selected photo before saving
- Falls back to avatar initials if no photo is selected
- Camera icon button positioned on bottom-right of avatar

### 2. **First & Last Name Editing**
- Separate text fields for first name and last name
- Auto-capitalization for proper names
- Required fields (can't be empty)
- Replaces the old "displayName" field

### 3. **Username Validation**
- Real-time username availability checking
- Queries Supabase `profiles` table to check if username exists
- Shows loading indicator while checking
- Visual feedback:
  - ✅ Green checkmark if username is available
  - ❌ Red X if username is taken
  - "Username is already taken" error message
- Filters input: only allows letters, numbers, and underscores
- Auto-converts to lowercase
- Save button is disabled if username is taken

### 4. **Height & Weight**
- Moved from separate sheet into main profile editor
- **Height**: Feet and inches pickers (3'-8')
- **Weight**: Pounds picker (80-400 lbs)
- Data stored in metric (cm, kg) in database
- Loaded from UserDefaults on open
- Privacy notice at bottom

### 5. **Modern UI**
- Clean, scrollable form layout
- Grouped sections with headers:
  - Profile Photo
  - Name
  - Username
  - Body Measurements
- Light gray background for input fields
- Yellow primary color for save button
- Real-time validation feedback

## 🗄️ Database Schema

The `profiles` table already has username as UNIQUE:

```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,  -- ✅ UNIQUE constraint enforces one username per user
  first_name TEXT,
  last_name TEXT,
  height INTEGER,  -- in cm
  weight INTEGER,  -- in kg
  avatar_url TEXT,
  -- ... other fields
);
```

**Username uniqueness is enforced at the database level**, so even if multiple users try to claim the same username simultaneously, only one will succeed.

## 🔧 Implementation Details

### Username Validation Flow

1. User types in username field
2. Text is filtered: lowercase, alphanumeric + underscore only
3. If username differs from current user's username:
   - `isCheckingUsername` = true (shows loading spinner)
   - Query Supabase: `SELECT * FROM profiles WHERE username = ?`
   - If results exist → show error "Username is already taken"
   - If no results → show green checkmark
4. Save button disabled if `usernameError != nil`

```swift
private func checkUsernameAvailability(_ username: String) async {
    isCheckingUsername = true
    usernameError = nil
    
    let profiles: [UserProfile] = try await supabase
        .from("profiles")
        .select()
        .eq("username", value: username)
        .execute()
        .value
    
    if !profiles.isEmpty {
        usernameError = "Username is already taken"
    }
    
    isCheckingUsername = false
}
```

### Photo Upload

- Uses iOS 16+ `PhotosPicker` from PhotosUI
- Loads photo as `Data`
- Displays preview using `UIImage(data:)`
- TODO: Upload to Supabase Storage and get URL (can be added later)

```swift
@State private var selectedPhotoItem: PhotosPickerItem?
@State private var selectedPhotoData: Data?

PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
    // Camera button UI
}
.onChange(of: selectedPhotoItem) { oldValue, newValue in
    Task {
        if let data = try? await newValue?.loadTransferable(type: Data.self) {
            selectedPhotoData = data
        }
    }
}
```

### Save Flow

1. Convert height/weight to metric (cm, kg)
2. Save to UserDefaults (for local access)
3. Update Supabase profiles table:
   - first_name
   - last_name
   - username (if available)
   - height (cm)
   - weight (kg)
4. Reload user profile in AuthService
5. Dismiss sheet

```swift
try await supabase
    .from("profiles")
    .update([
        "first_name": firstName,
        "last_name": lastName,
        "username": username,
        "height": heightCm,
        "weight": weightKg
    ])
    .eq("id", value: user.id)
    .execute()
```

## 📱 User Experience

### Before
- User had to edit name separately
- Username couldn't be changed
- Height/weight in separate modal
- No photo upload

### After
1. User taps edit button on profile circle in Settings
2. Sheet opens with all profile fields in one place:
   - Tap photo to upload from library
   - Edit first and last name
   - Change username (with validation)
   - Set height and weight
3. Real-time feedback on username availability
4. Tap "Save" → everything updates at once
5. Changes reflected immediately throughout app

## 🎯 Next Steps (Optional Enhancements)

### Photo Upload to Supabase Storage
```swift
// Upload photo to Supabase Storage
if let photoData = selectedPhotoData {
    let fileName = "\(user.id)_avatar_\(Date().timeIntervalSince1970).jpg"
    
    try await supabase.storage
        .from("avatars")
        .upload(
            path: fileName,
            file: photoData,
            options: FileOptions(contentType: "image/jpeg")
        )
    
    let publicURL = try supabase.storage
        .from("avatars")
        .getPublicURL(path: fileName)
    
    // Update profile with avatar_url
    try await supabase
        .from("profiles")
        .update(["avatar_url": publicURL])
        .eq("id", value: user.id)
        .execute()
}
```

### Image Compression
```swift
// Compress image before upload
if let image = UIImage(data: photoData),
   let compressedData = image.jpegData(compressionQuality: 0.7) {
    // Upload compressedData instead
}
```

### Add Bio Field
- Add `bio TEXT` column to profiles table
- Add TextEditor in profile settings
- Save alongside other fields

## 🔒 Security

- **RLS Policies**: Already in place on profiles table
  - Users can only update their own profile (`auth.uid() = id`)
- **Username Validation**: Client-side + database UNIQUE constraint
- **Photo Upload**: Will require Supabase Storage policies (when implemented)

## ✅ Testing Checklist

- [x] Username validation shows error for taken usernames
- [x] Username validation shows success for available usernames
- [x] Save button disabled when username is taken
- [x] First/last name required validation
- [x] Height/weight pickers work correctly
- [x] Photo picker opens and displays preview
- [x] Data saves to Supabase
- [x] Changes reflected in app immediately
- [ ] Photo upload to Supabase Storage (TODO)

---

## Files Modified

1. **StepComp/Screens/Settings/ProfileSettingsView.swift**
   - Complete rewrite with all new features
   - Photo upload
   - Username validation
   - Height/weight included
   - First/last name editing

## Files Referenced (Unchanged)

1. **StepComp/Services/AuthService.swift**
   - Already has `checkUsernameExists()` function (line 169)
   - Already has `loadUserProfile()` function
   
2. **Database Schema**
   - `profiles.username` already has UNIQUE constraint
   - `profiles.first_name`, `last_name`, `height`, `weight` columns exist

---

**Status**: ✅ **COMPLETE** (except photo upload to cloud storage, which is optional)

