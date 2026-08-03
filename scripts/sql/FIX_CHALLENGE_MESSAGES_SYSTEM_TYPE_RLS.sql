-- ============================================
-- FIX: Block client forgery of system chat messages
-- ============================================
-- Live proof (2026-08-03):
-- Challenge members can POST/PATCH challenge_messages with
-- message_type='system'. The iOS chat UI renders those rows as
-- centered official system notices (no author), so any member
-- can impersonate join/leave/end announcements.
--
-- Related but distinct from FIX_CHALLENGE_CHAT_SYSTEM_MESSAGE_AND_SNAPSHOT_IDOR.sql
-- (PR #57), which gates the create_system_message RPC for non-members.
-- That RPC path does not stop direct table INSERT/UPDATE forgery.
--
-- Deploy in Supabase SQL Editor after review.
-- ============================================

-- INSERT: members may only create user text messages
DROP POLICY IF EXISTS "Send messages in joined challenges" ON public.challenge_messages;
CREATE POLICY "Send messages in joined challenges"
ON public.challenge_messages
FOR INSERT
WITH CHECK (
    user_id = auth.uid()
    AND COALESCE(is_deleted, FALSE) = FALSE
    AND message_type = 'text'
    AND EXISTS (
        SELECT 1
        FROM public.challenge_members cm
        WHERE cm.challenge_id = challenge_messages.challenge_id
          AND cm.user_id = auth.uid()
    )
);

-- UPDATE: members may edit/soft-delete only their own text messages;
-- cannot escalate message_type to 'system'
DROP POLICY IF EXISTS "Edit own messages" ON public.challenge_messages;
CREATE POLICY "Edit own messages"
ON public.challenge_messages
FOR UPDATE
USING (
    user_id = auth.uid()
    AND message_type = 'text'
)
WITH CHECK (
    user_id = auth.uid()
    AND message_type = 'text'
);

COMMENT ON POLICY "Send messages in joined challenges" ON public.challenge_messages IS
  'Members may insert only message_type=text as themselves; system rows require SECURITY DEFINER RPCs.';

COMMENT ON POLICY "Edit own messages" ON public.challenge_messages IS
  'Members may update only their own text messages; cannot forge or edit system rows via RLS.';

-- Ensure send_challenge_message cannot take a client-supplied message_type
-- (live already uses the 2-arg form; drop any 3-arg overload footgun).
DROP FUNCTION IF EXISTS public.send_challenge_message(UUID, TEXT, TEXT);
CREATE OR REPLACE FUNCTION public.send_challenge_message(
    p_challenge_id UUID,
    p_content TEXT
)
RETURNS TABLE(
    message_id UUID,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_message_id UUID;
    v_created_at TIMESTAMPTZ;
    v_is_member BOOLEAN;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM public.challenge_members cm
        WHERE cm.challenge_id = p_challenge_id
          AND cm.user_id = v_user_id
    ) INTO v_is_member;

    IF NOT v_is_member THEN
        RAISE EXCEPTION 'You must be a member of this challenge to send messages';
    END IF;

    IF char_length(trim(p_content)) = 0 THEN
        RAISE EXCEPTION 'Message content cannot be empty';
    END IF;

    IF char_length(p_content) > 2000 THEN
        RAISE EXCEPTION 'Message content cannot exceed 2000 characters';
    END IF;

    INSERT INTO public.challenge_messages (
        challenge_id,
        user_id,
        content,
        message_type
    )
    VALUES (
        p_challenge_id,
        v_user_id,
        trim(p_content),
        'text'
    )
    RETURNING id, created_at INTO v_message_id, v_created_at;

    RETURN QUERY SELECT v_message_id, v_created_at;
END;
$$;

REVOKE ALL ON FUNCTION public.send_challenge_message(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.send_challenge_message(UUID, TEXT) TO authenticated;
