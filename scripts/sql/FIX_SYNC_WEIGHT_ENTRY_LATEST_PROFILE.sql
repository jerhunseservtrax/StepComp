-- ============================================
-- FIX: sync_weight_entry profiles.weight order corruption
-- ============================================
-- Live proof (2026-08-10):
-- 1) Authenticated user calls sync_weight_entry for 2026-08-09 @ 82 kg.
-- 2) Same user then calls sync_weight_entry for 2026-08-01 @ 80 kg
--    (simulating MetricsService bulk catch-up over newest-first local array).
-- 3) weight_log correctly keeps both days, but profiles.weight becomes 80.
--
-- Same-day proof:
-- 1) sync 2026-08-09 @ 83 then @ 81 (newest-first same calendar day).
-- 2) weight_log.recorded_on=2026-08-09 stores 81 (older sample wins).
--
-- Root cause:
--   sync_weight_entry always SET profiles.weight = p_weight_kg after upsert,
--   ignoring whether a later recorded_on already exists.
--   Client bulk sync iterates WeightViewModel.entries (newest-first) and
--   falls back to sequential sync_weight_entry because
--   sync_weight_entries_batch is not deployed (PGRST202/404).
--
-- Fix:
--   Only update profiles.weight when no weight_log row exists with a later
--   recorded_on. Pair with client oldest→newest bulk ordering.
--
-- Deploy in Supabase SQL Editor after review.
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

    UPDATE public.profiles
    SET weight = p_weight_kg::INT
    WHERE id = v_user_id
      AND NOT EXISTS (
          SELECT 1
          FROM public.weight_log wl
          WHERE wl.user_id = v_user_id
            AND wl.recorded_on > p_date
      );

    RETURN v_entry_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.sync_weight_entry(DATE, NUMERIC, TEXT) TO authenticated;

COMMENT ON FUNCTION public.sync_weight_entry IS
    'Upserts a body weight entry for the authenticated user. One entry per day. profiles.weight updates only when p_date is not older than existing logs.';
