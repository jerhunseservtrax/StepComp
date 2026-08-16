-- ============================================================================
-- FIX: Past-dated / same-timestamp workout sync overwrite
-- ============================================================================
-- Root cause:
--   sync_workout_session upserted on UNIQUE(user_id, started_at) and then
--   deleted all sets for the matched row. The iOS client pinned every
--   non-today workout to 23:59:59 and reconstructed started_at as
--   end - duration, so two same-duration backfills silently replaced each
--   other.
--
-- Fix:
--   Idempotency key becomes the client session UUID (user_id, client_session_id).
--   Distinct workouts can share a started_at without data loss. Re-syncing the
--   same local session still replaces its sets.
--
-- Safe to re-run.
-- ============================================================================

ALTER TABLE public.workout_sessions
    ADD COLUMN IF NOT EXISTS client_session_id UUID;

UPDATE public.workout_sessions
SET client_session_id = id
WHERE client_session_id IS NULL;

ALTER TABLE public.workout_sessions
    ALTER COLUMN client_session_id SET DEFAULT gen_random_uuid();

ALTER TABLE public.workout_sessions
    ALTER COLUMN client_session_id SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_workout_sessions_user_client
    ON public.workout_sessions(user_id, client_session_id);

ALTER TABLE public.workout_sessions
    DROP CONSTRAINT IF EXISTS uq_workout_sessions_user_start;

ALTER TABLE public.workout_sessions
    DROP CONSTRAINT IF EXISTS workout_sessions_user_id_started_at_key;

DROP INDEX IF EXISTS uq_workout_sessions_user_start;
DROP INDEX IF EXISTS workout_sessions_user_id_started_at_key;

CREATE OR REPLACE FUNCTION public.sync_workout_session(p_session JSONB)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_session_id UUID;
    v_client_session_id UUID;
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

    v_workout_name := p_session->>'workout_name';
    v_started_at   := (p_session->>'started_at')::TIMESTAMPTZ;
    v_ended_at     := (p_session->>'ended_at')::TIMESTAMPTZ;
    v_source       := COALESCE(p_session->>'source', 'app');

    IF p_session->>'id' IS NOT NULL AND p_session->>'id' <> '' THEN
        BEGIN
            v_client_session_id := (p_session->>'id')::UUID;
        EXCEPTION WHEN invalid_text_representation THEN
            v_client_session_id := gen_random_uuid();
        END;
    ELSE
        v_client_session_id := gen_random_uuid();
    END IF;

    IF p_session->>'workout_id' IS NOT NULL AND p_session->>'workout_id' <> '' THEN
        v_workout_id := (p_session->>'workout_id')::UUID;
    END IF;

    IF v_workout_name IS NULL OR v_started_at IS NULL OR v_ended_at IS NULL THEN
        RAISE EXCEPTION 'Missing required fields: workout_name, started_at, ended_at';
    END IF;

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

    INSERT INTO public.workout_sessions (
        user_id, client_session_id, workout_id, workout_name, started_at, ended_at,
        total_volume_kg, max_weight_kg, source
    )
    VALUES (
        v_user_id, v_client_session_id, v_workout_id, v_workout_name, v_started_at, v_ended_at,
        v_total_volume, v_max_weight, v_source
    )
    ON CONFLICT (user_id, client_session_id) DO UPDATE SET
        workout_name   = EXCLUDED.workout_name,
        started_at     = EXCLUDED.started_at,
        ended_at       = EXCLUDED.ended_at,
        total_volume_kg = EXCLUDED.total_volume_kg,
        max_weight_kg  = EXCLUDED.max_weight_kg,
        source         = EXCLUDED.source
    RETURNING id INTO v_session_id;

    DELETE FROM public.workout_session_sets WHERE session_id = v_session_id;

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
    'Upserts a completed workout session with its sets. Idempotent on (user_id, client_session_id) so distinct workouts cannot overwrite each other when started_at collides.';
