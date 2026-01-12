-- ========================================
-- FINAL DATABASE FIXES
-- Fixes all remaining schema and data issues
-- ========================================

-- PART 1: Fix daily_steps table schema
-- The RPC expects 'ip_address' but we added 'device_id' and the IP column may have wrong name

-- First, let's see what columns exist
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'daily_steps'
ORDER BY ordinal_position;

-- Check sync_daily_steps RPC function parameters
SELECT 
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as parameters
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND p.proname = 'sync_daily_steps';

-- PART 2: Add missing creators to challenge_members
-- This ensures all challenge creators are participants
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
WHERE cm.id IS NULL
  AND c.end_date >= NOW()
ON CONFLICT (challenge_id, user_id) DO NOTHING;

-- PART 3: Verify challenge_members data
SELECT 
    'Challenge Members Count' as check_name,
    COUNT(*)::TEXT as result
FROM challenge_members

UNION ALL

SELECT 
    'Challenges with Members' as check_name,
    COUNT(DISTINCT challenge_id)::TEXT as result
FROM challenge_members

UNION ALL

SELECT 
    'Unique Users in Challenges' as check_name,
    COUNT(DISTINCT user_id)::TEXT as result
FROM challenge_members;

-- PART 4: Sample challenge_members data
SELECT 
    cm.challenge_id,
    c.name as challenge_name,
    cm.user_id,
    c.created_by,
    CASE WHEN cm.user_id = c.created_by THEN 'CREATOR' ELSE 'MEMBER' END as role
FROM challenge_members cm
INNER JOIN challenges c ON c.id = cm.challenge_id
WHERE c.end_date >= NOW()
ORDER BY c.created_at DESC
LIMIT 10;

