# RLS Policy Performance Optimization

## Overview

All Row Level Security (RLS) policies have been updated to use scalar subqueries instead of direct function calls. This optimization ensures PostgreSQL evaluates `auth.uid()` once per statement instead of once per row, significantly improving query performance.

## Changes Made

### Pattern Updated

**Before:**
```sql
USING (auth.uid() = user_id)
```

**After:**
```sql
USING ((SELECT auth.uid()) = user_id)
```

## Updated Policies

### Profiles Table (3 policies)
- ✅ "Users can read own profile" - SELECT policy
- ✅ "Users can insert own profile" - INSERT policy  
- ✅ "Users can update own profile" - UPDATE policy

### Challenges Table (4 policies)
- ✅ "Users can read own challenges" - SELECT policy
- ✅ "Users can create challenges" - INSERT policy
- ✅ "Users can update own challenges" - UPDATE policy
- ✅ "Users can delete own challenges" - DELETE policy

### Challenge Members Table (4 policies)
- ✅ "Users can read challenge members" - SELECT policy (with nested EXISTS)
- ✅ "Users can join challenges" - INSERT policy
- ✅ "Users can update own steps" - UPDATE policy
- ✅ "Users can leave challenges" - DELETE policy
- ✅ "Challenge members can read challenges" - SELECT policy on challenges table

### Friends Table (3 policies)
- ✅ "Users can read own friendships" - SELECT policy
- ✅ "Users can create friend requests" - INSERT policy
- ✅ "Users can update received friend requests" - UPDATE policy

**Total: 14 policies optimized**

## Performance Benefits

1. **Reduced CPU Usage**: `auth.uid()` is evaluated once per query instead of once per row
2. **Better Query Planning**: PostgreSQL can optimize queries more effectively
3. **Improved Latency**: Faster query execution, especially on large tables
4. **Index Utilization**: Better use of indexes on `user_id`, `created_by`, etc.

## Implementation

All changes are in `SUPABASE_DATABASE_SETUP_UPDATED.sql`. To apply:

1. Go to Supabase Dashboard → SQL Editor
2. Copy and paste the updated SQL script
3. Run the script (it will drop and recreate policies with optimized versions)

## Testing

After applying the changes, test typical queries:

```sql
-- Test profile access
SELECT * FROM profiles WHERE user_id = auth.uid();

-- Test challenge access
SELECT * FROM challenges WHERE created_by = auth.uid();

-- Test challenge members
SELECT * FROM challenge_members WHERE user_id = auth.uid();
```

Monitor query execution times to verify performance improvement.

## Reference

This optimization follows Supabase's recommended best practices for RLS policies. See: https://supabase.com/docs/guides/database/postgres/row-level-security#calling-functions-with-select

