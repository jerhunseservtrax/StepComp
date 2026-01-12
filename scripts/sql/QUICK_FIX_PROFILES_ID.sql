-- ============================================
-- QUICK FIX: Rename user_id to id in profiles
-- ============================================
-- Run this FIRST if you're getting the "Could not find the 'id' column" error
-- ============================================

-- Rename user_id to id (if user_id exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE profiles RENAME COLUMN user_id TO id;
    RAISE NOTICE '✅ Fixed: Renamed user_id to id';
  ELSE
    RAISE NOTICE 'ℹ️  Profiles table already has id column or structure is different';
  END IF;
END $$;

-- Verify
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'profiles' AND column_name = 'id'
        ) THEN '✅ id column exists'
        ELSE '❌ id column missing'
    END as status;

