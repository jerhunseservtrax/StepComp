-- ============================================
-- StepComp Database Setup Script (Updated)
-- ============================================
-- Run this script in Supabase Dashboard → SQL Editor
-- This updates the schema to include first_name and last_name
-- ============================================

-- ============================================
-- 1. UPDATE PROFILES TABLE
-- ============================================
-- Add first_name and last_name columns if they don't exist

-- Add first_name column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'first_name'
    ) THEN
        ALTER TABLE profiles ADD COLUMN first_name TEXT;
    END IF;
END $$;

-- Add last_name column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'last_name'
    ) THEN
        ALTER TABLE profiles ADD COLUMN last_name TEXT;
    END IF;
END $$;

-- Add height column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'height'
    ) THEN
        ALTER TABLE profiles ADD COLUMN height INTEGER;
    END IF;
END $$;

-- Add weight column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'weight'
    ) THEN
        ALTER TABLE profiles ADD COLUMN weight INTEGER;
    END IF;
END $$;

-- ============================================
-- 2. CREATE PROFILES TABLE (if it doesn't exist)
-- ============================================

CREATE TABLE IF NOT EXISTS profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  avatar TEXT,
  is_premium BOOLEAN DEFAULT FALSE,
  height INTEGER, -- Height in cm
  weight INTEGER, -- Weight in kg
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
DROP POLICY IF EXISTS "Users can read other profiles" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- Policy: Users can read their own profile
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can read other users' profiles (for leaderboards, etc.)
CREATE POLICY "Users can read other profiles"
  ON profiles FOR SELECT
  USING (true);

-- Policy: Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = user_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on profile updates
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 3. CREATE TRIGGER FOR AUTO PROFILE CREATION
-- ============================================
-- Automatically create a profile when a new user signs up

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (user_id, username, first_name, last_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
    NEW.raw_user_meta_data->>'first_name',
    NEW.raw_user_meta_data->>'last_name'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger on auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- 4. CHALLENGES TABLE (if not exists)
-- ============================================

CREATE TABLE IF NOT EXISTS challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  is_public BOOLEAN DEFAULT TRUE,
  invite_code TEXT UNIQUE,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can read public challenges" ON challenges;
DROP POLICY IF EXISTS "Users can read own challenges" ON challenges;
DROP POLICY IF EXISTS "Users can create challenges" ON challenges;
DROP POLICY IF EXISTS "Users can update own challenges" ON challenges;
DROP POLICY IF EXISTS "Users can delete own challenges" ON challenges;
DROP POLICY IF EXISTS "Challenge members can read challenges" ON challenges;

-- Policy: Anyone can read public challenges
CREATE POLICY "Anyone can read public challenges"
  ON challenges FOR SELECT
  USING (is_public = TRUE);

-- Policy: Users can read challenges they created
CREATE POLICY "Users can read own challenges"
  ON challenges FOR SELECT
  USING (auth.uid() = created_by);

-- Policy: Users can create challenges
CREATE POLICY "Users can create challenges"
  ON challenges FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Policy: Challenge creators can update their challenges
CREATE POLICY "Users can update own challenges"
  ON challenges FOR UPDATE
  USING (auth.uid() = created_by);

-- Policy: Challenge creators can delete their challenges
CREATE POLICY "Users can delete own challenges"
  ON challenges FOR DELETE
  USING (auth.uid() = created_by);

-- Trigger to update updated_at on challenge updates
DROP TRIGGER IF EXISTS update_challenges_updated_at ON challenges;
CREATE TRIGGER update_challenges_updated_at
  BEFORE UPDATE ON challenges
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to generate unique invite codes
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;

-- ============================================
-- 5. CHALLENGE_MEMBERS TABLE (if not exists)
-- ============================================

CREATE TABLE IF NOT EXISTS challenge_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  total_steps INTEGER DEFAULT 0,
  daily_steps JSONB DEFAULT '{}'::jsonb,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(challenge_id, user_id)
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_challenge_members_challenge_id ON challenge_members(challenge_id);
CREATE INDEX IF NOT EXISTS idx_challenge_members_user_id ON challenge_members(user_id);
CREATE INDEX IF NOT EXISTS idx_challenge_members_total_steps ON challenge_members(challenge_id, total_steps DESC);

-- Enable Row Level Security
ALTER TABLE challenge_members ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read challenge members" ON challenge_members;
DROP POLICY IF EXISTS "Users can join challenges" ON challenge_members;
DROP POLICY IF EXISTS "Users can update own steps" ON challenge_members;
DROP POLICY IF EXISTS "Users can leave challenges" ON challenge_members;

-- Policy: Users can read members of challenges they're in
CREATE POLICY "Users can read challenge members"
  ON challenge_members FOR SELECT
  USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM challenges
      WHERE challenges.id = challenge_members.challenge_id
      AND (
        challenges.is_public = TRUE OR
        challenges.created_by = auth.uid() OR
        EXISTS (
          SELECT 1 FROM challenge_members cm
          WHERE cm.challenge_id = challenges.id
          AND cm.user_id = auth.uid()
        )
      )
    )
  );

