-- ========================================
-- DIAGNOSTIC: Check if leaderboard RPC exists
-- ========================================

-- Check if get_challenge_leaderboard function exists
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE '%leaderboard%'
ORDER BY routine_name;

-- Check daily_steps table structure
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'daily_steps'
ORDER BY ordinal_position;

-- Check if there's any data in challenge_members
SELECT 
    COUNT(*) as member_count,
    COUNT(DISTINCT challenge_id) as unique_challenges,
    COUNT(DISTINCT user_id) as unique_users
FROM challenge_members;

-- Sample a few challenge_members rows
SELECT 
    id,
    challenge_id,
    user_id,
    total_steps
FROM challenge_members
LIMIT 5;

