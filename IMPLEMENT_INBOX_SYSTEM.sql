-- ============================================================
-- CHALLENGE INVITES & INBOX SYSTEM
-- ============================================================
-- Creates tables for challenge invites and general inbox notifications
-- ============================================================

-- ============================================================
-- 1. Challenge Invites Table
-- ============================================================

CREATE TABLE IF NOT EXISTS public.challenge_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
    inviter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    invitee_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Prevent duplicate invites
    UNIQUE(challenge_id, invitee_id)
);

CREATE INDEX idx_challenge_invites_invitee ON public.challenge_invites(invitee_id, status);
CREATE INDEX idx_challenge_invites_challenge ON public.challenge_invites(challenge_id);

-- Enable RLS
ALTER TABLE public.challenge_invites ENABLE ROW LEVEL SECURITY;

-- RLS Policies for challenge_invites
CREATE POLICY "Users can view their own invites"
ON public.challenge_invites
FOR SELECT
USING (invitee_id = auth.uid() OR inviter_id = auth.uid());

CREATE POLICY "Challenge members can invite friends"
ON public.challenge_invites
FOR INSERT
WITH CHECK (
    inviter_id = auth.uid()
    AND EXISTS (
        SELECT 1
        FROM public.challenge_members cm
        WHERE cm.challenge_id = challenge_invites.challenge_id
        AND cm.user_id = auth.uid()
    )
);

CREATE POLICY "Invitees can update their own invites"
ON public.challenge_invites
FOR UPDATE
USING (invitee_id = auth.uid())
WITH CHECK (invitee_id = auth.uid());

-- ============================================================
-- 2. Inbox Notifications Table
-- ============================================================

CREATE TABLE IF NOT EXISTS public.inbox_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('friend_request', 'challenge_invite', 'challenge_update', 'achievement')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    related_id UUID, -- Can be friend_request_id, challenge_id, etc.
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_inbox_user_unread ON public.inbox_notifications(user_id, is_read, created_at DESC);
CREATE INDEX idx_inbox_user_created ON public.inbox_notifications(user_id, created_at DESC);

-- Enable RLS
ALTER TABLE public.inbox_notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies for inbox_notifications
CREATE POLICY "Users can view their own notifications"
ON public.inbox_notifications
FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "Users can update their own notifications"
ON public.inbox_notifications
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================================
-- 3. RPC Function: Send Challenge Invites
-- ============================================================

