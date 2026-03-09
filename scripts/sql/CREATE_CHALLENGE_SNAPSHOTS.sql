-- ============================================
-- CHALLENGE SNAPSHOTS SYSTEM
-- ============================================
-- Preserves participant data and metrics when challenges end
-- so archived challenges always show correct participant counts and stats
-- ============================================

-- STEP 1: Create challenge_snapshots table
-- ============================================
CREATE TABLE IF NOT EXISTS public.challenge_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT NOT NULL DEFAULT '',
    display_name TEXT NOT NULL DEFAULT 'User',
    avatar_url TEXT,
    total_steps INT NOT NULL DEFAULT 0,
    rank INT NOT NULL DEFAULT 0,
    snapshotted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(challenge_id, user_id)
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_challenge_snapshots_challenge_id 
ON public.challenge_snapshots(challenge_id);

CREATE INDEX IF NOT EXISTS idx_challenge_snapshots_user_id 
ON public.challenge_snapshots(user_id);

CREATE INDEX IF NOT EXISTS idx_challenge_snapshots_rank 
ON public.challenge_snapshots(challenge_id, rank);

-- Enable RLS
ALTER TABLE public.challenge_snapshots ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can read snapshots for challenges they participated in
CREATE POLICY "Users can read snapshots for their challenges"
ON public.challenge_snapshots
FOR SELECT
TO authenticated
USING (
    user_id = auth.uid()
    OR EXISTS (
        SELECT 1 FROM public.challenge_members cm
        WHERE cm.challenge_id = challenge_snapshots.challenge_id
        AND cm.user_id = auth.uid()
    )
    OR EXISTS (
        SELECT 1 FROM public.challenges c
        WHERE c.id = challenge_snapshots.challenge_id
        AND (c.is_public = TRUE OR c.created_by = auth.uid())
    )
);

-- RLS Policy: Only system/functions can insert/update snapshots
CREATE POLICY "System can manage snapshots"
ON public.challenge_snapshots
FOR ALL
TO authenticated
USING (false)
WITH CHECK (false);

-- STEP 2: Create snapshot_challenge_results RPC function
-- ============================================
CREATE OR REPLACE FUNCTION public.snapshot_challenge_results(p_challenge_id UUID)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    display_name TEXT,
    avatar_url TEXT,
    total_steps BIGINT,
    rank BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_snapshot_count INT;
BEGIN
    -- Compute leaderboard data (same logic as get_challenge_leaderboard)
    WITH challenge_members_cte AS (
        SELECT cm.user_id
        FROM public.challenge_members cm
        WHERE cm.challenge_id = p_challenge_id
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
    ),
    ranked_results AS (
        SELECT 
            ms.user_id,
            COALESCE(p.username, 'User') AS username,
            COALESCE(p.display_name, p.username, 'User') AS display_name,
            p.avatar_url,
            ms.total_steps,
            RANK() OVER (ORDER BY ms.total_steps DESC) AS rank
        FROM member_steps ms
        LEFT JOIN public.profiles p ON p.id = ms.user_id
    )
    -- Upsert snapshot data (idempotent)
    INSERT INTO public.challenge_snapshots (
        challenge_id,
        user_id,
        username,
        display_name,
        avatar_url,
        total_steps,
        rank,
        snapshotted_at
    )
    SELECT 
        p_challenge_id,
        rr.user_id,
        rr.username,
        rr.display_name,
        rr.avatar_url,
        rr.total_steps::INT,
        rr.rank::INT,
        NOW()
    FROM ranked_results rr
    ON CONFLICT (challenge_id, user_id) 
    DO UPDATE SET
        username = EXCLUDED.username,
        display_name = EXCLUDED.display_name,
        avatar_url = EXCLUDED.avatar_url,
        total_steps = EXCLUDED.total_steps,
        rank = EXCLUDED.rank,
        snapshotted_at = NOW();
    
    -- Return the snapshot data
    RETURN QUERY
    SELECT 
        cs.user_id::UUID,
        cs.username,
        cs.display_name,
        cs.avatar_url,
        cs.total_steps::BIGINT,
        cs.rank::BIGINT
    FROM public.challenge_snapshots cs
    WHERE cs.challenge_id = p_challenge_id
    ORDER BY cs.rank;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.snapshot_challenge_results(UUID) TO authenticated;

COMMENT ON FUNCTION public.snapshot_challenge_results IS 'Creates/updates snapshot of challenge results. Idempotent - safe to call multiple times. Returns snapshotted leaderboard data.';

-- STEP 3: Helper function to check if snapshot exists
-- ============================================
CREATE OR REPLACE FUNCTION public.has_challenge_snapshot(p_challenge_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM public.challenge_snapshots
        WHERE challenge_id = p_challenge_id
        LIMIT 1
    );
$$;

GRANT EXECUTE ON FUNCTION public.has_challenge_snapshot(UUID) TO authenticated;

-- STEP 4: Verification query
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '✅ Challenge snapshots system created!';
    RAISE NOTICE '';
    RAISE NOTICE 'To snapshot a challenge:';
    RAISE NOTICE '  SELECT * FROM snapshot_challenge_results(''your-challenge-id''::UUID);';
    RAISE NOTICE '';
    RAISE NOTICE 'To check if snapshot exists:';
    RAISE NOTICE '  SELECT has_challenge_snapshot(''your-challenge-id''::UUID);';
END $$;
