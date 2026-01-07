-- ============================================
-- COMBINED FIX: Run Both SQL Scripts
-- ============================================
-- This script fixes BOTH:
-- 1. Friend invite link base64url error
-- 2. Challenge invite system setup
-- Run this ONCE in Supabase SQL Editor
-- ============================================

-- ============================================
-- PART 1: Fix Friend Invite Base64URL Error
-- ============================================

CREATE OR REPLACE FUNCTION public.create_friend_invite(expires_in_hours INTEGER DEFAULT 168)
RETURNS TABLE(token TEXT, expires_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
  t TEXT;
  exp TIMESTAMPTZ;
BEGIN
  -- Generate URL-safe token: base64 encode then replace +/= with -_~ for URL safety
  t := REPLACE(REPLACE(REPLACE(
    encode(gen_random_bytes(16), 'base64'),
    '+', '-'),
    '/', '_'),
    '=', '~'
  );
  
  exp := NOW() + make_interval(hours => expires_in_hours);

  INSERT INTO public.friend_invites(inviter_id, token, expires_at)
  VALUES (auth.uid(), t, exp);

  RETURN QUERY SELECT t, exp;
END;
$$;

-- Ensure proper grants
REVOKE ALL ON FUNCTION public.create_friend_invite(INTEGER) FROM public;
GRANT EXECUTE ON FUNCTION public.create_friend_invite(INTEGER) TO authenticated;

-- ============================================
-- PART 2: Challenge Invites System Setup
-- ============================================

-- Create challenge_invites table
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

CREATE INDEX IF NOT EXISTS idx_challenge_invites_invitee ON public.challenge_invites(invitee_id, status);
CREATE INDEX IF NOT EXISTS idx_challenge_invites_challenge ON public.challenge_invites(challenge_id);

-- Enable RLS
ALTER TABLE public.challenge_invites ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own invites" ON public.challenge_invites;
DROP POLICY IF EXISTS "Challenge members can invite friends" ON public.challenge_invites;
DROP POLICY IF EXISTS "Invitees can update their own invites" ON public.challenge_invites;

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

-- Create notifications table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('friend_request', 'challenge_invite', 'challenge_update', 'challenge_joined', 'achievement')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    related_id TEXT, -- Challenge ID, Friend ID, etc.
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id, is_read) WHERE is_read = FALSE;

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Authenticated users can insert notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;

-- RLS Policies for notifications
CREATE POLICY "Users can read own notifications"
ON public.notifications
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
ON public.notifications
FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Authenticated users can insert notifications"
ON public.notifications
FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can delete own notifications"
ON public.notifications
FOR DELETE
USING (auth.uid() = user_id);

-- RPC Function: Send Challenge Invites
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
        RAISE EXCEPTION 'You are not a member of this challenge';
    END IF;
    
    -- Get inviter name
    SELECT display_name INTO v_inviter_name
    FROM public.profiles
    WHERE id = v_inviter_id;
    
    -- Get challenge name
    SELECT name INTO v_challenge_name
    FROM public.challenges
    WHERE id = p_challenge_id;
    
    -- Send invites to each friend
    FOREACH v_friend_id IN ARRAY p_friend_ids
    LOOP
        -- Check if friend is not already a member
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
            
            -- Create notification
            INSERT INTO public.notifications (
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
                p_challenge_id::TEXT
            );
            
            v_invite_count := v_invite_count + 1;
        END IF;
    END LOOP;
    
    RETURN v_invite_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.send_challenge_invites TO authenticated;

-- RPC Function: Accept Challenge Invite
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
    UPDATE public.notifications
    SET is_read = TRUE
    WHERE user_id = v_user_id
    AND related_id = v_challenge_id::TEXT
    AND type = 'challenge_invite';
    
    RETURN TRUE;
END;
$$;

GRANT EXECUTE ON FUNCTION public.accept_challenge_invite TO authenticated;

-- RPC Function: Decline Challenge Invite
CREATE OR REPLACE FUNCTION public.decline_challenge_invite(
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
    SET status = 'declined', updated_at = NOW()
    WHERE id = p_invite_id;
    
    -- Mark notification as read
    UPDATE public.notifications
    SET is_read = TRUE
    WHERE user_id = v_user_id
    AND related_id = v_challenge_id::TEXT
    AND type = 'challenge_invite';
    
    RETURN TRUE;
END;
$$;

GRANT EXECUTE ON FUNCTION public.decline_challenge_invite TO authenticated;

-- ============================================
-- Verification
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '✅ ALL FIXES APPLIED SUCCESSFULLY!';
  RAISE NOTICE '1. Friend invite function updated (base64url → base64 with URL-safe replacements)';
  RAISE NOTICE '2. Challenge invites tables created';
  RAISE NOTICE '3. Challenge invite RPC functions created';
  RAISE NOTICE '4. All RLS policies configured';
  RAISE NOTICE '';
  RAISE NOTICE '🎉 You can now:';
  RAISE NOTICE '   - Create friend invite links';
  RAISE NOTICE '   - Invite friends to challenges';
  RAISE NOTICE '   - Accept/decline challenge invites from inbox';
END $$;

