-- ============================================
-- FIX: sync_daily_steps last-write-wins data loss
-- ============================================
-- Live proof (2026-08-01):
-- 1) Authenticated user calls sync_daily_steps with p_steps=12000 → stored.
-- 2) Same user later calls sync_daily_steps with p_steps=3000 → RPC returns
--    accepted_steps=3000 and daily_steps.steps becomes 3000.
-- 3) Challenge leaderboards SUM(daily_steps.steps), so competitive totals drop.
--
-- Trigger scenarios:
-- - Mid-day high sync followed by a lower HealthKit reading / second device
-- - UTC day-key skew (evening local steps keyed to next UTC day, then morning
--   overwrite with a low morning count) — see also PR #51 local-day fix
--
-- Root cause:
--   ON CONFLICT DO UPDATE SET steps = p_steps unconditionally overwrites.
--   Large negative deltas only set a response is_suspicious flag; the live
--   table has no is_suspicious column, so the lower value still wins.
--
-- Fix:
--   Keep the higher of the existing and incoming step counts (monotonic upsert).
--   Matches live schema: last_synced_at (not updated_at), no is_suspicious column.
--
-- Deploy in Supabase SQL Editor after review.
-- ============================================

CREATE OR REPLACE FUNCTION public.sync_daily_steps(
    p_day DATE DEFAULT NULL,
    p_steps INT DEFAULT 0,
    p_source TEXT DEFAULT 'healthkit',
    p_device_id TEXT DEFAULT NULL,
    p_ip INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_day DATE;
    v_previous_steps INT;
    v_step_diff INT;
    v_is_suspicious BOOLEAN := FALSE;
    v_last_update TIMESTAMPTZ;
    v_accepted_steps INT;
BEGIN
    -- Get user from JWT (never trust client)
    v_user_id := auth.uid();

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Default to today if no day specified
    v_day := COALESCE(p_day, CURRENT_DATE);

    -- Validate: can't sync future days
    IF v_day > CURRENT_DATE THEN
        RAISE EXCEPTION 'Cannot sync steps for future dates';
    END IF;

    -- Validate: can't sync very old days (30 days max)
    IF v_day < CURRENT_DATE - INTERVAL '30 days' THEN
        RAISE EXCEPTION 'Cannot sync steps older than 30 days';
    END IF;

    -- Reject absurd absolute values (Edge Function also guards this)
    IF p_steps < 0 THEN
        RAISE EXCEPTION 'Invalid steps value';
    END IF;

    -- Get previous record if exists (live column is last_synced_at)
    SELECT steps, last_synced_at INTO v_previous_steps, v_last_update
    FROM public.daily_steps
    WHERE user_id = v_user_id AND day = v_day;

    v_step_diff := p_steps - COALESCE(v_previous_steps, 0);

    -- ============================================
    -- Fraud detection: realistic patterns (response flag only;
    -- live daily_steps has no is_suspicious column to persist)
    -- ============================================
    IF v_last_update IS NOT NULL THEN
        -- Too many steps added too quickly (>5000 in 5 minutes)
        IF v_step_diff > 5000 AND (NOW() - v_last_update) < INTERVAL '5 minutes' THEN
            v_is_suspicious := TRUE;
        END IF;

        -- Large downward revision (HealthKit/device race) — keep higher via GREATEST
        IF v_step_diff < -500 THEN
            v_is_suspicious := TRUE;
        END IF;
    END IF;

    -- Absolute limits (100k steps/day is ~50 miles, very rare but possible)
    IF p_steps > 100000 THEN
        v_is_suspicious := TRUE;
    END IF;

    -- Never store below the highest known count for the day
    v_accepted_steps := GREATEST(COALESCE(v_previous_steps, 0), p_steps);

    -- ============================================
    -- Insert or update daily_steps (live columns only)
    -- ============================================
    INSERT INTO public.daily_steps (
        user_id,
        day,
        steps,
        source,
        device_id,
        ip_address,
        user_agent,
        last_synced_at
    )
    VALUES (
        v_user_id,
        v_day,
        v_accepted_steps,
        p_source,
        p_device_id,
        p_ip,
        p_user_agent,
        NOW()
    )
    ON CONFLICT (user_id, day)
    DO UPDATE SET
        steps = GREATEST(daily_steps.steps, EXCLUDED.steps),
        source = EXCLUDED.source,
        device_id = EXCLUDED.device_id,
        ip_address = EXCLUDED.ip_address,
        user_agent = EXCLUDED.user_agent,
        last_synced_at = NOW();

    -- Re-read accepted value after upsert (defense if concurrent writers)
    SELECT steps INTO v_accepted_steps
    FROM public.daily_steps
    WHERE user_id = v_user_id AND day = v_day;

    -- ============================================
    -- Update profiles.total_steps (last 30 days only - bounded!)
    -- Do not filter is_suspicious — column is not live.
    -- ============================================
    UPDATE public.profiles
    SET
        total_steps = (
            SELECT COALESCE(SUM(steps), 0)
            FROM public.daily_steps
            WHERE user_id = v_user_id
              AND day >= CURRENT_DATE - INTERVAL '30 days'
        ),
        updated_at = NOW()
    WHERE id = v_user_id;

    RETURN json_build_object(
        'success', TRUE,
        'accepted_steps', v_accepted_steps,
        'day', v_day,
        'is_suspicious', v_is_suspicious,
        'previous_steps', v_previous_steps,
        'message', CASE
            WHEN v_previous_steps IS NOT NULL AND v_accepted_steps > p_steps THEN
                'Kept higher previously synced step count'
            WHEN v_is_suspicious THEN
                'Steps recorded but flagged for review'
            ELSE
                'Steps synced successfully'
        END
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.sync_daily_steps TO authenticated;

COMMENT ON FUNCTION public.sync_daily_steps IS
  'Server-side step sync with validation. Uses auth.uid(). Monotonic upsert: never lowers daily_steps.steps on conflict.';
