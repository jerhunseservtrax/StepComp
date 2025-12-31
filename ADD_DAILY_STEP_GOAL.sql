-- ============================================
-- Add Daily Step Goal Column to Profiles Table
-- ============================================
-- Run this script in Supabase Dashboard → SQL Editor
-- ============================================

-- Add daily_step_goal column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles' 
        AND column_name = 'daily_step_goal'
    ) THEN
        ALTER TABLE profiles ADD COLUMN daily_step_goal INTEGER DEFAULT 10000;
    END IF;
END $$;

-- Add index for faster queries (optional)
CREATE INDEX IF NOT EXISTS idx_profiles_daily_step_goal ON profiles(daily_step_goal);

-- ============================================
-- Verification Query
-- ============================================
-- SELECT column_name, data_type, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public' 
-- AND table_name = 'profiles' 
-- AND column_name = 'daily_step_goal';

