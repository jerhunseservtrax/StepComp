-- Fix infinite recursion in challenge_members RLS policy
-- Run this in Supabase SQL Editor

-- Drop the problematic policy
DROP POLICY IF EXISTS "Users can read challenge members" ON challenge_members;

-- Create a fixed policy without recursion
-- Users can read challenge_members if:
-- 1. They are the member themselves, OR
-- 2. The challenge is public, OR
-- 3. They created the challenge
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

-- Also fix INSERT and UPDATE policies to avoid recursion
DROP POLICY IF EXISTS "Users can insert challenge members" ON challenge_members;
CREATE POLICY "Users can insert challenge members"
  ON challenge_members FOR INSERT
  WITH CHECK (
    -- User can only insert themselves as a member
    (SELECT auth.uid()) = user_id
    OR
    -- Or if they're creating a challenge, they can add members
    EXISTS (
      SELECT 1 FROM challenges
      WHERE challenges.id = challenge_members.challenge_id
      AND challenges.created_by = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can update challenge members" ON challenge_members;
CREATE POLICY "Users can update challenge members"
  ON challenge_members FOR UPDATE
  USING (
    -- User can only update their own member record
    (SELECT auth.uid()) = user_id
  )
  WITH CHECK (
    -- User can only update their own member record
    (SELECT auth.uid()) = user_id
  );

