-- ============================================
-- Friends Feature Database Schema Update
-- ============================================
-- This script updates the database schema to support the friends feature
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================

-- ============================================
-- 1. UPDATE PROFILES TABLE
-- ============================================
-- Ensure profiles table has the required structure

-- First, ensure the table exists with correct structure
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  email TEXT,
  first_name TEXT,
  last_name TEXT,
  avatar TEXT,
  is_premium BOOLEAN DEFAULT FALSE,
  height INTEGER,
  weight INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- If the table already exists with user_id, we need to migrate
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
    ALTER TABLE profiles RENAME COLUMN user_id TO id;
  END IF;
END $$;

-- Ensure username is unique (add constraint if it doesn't exist)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'profiles_username_key'
  ) THEN
    ALTER TABLE profiles ADD CONSTRAINT profiles_username_key UNIQUE (username);
  END IF;
END $$;

-- Add email column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'email'
  ) THEN
    ALTER TABLE profiles ADD COLUMN email TEXT;
  END IF;
END $$;

-- Add first_name if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'first_name'
  ) THEN
    ALTER TABLE profiles ADD COLUMN first_name TEXT;
  END IF;
END $$;

-- Add last_name if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'last_name'
  ) THEN
    ALTER TABLE profiles ADD COLUMN last_name TEXT;
  END IF;
END $$;

-- Add avatar if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'avatar'
  ) THEN
    ALTER TABLE profiles ADD COLUMN avatar TEXT;
  END IF;
END $$;

-- Add is_premium if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'is_premium'
  ) THEN
    ALTER TABLE profiles ADD COLUMN is_premium BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- Add height if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'height'
  ) THEN
    ALTER TABLE profiles ADD COLUMN height INTEGER;
  END IF;
END $$;

-- Add weight if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'weight'
  ) THEN
    ALTER TABLE profiles ADD COLUMN weight INTEGER;
  END IF;
END $$;

-- Add created_at if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE profiles ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
  END IF;
END $$;

-- Add updated_at if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE profiles ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
  END IF;
END $$;

-- Ensure username is NOT NULL
ALTER TABLE profiles ALTER COLUMN username SET NOT NULL;

-- ============================================
-- 2. DROP AND RECREATE FRIENDS TABLE
-- ============================================
-- Drop existing friends table if it has the old structure
DROP TABLE IF EXISTS friends CASCADE;

-- Create friends table with the correct structure
CREATE TABLE friends (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  addressee_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT CHECK (status IN ('pending', 'accepted')) NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE (requester_id, addressee_id),
  CHECK (requester_id != addressee_id)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_friends_requester ON friends(requester_id);
CREATE INDEX IF NOT EXISTS idx_friends_addressee ON friends(addressee_id);
CREATE INDEX IF NOT EXISTS idx_friends_status ON friends(status);

-- ============================================
-- 3. ENABLE ROW LEVEL SECURITY
-- ============================================

-- Enable RLS on profiles (if not already enabled)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Enable RLS on friends
ALTER TABLE friends ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 4. DROP EXISTING POLICIES
-- ============================================

-- Drop existing profiles policies
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
DROP POLICY IF EXISTS "Users can read other profiles" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- Drop existing friends policies (clean up any old policy names)
DROP POLICY IF EXISTS "Users can view own friend relationships" ON friends;
DROP POLICY IF EXISTS "Users can read own friendships" ON friends;
DROP POLICY IF EXISTS "Users can send friend requests" ON friends;
DROP POLICY IF EXISTS "Users can create friend requests" ON friends;
DROP POLICY IF EXISTS "Users can update incoming requests" ON friends;
DROP POLICY IF EXISTS "Users can update received friend requests" ON friends;
DROP POLICY IF EXISTS "Users can delete own friend requests" ON friends;

-- ============================================
-- 5. CREATE RLS POLICIES FOR PROFILES
-- ============================================

-- Policy: Users can read their own profile
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  USING ((SELECT auth.uid()) = id);

-- Policy: Users can read other users' profiles (for search, leaderboards, etc.)
CREATE POLICY "Users can read other profiles"
  ON profiles FOR SELECT
  USING (true);

-- Policy: Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING ((SELECT auth.uid()) = id);

-- ============================================
-- 6. CREATE RLS POLICIES FOR FRIENDS
-- ============================================

-- Policy: Users can view their own friend relationships
-- Users can see friendships where they are requester or addressee
CREATE POLICY "Users can view own friend relationships"
  ON friends
  FOR SELECT
  USING (
    auth.uid() = requester_id OR auth.uid() = addressee_id
  );

-- Policy: Users can send friend requests
-- Users can only insert friend requests where they are the requester
CREATE POLICY "Users can send friend requests"
  ON friends
  FOR INSERT
  WITH CHECK (
    auth.uid() = requester_id
  );

-- Policy: Users can accept incoming requests
-- Users can only update friend requests where they are the addressee
-- This allows accepting/rejecting friend requests
CREATE POLICY "Users can update incoming requests"
  ON friends
  FOR UPDATE
  USING (
    auth.uid() = addressee_id
  );

-- ============================================
-- 7. CREATE HELPER FUNCTIONS
-- ============================================

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
-- 8. CREATE TRIGGER FOR AUTO PROFILE CREATION
-- ============================================

-- Function to automatically create profile when user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
    NEW.email
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- 9. VERIFICATION QUERIES
-- ============================================

-- Verify profiles table structure
DO $$
BEGIN
  RAISE NOTICE 'Profiles table structure verified';
  RAISE NOTICE 'Friends table structure verified';
  RAISE NOTICE 'RLS policies created';
  RAISE NOTICE 'Schema update complete!';
END $$;

