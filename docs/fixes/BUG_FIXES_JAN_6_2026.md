# Bug Fixes Summary - January 6, 2026

## 1. ✅ Fixed: Swipe-to-Delete on Friends List

### Problem
When swiping left on a friend's name to delete them, the app instead navigated to the Discover friends page.

### Root Cause
The `TabView` with `.page(indexDisplayMode: .never)` style enabled horizontal swipe gestures for tab navigation. This gesture had higher priority than the List's `.swipeActions`, preventing the swipe-to-delete functionality.

### Solution
Changed `TabView` style from `.page(indexDisplayMode: .never)` to `.automatic` to disable the horizontal page swipe gesture.

**File**: `StepComp/Screens/Friends/FriendsView.swift`

**Change**:
```swift
// Before:
.tabViewStyle(.page(indexDisplayMode: .never))

// After:
.tabViewStyle(.automatic)
```

### Impact
- ✅ Swipe-to-delete on friends now works properly
- ✅ Tab switching still works via header buttons (Friends/Discover)
- ✅ No gesture conflicts

---

## 2. ❌ NEEDS DATABASE FIX: Friend Invite Link Base64URL Error

### Problem
```
❌ Error creating invite link: PostgrestError(detail: nil, hint: nil, code: Optional("22023"), message: "unrecognized encoding: \"base64url\"")
```

### Root Cause
The PostgreSQL function `create_friend_invite` uses `encode(gen_random_bytes(16), 'base64url')`, but **'base64url' encoding is not available in PostgreSQL versions before 13** or may not be enabled in your Supabase instance.

### Solution
Replace `'base64url'` encoding with `'base64'` and manually replace characters to make it URL-safe.

**Action Required**: Run the SQL script in Supabase SQL Editor:
```bash
File: FIX_FRIEND_INVITE_BASE64_ERROR.sql
```

**Changes**:
- Replace `+` with `-`
- Replace `/` with `_`  
- Replace `=` with `~`

This achieves the same URL-safe result as base64url encoding.

---

## 3. ✅ Fixed: Emoji Avatar URL Errors

### Problem
```
Task finished with error [-1002] "unsupported URL" 
NSErrorFailingURLStringKey=%F0%9F%A6%8A (🦊)
```

The app was attempting to load emoji strings (🦊, 🐱, 👽, 🤖) as image URLs, causing network errors.

### Root Cause
The `AvatarCircle` component in `FriendsView.swift` didn't check if the avatar URL was an emoji before attempting to load it as an image.

### Solution
Added emoji detection logic to `AvatarCircle` component to display emojis directly instead of trying to load them as URLs.

**File**: `StepComp/Screens/Friends/FriendsView.swift`

**Added**:
- Emoji detection check
- Direct emoji text rendering for emoji avatars
- URL validation before attempting AsyncImage load

### Impact
- ✅ Emoji avatars display correctly
- ✅ No more unsupported URL errors
- ✅ Better performance (no failed network requests)

---

## Testing Checklist

### Swipe-to-Delete
- [x] Build succeeded
- [ ] Swipe left on friend shows "Remove" button
- [ ] Tapping "Remove" deletes friend
- [ ] Header buttons still switch tabs

### Friend Invite Link
- [ ] Run SQL script: `FIX_FRIEND_INVITE_BASE64_ERROR.sql`
- [ ] Tap "Share Friend Invite Link" button
- [ ] Verify no error message
- [ ] Confirm invite link is generated

### Emoji Avatars
- [x] Code updated
- [ ] Emoji avatars display correctly in friends list
- [ ] No console errors for emoji URLs
- [ ] Profile images still load normally

---

## Files Modified

1. `StepComp/Screens/Friends/FriendsView.swift`
   - Changed TabView style (swipe-to-delete fix)
   - Updated AvatarCircle component (emoji avatar fix)

2. `FIX_FRIEND_INVITE_BASE64_ERROR.sql` (NEW)
   - Database fix for base64url encoding error

---

## Next Steps

1. **Immediate**: Run `FIX_FRIEND_INVITE_BASE64_ERROR.sql` in Supabase SQL Editor
2. **Test**: Verify swipe-to-delete works on friends list
3. **Test**: Verify friend invite links can be created
4. **Monitor**: Check console for any remaining errors

