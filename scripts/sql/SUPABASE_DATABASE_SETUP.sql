-- ============================================
-- FitComp Database Setup Script
-- ============================================
-- Run this script in Supabase Dashboard → SQL Editor
-- ============================================

-- ============================================
-- 1. PROFILES TABLE
-- ============================================
-- Stores user profile information linked to auth.users

CREATE TABLE IF NOT EXISTS profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  avatar TEXT,
  public_profile BOOLEAN DEFAULT TRUE,
  is_premium BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own profile
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can read other users' profiles (for leaderboards, etc.)
CREATE POLICY "Users can read other profiles"
  ON profiles FOR SELECT
  USING (auth.uid() = user_id OR public_profile = TRUE);

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
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 2. CHALLENGES TABLE
-- ============================================
-- Stores challenge/challenge group information

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
-- 3. CHALLENGE_MEMBERS TABLE
-- ============================================
-- Tracks which users are in which challenges and their step counts

CREATE TABLE IF NOT EXISTS challenge_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  total_steps INTEGER DEFAULT 0,
  daily_steps JSONB DEFAULT '{}'::jsonb, -- Store daily step counts: {"2024-12-24": 5000, ...}
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(challenge_id, user_id)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_challenge_members_challenge_id ON challenge_members(challenge_id);
CREATE INDEX IF NOT EXISTS idx_challenge_members_user_id ON challenge_members(user_id);
CREATE INDEX IF NOT EXISTS idx_challenge_members_total_steps ON challenge_members(challenge_id, total_steps DESC);

-- Enable Row Level Security
ALTER TABLE challenge_members ENABLE ROW LEVEL SECURITY;

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
CREATE TRIGGER update_challenge_members_last_updated
  BEFORE UPDATE ON challenge_members
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Policy: Challenge members can read their challenges
-- (Created after challenge_members table exists)
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
-- 4. FRIENDS TABLE (Optional)
-- ============================================
-- Tracks friend relationships between users

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
CREATE TRIGGER update_friends_updated_at
  BEFORE UPDATE ON friends
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 5. HELPER FUNCTIONS
-- ============================================

-- Function to get user's total steps across all challenges
CREATE OR REPLACE FUNCTION get_user_total_steps(p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
  IF auth.uid() IS NULL OR auth.uid() <> p_user_id THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

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
-- 6. SETUP COMPLETE
-- ============================================

-- Verify tables were created
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
-- 4. Challenge members can see each other's step counts
-- 5. Invite codes are generated automatically when creating challenges
-- 6. Daily steps are stored as JSONB for flexibility
-- ============================================

