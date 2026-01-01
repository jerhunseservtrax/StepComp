-- ========================================
-- COMPREHENSIVE FIX: Step Sync + Leaderboard
-- This script fixes all remaining issues
-- ========================================

-- PART 1: Re-populate challenge_members
-- Add missing creators to their challenges
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

-- PART 2: Create leaderboard RPC function
-- This returns leaderboard entries for a challenge based on total_steps
CREATE OR REPLACE FUNCTION get_challenge_leaderboard(p_challenge_id UUID)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    display_name TEXT,
    avatar_url TEXT,
    steps BIGINT,
    rank BIGINT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id::UUID as user_id,
        p.username,
        p.display_name,
        p.avatar_url,
        COALESCE(cm.total_steps, 0)::BIGINT as steps,
        ROW_NUMBER() OVER (ORDER BY COALESCE(cm.total_steps, 0) DESC)::BIGINT as rank
    FROM challenge_members cm
    INNER JOIN profiles p ON p.id = cm.user_id
    WHERE cm.challenge_id = p_challenge_id
    ORDER BY steps DESC;
END;
$$;

-- PART 3: Create daily leaderboard RPC function
-- This returns today's steps from daily_steps table
CREATE OR REPLACE FUNCTION get_challenge_leaderboard_today(p_challenge_id UUID)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    display_name TEXT,
    avatar_url TEXT,
    steps BIGINT,
    rank BIGINT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_today DATE := CURRENT_DATE;
BEGIN
    RETURN QUERY
    SELECT 
        p.id::UUID as user_id,
        p.username,
        p.display_name,
        p.avatar_url,
        COALESCE(ds.steps, 0)::BIGINT as steps,
        ROW_NUMBER() OVER (ORDER BY COALESCE(ds.steps, 0) DESC)::BIGINT as rank
    FROM challenge_members cm
    INNER JOIN profiles p ON p.id = cm.user_id
    LEFT JOIN daily_steps ds ON ds.user_id = cm.user_id AND ds.day = v_today
    WHERE cm.challenge_id = p_challenge_id
    ORDER BY steps DESC;
END;
$$;

-- PART 4: Add RLS policy for device_id column in daily_steps
-- Allow users to insert/update their own steps
DROP POLICY IF EXISTS "daily_steps_insert" ON daily_steps;
DROP POLICY IF EXISTS "daily_steps_update" ON daily_steps;
DROP POLICY IF EXISTS "daily_steps_select" ON daily_steps;

CREATE POLICY "daily_steps_select"
ON daily_steps FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "daily_steps_insert"
ON daily_steps FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "daily_steps_update"
ON daily_steps FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- PART 5: Verification Queries
SELECT 
    'Challenge Members Re-added' as check_name,
    COUNT(*)::TEXT as result
FROM challenge_members

UNION ALL

SELECT 
    'Challenges with Members' as check_name,
    COUNT(DISTINCT challenge_id)::TEXT as result
FROM challenge_members

UNION ALL

SELECT 
    'Leaderboard RPC Exists' as check_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'get_challenge_leaderboard'
    ) THEN 'YES' ELSE 'NO' END as result

UNION ALL

SELECT 
    'Daily Leaderboard RPC Exists' as check_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'get_challenge_leaderboard_today'
    ) THEN 'YES' ELSE 'NO' END as result

UNION ALL

SELECT 
    'Daily Steps RLS Policies' as check_name,
    COUNT(*)::TEXT as result
FROM pg_policies
WHERE tablename = 'daily_steps';

-- Sample query to verify leaderboard works
-- Uncomment to test with a real challenge ID
-- SELECT * FROM get_challenge_leaderboard('your-challenge-id-here'::UUID);

