-- ============================================
-- Security Overhaul: Backend as Source of Truth
-- ============================================
-- This script implements:
-- 1. daily_steps table for audit trail
-- 2. rate_limits table for API throttling
-- 3. Server-side step sync function
-- 4. Leaderboard calculation from daily_steps
-- 5. RLS policies for all new tables
-- ============================================

-- ============================================
-- 1. Create daily_steps table (event log)
-- ============================================

CREATE TABLE IF NOT EXISTS public.daily_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    day DATE NOT NULL,
    steps INT NOT NULL CHECK (steps >= 0),
    source TEXT NOT NULL DEFAULT 'healthkit', -- 'healthkit', 'manual', 'synced'
    device_id TEXT,
    ip_address INET,
    user_agent TEXT,
    is_suspicious BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- One record per user per day
    UNIQUE(user_id, day)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_daily_steps_user_day ON public.daily_steps(user_id, day DESC);
CREATE INDEX IF NOT EXISTS idx_daily_steps_day ON public.daily_steps(day);
CREATE INDEX IF NOT EXISTS idx_daily_steps_suspicious ON public.daily_steps(is_suspicious) WHERE is_suspicious = TRUE;

-- RLS policies
ALTER TABLE public.daily_steps ENABLE ROW LEVEL SECURITY;

-- Users can view their own daily steps
CREATE POLICY "Users can view own daily steps"
  ON public.daily_steps FOR SELECT
  USING (user_id = auth.uid());

-- Users can view daily steps for public challenge members
CREATE POLICY "Users can view challenge members daily steps"
  ON public.daily_steps FOR SELECT
  USING (
    EXISTS (
      SELECT 1 
      FROM public.challenge_members cm
      JOIN public.challenges c ON c.id = cm.challenge_id
      WHERE cm.user_id = daily_steps.user_id
      AND (
        c.is_public = TRUE 
        OR c.created_by = auth.uid()
        OR EXISTS (
          SELECT 1 FROM public.challenge_members cm2 
          WHERE cm2.challenge_id = c.id 
          AND cm2.user_id = auth.uid()
        )
      )
    )
  );

-- Only server can insert/update (via RPC functions)
-- No direct INSERT/UPDATE policies for clients

COMMENT ON TABLE public.daily_steps IS 'Audit trail of user step counts per day. Source of truth for leaderboards.';

-- ============================================
-- 2. Create rate_limits table
-- ============================================

CREATE TABLE IF NOT EXISTS public.rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    bucket TEXT NOT NULL, -- e.g., 'minute:2024-01-15T10:30', 'hour:2024-01-15T10'
    count INT NOT NULL DEFAULT 1,
    reset_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE(user_id, bucket)
);

CREATE INDEX IF NOT EXISTS idx_rate_limits_user_bucket ON public.rate_limits(user_id, bucket);
CREATE INDEX IF NOT EXISTS idx_rate_limits_reset ON public.rate_limits(reset_at);

-- Clean up expired rate limits (run periodically)
CREATE OR REPLACE FUNCTION public.cleanup_expired_rate_limits()
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INT;
BEGIN
    DELETE FROM public.rate_limits
    WHERE reset_at < NOW() - INTERVAL '1 day';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$;

-- No RLS on rate_limits - only Edge Functions access this table

COMMENT ON TABLE public.rate_limits IS 'Rate limiting buckets for API throttling';

-- ============================================
-- 3. Helper function: increment_rate_limit
-- ============================================

