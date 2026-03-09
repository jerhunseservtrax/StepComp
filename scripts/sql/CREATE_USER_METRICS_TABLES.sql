-- ============================================
-- USER METRICS BACKEND
-- ============================================
-- Stores workout sessions, exercise sets, and body weight entries
-- per user so the app can display historical trends on a Metrics page.
-- All tables use RLS to ensure each user only sees their own data.
-- ============================================

-- ============================================
-- STEP 1: workout_sessions table
-- ============================================
CREATE TABLE IF NOT EXISTS public.workout_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    workout_id UUID,
    workout_name TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ NOT NULL,
    duration_seconds INT GENERATED ALWAYS AS (
        EXTRACT(EPOCH FROM (ended_at - started_at))::INT
    ) STORED,
    total_volume_kg INT NOT NULL DEFAULT 0,
    max_weight_kg INT NOT NULL DEFAULT 0,
    source TEXT NOT NULL DEFAULT 'app',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_workout_sessions_user_start UNIQUE(user_id, started_at)
);

CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_ended
    ON public.workout_sessions(user_id, ended_at DESC);

CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_created
    ON public.workout_sessions(user_id, created_at DESC);

ALTER TABLE public.workout_sessions ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can read own workout sessions" ON public.workout_sessions;
    DROP POLICY IF EXISTS "Users can insert own workout sessions" ON public.workout_sessions;
    DROP POLICY IF EXISTS "Users can update own workout sessions" ON public.workout_sessions;
    DROP POLICY IF EXISTS "Users can delete own workout sessions" ON public.workout_sessions;
END $$;

CREATE POLICY "Users can read own workout sessions"
    ON public.workout_sessions FOR SELECT TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert own workout sessions"
    ON public.workout_sessions FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own workout sessions"
    ON public.workout_sessions FOR UPDATE TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own workout sessions"
    ON public.workout_sessions FOR DELETE TO authenticated
    USING (user_id = auth.uid());

-- ============================================
-- STEP 2: workout_session_sets table
-- ============================================
CREATE TABLE IF NOT EXISTS public.workout_session_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES public.workout_sessions(id) ON DELETE CASCADE,
    exercise_name TEXT NOT NULL,
    target_muscles TEXT,
    set_number INT NOT NULL,
    weight_kg INT,
    reps INT,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workout_session_sets_session
    ON public.workout_session_sets(session_id);

CREATE INDEX IF NOT EXISTS idx_workout_session_sets_exercise_time
    ON public.workout_session_sets(exercise_name, created_at);

ALTER TABLE public.workout_session_sets ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can read own workout sets" ON public.workout_session_sets;
    DROP POLICY IF EXISTS "Users can insert own workout sets" ON public.workout_session_sets;
    DROP POLICY IF EXISTS "Users can delete own workout sets" ON public.workout_session_sets;
END $$;

CREATE POLICY "Users can read own workout sets"
    ON public.workout_session_sets FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.workout_sessions ws
            WHERE ws.id = session_id AND ws.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own workout sets"
    ON public.workout_session_sets FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.workout_sessions ws
            WHERE ws.id = session_id AND ws.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own workout sets"
    ON public.workout_session_sets FOR DELETE TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.workout_sessions ws
            WHERE ws.id = session_id AND ws.user_id = auth.uid()
        )
    );

-- ============================================
-- STEP 3: weight_log table
-- ============================================
CREATE TABLE IF NOT EXISTS public.weight_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    recorded_on DATE NOT NULL,
    weight_kg NUMERIC(5,2) NOT NULL CHECK (weight_kg > 0),
    source TEXT NOT NULL DEFAULT 'manual',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_weight_log_user_date UNIQUE(user_id, recorded_on)
);

CREATE INDEX IF NOT EXISTS idx_weight_log_user_date
    ON public.weight_log(user_id, recorded_on DESC);

ALTER TABLE public.weight_log ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can read own weight log" ON public.weight_log;
    DROP POLICY IF EXISTS "Users can insert own weight log" ON public.weight_log;
    DROP POLICY IF EXISTS "Users can update own weight log" ON public.weight_log;
    DROP POLICY IF EXISTS "Users can delete own weight log" ON public.weight_log;
END $$;

