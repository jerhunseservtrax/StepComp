-- ============================================
-- COMPLETE FIX V3: Leaderboard Steps Not Showing
-- ============================================
-- Fixed: Drop functions first, removed is_suspicious checks
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

-- STEP 2: DROP existing functions first
-- ============================================
DROP FUNCTION IF EXISTS public.get_challenge_leaderboard(UUID);
DROP FUNCTION IF EXISTS public.get_challenge_leaderboard_today(UUID);

-- STEP 3: Create get_challenge_leaderboard with DATE casting
-- ============================================
CREATE FUNCTION public.get_challenge_leaderboard(p_challenge_id UUID)
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

-- STEP 4: Create get_challenge_leaderboard_today
-- ============================================
CREATE FUNCTION public.get_challenge_leaderboard_today(p_challenge_id UUID)
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

-- STEP 5: Grant permissions
GRANT EXECUTE ON FUNCTION public.get_challenge_leaderboard(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_challenge_leaderboard_today(UUID) TO authenticated;

-- STEP 6: Verify data
SELECT '=== Challenge Members ===' as info;
SELECT 
    c.name as challenge_name,
    COUNT(cm.id) as member_count
FROM challenges c
LEFT JOIN challenge_members cm ON cm.challenge_id = c.id
WHERE c.end_date >= NOW()
GROUP BY c.id, c.name;

SELECT '=== Daily Steps (last 7 days) ===' as info;
SELECT 
    p.display_name,
    ds.day,
    ds.steps
FROM daily_steps ds
LEFT JOIN profiles p ON p.id = ds.user_id
WHERE ds.day >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY ds.day DESC, ds.steps DESC
LIMIT 10;

-- STEP 7: Test the fix
SELECT '=== Leaderboard Test ===' as info;
SELECT * FROM get_challenge_leaderboard('aedfc825-d64e-4b36-84cb-cfe882781cb1'::uuid);

SELECT '=== Daily Leaderboard Test ===' as info;
SELECT * FROM get_challenge_leaderboard_today('aedfc825-d64e-4b36-84cb-cfe882781cb1'::uuid);

-- Done!
DO $$
BEGIN
    RAISE NOTICE '✅ FIX V3 COMPLETE - Refresh app now!';
END $$;

