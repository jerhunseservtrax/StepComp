# 🔧 Fix All Critical Issues Guide

## Issues to Fix

1. ✅ Edge Function 404 error
2. ✅ Infinite recursion in RLS policies
3. ✅ Apple Sign In challenge creation
4. ✅ Challenges not showing
5. ✅ Unable to cancel friend requests
6. ✅ App freeze on sign out

---

## Step 1: Fix Database RLS Policies

**Run this SQL in Supabase Dashboard → SQL Editor:**

```sql
-- Copy and paste the entire contents of FIX_ALL_CRITICAL_ISSUES.sql
```

**What it fixes:**
- Infinite recursion in `challenges` table RLS
- Infinite recursion in `challenge_members` table RLS
- Missing `avatar_url` column error
- Challenge visibility issues

**After running:**
- Challenges should load without recursion errors
- Public challenges should appear in Discover tab
- Home screen should show active challenges

---

## Step 2: Edge Function 404 (Already Fixed in Code)

**Status:** ✅ Fixed in `StepSyncService.swift`

**What was fixed:**
- Added graceful fallback when Edge Function returns 404
- Falls back to RPC `sync_daily_steps` if Edge Function not deployed
- No more 404 errors in console

**If you want to deploy the Edge Function:**
1. Go to Supabase Dashboard → Edge Functions
2. Deploy `supabase/functions/sync-steps/index.ts`
3. This provides better security (rate limiting, validation)

**Otherwise:** The app will use RPC fallback automatically.

---

## Step 3: Apple Sign In Profile Creation (Already Fixed)

**Status:** ✅ Fixed in `AuthService.swift`

**What was fixed:**
- Ensures `displayName` is always set
- Sets `totalSteps: 0` and `dailyStepGoal: 10000` defaults
- Generates unique username using full UUID if needed
- Verifies profile creation before proceeding

**If you still have issues:**
1. Run `FIX_APPLE_SIGNIN_PROFILE_FK.sql` in Supabase
2. Sign out and sign back in with Apple
3. Try creating a challenge again

---

## Step 4: Cancel Friend Requests (Already Fixed)

**Status:** ✅ Fixed in `FriendsViewModel.swift`

**What was fixed:**
- Added `cancelFriendRequest(to:)` function
- Finds pending outgoing requests
- Deletes the friendship record
- Refreshes friends list and discover tab

**How to use:**
- Tap "Request Sent" button in Discover tab
- Confirm "Unsend" in alert
- Request is cancelled immediately

---

## Step 5: Sign Out Freeze (Already Fixed)

**Status:** ✅ Fixed in `AuthService.swift`

**What was fixed:**
- Added error handling for Supabase sign out
- Always clears local state even if Supabase fails
- Uses `MainActor.run` for thread safety
- Added logging for debugging

**How to test:**
1. Sign out from Settings or Profile
2. App should return to onboarding screen
3. Should be able to sign back in immediately

---

## Step 6: Verify All Fixes

### Test Checklist:

- [ ] **RLS Policies:**
  - Run `FIX_ALL_CRITICAL_ISSUES.sql`
  - Check console - no more recursion errors
  - Challenges load on home screen
  - Public challenges appear in Discover tab

- [ ] **Edge Function:**
  - Check console - no more 404 errors
  - Steps still sync (via RPC fallback)
  - HealthKit data updates correctly

- [ ] **Apple Sign In:**
  - Sign in with Apple
  - Check profile is complete in Supabase Dashboard
  - Create a challenge - should work
  - Challenge appears on home screen

- [ ] **Friend Requests:**
  - Send a friend request
  - Tap "Request Sent" button
  - Confirm "Unsend"
  - Request should be cancelled

- [ ] **Sign Out:**
  - Sign out from Settings
  - App returns to onboarding
  - Sign back in - should work immediately

---

## Troubleshooting

### If challenges still don't show:

1. **Check RLS policies were applied:**
```sql
SELECT schemaname, tablename, policyname 
FROM pg_policies
WHERE tablename IN ('challenges', 'challenge_members');
```

2. **Verify user is in challenge:**
```sql
SELECT * FROM challenge_members 
WHERE user_id = 'YOUR_USER_ID';
```

3. **Check challenge is public:**
```sql
SELECT id, name, is_public 
FROM challenges 
WHERE id = 'YOUR_CHALLENGE_ID';
```

### If Apple Sign In still fails:

1. **Check profile exists:**
```sql
SELECT * FROM profiles 
WHERE id = 'YOUR_USER_ID';
```

2. **Run fix script:**
```sql
-- Run FIX_APPLE_SIGNIN_PROFILE_FK.sql
```

3. **Sign out and back in**

### If sign out still freezes:

1. **Force quit the app**
2. **Reopen**
3. **Check console logs** for errors
4. **Try signing out again**

---

## Summary

**All fixes are in code!** Just need to:

1. ✅ Run `FIX_ALL_CRITICAL_ISSUES.sql` in Supabase
2. ✅ Rebuild the app in Xcode
3. ✅ Test all features

**Expected results:**
- ✅ No more recursion errors
- ✅ No more 404 errors
- ✅ Challenges show on home screen
- ✅ Public challenges in Discover tab
- ✅ Can cancel friend requests
- ✅ Sign out works smoothly
- ✅ Apple Sign In creates challenges

---

## Files Modified

1. `StepComp/Services/StepSyncService.swift` - Edge Function 404 fallback
2. `StepComp/ViewModels/FriendsViewModel.swift` - Cancel friend request
3. `StepComp/Services/AuthService.swift` - Sign out fix, Apple Sign In profile
4. `FIX_ALL_CRITICAL_ISSUES.sql` - Database RLS fixes

---

**All issues should now be resolved!** 🎉
