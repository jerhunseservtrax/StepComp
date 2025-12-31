-- ============================================
-- Fix Supabase Security Issues
-- ============================================
-- This script fixes the "Function Search Path Mutable" warnings
-- by adding SET search_path to all functions
-- ============================================
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================

-- 1. Fix update_updated_at_column function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER 
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 2. Fix set_updated_at function (from friends system)
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER 
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- 3. Fix handle_new_user function
-- Note: Check your profiles table schema first!
-- If your profiles table uses 'id' as primary key, use this version:
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name)
  VALUES (
    NEW.id,
    'user_' || LEFT(NEW.id::TEXT, 8),
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email)
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- If your profiles table uses 'user_id' instead of 'id', comment out the above
-- and uncomment this version:
/*
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
  INSERT INTO public.profiles (user_id, username, first_name, last_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
    NEW.raw_user_meta_data->>'first_name',
    NEW.raw_user_meta_data->>'last_name'
  )
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;
*/

-- 4. Fix generate_invite_code function
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT 
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..8 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$$;

-- 5. Fix get_user_total_steps function
CREATE OR REPLACE FUNCTION get_user_total_steps(p_user_id UUID)
RETURNS INTEGER 
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
  RETURN COALESCE(
    (SELECT SUM(total_steps) FROM challenge_members WHERE user_id = p_user_id),
    0
  );
END;
$$;

-- 6. Fix get_challenge_leaderboard function
CREATE OR REPLACE FUNCTION get_challenge_leaderboard(p_challenge_id UUID)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  avatar TEXT,
  total_steps INTEGER,
  rank BIGINT
) 
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cm.user_id,
    p.username,
    p.avatar,
    cm.total_steps,
    RANK() OVER (ORDER BY cm.total_steps DESC) as rank
  FROM challenge_members cm
  JOIN profiles p ON p.user_id = cm.user_id
  WHERE cm.challenge_id = p_challenge_id
  ORDER BY cm.total_steps DESC;
END;
$$;

-- 7. Fix create_friend_invite function (from friends system)
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
  -- token: url-safe
  t := encode(gen_random_bytes(16), 'base64url');
  exp := NOW() + make_interval(hours => expires_in_hours);

  INSERT INTO public.friend_invites(inviter_id, token, expires_at)
  VALUES (auth.uid(), t, exp);

  RETURN QUERY SELECT t, exp;
END;
$$;

-- 8. Fix consume_friend_invite function (from friends system)
CREATE OR REPLACE FUNCTION public.consume_friend_invite(invite_token TEXT)
RETURNS TABLE(
  friendship_id UUID, 
  inviter_id UUID, 
  inviter_username TEXT, 
  inviter_display_name TEXT, 
  inviter_avatar_url TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
  inv public.friend_invites;
  f public.friendships;
BEGIN
  SELECT * INTO inv
  FROM public.friend_invites
  WHERE token = invite_token;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid invite token';
  END IF;

  IF inv.used_at IS NOT NULL THEN
    RAISE EXCEPTION 'Invite already used';
  END IF;

  IF inv.expires_at IS NOT NULL AND inv.expires_at <= NOW() THEN
    RAISE EXCEPTION 'Invite expired';
  END IF;

  IF inv.inviter_id = auth.uid() THEN
    RAISE EXCEPTION 'You cannot friend yourself';
  END IF;

  -- Create friendship as pending (requester = current user, addressee = inviter)
  INSERT INTO public.friendships(requester_id, addressee_id, status)
  VALUES (auth.uid(), inv.inviter_id, 'pending')
  RETURNING * INTO f;

  -- mark invite used (one-time). If you want reusable, remove this.
  UPDATE public.friend_invites
  SET used_at = NOW()
  WHERE id = inv.id;

  RETURN QUERY
  SELECT
    f.id,
    inv.inviter_id,
    p.username,
    p.display_name,
    p.avatar_url
  FROM public.profiles p
  WHERE p.id = inv.inviter_id;
END;
$$;

-- ============================================
-- Note: Leaked Password Protection
-- ============================================
-- The "Leaked Password Protection Disabled" warning
-- needs to be enabled in Supabase Dashboard:
-- 
-- 1. Go to Authentication → Settings
-- 2. Find "Password Protection" section
-- 3. Enable "Leaked Password Protection"
-- 
-- This cannot be enabled via SQL - it's a dashboard setting.
-- ============================================

