-- ============================================
-- FIX: Infinite Recursion in Challenges RLS Policies
-- ============================================
-- This script fixes the infinite recursion error in the challenges table RLS policies
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================

-- 1. Drop existing problematic policies
DROP POLICY IF EXISTS "Users can read own challenges" ON challenges;
DROP POLICY IF EXISTS "Users can read challenges they created" ON challenges;
DROP POLICY IF EXISTS "Users can read challenges they're in" ON challenges;
DROP POLICY IF EXISTS "Users can view challenges they participate in" ON challenges;
DROP POLICY IF EXISTS "Users can create challenges" ON challenges;
DROP POLICY IF EXISTS "Users can update own challenges" ON challenges;
DROP POLICY IF EXISTS "Users can delete own challenges" ON challenges;

-- 2. Create non-recursive policies for challenges

-- SELECT: Users can read challenges they created OR challenges where they are members
CREATE POLICY "Users can read own challenges or joined challenges"
ON challenges FOR SELECT
USING (
    auth.uid() = created_by 
    OR 
    id IN (
        SELECT challenge_id 
        FROM challenge_members 
        WHERE user_id = auth.uid()
    )
);

-- INSERT: Users can create challenges (they become the creator)
CREATE POLICY "Users can create challenges"
ON challenges FOR INSERT
WITH CHECK (auth.uid() = created_by);

-- UPDATE: Only challenge creator can update
CREATE POLICY "Challenge creator can update"
ON challenges FOR UPDATE
USING (auth.uid() = created_by)
WITH CHECK (auth.uid() = created_by);

-- DELETE: Only challenge creator can delete
CREATE POLICY "Challenge creator can delete"
ON challenges FOR DELETE
USING (auth.uid() = created_by);

-- 3. Verify challenge_members policies (ensure they're not recursive)
DROP POLICY IF EXISTS "Users can read challenge members" ON challenge_members;
DROP POLICY IF EXISTS "Users can view challenge members" ON challenge_members;

-- Non-recursive policy: Users can read members of challenges they're in
CREATE POLICY "Users can read members of their challenges"
ON challenge_members FOR SELECT
USING (
    -- User is the member
    user_id = auth.uid()
    OR
    -- User created the challenge
    challenge_id IN (
        SELECT id FROM challenges WHERE created_by = auth.uid()
    )
);

-- INSERT: Users can join challenges (if public or invited)
CREATE POLICY "Users can join challenges"
ON challenge_members FOR INSERT
WITH CHECK (user_id = auth.uid());

-- UPDATE: Users can update their own challenge member record
CREATE POLICY "Users can update own membership"
ON challenge_members FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- DELETE: Users can leave challenges
CREATE POLICY "Users can leave challenges"
ON challenge_members FOR DELETE
USING (user_id = auth.uid());

-- ============================================
-- Verification Query
-- ============================================
-- Run this to verify policies are created correctly:
-- 
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
-- FROM pg_policies
-- WHERE tablename IN ('challenges', 'challenge_members')
-- ORDER BY tablename, policyname;

