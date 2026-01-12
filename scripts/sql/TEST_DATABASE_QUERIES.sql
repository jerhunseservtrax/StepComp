-- Test Queries for Debugging Challenge Display Issues
-- Run these in Supabase SQL Editor to diagnose the problem

-- ========================================
-- PART 1: CHECK IF CHALLENGES EXIST
-- ========================================

-- Query 1: Show all challenges in database
SELECT 
    id,
    name,
    created_by,
    is_public,
    start_date,
    end_date,
    created_at
FROM challenges
ORDER BY created_at DESC
LIMIT 20;

-- Expected: You should see your created challenges here
-- If empty: Challenges are not being created at all


-- ========================================
-- PART 2: CHECK IF CHALLENGE_MEMBERS EXIST
-- ========================================

-- Query 2: Show all challenge members
SELECT 
    cm.id,
    cm.challenge_id,
    cm.user_id,
    c.name as challenge_name,
    c.created_by,
    cm.joined_at,
    (cm.user_id = c.created_by) as is_creator
FROM challenge_members cm
LEFT JOIN challenges c ON c.id = cm.challenge_id
ORDER BY cm.joined_at DESC
LIMIT 20;

-- Expected: Creator should be added to challenge_members automatically
-- If empty: RLS policy is blocking member insertion
-- If missing creator: addChallengeMember() is failing


-- ========================================
-- PART 3: CHECK YOUR USER PROFILE
-- ========================================

-- Query 3: Get your current user ID (run this first)
SELECT 
    auth.uid() as my_user_id;

-- Copy the user ID from results above and use it below


-- Query 4: Get your profile info (replace YOUR_USER_ID)
SELECT 
    id,
    username,
    email,
    display_name,
    first_name,
    last_name,
    total_steps,
    daily_step_goal
FROM profiles
WHERE id = 'YOUR_USER_ID_HERE'::uuid;

-- Expected: Your profile should exist with proper data
-- If empty: User profile wasn't created during sign-in
-- Check: display_name, total_steps, daily_step_goal should NOT be null


-- ========================================
-- PART 4: CHECK RLS POLICIES
-- ========================================

-- Query 5: List all RLS policies on challenges and challenge_members
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd,
    qual as policy_condition
FROM pg_policies
WHERE tablename IN ('challenges', 'challenge_members')
ORDER BY tablename, policyname;

-- Expected policies for challenges:
-- - "Users can read own challenges or joined challenges" (SELECT)
-- - "Challenge creator can insert challenges" (INSERT)
-- - "Challenge creator can update" (UPDATE)
-- - "Challenge creator can delete" (DELETE)

-- Expected policies for challenge_members:
-- - "Users can insert own challenge members" (INSERT)
-- - "Users can read members of their challenges" (SELECT)
-- - "Users can update own member stats" (UPDATE)
-- - "Users can delete own membership" (DELETE)


-- ========================================
-- PART 5: TEST RLS POLICIES MANUALLY
-- ========================================

-- Query 6: Simulate loading challenges (as your user)
-- First, set the session to your user (replace YOUR_USER_ID)
SET request.jwt.claim.sub = 'YOUR_USER_ID_HERE';

-- Then try to select challenges
SELECT 
    c.id,
    c.name,
    c.created_by,
    c.is_public,
    c.start_date,
    c.end_date
FROM challenges c
WHERE 
    c.created_by = 'YOUR_USER_ID_HERE'::uuid
    OR c.id IN (
        SELECT challenge_id 
        FROM challenge_members 
        WHERE user_id = 'YOUR_USER_ID_HERE'::uuid
    );

-- If this returns empty but Query 1 shows challenges exist:
-- RLS policy is blocking your access


-- Query 7: Test challenge_members access
SELECT 
    cm.id,
    cm.challenge_id,
    cm.user_id,
    cm.joined_at
FROM challenge_members cm
WHERE cm.user_id = 'YOUR_USER_ID_HERE'::uuid;

-- If this returns empty but Query 2 shows members exist:
-- RLS policy is blocking your access to members table


-- ========================================
-- PART 6: CHECK FOR INFINITE RECURSION
-- ========================================

-- Query 8: Detect recursive policy definitions
SELECT 
    tablename,
    policyname,
    qual
FROM pg_policies
WHERE 
    tablename IN ('challenges', 'challenge_members')
    AND (
        -- Check if challenges policy references challenge_members
        (tablename = 'challenges' AND qual::text LIKE '%challenge_members%')
        OR
        -- Check if challenge_members policy references challenges
        (tablename = 'challenge_members' AND qual::text LIKE '%challenges%')
    );

-- Expected: challenges can reference challenge_members (one-way)
-- ERROR: If challenge_members references challenges back, that's recursion


-- ========================================
-- PART 7: FIX TEST - Verify Policies Are Correct
-- ========================================

-- Query 9: Check if the fixed policies are in place
SELECT 
    tablename,
    policyname,
    CASE 
        WHEN qual::text LIKE '%infinite%' THEN 'BROKEN'
        WHEN qual::text LIKE '%SELECT id FROM challenges WHERE created_by%' THEN 'FIXED'
        WHEN qual::text LIKE '%SELECT challenge_id FROM challenge_members WHERE user_id%' THEN 'FIXED'
        ELSE 'UNKNOWN'
    END as policy_status,
    qual::text as full_policy
FROM pg_policies
WHERE tablename IN ('challenges', 'challenge_members')
ORDER BY tablename, policyname;

-- All policies should show 'FIXED' status
-- If any show 'BROKEN' or 'UNKNOWN', re-run FIX_ALL_CRITICAL_ISSUES.sql


-- ========================================
-- PART 8: VERIFICATION QUERIES
-- ========================================

-- Query 10: Count challenges by creator
SELECT 
    created_by,
    COUNT(*) as challenge_count,
    MAX(created_at) as last_created
FROM challenges
GROUP BY created_by
ORDER BY challenge_count DESC;

-- Expected: Your user ID should appear with challenge count > 0


-- Query 11: Count members per challenge
SELECT 
    c.id,
    c.name,
    c.created_by,
    COUNT(cm.id) as member_count
FROM challenges c
LEFT JOIN challenge_members cm ON cm.challenge_id = c.id
GROUP BY c.id, c.name, c.created_by
ORDER BY c.created_at DESC
LIMIT 10;

-- Expected: Each challenge should have at least 1 member (the creator)
-- If member_count = 0, creator wasn't added to challenge_members


-- ========================================
-- DIAGNOSTIC SUMMARY
-- ========================================

-- Run all queries above and look for:
-- ❌ Query 1 empty = Challenges not being created
-- ❌ Query 2 empty = Members not being added (RLS issue)
-- ❌ Query 4 empty = User profile missing
-- ❌ Query 5 missing policies = RLS not configured
-- ❌ Query 6 empty + Query 1 has data = RLS blocking access
-- ❌ Query 8 shows recursion = Policies reference each other
-- ❌ Query 11 member_count = 0 = Creator not added to members

-- Once you identify the issue, run FIX_ALL_CRITICAL_ISSUES.sql
-- Then rebuild the app and test again

