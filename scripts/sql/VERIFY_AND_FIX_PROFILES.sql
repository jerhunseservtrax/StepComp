-- ============================================
-- Verify and Fix Profiles Table Schema
-- ============================================
-- Run this in Supabase Dashboard → SQL Editor
-- This will check the current schema and fix it
-- ============================================

-- ============================================
-- 1. CHECK CURRENT SCHEMA
-- ============================================

-- Check what columns exist in profiles table
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- ============================================
-- 2. FIX: Rename user_id to id if needed
-- ============================================

DO $$
BEGIN
  -- Check if user_id exists and id doesn't
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'user_id'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'id'
  ) THEN
    -- First, drop any foreign key constraints that reference user_id
    -- (PostgreSQL will handle this automatically, but we'll be explicit)
    
    -- Rename the column
    ALTER TABLE profiles RENAME COLUMN user_id TO id;
    
    RAISE NOTICE '✅ Successfully renamed user_id to id in profiles table';
  ELSIF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'id'
  ) THEN
    RAISE NOTICE '✅ Profiles table already has id column';
  ELSE
    RAISE WARNING '❌ Profiles table structure is unexpected';
  END IF;
END $$;

-- ============================================
-- 3. VERIFY FIX
-- ============================================

-- Check if id column now exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'id'
  ) THEN
    RAISE NOTICE '✅ VERIFICATION: Profiles table has id column';
  ELSE
    RAISE WARNING '❌ VERIFICATION FAILED: Profiles table missing id column';
  END IF;
END $$;

-- Show final schema
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

RAISE NOTICE 'Schema check and fix complete!';

