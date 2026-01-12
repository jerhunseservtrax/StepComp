-- CRITICAL CHECK: Are creators being added to challenge_members?
-- Run this query in Supabase SQL Editor

-- Query 1: Check if ANY challenge_members exist
SELECT COUNT(*) as total_members
FROM challenge_members;

-- Expected: Should be > 0
-- If 0: Creators are NOT being added (RLS blocking INSERT)


-- Query 2: Check challenge_members for your specific challenges
SELECT 
    cm.id,
    cm.challenge_id,
    cm.user_id,
    c.name as challenge_name,
    c.created_by,
    (cm.user_id = c.created_by) as is_creator,
    cm.joined_at
FROM challenge_members cm
RIGHT JOIN challenges c ON c.id = cm.challenge_id
WHERE c.created_by IN (
    '524ef8e2-ddb8-400b-bc8a-4ce18756cdd8'::uuid,
    'de2ac63a-ed51-4b64-a323-5d68d2807a6f'::uuid
)
ORDER BY c.created_at DESC
LIMIT 50;

-- Expected: Each challenge should have at least 1 row (the creator)
-- If challenge_id shows but user_id is NULL: Creator was NOT added


-- Query 3: Find challenges WITHOUT any members (ORPHANED CHALLENGES)
SELECT 
    c.id,
    c.name,
    c.created_by,
    c.created_at,
    COUNT(cm.id) as member_count
FROM challenges c
LEFT JOIN challenge_members cm ON cm.challenge_id = c.id
WHERE c.created_by IN (
    '524ef8e2-ddb8-400b-bc8a-4ce18756cdd8'::uuid,
    'de2ac63a-ed51-4b64-a323-5d68d2807a6f'::uuid
)
GROUP BY c.id, c.name, c.created_by, c.created_at
HAVING COUNT(cm.id) = 0
ORDER BY c.created_at DESC;

-- If this returns results: These challenges exist but have NO members
-- This is why they don't appear in your Active tab!


-- Query 4: MANUAL FIX - Add creators to challenge_members for orphaned challenges
-- Run this ONLY if Query 3 shows orphaned challenges
INSERT INTO challenge_members (id, challenge_id, user_id, total_steps, joined_at, last_updated)
SELECT 
    gen_random_uuid(),
    c.id,
    c.created_by,
    0,
    c.created_at,
    NOW()
FROM challenges c
LEFT JOIN challenge_members cm ON cm.challenge_id = c.id AND cm.user_id = c.created_by
WHERE cm.id IS NULL  -- Only add if creator is NOT already a member
  AND c.created_by IN (
      '524ef8e2-ddb8-400b-bc8a-4ce18756cdd8'::uuid,
      'de2ac63a-ed51-4b64-a323-5d68d2807a6f'::uuid
  )
  AND c.end_date >= NOW();  -- Only for active challenges

-- This will add creators to all their challenges that are missing them


-- Query 5: VERIFY the fix worked
SELECT 
    c.id,
    c.name,
    c.created_by,
    COUNT(cm.id) as member_count,
    BOOL_AND(cm.user_id = c.created_by) as creator_is_member
FROM challenges c
LEFT JOIN challenge_members cm ON cm.challenge_id = c.id
WHERE c.created_by IN (
    '524ef8e2-ddb8-400b-bc8a-4ce18756cdd8'::uuid,
    'de2ac63a-ed51-4b64-a323-5d68d2807a6f'::uuid
)
GROUP BY c.id, c.name, c.created_by
ORDER BY c.created_at DESC
LIMIT 20;

-- Expected: member_count should be >= 1 for all challenges
-- Expected: creator_is_member should be TRUE

