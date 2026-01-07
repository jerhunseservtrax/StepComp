-- ============================================
-- COMPLETE FIX: Leaderboard Steps Not Showing
-- ============================================
-- This script fixes ALL issues:
-- 1. Missing creators in challenge_members table
-- 2. DATE vs TIMESTAMP comparison bug
-- 3. Missing username handling
-- ============================================

-- STEP 1: Add all missing challenge creators to challenge_members
-- ============================================
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
ON CONFLICT (challenge_id, user_id) DO NOTHING;

-- Also add any users who are in participantIds but not in challenge_members
-- (This catches users who joined via the app but weren't properly added to the table)

-- STEP 2: Verify the data after adding
SELECT 
    c.name as challenge_name,
    c.id as challenge_id,
    COUNT(cm.id) as member_count,
    array_agg(p.display_name) as member_names
FROM challenges c
LEFT JOIN challenge_members cm ON cm.challenge_id = c.id
LEFT JOIN profiles p ON p.id = cm.user_id
WHERE c.end_date >= NOW()
GROUP BY c.id, c.name
ORDER BY c.created_at DESC;

-- STEP 3: Check daily_steps data
SELECT 
    ds.user_id,
    p.display_name,
    ds.day,
    ds.steps,
    ds.is_suspicious
FROM daily_steps ds
LEFT JOIN profiles p ON p.id = ds.user_id
WHERE ds.day >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY ds.day DESC, ds.steps DESC;

-- STEP 4: Fix get_challenge_leaderboard with DATE casting
-- ============================================
CREATE OR REPLACE FUNCTION public.get_challenge_leaderboard(p_challenge_id UUID)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    display_name TEXT,
    avatar_url TEXT,
    steps BIGINT,
    rank BIGINT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    WITH challenge_members_cte AS (
        SELECT cm.user_id
        FROM public.challenge_members cm
        WHERE cm.challenge_id = p_challenge_id
    ),
    challenge_info AS (
        SELECT 
            (start_date AT TIME ZONE 'UTC')::date AS start_date,
            (end_date AT TIME ZONE 'UTC')::date AS end_date
        FROM public.challenges
        WHERE id = p_challenge_id
    ),
    member_steps AS (
        SELECT 
            cm.user_id,
            COALESCE(SUM(ds.steps), 0) AS total_steps
        FROM challenge_members_cte cm
        CROSS JOIN challenge_info ci
        LEFT JOIN public.daily_steps ds 
            ON ds.user_id = cm.user_id
            AND ds.day >= ci.start_date
            AND ds.day <= ci.end_date
            AND ds.is_suspicious = FALSE
        GROUP BY cm.user_id
    )
    SELECT 
        ms.user_id,
        COALESCE(p.username, 'User') AS username,
        COALESCE(p.display_name, p.username, 'User') AS display_name,
        p.avatar_url,
        ms.total_steps AS steps,
        RANK() OVER (ORDER BY ms.total_steps DESC) AS rank
    FROM member_steps ms
    LEFT JOIN public.profiles p ON p.id = ms.user_id
    ORDER BY ms.total_steps DESC;
$$;

-- STEP 5: Fix get_challenge_leaderboard_today
-- ============================================
CREATE OR REPLACE FUNCTION public.get_challenge_leaderboard_today(p_challenge_id UUID)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    display_name TEXT,
    avatar_url TEXT,
    steps BIGINT,
    rank BIGINT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    WITH challenge_members_cte AS (
        SELECT cm.user_id
        FROM public.challenge_members cm
        WHERE cm.challenge_id = p_challenge_id
    ),
    today_steps AS (
        SELECT 
            cm.user_id,
            COALESCE(ds.steps, 0) AS today_steps
        FROM challenge_members_cte cm
        LEFT JOIN public.daily_steps ds 
            ON ds.user_id = cm.user_id
            AND ds.day = CURRENT_DATE
            AND ds.is_suspicious = FALSE
    )
    SELECT 
        ts.user_id,
        COALESCE(p.username, 'User') AS username,
        COALESCE(p.display_name, p.username, 'User') AS display_name,
        p.avatar_url,
        ts.today_steps AS steps,
        RANK() OVER (ORDER BY ts.today_steps DESC) AS rank
    FROM today_steps ts
    LEFT JOIN public.profiles p ON p.id = ts.user_id
    ORDER BY ts.today_steps DESC;
$$;

-- STEP 6: Grant permissions
GRANT EXECUTE ON FUNCTION public.get_challenge_leaderboard(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_challenge_leaderboard_today(UUID) TO authenticated;

-- STEP 7: Test the fix immediately
-- ============================================
-- Test with the specific challenge ID from the logs
SELECT 'Testing leaderboard for challenge aedfc825-d64e-4b36-84cb-cfe882781cb1' as test;
SELECT * FROM get_challenge_leaderboard('aedfc825-d64e-4b36-84cb-cfe882781cb1'::uuid);

SELECT 'Testing daily leaderboard' as test;
SELECT * FROM get_challenge_leaderboard_today('aedfc825-d64e-4b36-84cb-cfe882781cb1'::uuid);

-- STEP 8: Show summary
DO $$
DECLARE
    v_members_added INT;
    v_daily_steps_count INT;
BEGIN
    SELECT COUNT(*) INTO v_members_added FROM challenge_members;
    SELECT COUNT(*) INTO v_daily_steps_count FROM daily_steps WHERE day >= CURRENT_DATE - INTERVAL '7 days';
    
    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ COMPLETE FIX APPLIED';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Total challenge members: %', v_members_added;
    RAISE NOTICE 'Daily steps records (7 days): %', v_daily_steps_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Fixed:';
    RAISE NOTICE '1. Added missing creators to challenge_members';
    RAISE NOTICE '2. Fixed DATE vs TIMESTAMP comparison';
    RAISE NOTICE '3. Fixed NULL username handling';
    RAISE NOTICE '';
    RAISE NOTICE 'Now refresh the app and check the Members tab!';
    RAISE NOTICE '============================================';
END $$;

