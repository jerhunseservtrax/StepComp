-- Fix weekly challenge leaderboard after Security Overhaul V2.
--
-- V2 stopped denormalizing steps into challenge_members.daily_steps JSONB.
-- Daily/all-time already use SECURITY DEFINER RPCs over public.daily_steps,
-- but the iOS Week tab still summed the abandoned JSONB map (always 0).
--
-- Also accept an explicit local p_day for get_challenge_leaderboard_today so
-- clients east/west of UTC are not joined against server CURRENT_DATE.

-- ============================================
-- 1. Weekly leaderboard from daily_steps
-- ============================================

CREATE OR REPLACE FUNCTION public.get_challenge_leaderboard_week(
    p_challenge_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
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
    WITH access_check AS (
        SELECT 1
        FROM public.challenges c
        WHERE c.id = p_challenge_id
          AND (
              c.is_public = TRUE
              OR c.created_by = auth.uid()
              OR EXISTS (
                  SELECT 1
                  FROM public.challenge_members cm_auth
                  WHERE cm_auth.challenge_id = c.id
                    AND cm_auth.user_id = auth.uid()
              )
          )
    ),
    challenge_members AS (
        SELECT cm.user_id
        FROM public.challenge_members cm
        WHERE cm.challenge_id = p_challenge_id
          AND EXISTS (SELECT 1 FROM access_check)
    ),
    member_steps AS (
        SELECT
            cm.user_id,
            COALESCE(SUM(ds.steps), 0) AS total_steps
        FROM challenge_members cm
        LEFT JOIN public.daily_steps ds
            ON ds.user_id = cm.user_id
            AND ds.day BETWEEN LEAST(p_start_date, p_end_date)
                           AND GREATEST(p_start_date, p_end_date)
            AND ds.is_suspicious = FALSE
        GROUP BY cm.user_id
    )
    SELECT
        ms.user_id,
        COALESCE(p.username, 'User') AS username,
        p.display_name,
        p.avatar_url,
        ms.total_steps AS steps,
        RANK() OVER (ORDER BY ms.total_steps DESC) AS rank
    FROM member_steps ms
    LEFT JOIN public.profiles p ON p.id = ms.user_id
    ORDER BY ms.total_steps DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_challenge_leaderboard_week(UUID, DATE, DATE) TO authenticated;

COMMENT ON FUNCTION public.get_challenge_leaderboard_week IS
  'Compute challenge leaderboard for an inclusive local date range from daily_steps.';

-- ============================================
-- 2. Today leaderboard with optional local day
-- ============================================

DROP FUNCTION IF EXISTS public.get_challenge_leaderboard_today(UUID);
DROP FUNCTION IF EXISTS public.get_challenge_leaderboard_today(UUID, DATE);

CREATE FUNCTION public.get_challenge_leaderboard_today(
    p_challenge_id UUID,
    p_day DATE DEFAULT NULL
)
RETURNS TABLE(
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
    WITH access_check AS (
        SELECT 1
        FROM public.challenges c
        WHERE c.id = p_challenge_id
          AND (
              c.is_public = TRUE
              OR c.created_by = auth.uid()
              OR EXISTS (
                  SELECT 1
                  FROM public.challenge_members cm_auth
                  WHERE cm_auth.challenge_id = c.id
                    AND cm_auth.user_id = auth.uid()
              )
          )
    ),
    challenge_members AS (
        SELECT cm.user_id
        FROM public.challenge_members cm
        WHERE cm.challenge_id = p_challenge_id
          AND EXISTS (SELECT 1 FROM access_check)
    ),
    today_steps AS (
        SELECT
            cm.user_id,
            COALESCE(ds.steps, 0) AS today_steps
        FROM challenge_members cm
        LEFT JOIN public.daily_steps ds
            ON ds.user_id = cm.user_id
            AND ds.day = COALESCE(p_day, CURRENT_DATE)
            AND ds.is_suspicious = FALSE
    )
    SELECT
        ts.user_id,
        COALESCE(p.username, 'User') AS username,
        p.display_name,
        p.avatar_url,
        ts.today_steps AS steps,
        RANK() OVER (ORDER BY ts.today_steps DESC) AS rank
    FROM today_steps ts
    LEFT JOIN public.profiles p ON p.id = ts.user_id
    ORDER BY ts.today_steps DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_challenge_leaderboard_today(UUID, DATE) TO authenticated;

COMMENT ON FUNCTION public.get_challenge_leaderboard_today IS
  'Compute challenge leaderboard for a local calendar day from daily_steps. p_day defaults to CURRENT_DATE.';