CREATE POLICY "Users can read own weight log"
    ON public.weight_log FOR SELECT TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert own weight log"
    ON public.weight_log FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own weight log"
    ON public.weight_log FOR UPDATE TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own weight log"
    ON public.weight_log FOR DELETE TO authenticated
    USING (user_id = auth.uid());

-- ============================================
-- STEP 4: RPC — sync_workout_session
-- ============================================
-- Accepts a JSON payload containing the session header and an array of sets.
-- Inserts into workout_sessions + workout_session_sets in one transaction.
-- Uses ON CONFLICT to make re-syncs idempotent.
-- ============================================
CREATE OR REPLACE FUNCTION public.sync_workout_session(p_session JSONB)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_session_id UUID;
    v_workout_id UUID;
    v_workout_name TEXT;
    v_started_at TIMESTAMPTZ;
    v_ended_at TIMESTAMPTZ;
    v_total_volume INT := 0;
    v_max_weight INT := 0;
    v_source TEXT;
    v_set JSONB;
    v_weight INT;
    v_reps INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Extract session fields
    v_workout_name := p_session->>'workout_name';
    v_started_at   := (p_session->>'started_at')::TIMESTAMPTZ;
    v_ended_at     := (p_session->>'ended_at')::TIMESTAMPTZ;
    v_source       := COALESCE(p_session->>'source', 'app');

    IF p_session->>'workout_id' IS NOT NULL AND p_session->>'workout_id' <> '' THEN
        v_workout_id := (p_session->>'workout_id')::UUID;
    END IF;

    IF v_workout_name IS NULL OR v_started_at IS NULL OR v_ended_at IS NULL THEN
        RAISE EXCEPTION 'Missing required fields: workout_name, started_at, ended_at';
    END IF;

    -- Compute aggregates from the sets array
    FOR v_set IN SELECT * FROM jsonb_array_elements(COALESCE(p_session->'sets', '[]'::JSONB))
    LOOP
        v_weight := (v_set->>'weight_kg')::INT;
        v_reps   := (v_set->>'reps')::INT;
        IF v_weight IS NOT NULL AND v_reps IS NOT NULL AND (v_set->>'is_completed')::BOOLEAN THEN
            v_total_volume := v_total_volume + (v_weight * v_reps);
            IF v_weight > v_max_weight THEN
                v_max_weight := v_weight;
            END IF;
        END IF;
    END LOOP;

    -- Upsert session row
    INSERT INTO public.workout_sessions (
        user_id, workout_id, workout_name, started_at, ended_at,
        total_volume_kg, max_weight_kg, source
    )
    VALUES (
        v_user_id, v_workout_id, v_workout_name, v_started_at, v_ended_at,
        v_total_volume, v_max_weight, v_source
    )
    ON CONFLICT (user_id, started_at) DO UPDATE SET
        workout_name   = EXCLUDED.workout_name,
        ended_at       = EXCLUDED.ended_at,
        total_volume_kg = EXCLUDED.total_volume_kg,
        max_weight_kg  = EXCLUDED.max_weight_kg,
        source         = EXCLUDED.source
    RETURNING id INTO v_session_id;

    -- Replace existing sets for this session (idempotent)
    DELETE FROM public.workout_session_sets WHERE session_id = v_session_id;

    -- Insert sets
    INSERT INTO public.workout_session_sets (
        session_id, exercise_name, target_muscles, set_number,
        weight_kg, reps, is_completed
    )
    SELECT
        v_session_id,
        s->>'exercise_name',
        s->>'target_muscles',
        (s->>'set_number')::INT,
        (s->>'weight_kg')::INT,
        (s->>'reps')::INT,
        COALESCE((s->>'is_completed')::BOOLEAN, FALSE)
    FROM jsonb_array_elements(COALESCE(p_session->'sets', '[]'::JSONB)) AS s;

    RETURN v_session_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.sync_workout_session(JSONB) TO authenticated;

COMMENT ON FUNCTION public.sync_workout_session IS
    'Upserts a completed workout session with its sets. Idempotent — safe to call multiple times for the same session.';

