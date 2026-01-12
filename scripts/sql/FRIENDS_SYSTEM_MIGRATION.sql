-- ============================================
-- Friends System Database Migration
-- ============================================
-- Run this script in Supabase Dashboard → SQL Editor
-- This creates the complete friends system with public profiles and invite tokens
-- ============================================

-- 1.1 Extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1.2 Profiles table (add public_profile column if it doesn't exist)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'public_profile'
    ) THEN
        ALTER TABLE profiles ADD COLUMN public_profile BOOLEAN NOT NULL DEFAULT FALSE;
    END IF;
    
    -- Add display_name if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'display_name'
    ) THEN
        ALTER TABLE profiles ADD COLUMN display_name TEXT;
    END IF;
    
    -- Rename avatar to avatar_url if needed (check which exists)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'avatar'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'avatar_url'
    ) THEN
        ALTER TABLE profiles RENAME COLUMN avatar TO avatar_url;
    END IF;
    
    -- Add avatar_url if neither exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'avatar_url'
    ) THEN
        ALTER TABLE profiles ADD COLUMN avatar_url TEXT;
    END IF;
END $$;

-- Update display_name from first_name + last_name if needed
UPDATE profiles 
SET display_name = COALESCE(
    TRIM(CONCAT(COALESCE(first_name, ''), ' ', COALESCE(last_name, ''))),
    username
)
WHERE display_name IS NULL OR display_name = '';

-- 1.3 Friendships table (single row per pair, pending/accepted)
CREATE TABLE IF NOT EXISTS public.friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  addressee_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('pending', 'accepted')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  pair_low UUID GENERATED ALWAYS AS (LEAST(requester_id, addressee_id)) STORED,
  pair_high UUID GENERATED ALWAYS AS (GREATEST(requester_id, addressee_id)) STORED,
  CHECK (requester_id <> addressee_id)
);

-- Prevent duplicates regardless of direction
CREATE UNIQUE INDEX IF NOT EXISTS ux_friendships_pair
ON public.friendships(pair_low, pair_high);

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Add updated_at trigger for friendships
DROP TRIGGER IF EXISTS trg_friendships_updated_at ON public.friendships;
CREATE TRIGGER trg_friendships_updated_at
BEFORE UPDATE ON public.friendships
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 1.4 Friend invite tokens table (private discoverability)
CREATE TABLE IF NOT EXISTS public.friend_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inviter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  used_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS ix_friend_invites_inviter ON public.friend_invites(inviter_id);
CREATE INDEX IF NOT EXISTS ix_friend_invites_token ON public.friend_invites(token);

-- 1.5 RLS Policies

-- Profiles RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "read public profiles or self" ON public.profiles;
DROP POLICY IF EXISTS "update own profile" ON public.profiles;

-- Read: Everyone can read public profiles, users can always read their own profile
CREATE POLICY "read public profiles or self"
ON public.profiles
FOR SELECT
USING (public_profile = true OR id = auth.uid());

-- Update: Users can update only themselves (including public_profile toggle)
CREATE POLICY "update own profile"
ON public.profiles
FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Friendships RLS
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "read own friendships" ON public.friendships;
DROP POLICY IF EXISTS "send friend request as requester" ON public.friendships;
DROP POLICY IF EXISTS "addressee can accept" ON public.friendships;
DROP POLICY IF EXISTS "either side can remove" ON public.friendships;

-- Select: only participants can see their friendships
CREATE POLICY "read own friendships"
ON public.friendships
FOR SELECT
USING (requester_id = auth.uid() OR addressee_id = auth.uid());

-- Insert: requester must be current user
CREATE POLICY "send friend request as requester"
ON public.friendships
FOR INSERT
WITH CHECK (requester_id = auth.uid());

-- Update: only addressee can accept (pending -> accepted)
CREATE POLICY "addressee can accept"
ON public.friendships
FOR UPDATE
USING (addressee_id = auth.uid())
WITH CHECK (addressee_id = auth.uid());

-- Delete: either side can remove
CREATE POLICY "either side can remove"
ON public.friendships
FOR DELETE
USING (requester_id = auth.uid() OR addressee_id = auth.uid());

-- Friend Invites RLS (lock down table; use RPC for consumption)
ALTER TABLE public.friend_invites ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "inviter can manage own invites" ON public.friend_invites;

-- Only inviter can see/manage their invites directly
CREATE POLICY "inviter can manage own invites"
ON public.friend_invites
FOR ALL
USING (inviter_id = auth.uid())
WITH CHECK (inviter_id = auth.uid());

-- 1.6 RPC: Create Invite (secure, returns token)
CREATE OR REPLACE FUNCTION public.create_friend_invite(expires_in_hours INTEGER DEFAULT 168)
RETURNS TABLE(token TEXT, expires_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
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

REVOKE ALL ON FUNCTION public.create_friend_invite(INTEGER) FROM public;
GRANT EXECUTE ON FUNCTION public.create_friend_invite(INTEGER) TO authenticated;

-- 1.7 RPC: Consume Invite (secure) → creates friendship pending
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

REVOKE ALL ON FUNCTION public.consume_friend_invite(TEXT) FROM public;
GRANT EXECUTE ON FUNCTION public.consume_friend_invite(TEXT) TO authenticated;

-- Optional: auto-create profile on signup (if not already exists)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name)
  VALUES (
    NEW.id,
    -- default username: user_<first8>
    'user_' || LEFT(NEW.id::TEXT, 8),
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email)
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

