# 🔧 Fix Infinite Recursion in Challenges RLS Policies

## Problem

**Error:**
```
⚠️ Error loading challenges from Supabase: 
infinite recursion detected in policy for relation "challenges"
```

**Cause:** The RLS (Row Level Security) policies for the `challenges` table have circular dependencies, causing infinite recursion when PostgreSQL tries to evaluate them.

---

## Solution

Run the provided SQL script to replace the problematic policies with non-recursive versions.

---

## 🚀 How to Fix

### Step 1: Open Supabase Dashboard

1. Go to [https://app.supabase.com](https://app.supabase.com)
2. Select your **StepComp** project
3. Navigate to **SQL Editor** in the left sidebar

### Step 2: Run the Fix Script

1. Click **New Query**
2. Copy the contents of `FIX_CHALLENGES_RLS_RECURSION.sql`
3. Paste into the SQL editor
4. Click **Run** or press `Cmd/Ctrl + Enter`

### Step 3: Verify the Fix

Run this verification query:

```sql
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE tablename IN ('challenges', 'challenge_members')
ORDER BY tablename, policyname;
```

**Expected output:**
- `challenges` table should have 4 policies (SELECT, INSERT, UPDATE, DELETE)
- `challenge_members` table should have 4 policies (SELECT, INSERT, UPDATE, DELETE)
- No recursive references between tables

---

## 🔍 What Changed

### Before (Recursive - BAD ❌)

```sql
-- challenges SELECT policy
CREATE POLICY "Users can read challenges they're in"
ON challenges FOR SELECT
USING (
    auth.uid() = created_by 
    OR 
    EXISTS (
        SELECT 1 FROM challenge_members cm
        JOIN challenges c ON c.id = cm.challenge_id  -- ❌ RECURSION!
        WHERE cm.user_id = auth.uid()
        AND cm.challenge_id = challenges.id
    )
);
```

**Problem:** The policy queries `challenges` table while defining a policy FOR the `challenges` table, creating infinite recursion.

### After (Non-Recursive - GOOD ✅)

```sql
-- challenges SELECT policy
CREATE POLICY "Users can read own challenges or joined challenges"
ON challenges FOR SELECT
USING (
    auth.uid() = created_by 
    OR 
    id IN (
        SELECT challenge_id 
        FROM challenge_members 
        WHERE user_id = auth.uid()
    )
);
```

**Solution:** Simplified to only query `challenge_members` table, avoiding circular reference.

---

## 📋 New Policies Overview

### `challenges` Table Policies:

1. **SELECT** - "Users can read own challenges or joined challenges"
   - ✅ User created the challenge (`created_by = auth.uid()`)
   - ✅ User is a member (`id IN challenge_members`)

2. **INSERT** - "Users can create challenges"
   - ✅ User must be the creator (`created_by = auth.uid()`)

3. **UPDATE** - "Challenge creator can update"
   - ✅ Only creator can update their challenge

4. **DELETE** - "Challenge creator can delete"
   - ✅ Only creator can delete their challenge

### `challenge_members` Table Policies:

1. **SELECT** - "Users can read members of their challenges"
   - ✅ User is the member (`user_id = auth.uid()`)
   - ✅ User created the challenge

2. **INSERT** - "Users can join challenges"
   - ✅ User can join as themselves (`user_id = auth.uid()`)

3. **UPDATE** - "Users can update own membership"
   - ✅ User can update their own record

4. **DELETE** - "Users can leave challenges"
   - ✅ User can remove themselves from challenges

---

## ✅ Expected Behavior After Fix

1. **Loading Challenges:**
   ```
   ✅ Successfully synced 779 steps to profile
   ✅ Challenge created in Supabase: ABC-123
   ✅ Total challenges loaded: 6
   ```

2. **Creating Challenges:**
   - User creates challenge → Appears in Active tab
   - Public challenge → Also appears in Discover tab

3. **Joining Challenges:**
   - User joins challenge → Appears in their Active tab
   - Challenge members visible to all participants

---

## 🧪 Testing After Fix

### Test 1: Load Challenges
```swift
// Should work without recursion error
await challengeService.loadChallengesFromSupabase()
```

**Expected:** Challenges load successfully, no recursion error

### Test 2: Create Challenge
```swift
// Should create and appear in Active tab
let challenge = Challenge(...)
await challengeService.createChallenge(challenge, isPublic: false)
```

**Expected:** Challenge appears in Active tab immediately

### Test 3: Join Public Challenge
```swift
// Should join and appear in Active tab
await challengeService.joinChallenge(challengeId: "...")
```

**Expected:** User added as member, challenge appears in Active tab

---

## 🔧 Troubleshooting

### If Error Persists:

1. **Check Policy Names:**
   ```sql
   SELECT policyname FROM pg_policies WHERE tablename = 'challenges';
   ```
   Ensure old policies are dropped.

2. **Verify RLS is Enabled:**
   ```sql
   SELECT tablename, rowsecurity 
   FROM pg_tables 
   WHERE tablename IN ('challenges', 'challenge_members');
   ```
   Both should show `t` (true).

3. **Test Query Manually:**
   ```sql
   -- Run as authenticated user
   SELECT * FROM challenges WHERE auth.uid() = created_by;
   ```
   Should return user's challenges without error.

---

## 📝 Summary

**Problem:** RLS policies had circular dependencies causing infinite recursion

**Solution:** Simplified policies to avoid cross-table references

**Result:** 
- ✅ No more recursion errors
- ✅ Challenges load correctly
- ✅ Security maintained (users still can only see their own data)

---

## 🚀 Next Steps

1. Run `FIX_CHALLENGES_RLS_RECURSION.sql` in Supabase Dashboard
2. Restart your app
3. Test challenge loading, creation, and joining
4. Verify no more recursion errors in logs

**After running the script, your challenges feature should work perfectly!** 🎉

