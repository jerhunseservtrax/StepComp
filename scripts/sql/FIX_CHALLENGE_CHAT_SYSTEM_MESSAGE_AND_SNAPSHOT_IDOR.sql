-- ============================================
-- FIX: Challenge chat system-message forgery +
--      unread-count / snapshot IDOR
-- ============================================
-- Live proof (2026-07-30):
-- 1) Any authenticated non-member can call
--    create_system_message(private_challenge_id, text).
--    The SECURITY DEFINER RPC picks the first challenge
--    member as user_id and inserts message_type='system',
--    forging a system message into private chat.
-- 2) get_challenge_unread_count(private_challenge_id)
--    returns activity counts to non-members (no membership gate).
-- 3) snapshot_challenge_results / has_challenge_snapshot are
--    SECURITY DEFINER without an access check (same class as
--    get_challenge_leaderboard IDOR). Live snapshot currently
--    also fails with ambiguous user_id (42702); this script
--    gates access and resolves the ambiguity.
--
-- Deploy in Supabase SQL Editor after review.
-- ============================================

-- --------------------------------------------
-- 1. Gate create_system_message (membership/creator)
-- --------------------------------------------
CREATE OR REPLACE FUNCTION public.create_system_message(
    p_challenge_id UUID,
    p_content TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_caller_id UUID := auth.uid();
    v_message_id UUID;
    v_is_allowed BOOLEAN;
BEGIN
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    IF p_content IS NULL OR char_length(trim(p_content)) = 0 THEN
        RAISE EXCEPTION 'Message content cannot be empty';
    END IF;

    IF char_length(p_content) > 2000 THEN
        RAISE EXCEPTION 'Message content cannot exceed 2000 characters';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.challenge_members cm
        WHERE cm.challenge_id = p_challenge_id
          AND cm.user_id = v_caller_id
    )
    OR EXISTS (
        SELECT 1
        FROM public.challenges c
        WHERE c.id = p_challenge_id
          AND c.created_by = v_caller_id
    )
    INTO v_is_allowed;

    IF NOT v_is_allowed THEN
        RAISE EXCEPTION 'Not authorized to post system messages to this challenge';
    END IF;

    INSERT INTO public.challenge_messages (
        challenge_id,
        user_id,
        content,
        message_type
    )
    VALUES (
        p_challenge_id,
        v_caller_id,
        trim(p_content),
        'system'
    )
    RETURNING id INTO v_message_id;

    RETURN v_message_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_system_message(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_system_message(UUID, TEXT) TO authenticated;

COMMENT ON FUNCTION public.create_system_message IS
  'Inserts a system chat message. Caller must be a challenge member or creator.';

-- --------------------------------------------
-- 2. Gate get_challenge_unread_count
-- --------------------------------------------
CREATE OR REPLACE FUNCTION public.get_challenge_unread_count(
    p_challenge_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_unread_count INTEGER;
    v_is_member BOOLEAN;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN 0;
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.challenge_members cm
        WHERE cm.challenge_id = p_challenge_id
          AND cm.user_id = v_user_id
    )
    INTO v_is_member;

    IF NOT v_is_member THEN
        RETURN 0;
    END IF;

    SELECT COUNT(*)::INTEGER INTO v_unread_count
    FROM public.challenge_messages cm
    WHERE cm.challenge_id = p_challenge_id
      AND cm.is_deleted = FALSE
      AND cm.user_id != v_user_id
      AND NOT EXISTS (
          SELECT 1
          FROM public.challenge_message_reads cmr
          WHERE cmr.message_id = cm.id
            AND cmr.user_id = v_user_id
      );

    RETURN COALESCE(v_unread_count, 0);
END;
$$;

REVOKE ALL ON FUNCTION public.get_challenge_unread_count(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_challenge_unread_count(UUID) TO authenticated;

COMMENT ON FUNCTION public.get_challenge_unread_count IS
  'Unread challenge message count for the caller. Non-members always get 0.';

-- --------------------------------------------
-- 3. Gate snapshot_challenge_results + fix ambiguity
-- --------------------------------------------
-- LANGUAGE sql avoids PL/pgSQL RETURNS TABLE variable
-- shadowing that caused live 42702 "user_id is ambiguous".
-- Unauthorized callers get zero rows (no exception) — same
-- non-leak posture as gated leaderboard RPCs.
DROP FUNCTION IF EXISTS public.snapshot_challenge_results(UUID);

CREATE OR REPLACE FUNCTION public.snapshot_challenge_results(p_challenge_id UUID)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    display_name TEXT,
    avatar_url TEXT,
    total_steps BIGINT,
    rank BIGINT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    WITH access_check AS (
        SELECT 1
        FROM public.challenges c
        WHERE c.id = p_challenge_id
          AND auth.uid() IS NOT NULL
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
        SELECT cm.user_id AS member_user_id
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
            cm.member_user_id,
            COALESCE(SUM(ds.steps), 0) AS member_total_steps
        FROM challenge_members_cte cm
        CROSS JOIN challenge_info ci
        LEFT JOIN public.daily_steps ds
            ON ds.user_id = cm.member_user_id
            AND ds.day >= ci.start_date
            AND ds.day <= ci.end_date
        GROUP BY cm.member_user_id
    ),
    ranked_results AS (
        SELECT
            ms.member_user_id,
            COALESCE(p.username, 'User') AS member_username,
            COALESCE(p.display_name, p.username, 'User') AS member_display_name,
            p.avatar_url AS member_avatar_url,
            ms.member_total_steps,
            RANK() OVER (ORDER BY ms.member_total_steps DESC) AS member_rank
        FROM member_steps ms
        LEFT JOIN public.profiles p ON p.id = ms.member_user_id
    ),
    upserted AS (
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
            rr.member_user_id,
            rr.member_username,
            rr.member_display_name,
            rr.member_avatar_url,
            rr.member_total_steps::INT,
            rr.member_rank::INT,
            NOW()
        FROM ranked_results rr
        ON CONFLICT (challenge_id, user_id)
        DO UPDATE SET
            username = EXCLUDED.username,
            display_name = EXCLUDED.display_name,
            avatar_url = EXCLUDED.avatar_url,
            total_steps = EXCLUDED.total_steps,
            rank = EXCLUDED.rank,
            snapshotted_at = NOW()
        RETURNING
            challenge_snapshots.user_id,
            challenge_snapshots.username,
            challenge_snapshots.display_name,
            challenge_snapshots.avatar_url,
            challenge_snapshots.total_steps,
            challenge_snapshots.rank
    )
    SELECT
        u.user_id::UUID,
        u.username,
        u.display_name,
        u.avatar_url,
        u.total_steps::BIGINT,
        u.rank::BIGINT
    FROM upserted u
    ORDER BY u.rank;
$$;

REVOKE ALL ON FUNCTION public.snapshot_challenge_results(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.snapshot_challenge_results(UUID) TO authenticated;

COMMENT ON FUNCTION public.snapshot_challenge_results IS
  'Creates/updates challenge result snapshots for public challenges, creators, or members. Returns snapshotted leaderboard rows.';

-- --------------------------------------------
-- 4. Gate has_challenge_snapshot
-- --------------------------------------------
CREATE OR REPLACE FUNCTION public.has_challenge_snapshot(p_challenge_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.challenge_snapshots cs
        WHERE cs.challenge_id = p_challenge_id
          AND EXISTS (
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
          )
        LIMIT 1
    );
$$;

REVOKE ALL ON FUNCTION public.has_challenge_snapshot(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.has_challenge_snapshot(UUID) TO authenticated;

COMMENT ON FUNCTION public.has_challenge_snapshot IS
  'True when a snapshot exists and the caller may access the challenge.';
