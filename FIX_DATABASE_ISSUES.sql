-- ============================================
-- Fix Database Issues
-- ============================================
-- Run this script in Supabase Dashboard → SQL Editor
-- This fixes:
-- 1. Renames user_id to id in profiles table
-- 2. Fixes infinite recursion in challenge_members RLS policy
-- ============================================

-- ============================================
-- 1. FIX PROFILES TABLE: Rename user_id to id
-- ============================================

-- First, check current schema
DO $$
BEGIN
  RAISE NOTICE 'Checking profiles table schema...';
END $$;

-- Show current columns
SELECT 
    column_name, 
    data_type
FROM information_schema.columns
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- Check if user_id exists and id doesn't, then rename
DO $$
BEGIN
  -- Check if column is named 'user_id' instead of 'id'
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'user_id'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'id'
  ) THEN
    -- Rename user_id to id
    -- Note: This will automatically update any foreign key constraints
    ALTER TABLE profiles RENAME COLUMN user_id TO id;
    
    RAISE NOTICE '✅ Successfully renamed user_id to id in profiles table';
  ELSIF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'id'
  ) THEN
    RAISE NOTICE '✅ Profiles table already uses id column';
  ELSE
    RAISE WARNING '❌ Unexpected profiles table structure';
  END IF;
END $$;

-- ============================================
-- 2. FIX CHALLENGE_MEMBERS RLS POLICY
-- ============================================
-- The current policy has infinite recursion because it checks
-- challenge_members within itself. We need to fix this.

-- Drop the problematic policy
DROP POLICY IF EXISTS "Users can read challenge members" ON challenge_members;

-- Create a fixed policy without recursion
-- The key is to avoid querying challenge_members within the policy
-- Users can read challenge_members if:
-- 1. They are the member themselves, OR
-- 2. The challenge is public, OR
-- 3. They created the challenge
-- Note: We removed the "member of challenge" check to avoid recursion
-- This means users can see members of public challenges or challenges they created
CREATE POLICY "Users can read challenge members"
  ON challenge_members FOR SELECT
  USING (
    -- User is the member themselves
    (SELECT auth.uid()) = user_id
    OR
    -- Challenge is public
    EXISTS (
      SELECT 1 FROM challenges
      WHERE challenges.id = challenge_members.challenge_id
      AND challenges.is_public = TRUE
    )
    OR
    -- User created the challenge
    EXISTS (
      SELECT 1 FROM challenges
      WHERE challenges.id = challenge_members.challenge_id
      AND challenges.created_by = (SELECT auth.uid())
    )
  );

-- ============================================
-- 3. VERIFY FIXES
-- ============================================

-- Verify profiles table has 'id' column
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'id'
  ) THEN
    RAISE NOTICE '✅ Profiles table has id column';
  ELSE
    RAISE WARNING '❌ Profiles table missing id column';
  END IF;
END $$;

-- Verify challenge_members policy exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'challenge_members' 
    AND policyname = 'Users can read challenge members'
  ) THEN
    RAISE NOTICE '✅ challenge_members RLS policy fixed';
  ELSE
    RAISE WARNING '❌ challenge_members RLS policy missing';
  END IF;
END $$;

RAISE NOTICE 'Database fixes complete!';

