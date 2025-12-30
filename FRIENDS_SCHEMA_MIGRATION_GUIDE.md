# Friends Schema Migration Guide

This guide explains how to migrate your database schema to support the friends feature with the correct structure.

## Overview

The friends feature requires:
1. **profiles table** with `id` (not `user_id`) as primary key
2. **friends table** with `requester_id` and `addressee_id` referencing `profiles(id)`
3. **Unique username** constraint on profiles
4. **Proper RLS policies** for security

## Migration Steps

### Step 1: Run the SQL Migration

1. Open Supabase Dashboard → **SQL Editor**
2. Copy and paste the contents of `FRIENDS_SCHEMA_UPDATE.sql`
3. Click **Run** to execute the migration

The migration script will:
- ✅ Rename `user_id` to `id` in profiles table (if needed)
- ✅ Add `email` column to profiles (if missing)
- ✅ Ensure `username` is unique and NOT NULL
- ✅ Drop and recreate `friends` table with correct structure
- ✅ Set up proper RLS policies
- ✅ Create indexes for performance

### Step 2: Verify the Migration

Run these queries to verify:

```sql
-- Check profiles table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- Check friends table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'friends'
ORDER BY ordinal_position;

-- Verify username uniqueness
SELECT username, COUNT(*) 
FROM profiles 
GROUP BY username 
HAVING COUNT(*) > 1;
-- Should return 0 rows
```

### Step 3: Update Test Accounts Scripts

The test account creation scripts have been updated to use `id` instead of `user_id`. If you need to update existing scripts:

**Before:**
```python
profile_data = {
    "user_id": user_id,
    ...
}
```

**After:**
```python
profile_data = {
    "id": user_id,  # Use 'id' instead of 'user_id'
    ...
}
```

## Schema Changes Summary

### Profiles Table

**Before:**
```sql
CREATE TABLE profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  username TEXT NOT NULL,
  ...
);
```

**After:**
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  username TEXT UNIQUE NOT NULL,
  email TEXT,
  ...
);
```

### Friends Table

**Before:**
```sql
CREATE TABLE friends (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  friend_id UUID REFERENCES auth.users(id),
  status TEXT,
  ...
);
```

**After:**
```sql
CREATE TABLE friends (
  id UUID PRIMARY KEY,
  requester_id UUID REFERENCES profiles(id),
  addressee_id UUID REFERENCES profiles(id),
  status TEXT CHECK (status IN ('pending', 'accepted')),
  ...
);
```

## Code Changes

The Swift code has been updated to use `id` instead of `user_id`:

### UserProfile Model
- ✅ Updated `CodingKeys` to use `id` instead of `user_id`
- ✅ Added `email` field

### AuthService
- ✅ Updated profile queries to use `.eq("id", ...)` instead of `.eq("user_id", ...)`

### ChallengeService
- ✅ Updated profile queries to use `.in("id", ...)` instead of `.in("user_id", ...)`

## Important Notes

1. **Username Must Be Unique**: The migration enforces this with a UNIQUE constraint
2. **Username Must Be Searchable**: Ensure you have an index (the migration creates one)
3. **Username Should Be Immutable**: Consider adding a trigger to prevent changes, or handle changes carefully
4. **Direction Matters**: `requester_id → addressee_id` means the requester sent the request to the addressee
5. **One Row Per Relationship**: The UNIQUE constraint on `(requester_id, addressee_id)` ensures this

## Testing

After migration, test:

1. **Create a test user** and verify profile is created automatically
2. **Search for users** by username
3. **Send a friend request** from user A to user B
4. **Accept the request** as user B
5. **Verify friendship** appears for both users

## Rollback (if needed)

If you need to rollback:

```sql
-- Restore old friends table structure (if needed)
DROP TABLE IF EXISTS friends;

CREATE TABLE friends (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  friend_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, friend_id),
  CHECK (user_id != friend_id)
);

-- Rename id back to user_id in profiles (if needed)
ALTER TABLE profiles RENAME COLUMN id TO user_id;
```

⚠️ **Warning**: Rollback will lose all friend relationships. Only use if absolutely necessary.

## Next Steps

After migration:
1. ✅ Test friend request flow
2. ✅ Implement user search functionality
3. ✅ Add friend request UI
4. ✅ Update FriendsService to use Supabase

