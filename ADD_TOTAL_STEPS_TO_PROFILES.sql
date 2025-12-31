-- Add total_steps column to profiles table
-- This allows storing the user's total step count in their profile

-- Add the column (nullable, defaults to 0)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS total_steps INTEGER DEFAULT 0;

-- Add a comment to document the field
COMMENT ON COLUMN profiles.total_steps IS 'Total steps synced from HealthKit for the user';

-- Create an index for faster queries (optional, but helpful for leaderboards)
CREATE INDEX IF NOT EXISTS idx_profiles_total_steps ON profiles(total_steps DESC);

-- Note: This field will be updated by the StepSyncService when HealthKit steps are synced

