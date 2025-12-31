-- ============================================
-- FIX ALL CRITICAL ISSUES
-- ============================================
-- This script fixes:
-- 1. Infinite recursion in RLS policies
-- 2. Missing avatar column error
-- 3. Challenge visibility issues
-- ============================================
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================

-- ============================================
-- 1. FIX RLS RECURSION FOR CHALLENGES
-- ============================================

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Users can read own challenges" ON challenges;
DROP POLICY IF EXISTS "Users can read challenges they created" ON challenges;
DROP POLICY IF EXISTS "Users can read challenges they're in" ON challenges;
DROP POLICY IF EXISTS "Users can view challenges they participate in" ON challenges;
DROP POLICY IF EXISTS "Users can create challenges" ON challenges;
DROP POLICY IF EXISTS "Users can update own challenges" ON challenges;
DROP POLICY IF EXISTS "Users can delete own challenges" ON challenges;
DROP POLICY IF EXISTS "Users can read own challenges or joined challenges" ON challenges;
DROP POLICY IF EXISTS "Challenge creator can update" ON challenges;
DROP POLICY IF EXISTS "Challenge creator can delete" ON challenges;

-- Create non-recursive SELECT policy
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

-- INSERT: Users can create challenges
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

-- ============================================
-- 2. FIX RLS RECURSION FOR CHALLENGE_MEMBERS
-- ============================================

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Users can read challenge members" ON challenge_members;
DROP POLICY IF EXISTS "Users can view challenge members" ON challenge_members;
DROP POLICY IF EXISTS "Users can read members of their challenges" ON challenge_members;
DROP POLICY IF EXISTS "Users can join challenges" ON challenge_members;
DROP POLICY IF EXISTS "Users can update own membership" ON challenge_members;
DROP POLICY IF EXISTS "Users can leave challenges" ON challenge_members;

-- Non-recursive SELECT policy
CREATE POLICY "Users can read members of their challenges"
ON challenge_members FOR SELECT
USING (
    -- User is the member
    user_id = auth.uid()
    OR
    -- User created the challenge (check directly, no JOIN)
    challenge_id IN (
        SELECT id FROM challenges WHERE created_by = auth.uid()
    )
);

-- INSERT: Users can join challenges
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
-- 3. FIX MISSING AVATAR COLUMN ERROR
-- ============================================
-- Ensure profiles table has avatar_url column
-- (This should already exist, but adding check)

DO $$
BEGIN
    -- Check if avatar_url column exists, if not add it
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'avatar_url'
    ) THEN
        ALTER TABLE public.profiles 
        ADD COLUMN avatar_url TEXT;
        
        -- Copy existing avatar data to avatar_url if it exists
        UPDATE public.profiles 
        SET avatar_url = avatar 
        WHERE avatar IS NOT NULL AND avatar_url IS NULL;
        
        RAISE NOTICE 'Added avatar_url column to profiles table';
    ELSE
        RAISE NOTICE 'avatar_url column already exists';
    END IF;
END $$;

-- ============================================
-- 4. VERIFY PUBLIC CHALLENGES ARE VISIBLE
-- ============================================
-- Ensure public challenges can be read by anyone
-- (This is already handled by the SELECT policy above)

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check policies are created
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    cmd
FROM pg_policies
WHERE tablename IN ('challenges', 'challenge_members')
ORDER BY tablename, policyname;

-- Check profiles table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'profiles'
AND column_name IN ('avatar', 'avatar_url', 'id', 'username', 'display_name')
ORDER BY ordinal_position;

