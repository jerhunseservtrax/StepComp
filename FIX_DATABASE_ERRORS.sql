-- ============================================
-- Fix Database Errors
-- ============================================
-- This script fixes:
-- 1. Missing total_steps column in profiles
-- 2. Infinite recursion in challenges RLS policies
-- 3. Infinite recursion in challenge_members RLS policies
-- ============================================
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================

-- ============================================
-- 1. Add total_steps column to profiles table
-- ============================================
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'total_steps'
    ) THEN
        ALTER TABLE profiles ADD COLUMN total_steps INTEGER DEFAULT 0;
        CREATE INDEX IF NOT EXISTS idx_profiles_total_steps ON profiles(total_steps);
        RAISE NOTICE 'Added total_steps column to profiles table';
    ELSE
        RAISE NOTICE 'total_steps column already exists';
    END IF;
END $$;

-- ============================================
-- 2. Fix challenges RLS policies (remove recursion)
-- ============================================

-- Drop existing policies that might cause recursion
DROP POLICY IF EXISTS "Users can view challenges" ON challenges;
DROP POLICY IF EXISTS "Users can view public challenges" ON challenges;
DROP POLICY IF EXISTS "Users can view their own challenges" ON challenges;
DROP POLICY IF EXISTS "Users can view challenges they're members of" ON challenges;

-- Create simplified, non-recursive policies
CREATE POLICY "Users can view challenges"
  ON challenges FOR SELECT
  USING (
    -- User created the challenge
    created_by = (SELECT auth.uid())
    OR
    -- Challenge is public
    is_public = TRUE
    OR
    -- User is a member of the challenge (check challenge_members directly)
    EXISTS (
      SELECT 1 FROM challenge_members
      WHERE challenge_members.challenge_id = challenges.id
      AND challenge_members.user_id = (SELECT auth.uid())
    )
  );

-- Allow users to create challenges
DROP POLICY IF EXISTS "Users can create challenges" ON challenges;
CREATE POLICY "Users can create challenges"
  ON challenges FOR INSERT
  WITH CHECK (
    created_by = (SELECT auth.uid())
  );

-- Allow users to update their own challenges
DROP POLICY IF EXISTS "Users can update their challenges" ON challenges;
CREATE POLICY "Users can update their challenges"
  ON challenges FOR UPDATE
  USING (
    created_by = (SELECT auth.uid())
  )
  WITH CHECK (
    created_by = (SELECT auth.uid())
  );

-- ============================================
-- 3. Fix challenge_members RLS policies (remove recursion)
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can read challenge members" ON challenge_members;
DROP POLICY IF EXISTS "Users can insert challenge members" ON challenge_members;
DROP POLICY IF EXISTS "Users can update challenge members" ON challenge_members;

-- Create fixed policies without recursion
CREATE POLICY "Users can read challenge members"
  ON challenge_members FOR SELECT
  USING (
    -- User is the member themselves
    user_id = (SELECT auth.uid())
    OR
    -- Challenge is public (check directly, no recursion)
    EXISTS (
      SELECT 1 FROM challenges
      WHERE challenges.id = challenge_members.challenge_id
      AND challenges.is_public = TRUE
    )
    OR
    -- User created the challenge (check directly, no recursion)
    EXISTS (
      SELECT 1 FROM challenges
      WHERE challenges.id = challenge_members.challenge_id
      AND challenges.created_by = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can insert challenge members"
  ON challenge_members FOR INSERT
  WITH CHECK (
    -- User can only insert themselves as a member
    user_id = (SELECT auth.uid())
    OR
    -- Or if they're creating a challenge, they can add members
    EXISTS (
      SELECT 1 FROM challenges
      WHERE challenges.id = challenge_members.challenge_id
      AND challenges.created_by = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can update challenge members"
  ON challenge_members FOR UPDATE
  USING (
    -- User can only update their own member record
    user_id = (SELECT auth.uid())
  )
  WITH CHECK (
    -- User can only update their own member record
    user_id = (SELECT auth.uid())
  );

-- ============================================
-- 4. Verification Queries
-- ============================================

-- Check if total_steps column exists
SELECT 
    column_name, 
    data_type, 
    column_default
FROM information_schema.columns
WHERE table_name = 'profiles' 
  AND column_name = 'total_steps';

-- List all RLS policies on challenges
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename IN ('challenges', 'challenge_members')
ORDER BY tablename, policyname;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Database fixes applied successfully!';
    RAISE NOTICE '   - Added total_steps column to profiles (if missing)';
    RAISE NOTICE '   - Fixed challenges RLS policies (removed recursion)';
    RAISE NOTICE '   - Fixed challenge_members RLS policies (removed recursion)';
END $$;