-- ============================================
-- STEP 5: RPC — sync_weight_entry
-- ============================================
CREATE OR REPLACE FUNCTION public.sync_weight_entry(
    p_date DATE,
    p_weight_kg NUMERIC,
    p_source TEXT DEFAULT 'manual'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_entry_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF p_weight_kg <= 0 OR p_weight_kg > 500 THEN
        RAISE EXCEPTION 'Weight must be between 0 and 500 kg';
    END IF;

    INSERT INTO public.weight_log (user_id, recorded_on, weight_kg, source)
    VALUES (v_user_id, p_date, p_weight_kg, COALESCE(p_source, 'manual'))
    ON CONFLICT (user_id, recorded_on) DO UPDATE SET
        weight_kg = EXCLUDED.weight_kg,
        source    = EXCLUDED.source
    RETURNING id INTO v_entry_id;

    -- Keep profiles.weight in sync with latest entry
    UPDATE public.profiles
    SET weight = p_weight_kg::INT
    WHERE id = v_user_id;

    RETURN v_entry_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.sync_weight_entry(DATE, NUMERIC, TEXT) TO authenticated;

COMMENT ON FUNCTION public.sync_weight_entry IS
    'Upserts a body weight entry for the authenticated user. One entry per day.';

-- ============================================
-- STEP 6: RPC — get_user_metrics_summary
-- ============================================
CREATE OR REPLACE FUNCTION public.get_user_metrics_summary(p_days INT DEFAULT 30)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
    v_user_id UUID;
    v_result JSONB;
    v_cutoff DATE;
    v_total_workouts INT;
    v_total_volume BIGINT;
    v_avg_duration INT;
    v_current_weight NUMERIC;
    v_weight_change NUMERIC;
    v_total_steps BIGINT;
    v_avg_daily_steps INT;
    v_streak INT;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    v_cutoff := CURRENT_DATE - p_days;

    -- Workout aggregates
    SELECT
        COUNT(*),
        COALESCE(SUM(total_volume_kg), 0),
        COALESCE(AVG(duration_seconds)::INT, 0)
    INTO v_total_workouts, v_total_volume, v_avg_duration
    FROM public.workout_sessions
    WHERE user_id = v_user_id
      AND ended_at::DATE >= v_cutoff;

    -- Current weight (most recent entry)
    SELECT weight_kg INTO v_current_weight
    FROM public.weight_log
    WHERE user_id = v_user_id
    ORDER BY recorded_on DESC
    LIMIT 1;

    -- Weight change over period
    IF v_current_weight IS NOT NULL THEN
        DECLARE v_oldest_weight NUMERIC;
        BEGIN
            SELECT weight_kg INTO v_oldest_weight
            FROM public.weight_log
            WHERE user_id = v_user_id
              AND recorded_on >= v_cutoff
            ORDER BY recorded_on ASC
            LIMIT 1;

            IF v_oldest_weight IS NOT NULL THEN
                v_weight_change := v_current_weight - v_oldest_weight;
            END IF;
        END;
    END IF;

    -- Step aggregates from daily_steps
    SELECT
        COALESCE(SUM(steps), 0),
        COALESCE(AVG(steps)::INT, 0)
    INTO v_total_steps, v_avg_daily_steps
    FROM public.daily_steps
    WHERE user_id = v_user_id
      AND day >= v_cutoff;

    -- Workout streak (consecutive days with at least one session, counting backwards from today)
    v_streak := 0;
    DECLARE
        v_check_date DATE := CURRENT_DATE;
        v_has_session BOOLEAN;
    BEGIN
        LOOP
            SELECT EXISTS (
                SELECT 1 FROM public.workout_sessions
                WHERE user_id = v_user_id
                  AND ended_at::DATE = v_check_date
            ) INTO v_has_session;

            IF v_has_session THEN
                v_streak := v_streak + 1;
                v_check_date := v_check_date - 1;
            ELSE
                -- Grace: if checking today and no session, try yesterday
                IF v_check_date = CURRENT_DATE THEN
                    v_check_date := v_check_date - 1;
                ELSE
                    EXIT;
                END IF;
            END IF;
        END LOOP;
    END;

    v_result := jsonb_build_object(
        'total_workouts', v_total_workouts,
        'total_volume', v_total_volume,
        'avg_duration_seconds', v_avg_duration,
        'current_weight_kg', v_current_weight,
        'weight_change_kg', v_weight_change,
        'total_steps', v_total_steps,
        'avg_daily_steps', v_avg_daily_steps,
        'workout_streak', v_streak
    );

    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_metrics_summary(INT) TO authenticated;

COMMENT ON FUNCTION public.get_user_metrics_summary IS
    'Returns a JSON summary of the authenticated user''s metrics over the last N days.';

-- ============================================
-- STEP 7: RPC — get_exercise_history
-- ============================================
CREATE OR REPLACE FUNCTION public.get_exercise_history(
    p_exercise_name TEXT,
    p_days INT DEFAULT 90
)
RETURNS TABLE (
    session_date DATE,
    max_weight_kg INT,
    total_volume INT,
    max_reps INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    RETURN QUERY
    SELECT
        ws.ended_at::DATE AS session_date,
        MAX(wss.weight_kg)::INT AS max_weight_kg,
        SUM(
            CASE WHEN wss.weight_kg IS NOT NULL AND wss.reps IS NOT NULL AND wss.is_completed
                 THEN wss.weight_kg * wss.reps ELSE 0 END
        )::INT AS total_volume,
        MAX(wss.reps)::INT AS max_reps
    FROM public.workout_sessions ws
    JOIN public.workout_session_sets wss ON wss.session_id = ws.id
    WHERE ws.user_id = v_user_id
      AND ws.ended_at::DATE >= CURRENT_DATE - p_days
      AND LOWER(wss.exercise_name) LIKE LOWER('%' || p_exercise_name || '%')
    GROUP BY ws.ended_at::DATE
    ORDER BY session_date;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_exercise_history(TEXT, INT) TO authenticated;

COMMENT ON FUNCTION public.get_exercise_history IS
    'Returns per-session aggregates for a given exercise over the last N days.';

-- ============================================
-- STEP 8: RPC — get_weight_history
-- ============================================
CREATE OR REPLACE FUNCTION public.get_weight_history(p_days INT DEFAULT 90)
RETURNS TABLE (
    recorded_on DATE,
    weight_kg NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    RETURN QUERY
    SELECT wl.recorded_on, wl.weight_kg
    FROM public.weight_log wl
    WHERE wl.user_id = v_user_id
      AND wl.recorded_on >= CURRENT_DATE - p_days
    ORDER BY wl.recorded_on;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_weight_history(INT) TO authenticated;

COMMENT ON FUNCTION public.get_weight_history IS
    'Returns body weight entries for the authenticated user over the last N days.';

-- ============================================
-- STEP 9: RPC — get_workout_history
-- ============================================
CREATE OR REPLACE FUNCTION public.get_workout_history(p_days INT DEFAULT 90)
RETURNS TABLE (
    session_date DATE,
    workout_name TEXT,
    duration_seconds INT,
    total_volume_kg INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    RETURN QUERY
    SELECT
        ws.ended_at::DATE AS session_date,
        ws.workout_name,
        ws.duration_seconds,
        ws.total_volume_kg
    FROM public.workout_sessions ws
    WHERE ws.user_id = v_user_id
      AND ws.ended_at::DATE >= CURRENT_DATE - p_days
    ORDER BY ws.ended_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_workout_history(INT) TO authenticated;

COMMENT ON FUNCTION public.get_workout_history IS
    'Returns completed workout sessions for the authenticated user over the last N days.';

-- ============================================
-- STEP 10: Add to account deletion cascade
-- ============================================
-- The ON DELETE CASCADE on user_id handles this automatically,
-- but if delete_user_account() exists we should ensure it cleans up.
DO $$
BEGIN
    RAISE NOTICE '================================================';
    RAISE NOTICE 'User Metrics tables created successfully!';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables: workout_sessions, workout_session_sets, weight_log';
    RAISE NOTICE 'RPCs: sync_workout_session, sync_weight_entry,';
    RAISE NOTICE '      get_user_metrics_summary, get_exercise_history,';
    RAISE NOTICE '      get_weight_history, get_workout_history';
    RAISE NOTICE '';
    RAISE NOTICE 'All tables use RLS — each user only sees their own data.';
    RAISE NOTICE '================================================';
END $$;
