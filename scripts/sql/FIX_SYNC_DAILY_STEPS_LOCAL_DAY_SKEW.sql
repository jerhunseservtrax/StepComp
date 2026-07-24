-- Allow syncing the client's local calendar day when it is one day ahead of
-- the database CURRENT_DATE (UTC). Required after clients send YYYY-MM-DD in
-- the device local timezone to match HealthKit day boundaries.
--
-- This is the sync_daily_steps body from IMPLEMENT_SECURITY_OVERHAUL_V2_SAFE.sql
-- with only the future-day guard relaxed to CURRENT_DATE + 1.

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
BEGIN
    -- Get user from JWT (never trust client)
    v_user_id := auth.uid();

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Default to today if no day specified
    v_day := COALESCE(p_day, CURRENT_DATE);

    -- Validate: can't sync far-future days.
    -- Allow CURRENT_DATE + 1 so clients east of UTC can sync their local
    -- calendar day while the database session is still on the previous UTC date.
    IF v_day > CURRENT_DATE + 1 THEN
        RAISE EXCEPTION 'Cannot sync steps for future dates';
    END IF;

    -- Validate: can't sync very old days (30 days max)
    IF v_day < CURRENT_DATE - INTERVAL '30 days' THEN
        RAISE EXCEPTION 'Cannot sync steps older than 30 days';
    END IF;

    -- Get previous record if exists
    SELECT steps, updated_at INTO v_previous_steps, v_last_update
    FROM public.daily_steps
    WHERE user_id = v_user_id AND day = v_day;

    v_step_diff := p_steps - COALESCE(v_previous_steps, 0);

    -- ============================================
    -- Fraud detection: realistic patterns
    -- ============================================
    IF v_last_update IS NOT NULL THEN
        -- Too many steps added too quickly (>5000 in 5 minutes)
        IF v_step_diff > 5000 AND (NOW() - v_last_update) < INTERVAL '5 minutes' THEN
            v_is_suspicious := TRUE;
        END IF;

        -- ✅ Allow small negative deltas (HealthKit can revise downward)
        -- Only flag large negative changes
        IF v_step_diff < -500 THEN
            v_is_suspicious := TRUE;
        END IF;
    END IF;

    -- Absolute limits (100k steps/day is ~50 miles, very rare but possible)
    IF p_steps > 100000 THEN
        v_is_suspicious := TRUE;
    END IF;

    -- ============================================
    -- Insert or update daily_steps
    -- ============================================
    INSERT INTO public.daily_steps (
        user_id,
        day,
        steps,
        source,
        device_id,
        ip_address,
        user_agent,
        is_suspicious
    )
    VALUES (
        v_user_id,
        v_day,
        p_steps,
        p_source,
        p_device_id,
        p_ip,
        p_user_agent,
        v_is_suspicious
    )
    ON CONFLICT (user_id, day)
    DO UPDATE SET
        steps = p_steps,
        source = p_source,
        device_id = p_device_id,
        ip_address = p_ip,
        user_agent = p_user_agent,
        is_suspicious = CASE
            WHEN v_is_suspicious THEN TRUE
            ELSE daily_steps.is_suspicious
        END,
        updated_at = NOW();

    -- ============================================
    -- Update profiles.total_steps (last 30 days only - bounded!)
    -- ============================================
    UPDATE public.profiles
    SET
        total_steps = (
            SELECT COALESCE(SUM(steps), 0)
            FROM public.daily_steps
            WHERE user_id = v_user_id
            AND day >= CURRENT_DATE - INTERVAL '30 days'  -- ✅ Bounded query
            AND is_suspicious = FALSE  -- Only count verified steps
        ),
        updated_at = NOW()
    WHERE id = v_user_id;

    -- ============================================
    -- ❌ REMOVED: challenge_members denormalization
    -- ============================================
    -- We compute challenge totals via leaderboard RPCs instead.
    -- This is MUCH faster and more scalable.

    -- Return result
    RETURN json_build_object(
        'success', TRUE,
        'accepted_steps', p_steps,
        'day', v_day,
        'is_suspicious', v_is_suspicious,
        'previous_steps', v_previous_steps,
        'message', CASE
            WHEN v_is_suspicious THEN 'Steps recorded but flagged for review'
            ELSE 'Steps synced successfully'
        END
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.sync_daily_steps TO authenticated;

COMMENT ON FUNCTION public.sync_daily_steps IS 'Server-side step sync with validation. Called by Edge Function. Uses auth.uid() for security. Allows local calendar day up to CURRENT_DATE + 1 for timezone skew.';
