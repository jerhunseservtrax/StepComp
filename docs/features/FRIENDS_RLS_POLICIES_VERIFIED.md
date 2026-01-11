# Friends Table RLS Policies - Verified ✅

## RLS Enabled

```sql
ALTER TABLE friends ENABLE ROW LEVEL SECURITY;
```

✅ **Status**: Included in `FRIENDS_SCHEMA_UPDATE.sql` (line 187)

## Policy 1: Users can view own friend relationships

```sql
CREATE POLICY "Users can view own friend relationships"
ON friends
FOR SELECT
USING (
  auth.uid() = requester_id OR auth.uid() = addressee_id
);
```

✅ **Status**: Implemented in `FRIENDS_SCHEMA_UPDATE.sql` (lines 238-243)

**What it does:**
- Users can SELECT (read) friend relationships where they are either:
  - The requester (they sent the request)
  - The addressee (they received the request)

## Policy 2: Users can send friend requests

```sql
CREATE POLICY "Users can send friend requests"
ON friends
FOR INSERT
WITH CHECK (
  auth.uid() = requester_id
);
```

✅ **Status**: Implemented in `FRIENDS_SCHEMA_UPDATE.sql` (lines 247-252)

**What it does:**
- Users can INSERT (create) friend requests
- They can only create requests where they are the requester
- Prevents users from creating requests on behalf of others

## Policy 3: Users can update incoming requests

```sql
CREATE POLICY "Users can update incoming requests"
ON friends
FOR UPDATE
USING (
  auth.uid() = addressee_id
);
```

✅ **Status**: Implemented in `FRIENDS_SCHEMA_UPDATE.sql` (lines 257-262)

**What it does:**
- Users can UPDATE friend requests
- They can only update requests where they are the addressee (received the request)
- Allows accepting/rejecting incoming friend requests
- Prevents users from modifying requests they sent

## Complete Policy Summary

| Policy Name | Operation | Who Can Use | Purpose |
|------------|-----------|-------------|---------|
| Users can view own friend relationships | SELECT | Requester OR Addressee | View friendships |
| Users can send friend requests | INSERT | Requester only | Send friend requests |
| Users can update incoming requests | UPDATE | Addressee only | Accept/reject requests |

## Security Guarantees

✅ **Users cannot:**
- View friend relationships they're not part of
- Send friend requests on behalf of others
- Modify friend requests they sent (only the recipient can accept/reject)
- Delete friend relationships (no DELETE policy = no deletions allowed)

✅ **Users can:**
- View their own friend relationships (as requester or addressee)
- Send friend requests (as requester)
- Accept/reject incoming friend requests (as addressee)

## Testing Checklist

After running the migration, test:

1. ✅ User A sends friend request to User B
   - User A should be able to INSERT with `requester_id = A.id`
   - User B should be able to SELECT the request
   - User A should be able to SELECT the request

2. ✅ User B accepts the request
   - User B should be able to UPDATE with `addressee_id = B.id`
   - Change status from 'pending' to 'accepted'

3. ✅ User C cannot see A-B friendship
   - User C should NOT be able to SELECT the A-B relationship

4. ✅ User A cannot modify their own sent request
   - User A should NOT be able to UPDATE (only addressee can)

## Migration Script Location

All policies are in: `FRIENDS_SCHEMA_UPDATE.sql`

Run this script in Supabase Dashboard → SQL Editor to apply all changes.

