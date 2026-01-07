# Fix: Public Challenges Not Appearing in Discover Tab

## 🐛 Problem Identified

**Symptom:** Account 2 cannot see public challenges created by Account 1 in the Discover tab.

**Root Cause:** Row Level Security (RLS) policy on `challenges` table blocks users from seeing challenges they didn't create or join.

## 📊 Evidence from Logs

### Account 1 (Creator):
```
🔍 [DISCOVER] Found 2 public challenges:
🔍 [DISCOVER]   1. Corporate test (is_public: true)
🔍 [DISCOVER]   2. Test public challenge (is_public: true)
```

### Account 2 (Viewer):
```
🔍 [DISCOVER] Found 1 public challenges:
🔍 [DISCOVER]   1. Rise and grind  <- Only sees their OWN challenge!
```

**Account 2 should see all 3 challenges, but only sees their own!**

## 🔍 Why This Happens

The Supabase query is correct:
```swift
.from("challenges")
.select()
.eq("is_public", value: true)  // ✅ Correct query
```

But the **RLS policy** blocks it:
```sql
-- Current WRONG policy
USING (created_by = auth.uid() OR id IN (...member check...))
```

This policy says: "You can only see challenges YOU created or YOU joined"

But we need: "You can see ALL public challenges + your own challenges"

## ✅ Solution

Update the RLS SELECT policy to include public challenges:

```sql
USING (
    is_public = true  -- ✅ NEW: Anyone can see public challenges
    OR 
    created_by = auth.uid()
    OR 
    id IN (SELECT challenge_id FROM challenge_members WHERE user_id = auth.uid())
)
```

## 🚀 How to Fix

1. **Open Supabase Dashboard**
2. **Go to SQL Editor**
3. **Copy and execute:** `FIX_PUBLIC_CHALLENGES_RLS.sql`
4. **Test:** Sign in as Account 2 → Go to Discover tab
5. **Expected:** See Account 1's public challenges!

## 📋 Testing Checklist

After running the SQL fix:

- [ ] Account 2 can see Account 1's "Corporate test" challenge
- [ ] Account 2 can see Account 1's "Test public challenge" challenge
- [ ] Account 2 can tap and view challenge details
- [ ] Account 2 sees "Join Challenge" button
- [ ] Account 2 can successfully join
- [ ] After joining, challenge moves from Discover → Active for Account 2
- [ ] Account 1 still sees their own challenges in Active (not affected)

## 🎯 What Changes

**Before Fix:**
- User sees: Own challenges only (creator or member)
- Discover tab: Empty or very limited

**After Fix:**
- User sees: ALL public challenges + own challenges
- Discover tab: Shows all public challenges from all users
- Correctly filters out challenges user already joined

## 🔐 Security

This change is **safe and intended**:
- ✅ Only affects PUBLIC challenges (`is_public = true`)
- ✅ Private challenges still protected
- ✅ Users can't edit/delete others' challenges
- ✅ Users still need to join to participate

## 📝 Files

- `FIX_PUBLIC_CHALLENGES_RLS.sql` - SQL script to fix RLS policy
- All Swift code is correct and working!