-- Policy: Users can join challenges
CREATE POLICY "Users can join challenges"
  ON challenge_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own step count
CREATE POLICY "Users can update own steps"
  ON challenge_members FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can leave challenges
CREATE POLICY "Users can leave challenges"
  ON challenge_members FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger to update last_updated timestamp
DROP TRIGGER IF EXISTS update_challenge_members_last_updated ON challenge_members;
CREATE TRIGGER update_challenge_members_last_updated
  BEFORE UPDATE ON challenge_members
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Policy: Challenge members can read their challenges
CREATE POLICY "Challenge members can read challenges"
  ON challenges FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM challenge_members
      WHERE challenge_members.challenge_id = challenges.id
      AND challenge_members.user_id = auth.uid()
    )
  );

-- ============================================
-- 6. FRIENDS TABLE (if not exists)
-- ============================================

CREATE TABLE IF NOT EXISTS friends (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  friend_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, friend_id),
  CHECK (user_id != friend_id)
);

-- Enable Row Level Security
ALTER TABLE friends ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read own friendships" ON friends;
DROP POLICY IF EXISTS "Users can create friend requests" ON friends;
DROP POLICY IF EXISTS "Users can update received friend requests" ON friends;

-- Policy: Users can read their own friendships
CREATE POLICY "Users can read own friendships"
  ON friends FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Policy: Users can create friend requests
CREATE POLICY "Users can create friend requests"
  ON friends FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update friend requests they received
CREATE POLICY "Users can update received friend requests"
  ON friends FOR UPDATE
  USING (auth.uid() = friend_id);

-- Trigger to update updated_at
DROP TRIGGER IF EXISTS update_friends_updated_at ON friends;
CREATE TRIGGER update_friends_updated_at
  BEFORE UPDATE ON friends
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 7. HELPER FUNCTIONS
-- ============================================

-- Function to get user's total steps across all challenges
CREATE OR REPLACE FUNCTION get_user_total_steps(p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN COALESCE(
    (SELECT SUM(total_steps) FROM challenge_members WHERE user_id = p_user_id),
    0
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get challenge leaderboard
CREATE OR REPLACE FUNCTION get_challenge_leaderboard(p_challenge_id UUID)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  avatar TEXT,
  total_steps INTEGER,
  rank BIGINT
) AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 8. VERIFY SETUP
-- ============================================

-- Check if tables exist and show row counts
SELECT 
  'profiles' as table_name,
  COUNT(*) as row_count
FROM profiles
UNION ALL
SELECT 
  'challenges' as table_name,
  COUNT(*) as row_count
FROM challenges
UNION ALL
SELECT 
  'challenge_members' as table_name,
  COUNT(*) as row_count
FROM challenge_members
UNION ALL
SELECT 
  'friends' as table_name,
  COUNT(*) as row_count
FROM friends;

-- ============================================
-- NOTES:
-- ============================================
-- 1. All tables have Row Level Security (RLS) enabled
-- 2. Users can only access their own data or public data
-- 3. The profiles table is automatically linked to auth.users
-- 4. A trigger automatically creates a profile when a user signs up
-- 5. Challenge members can see each other's step counts
-- 6. Invite codes are generated automatically when creating challenges
-- 7. Daily steps are stored as JSONB for flexibility
-- ============================================

