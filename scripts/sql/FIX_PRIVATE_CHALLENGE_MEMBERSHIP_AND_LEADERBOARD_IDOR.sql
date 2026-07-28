-- ============================================
-- FIX: Private challenge membership + leaderboard IDOR
-- ============================================
-- Live proof (2026-07-28):
-- 1) Any authenticated user who knows a private challenge UUID can
--    INSERT themselves into challenge_members (policy only required
--    user_id = auth.uid()). Membership then unlocks challenge_messages
--    SELECT/INSERT via membership-scoped chat RLS.
-- 2) get_challenge_leaderboard / get_challenge_leaderboard_today are
--    SECURITY DEFINER with no membership/public/creator gate, so a
--    non-member can read member user_id / username / display_name / steps.
--
-- Legitimate join paths preserved:
-- - Public challenges: direct INSERT when is_public
-- - Creator self-enroll on create: created_by = auth.uid()
-- - Pending challenge_invites: invitee may INSERT (or use accept_challenge_invite
--   SECURITY DEFINER RPC, which bypasses RLS)
--
-- Deploy in Supabase SQL Editor after review.
-- Does NOT depend on daily_steps.is_suspicious (column not live).
-- ============================================

-- --------------------------------------------
-- 1. Tighten challenge_members INSERT policies
-- --------------------------------------------
DROP POLICY IF EXISTS "Insert own membership" ON public.challenge_members;
DROP POLICY IF EXISTS "Users can insert their own membership" ON public.challenge_members;
DROP POLICY IF EXISTS "Users can insert challenge members" ON public.challenge_members;
DROP POLICY IF EXISTS "Users can join challenges" ON public.challenge_members;
DROP POLICY IF EXISTS "Creators can add members" ON public.challenge_members;
DROP POLICY IF EXISTS "Creators can add members to their challenges" ON public.challenge_members;

-- Self-insert only when the challenge is public, the caller is the creator
-- (self-enroll), or the caller has a pending invite row.
CREATE POLICY "Insert own membership when allowed"
  ON public.challenge_members
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND (
      EXISTS (
        SELECT 1
        FROM public.challenges c
        WHERE c.id = challenge_members.challenge_id
          AND (
            c.is_public = TRUE
            OR c.created_by = auth.uid()
          )
      )
      OR EXISTS (
        SELECT 1
        FROM public.challenge_invites ci
        WHERE ci.challenge_id = challenge_members.challenge_id
          AND ci.invitee_id = auth.uid()
          AND ci.status = 'pending'
      )
    )
  );

-- --------------------------------------------
-- 2. Gate all-time leaderboard RPC (live signature)
-- --------------------------------------------
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
    challenge_members_cte AS (
        SELECT cm.user_id
        FROM public.challenge_members cm
        WHERE cm.challenge_id = p_challenge_id
          AND EXISTS (SELECT 1 FROM access_check)
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

GRANT EXECUTE ON FUNCTION public.get_challenge_leaderboard(UUID) TO authenticated;

COMMENT ON FUNCTION public.get_challenge_leaderboard IS
  'All-time challenge leaderboard from daily_steps. Requires member, creator, or public challenge.';

-- --------------------------------------------
-- 3. Gate today leaderboard RPC (live UUID-only signature)
-- --------------------------------------------
-- Keep the live single-arg signature so existing clients keep working.
-- Optional local-day overload can be added by a separate weekly/day fix.
DROP FUNCTION IF EXISTS public.get_challenge_leaderboard_today(UUID);

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
    challenge_members_cte AS (
        SELECT cm.user_id
        FROM public.challenge_members cm
        WHERE cm.challenge_id = p_challenge_id
          AND EXISTS (SELECT 1 FROM access_check)
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

GRANT EXECUTE ON FUNCTION public.get_challenge_leaderboard_today(UUID) TO authenticated;

COMMENT ON FUNCTION public.get_challenge_leaderboard_today IS
  'Daily challenge leaderboard from daily_steps. Requires member, creator, or public challenge.';

-- --------------------------------------------
-- 4. Hardening note for overhaul scripts
-- --------------------------------------------
-- Also update checked-in V2 INSERT policies so a future redeploy does not
-- reintroduce force-enroll / open private self-join. See companion edits in
-- IMPLEMENT_SECURITY_OVERHAUL_V2_SAFE.sql when applying this fix in-repo.