CREATE OR REPLACE FUNCTION public.send_challenge_invites(
    p_challenge_id UUID,
    p_friend_ids UUID[]
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_inviter_id UUID := auth.uid();
    v_inviter_name TEXT;
    v_challenge_name TEXT;
    v_friend_id UUID;
    v_invite_count INTEGER := 0;
BEGIN
    -- Check authentication
    IF v_inviter_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    
    -- Verify user is a member of the challenge
    IF NOT EXISTS (
        SELECT 1
        FROM public.challenge_members cm
        WHERE cm.challenge_id = p_challenge_id
        AND cm.user_id = v_inviter_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this challenge';
    END IF;
    
    -- Get inviter name and challenge name
    SELECT display_name INTO v_inviter_name
    FROM public.profiles
    WHERE id = v_inviter_id;
    
    SELECT name INTO v_challenge_name
    FROM public.challenges
    WHERE id = p_challenge_id;
    
    -- Loop through friend IDs and create invites
    FOREACH v_friend_id IN ARRAY p_friend_ids
    LOOP
        -- Check if friend is not already in challenge
        IF NOT EXISTS (
            SELECT 1
            FROM public.challenge_members cm
            WHERE cm.challenge_id = p_challenge_id
            AND cm.user_id = v_friend_id
        ) THEN
            -- Insert invite (ON CONFLICT to handle duplicates)
            INSERT INTO public.challenge_invites (
                challenge_id,
                inviter_id,
                invitee_id,
                status
            )
            VALUES (
                p_challenge_id,
                v_inviter_id,
                v_friend_id,
                'pending'
            )
            ON CONFLICT (challenge_id, invitee_id) DO NOTHING;
            
            -- Create inbox notification
            INSERT INTO public.inbox_notifications (
                user_id,
                type,
                title,
                message,
                related_id
            )
            VALUES (
                v_friend_id,
                'challenge_invite',
                'Challenge Invite',
                v_inviter_name || ' invited you to join "' || v_challenge_name || '"',
                p_challenge_id
            );
            
            v_invite_count := v_invite_count + 1;
        END IF;
    END LOOP;
    
    RETURN v_invite_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.send_challenge_invites TO authenticated;

-- ============================================================
-- 4. RPC Function: Accept Challenge Invite
-- ============================================================

CREATE OR REPLACE FUNCTION public.accept_challenge_invite(
    p_invite_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_challenge_id UUID;
BEGIN
    -- Check authentication
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    
    -- Get challenge ID and verify invite belongs to user
    SELECT challenge_id INTO v_challenge_id
    FROM public.challenge_invites
    WHERE id = p_invite_id
    AND invitee_id = v_user_id
    AND status = 'pending';
    
    IF v_challenge_id IS NULL THEN
        RAISE EXCEPTION 'Invalid or already processed invite';
    END IF;
    
    -- Update invite status
    UPDATE public.challenge_invites
    SET status = 'accepted', updated_at = NOW()
    WHERE id = p_invite_id;
    
    -- Add user to challenge
    INSERT INTO public.challenge_members (challenge_id, user_id)
    VALUES (v_challenge_id, v_user_id)
    ON CONFLICT (challenge_id, user_id) DO NOTHING;
    
    -- Mark notification as read
    UPDATE public.inbox_notifications
    SET is_read = TRUE
    WHERE user_id = v_user_id
    AND related_id = v_challenge_id
    AND type = 'challenge_invite';
    
    RETURN TRUE;
END;
$$;

GRANT EXECUTE ON FUNCTION public.accept_challenge_invite TO authenticated;

-- ============================================================
-- 5. RPC Function: Decline Challenge Invite
-- ============================================================

CREATE OR REPLACE FUNCTION public.decline_challenge_invite(
    p_invite_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    -- Check authentication
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    
    -- Update invite status
    UPDATE public.challenge_invites
    SET status = 'declined', updated_at = NOW()
    WHERE id = p_invite_id
    AND invitee_id = v_user_id
    AND status = 'pending';
    
    -- Mark notification as read
    UPDATE public.inbox_notifications
    SET is_read = TRUE
    WHERE user_id = v_user_id
    AND type = 'challenge_invite'
    AND related_id = (
        SELECT challenge_id 
        FROM public.challenge_invites 
        WHERE id = p_invite_id
    );
    
    RETURN TRUE;
END;
$$;

GRANT EXECUTE ON FUNCTION public.decline_challenge_invite TO authenticated;

-- ============================================================
-- 6. RPC Function: Get Unread Inbox Count
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_unread_inbox_count()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_count INTEGER;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN 0;
    END IF;
    
    SELECT COUNT(*)::INTEGER INTO v_count
    FROM public.inbox_notifications
    WHERE user_id = v_user_id
    AND is_read = FALSE;
    
    RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_unread_inbox_count TO authenticated;

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

SELECT 'Challenge invites table' AS check_type, COUNT(*) AS exists
FROM information_schema.tables
WHERE table_schema = 'public' AND table_name = 'challenge_invites';

SELECT 'Inbox notifications table' AS check_type, COUNT(*) AS exists
FROM information_schema.tables
WHERE table_schema = 'public' AND table_name = 'inbox_notifications';

SELECT 'RPC functions' AS check_type, COUNT(*) AS function_count
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname IN ('send_challenge_invites', 'accept_challenge_invite', 'decline_challenge_invite', 'get_unread_inbox_count');

SELECT '✅ INBOX SYSTEM READY' AS status;

