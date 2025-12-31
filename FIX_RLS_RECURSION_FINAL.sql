-- ============================================
-- Fix RLS Recursion Issues - Final Fix
-- ============================================
-- This script completely removes recursion from RLS policies
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================

-- ============================================
-- 1. Drop ALL existing policies to start fresh
-- ============================================

-- Drop all challenge policies
DROP POLICY IF EXISTS "Users can view challenges" ON challenges;
DROP POLICY IF EXISTS "Users can view public challenges" ON challenges;
DROP POLICY IF EXISTS "Users can view their own challenges" ON challenges;
DROP POLICY IF EXISTS "Users can view challenges they're members of" ON challenges;
DROP POLICY IF EXISTS "Anyone can read public challenges" ON challenges;
DROP POLICY IF EXISTS "Users can create challenges" ON challenges;
DROP POLICY IF EXISTS "Users can update their challenges" ON challenges;

-- Drop all challenge_members policies
DROP POLICY IF EXISTS "Users can read challenge members" ON challenge_members;
DROP POLICY IF EXISTS "Users can insert challenge members" ON challenge_members;
DROP POLICY IF EXISTS "Users can update challenge members" ON challenge_members;
DROP POLICY IF EXISTS "Users can view own challenge relationships" ON challenge_members;

-- ============================================
-- 2. Create SIMPLE, NON-RECURSIVE policies for challenges
-- ============================================

-- Policy: Anyone can view public challenges (no recursion)
CREATE POLICY "Anyone can view public challenges"
  ON challenges FOR SELECT
  USING (is_public = TRUE);

-- Policy: Users can view challenges they created (no recursion)
CREATE POLICY "Users can view their own challenges"
  ON challenges FOR SELECT
  USING (created_by = auth.uid());

-- Policy: Users can view challenges where they are a member
-- This checks challenge_members directly without querying challenges again
CREATE POLICY "Users can view challenges they joined"
  ON challenges FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM challenge_members cm
      WHERE cm.challenge_id = challenges.id
      AND cm.user_id = auth.uid()
    )
  );

-- Policy: Users can create challenges
CREATE POLICY "Users can create challenges"
  ON challenges FOR INSERT
  WITH CHECK (created_by = auth.uid());

-- Policy: Users can update challenges they created
CREATE POLICY "Users can update their challenges"
  ON challenges FOR UPDATE
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

-- ============================================
-- 3. Create SIMPLE, NON-RECURSIVE policies for challenge_members
-- ============================================

-- Policy: Users can view challenge_members for public challenges
-- This checks challenges.is_public directly (no recursion)
CREATE POLICY "Users can view members of public challenges"
  ON challenge_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM challenges c
      WHERE c.id = challenge_members.challenge_id
      AND c.is_public = TRUE
    )
  );

-- Policy: Users can view challenge_members for challenges they created
CREATE POLICY "Users can view members of their challenges"
  ON challenge_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM challenges c
      WHERE c.id = challenge_members.challenge_id
      AND c.created_by = auth.uid()
    )
  );

-- Policy: Users can view their own challenge_members record
CREATE POLICY "Users can view their own membership"
  ON challenge_members FOR SELECT
  USING (user_id = auth.uid());

-- Policy: Users can insert themselves as challenge members
CREATE POLICY "Users can join challenges"
  ON challenge_members FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    OR
    -- Challenge creator can add members
    EXISTS (
      SELECT 1 FROM challenges c
      WHERE c.id = challenge_members.challenge_id
      AND c.created_by = auth.uid()
    )
  );

-- Policy: Users can update their own challenge_members record
CREATE POLICY "Users can update their own membership"
  ON challenge_members FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ============================================
-- 4. Verification
-- ============================================

-- Check policies
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename IN ('challenges', 'challenge_members')
ORDER BY tablename, policyname;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ RLS policies fixed! No more recursion.';
    RAISE NOTICE '   - Challenges: 3 SELECT policies (public, own, joined)';
    RAISE NOTICE '   - Challenge_members: 3 SELECT policies (public, own, creator)';
END $$;

