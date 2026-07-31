-- ============================================
-- FIX: Friendship force-accept + non-friend challenge invites
-- ============================================
-- Live proof (2026-07-31):
-- 1) friendships INSERT RLS only required requester_id = auth.uid().
--    Any authenticated user can POST status='accepted' and appear as an
--    accepted friend of an arbitrary user without consent.
-- 2) send_challenge_invites (SECURITY DEFINER) and challenge_invites INSERT
--    RLS only check challenge membership — not accepted friendship — so
--    members can invite any user ID (UI claims friends-only). After private
--    membership hardening, pending invites are a privileged join path.
--
-- Legitimate paths preserved:
-- - Requester INSERT status='pending'
-- - Addressee UPDATE pending -> accepted
-- - Either side DELETE
-- - consume_friend_invite still inserts pending
-- - Challenge invites only to accepted friends (RPC + RLS)
--
-- Deploy in Supabase SQL Editor after review.
-- ============================================

-- --------------------------------------------
-- 1. Friendships INSERT: pending only
-- --------------------------------------------
DROP POLICY IF EXISTS "send friend request as requester" ON public.friendships;

CREATE POLICY "send friend request as requester"
ON public.friendships
FOR INSERT
WITH CHECK (
  requester_id = auth.uid()
  AND status = 'pending'
  AND addressee_id <> auth.uid()
);

-- --------------------------------------------
-- 2. Friendships UPDATE: addressee pending -> accepted
-- --------------------------------------------
DROP POLICY IF EXISTS "addressee can accept" ON public.friendships;

CREATE POLICY "addressee can accept"
ON public.friendships
FOR UPDATE
USING (
  addressee_id = auth.uid()
  AND status = 'pending'
)
WITH CHECK (
  addressee_id = auth.uid()
  AND status = 'accepted'
);

-- Freeze participant columns on update (prevents identity swap on accept)
CREATE OR REPLACE FUNCTION public.friendships_freeze_participants()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.requester_id IS DISTINCT FROM OLD.requester_id
     OR NEW.addressee_id IS DISTINCT FROM OLD.addressee_id THEN
    RAISE EXCEPTION 'friendship participants cannot be changed';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_friendships_freeze_participants ON public.friendships;
CREATE TRIGGER trg_friendships_freeze_participants
BEFORE UPDATE ON public.friendships
FOR EACH ROW
EXECUTE FUNCTION public.friendships_freeze_participants();

-- --------------------------------------------
-- 3. challenge_invites INSERT: accepted friends only
-- --------------------------------------------
DROP POLICY IF EXISTS "Challenge members can invite friends" ON public.challenge_invites;

CREATE POLICY "Challenge members can invite friends"
ON public.challenge_invites
FOR INSERT
WITH CHECK (
  inviter_id = auth.uid()
  AND invitee_id <> auth.uid()
  AND EXISTS (
    SELECT 1
    FROM public.challenge_members cm
    WHERE cm.challenge_id = challenge_invites.challenge_id
      AND cm.user_id = auth.uid()
  )
  AND EXISTS (
    SELECT 1
    FROM public.friendships f
    WHERE f.status = 'accepted'
      AND (
        (f.requester_id = auth.uid() AND f.addressee_id = challenge_invites.invitee_id)
        OR (f.addressee_id = auth.uid() AND f.requester_id = challenge_invites.invitee_id)
      )
  )
);

-- --------------------------------------------
-- 4. send_challenge_invites: skip non-friends
-- --------------------------------------------
CREATE OR REPLACE FUNCTION public.send_challenge_invites(
    p_challenge_id UUID,
    p_friend_ids UUID[]
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_inviter_id UUID := auth.uid();
    v_inviter_name TEXT;
    v_challenge_name TEXT;
    v_friend_id UUID;
    v_invite_count INTEGER := 0;
    v_inserted INTEGER;
BEGIN
    IF v_inviter_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.challenge_members cm
        WHERE cm.challenge_id = p_challenge_id
          AND cm.user_id = v_inviter_id
    ) THEN
        RAISE EXCEPTION 'You are not a member of this challenge';
    END IF;

    SELECT COALESCE(display_name, username, 'Someone') INTO v_inviter_name
    FROM public.profiles
    WHERE id = v_inviter_id;

    SELECT name INTO v_challenge_name
    FROM public.challenges
    WHERE id = p_challenge_id;

    FOREACH v_friend_id IN ARRAY p_friend_ids
    LOOP
        -- Must be an accepted friend
        IF NOT EXISTS (
            SELECT 1
            FROM public.friendships f
            WHERE f.status = 'accepted'
              AND (
                (f.requester_id = v_inviter_id AND f.addressee_id = v_friend_id)
                OR (f.addressee_id = v_inviter_id AND f.requester_id = v_friend_id)
              )
        ) THEN
            CONTINUE;
        END IF;

        IF NOT EXISTS (
            SELECT 1
            FROM public.challenge_members cm
            WHERE cm.challenge_id = p_challenge_id
              AND cm.user_id = v_friend_id
        ) THEN
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

            GET DIAGNOSTICS v_inserted = ROW_COUNT;
            IF v_inserted > 0 THEN
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
        END IF;
    END LOOP;

    RETURN v_invite_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.send_challenge_invites(UUID, UUID[]) TO authenticated;
