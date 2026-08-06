-- ============================================
-- FIX: Step history + waitlist SECURITY DEFINER IDORs
-- ============================================
-- Live proof (2026-08-06):
--
-- 1) get_user_step_history(p_user_id, p_start_date, p_end_date)
--    Any authenticated user can pass another user's UUID and read that
--    user's private daily_steps history. Direct SELECT on daily_steps is
--    correctly RLS-filtered to the caller (returns []), but this
--    SECURITY DEFINER RPC bypasses RLS and trusts p_user_id.
--
--    Example:
--      User A syncs steps for 2026-08-06 via sync_daily_steps
--      User B GET /daily_steps?user_id=eq.<A> → []
--      User B POST /rpc/get_user_step_history
--        {"p_user_id":"<A>","p_start_date":"...","p_end_date":"..."}
--        → [{"day":"...","steps":4321,"is_suspicious":false}]
--
-- 2) get_recent_waitlist_signups(limit_count)
--    Comment says "admin only", but EXECUTE is granted to authenticated.
--    Any signed-up user can read waitlist emails / referral metadata while
--    direct SELECT on waitlist correctly returns [].
--
-- Live schema notes:
--   - daily_steps has NO is_suspicious column (RPC synthesizes false)
--   - daily_steps uses last_synced_at (not updated_at)
--   - Live get_user_step_history requires p_user_id (repo 2-arg overload
--     is not what production exposes)
--
-- Fix:
--   - Force get_user_step_history to auth.uid() only (ignore/deny other ids)
--   - Revoke waitlist signup listing from anon/authenticated; service_role only
--
-- Deploy in Supabase SQL Editor after review.
-- ============================================

-- ----------------------------------------
-- 1) get_user_step_history — self only
-- ----------------------------------------
-- Drop both known signatures so PostgREST cannot keep serving the
-- cross-user overload alongside a safer one.
DROP FUNCTION IF EXISTS public.get_user_step_history(UUID, DATE, DATE);
DROP FUNCTION IF EXISTS public.get_user_step_history(DATE, DATE);

CREATE OR REPLACE FUNCTION public.get_user_step_history(
    p_user_id UUID DEFAULT NULL,
    p_start_date DATE DEFAULT (CURRENT_DATE - INTERVAL '7 days'),
    p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE(
    day DATE,
    steps INT,
    is_suspicious BOOLEAN
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    SELECT
        ds.day,
        ds.steps,
        FALSE AS is_suspicious
    FROM public.daily_steps ds
    WHERE auth.uid() IS NOT NULL
      AND ds.user_id = auth.uid()
      -- Reject cross-user requests; NULL p_user_id means "caller".
      AND (p_user_id IS NULL OR p_user_id = auth.uid())
      AND ds.day BETWEEN p_start_date AND p_end_date
      AND ds.day >= CURRENT_DATE - INTERVAL '90 days'
    ORDER BY ds.day DESC;
$$;

REVOKE ALL ON FUNCTION public.get_user_step_history(UUID, DATE, DATE) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_user_step_history(UUID, DATE, DATE) TO authenticated;

COMMENT ON FUNCTION public.get_user_step_history(UUID, DATE, DATE) IS
  'Returns the caller''s own daily_steps history only. p_user_id must be NULL or auth.uid(); other users always get an empty result (no RLS bypass IDOR).';

-- ----------------------------------------
-- 2) get_recent_waitlist_signups — service_role only
-- ----------------------------------------
CREATE OR REPLACE FUNCTION public.get_recent_waitlist_signups(
    limit_count INTEGER DEFAULT 10
)
RETURNS TABLE (
    id UUID,
    email TEXT,
    referral_source TEXT,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
BEGIN
    IF auth.role() IS DISTINCT FROM 'service_role' THEN
        RAISE EXCEPTION 'not authorized'
            USING ERRCODE = '42501';
    END IF;

    RETURN QUERY
    SELECT
        w.id,
        w.email,
        w.referral_source,
        w.created_at
    FROM public.waitlist w
    ORDER BY w.created_at DESC
    LIMIT GREATEST(COALESCE(limit_count, 10), 0);
END;
$$;

REVOKE ALL ON FUNCTION public.get_recent_waitlist_signups(INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_recent_waitlist_signups(INTEGER) FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_recent_waitlist_signups(INTEGER) TO service_role;

COMMENT ON FUNCTION public.get_recent_waitlist_signups(INTEGER) IS
  'Admin/service_role only. Lists recent waitlist emails; must never be executable by anon or authenticated clients.';
