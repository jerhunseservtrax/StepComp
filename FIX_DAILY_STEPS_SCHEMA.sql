-- ========================================
-- FIX: Add missing device_id column to daily_steps table
-- ========================================

-- Add device_id column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'daily_steps'
          AND column_name = 'device_id'
    ) THEN
        ALTER TABLE daily_steps
        ADD COLUMN device_id TEXT;
        
        RAISE NOTICE 'Added device_id column to daily_steps';
    ELSE
        RAISE NOTICE 'device_id column already exists';
    END IF;
END $$;

-- Verify the column was added
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'daily_steps'
ORDER BY ordinal_position;

