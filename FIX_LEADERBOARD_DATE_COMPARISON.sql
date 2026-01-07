-- ============================================
-- FIX: Leaderboard RPC Date Comparison Bug
-- ============================================
-- Problem: daily_steps.day (DATE) compared with challenge start_date/end_date (TIMESTAMP)
-- causes DATE '2026-01-06' to be cast to '2026-01-06 00:00:00', which is BEFORE
-- a challenge that starts at '2026-01-06 20:35:26'. This makes all steps show as 0.
--
-- Solution: Cast TIMESTAMP to DATE for proper comparison
-- ============================================

-- Fix get_challenge_leaderboard (all-time within challenge range)
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
    -- Step 1: Get all challenge members
    WITH challenge_members AS (
        SELECT cm.user_id
        FROM public.challenge_members cm
        WHERE cm.challenge_id = p_challenge_id
    ),
    -- Step 2: Get challenge date range (cast to DATE!)
    challenge_info AS (
        SELECT 
            start_date::date AS start_date,  -- Cast to DATE
            end_date::date AS end_date       -- Cast to DATE
        FROM public.challenges
        WHERE id = p_challenge_id
    ),
    -- Step 3: Compute steps for each member
    member_steps AS (
        SELECT 
            cm.user_id,
            COALESCE(SUM(ds.steps), 0) AS total_steps
        FROM challenge_members cm
        CROSS JOIN challenge_info ci
        LEFT JOIN public.daily_steps ds 
            ON ds.user_id = cm.user_id
            AND ds.day >= ci.start_date   -- Now comparing DATE to DATE
            AND ds.day <= ci.end_date     -- Now comparing DATE to DATE
            AND ds.is_suspicious = FALSE
        GROUP BY cm.user_id
    )
    -- Step 4: Join with profiles and rank
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

-- Fix get_challenge_leaderboard_today (today's steps only)
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
    WITH challenge_members AS (
        SELECT cm.user_id
        FROM public.challenge_members cm
        WHERE cm.challenge_id = p_challenge_id
    ),
    today_steps AS (
        SELECT 
            cm.user_id,
            COALESCE(ds.steps, 0) AS today_steps
        FROM challenge_members cm
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_challenge_leaderboard(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_challenge_leaderboard_today(UUID) TO authenticated;

-- Verification: Test the fix
DO $$
BEGIN
    RAISE NOTICE '✅ Leaderboard RPC functions updated!';
    RAISE NOTICE '   - Fixed DATE vs TIMESTAMP comparison';
    RAISE NOTICE '   - Fixed NULL username handling';
    RAISE NOTICE '';
    RAISE NOTICE 'To verify, run:';
    RAISE NOTICE '   SELECT * FROM get_challenge_leaderboard(''YOUR_CHALLENGE_ID'');';
END $$;

