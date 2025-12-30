-- Add height column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'height'
    ) THEN
        ALTER TABLE profiles ADD COLUMN height INTEGER;
    END IF;
END $$;

-- Add weight column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'weight'
    ) THEN
        ALTER TABLE profiles ADD COLUMN weight INTEGER;
    END IF;
END $$;

