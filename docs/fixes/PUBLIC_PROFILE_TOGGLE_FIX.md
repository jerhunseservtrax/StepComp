# 🔍 Public Profile Toggle Fix

## Overview

Fixed the public profile toggle in Settings to correctly control whether users appear in the Friends Discover tab search results.

---

## 🐛 Problem

The public profile toggle in Settings was not working correctly:
1. Toggle always showed as OFF regardless of actual database value
2. Toggle state was checking `sessionViewModel.currentUser != nil` instead of actual `publicProfile` field
3. `User` model was missing the `publicProfile` field
4. User profiles loaded from Supabase were not mapping the `public_profile` field

**Result:** Users could not control their visibility in the Friends Discover tab.

---

## ✅ Solution

### 1. Added `publicProfile` Field to `User` Model

**File:** `StepComp/Models/User.swift`

```swift
struct User: Identifiable, Codable, Equatable {
    let id: String
    var username: String
    var firstName: String
    var lastName: String
    var displayName: String { ... }
    var avatarURL: String?
    var email: String?
    var publicProfile: Bool // ✅ NEW: Whether user appears in public search
    var totalSteps: Int
    var totalChallenges: Int
    var badges: [Badge]
    var createdAt: Date
}
```

**Updated Init:**
```swift
init(
    ...
    publicProfile: Bool = false, // ✅ Default to private
    ...
)
```

---

### 2. Fixed Settings Toggle to Read Actual Value

**File:** `StepComp/Screens/Settings/SettingsView.swift`

**Before:**
```swift
Toggle("", isOn: Binding(
    get: {
        // ❌ Wrong: Always returns true if user exists
        return sessionViewModel.currentUser != nil
    },
    set: { newValue in
        // ... update logic
    }
))
```

**After:**
```swift
Toggle("", isOn: Binding(
    get: {
        // ✅ Correct: Read actual publicProfile value
        return sessionViewModel.currentUser?.publicProfile ?? false
    },
    set: { newValue in
        Task {
            if let userId = sessionViewModel.currentUser?.id {
                let service = FriendsService()
                try? await service.setPublicProfile(newValue, myUserId: userId)
                // Refresh user profile to reflect change
                await sessionViewModel.checkSession()
            }
        }
    }
))
```

---

### 3. Updated Profile Loading to Map `publicProfile`

**File:** `StepComp/Services/AuthService.swift`

**In `loadUserProfile(userId:)` function:**

```swift
let user = User(
    id: profile.id,
    username: profile.username,
    firstName: firstName,
    lastName: lastName,
    avatarURL: avatarURL,
    email: email,
    publicProfile: profile.publicProfile, // ✅ Map from database
    totalSteps: profile.totalSteps ?? 0,
    totalChallenges: 0
)
```

**In default profile creation (error fallback):**

```swift
let user = User(
    id: userId,
    username: "user_\(userId.prefix(8))",
    firstName: "User",
    lastName: "",
    email: email,
    publicProfile: false, // ✅ Default to private
    totalSteps: 0,
    totalChallenges: 0
)
```

**In sign-up flow:**

```swift
let appUser = User(
    id: userId,
    username: username,
    firstName: firstName,
    lastName: lastName,
    email: email,
    publicProfile: false, // ✅ Default to private
    totalSteps: 0,
    totalChallenges: 0
)
```

---

## 🔄 How It Works Now

### User Flow:

1. **User opens Settings**
   - Toggle shows current `publicProfile` state from database
   - OFF by default for new users

2. **User toggles Public Profile ON**
   - `FriendsService.setPublicProfile(true, myUserId: userId)` called
   - Updates `profiles.public_profile = true` in database
   - `SessionViewModel.checkSession()` refreshes user data
   - Toggle updates to show ON

3. **User appears in Discover tab**
   - `FriendsService.searchPublicProfiles()` queries:
     ```sql
     SELECT * FROM profiles
     WHERE public_profile = true
     AND id != current_user_id
     ```
   - User now appears in search results

4. **User toggles Public Profile OFF**
   - Updates `profiles.public_profile = false`
   - User no longer appears in Discover tab searches

---

## 📊 Database Integration

### Existing Schema (Already Correct):

```sql
-- profiles table
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    username TEXT UNIQUE NOT NULL,
    ...
    public_profile BOOLEAN NOT NULL DEFAULT FALSE,
    ...
);
```

### RLS Policies (Already Correct):

```sql
-- Users can update their own public_profile setting
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Public profiles are searchable by anyone
CREATE POLICY "Public profiles are visible"
ON profiles FOR SELECT
USING (public_profile = true OR auth.uid() = id);
```

---

## ✅ Testing Checklist

- [ ] Toggle OFF by default for new users
- [ ] Toggle shows correct state when opening Settings
- [ ] Toggling ON updates database and UI
- [ ] User appears in Discover tab when public
- [ ] Toggling OFF removes user from Discover tab
- [ ] Toggle state persists after app restart
- [ ] Other users can find public profiles in search
- [ ] Private profiles don't appear in search

---

## 🎯 Expected Behavior

### Public Profile = OFF (Default):
- ❌ User does NOT appear in Friends → Discover tab
- ✅ User can still be added via invite link
- ✅ User can still search for others
- ✅ User's profile is visible to existing friends

### Public Profile = ON:
- ✅ User appears in Friends → Discover tab
- ✅ Anyone can search and find the user
- ✅ Anyone can send friend request
- ✅ User still controls who they accept

---

## 📝 Summary

**Files Changed:**
1. `StepComp/Models/User.swift` - Added `publicProfile` field
2. `StepComp/Services/AuthService.swift` - Map `publicProfile` when loading profiles
3. `StepComp/Screens/Settings/SettingsView.swift` - Fixed toggle to read actual value

**Database:**
- No changes needed (schema already correct)

**Result:**
- ✅ Toggle correctly reflects database state
- ✅ Users can control their visibility
- ✅ Discover tab respects `public_profile` setting
- ✅ Privacy is properly enforced