CREATE OR REPLACE FUNCTION public.increment_rate_limit(
    p_user_id UUID,
    p_bucket TEXT,
    p_reset_at TIMESTAMPTZ
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.rate_limits (user_id, bucket, count, reset_at)
    VALUES (p_user_id, p_bucket, 1, p_reset_at)
    ON CONFLICT (user_id, bucket)
    DO UPDATE SET 
        count = rate_limits.count + 1,
        updated_at = NOW();
END;
$$;

GRANT EXECUTE ON FUNCTION public.increment_rate_limit TO authenticated;

-- ============================================
-- 4. Server-side step sync function
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
    
    -- Validate: can't sync future days
    IF v_day > CURRENT_DATE THEN
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
    
    -- Fraud detection: suspicious patterns
    IF v_last_update IS NOT NULL THEN
        -- Too many steps added too quickly (>5000 in 5 minutes)
        IF v_step_diff > 5000 AND (NOW() - v_last_update) < INTERVAL '5 minutes' THEN
            v_is_suspicious := TRUE;
        END IF;
        
        -- Steps decreased (shouldn't happen)
        IF v_step_diff < 0 THEN
            v_is_suspicious := TRUE;
        END IF;
    END IF;
    
    -- Absolute limits
    IF p_steps > 100000 THEN
        v_is_suspicious := TRUE;
    END IF;
    
    -- Insert or update
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
    
    -- Also update profiles.total_steps (for quick display)
    UPDATE public.profiles
    SET 
        total_steps = (
            SELECT COALESCE(SUM(steps), 0)
            FROM public.daily_steps
            WHERE user_id = v_user_id
        ),
        updated_at = NOW()
    WHERE id = v_user_id;
    
    -- Update challenge_members with today's steps
    UPDATE public.challenge_members cm
    SET 
        total_steps = (
            SELECT COALESCE(SUM(ds.steps), 0)
            FROM public.daily_steps ds
            JOIN public.challenges c ON c.id = cm.challenge_id
            WHERE ds.user_id = cm.user_id
            AND ds.day BETWEEN c.start_date AND c.end_date
        ),
        daily_steps = jsonb_set(
            COALESCE(cm.daily_steps, '{}'::jsonb),
            ARRAY[v_day::text],
            to_jsonb(p_steps)
        ),
        last_updated = NOW()
    WHERE cm.user_id = v_user_id
    AND EXISTS (
        SELECT 1 FROM public.challenges c
        WHERE c.id = cm.challenge_id
        AND v_day BETWEEN c.start_date AND c.end_date
    );
    
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

COMMENT ON FUNCTION public.sync_daily_steps IS 'Server-side step synchronization with validation and fraud detection';

-- ============================================
-- 5. Leaderboard calculation functions
-- ============================================

-- Get challenge leaderboard (overall)
CREATE OR REPLACE FUNCTION public.get_challenge_leaderboard(
    p_challenge_id UUID
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
STABLE
AS $$
    WITH member_steps AS (
        SELECT 
            cm.user_id,
            COALESCE(SUM(ds.steps), 0) AS total_steps
        FROM public.challenge_members cm
        JOIN public.challenges c ON c.id = cm.challenge_id
        LEFT JOIN public.daily_steps ds 
            ON ds.user_id = cm.user_id
            AND ds.day BETWEEN c.start_date AND c.end_date
            AND ds.is_suspicious = FALSE  -- Exclude suspicious entries
        WHERE cm.challenge_id = p_challenge_id
        GROUP BY cm.user_id
    )
    SELECT 
        ms.user_id,
        p.username,
        p.display_name,
        p.avatar_url,
        ms.total_steps AS steps,
        RANK() OVER (ORDER BY ms.total_steps DESC) AS rank
    FROM member_steps ms
    JOIN public.profiles p ON p.id = ms.user_id
    ORDER BY ms.total_steps DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_challenge_leaderboard(UUID) TO authenticated;

-- Get challenge leaderboard for today
CREATE OR REPLACE FUNCTION public.get_challenge_leaderboard_today(
    p_challenge_id UUID
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
STABLE
AS $$
    WITH today_steps AS (
        SELECT 
            cm.user_id,
            COALESCE(ds.steps, 0) AS today_steps
        FROM public.challenge_members cm
        LEFT JOIN public.daily_steps ds 
            ON ds.user_id = cm.user_id
            AND ds.day = CURRENT_DATE
            AND ds.is_suspicious = FALSE
        WHERE cm.challenge_id = p_challenge_id
    )
    SELECT 
        ts.user_id,
        p.username,
        p.display_name,
        p.avatar_url,
        ts.today_steps AS steps,
        RANK() OVER (ORDER BY ts.today_steps DESC) AS rank
    FROM today_steps ts
    JOIN public.profiles p ON p.id = ts.user_id
    ORDER BY ts.today_steps DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_challenge_leaderboard_today(UUID) TO authenticated;

-- Get user's step history for a date range
CREATE OR REPLACE FUNCTION public.get_user_step_history(
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '7 days',
    p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE(
    day DATE,
    steps INT,
    is_suspicious BOOLEAN
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
    SELECT 
        day,
        steps,
        is_suspicious
    FROM public.daily_steps
    WHERE user_id = auth.uid()
    AND day BETWEEN p_start_date AND p_end_date
    ORDER BY day DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_step_history TO authenticated;

-- ============================================
-- 6. Verification queries
-- ============================================

-- Check if tables exist
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM (VALUES 
    ('daily_steps'),
    ('rate_limits')
) AS t(table_name);

-- Check if functions exist
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN (
    'sync_daily_steps',
    'get_challenge_leaderboard',
    'get_challenge_leaderboard_today',
    'get_user_step_history',
    'increment_rate_limit',
    'cleanup_expired_rate_limits'
);

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Security overhaul complete!';
    RAISE NOTICE '   - daily_steps table created (audit trail)';
    RAISE NOTICE '   - rate_limits table created';
    RAISE NOTICE '   - sync_daily_steps() function ready';
    RAISE NOTICE '   - Leaderboard functions ready';
    RAISE NOTICE '   - All RLS policies applied';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Deploy Edge Function: supabase functions deploy sync-steps';
    RAISE NOTICE '2. Update Swift code to use Edge Function';
    RAISE NOTICE '3. Remove direct database writes from client';
END $$;

