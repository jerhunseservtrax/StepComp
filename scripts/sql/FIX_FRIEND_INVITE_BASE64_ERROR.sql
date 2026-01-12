-- ============================================
-- Fix Friend Invite Base64URL Encoding Error
-- ============================================
-- Problem: PostgreSQL encode() function doesn't support 'base64url' in older versions
-- Solution: Use 'base64' and manually replace characters to make it URL-safe
-- Run this in Supabase SQL Editor
-- ============================================

CREATE OR REPLACE FUNCTION public.create_friend_invite(expires_in_hours INTEGER DEFAULT 168)
RETURNS TABLE(token TEXT, expires_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions, pg_catalog
AS $$
DECLARE
  t TEXT;
  exp TIMESTAMPTZ;
BEGIN
  -- Generate URL-safe token: base64 encode then replace +/= with -_~ for URL safety
  t := REPLACE(REPLACE(REPLACE(
    encode(extensions.gen_random_bytes(16), 'base64'),
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

-- Verification
DO $$
BEGIN
  RAISE NOTICE '✅ create_friend_invite function updated to use base64 with URL-safe character replacement';
  RAISE NOTICE 'Characters replaced: + → -, / → _, = → ~';
END $$;

