# Fix All Current Issues Guide

This guide addresses all the errors you're seeing in the console.

## Issue 1: Infinite Recursion in challenge_members RLS Policy

**Error:** `infinite recursion detected in policy for relation "challenge_members"`

**Solution:**
1. Go to Supabase Dashboard → SQL Editor
2. Run the SQL from `FIX_CHALLENGE_MEMBERS_RLS_RECURSION.sql`
3. This fixes the RLS policy to avoid recursion

**Or run this SQL directly:**

```sql
-- Drop the problematic policy
DROP POLICY IF EXISTS "Users can read challenge members" ON challenge_members;

-- Create a fixed policy without recursion
CREATE POLICY "Users can read challenge members"
  ON challenge_members FOR SELECT
  USING (
    (SELECT auth.uid()) = user_id
    OR
    EXISTS (
      SELECT 1 FROM challenges
      WHERE challenges.id = challenge_members.challenge_id
      AND challenges.is_public = TRUE
    )
    OR
    EXISTS (
      SELECT 1 FROM challenges
      WHERE challenges.id = challenge_members.challenge_id
      AND challenges.created_by = (SELECT auth.uid())
    )
  );
```

## Issue 2: HealthKit Usage Descriptions Missing

**Error:** `HealthKit usage descriptions missing in Info.plist`

**Solution:**
1. Open Xcode
2. Select your project in the navigator
3. Select the **StepComp** target
4. Go to the **Info** tab
5. Click the **+** button to add new keys
6. Add these two keys:

   **Key 1:**
   - Key: `NSHealthShareUsageDescription`
   - Type: `String`
   - Value: `StepComp needs access to your step count to track your progress in challenges.`

   **Key 2:**
   - Key: `NSHealthUpdateUsageDescription`
   - Type: `String`
   - Value: `StepComp needs permission to save your step data for challenge tracking.`

**Or edit Info.plist directly:**

```xml
<key>NSHealthShareUsageDescription</key>
<string>StepComp needs access to your step count to track your progress in challenges.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>StepComp needs permission to save your step data for challenge tracking.</string>
```

## Issue 3: Avatar Column Not Found

**Error:** `Could not find the 'avatar' column of 'profiles' in the schema cache`

**Solution:**
The code has been updated to use `avatar_url` if available, falling back to `avatar`. However, you may need to ensure your `profiles` table has one of these columns.

**Check your schema:**
```sql
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND column_name IN ('avatar', 'avatar_url');
```

**If neither exists, add avatar_url:**
```sql
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS avatar_url TEXT;
```

## Issue 4: 'footprint' Symbol Not Found

**Error:** `No symbol named 'footprint' found in system symbol set`

**Solution:**
This has been fixed in the code - replaced `"footprint"` with `"figure.walk"` which is a valid SF Symbol.

## Quick Fix Checklist

- [ ] Run `FIX_CHALLENGE_MEMBERS_RLS_RECURSION.sql` in Supabase SQL Editor
- [ ] Add `NSHealthShareUsageDescription` to Info.plist
- [ ] Add `NSHealthUpdateUsageDescription` to Info.plist
- [ ] Verify `profiles` table has `avatar_url` or `avatar` column
- [ ] Rebuild the app (Product → Clean Build Folder, then Build)

## After Fixes

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Rebuild**: Product → Build (⌘B)
3. **Run on device**: HealthKit requires a real device
4. **Test**: The errors should be gone

## Verification

After applying fixes, you should see:
- ✅ No more "infinite recursion" errors
- ✅ No more "HealthKit usage descriptions missing" warnings
- ✅ No more "avatar column not found" errors
- ✅ No more "footprint symbol not found" errors

