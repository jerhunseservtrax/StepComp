-- ============================================================
-- FIX PROFILE RELATIONSHIP FOR CHAT
-- ============================================================
-- This ensures challenge_messages can properly join to profiles
-- ============================================================

-- Option 1: Ensure profiles table has correct structure
-- Check if profiles.id references auth.users correctly
DO $$ 
BEGIN
    -- Verify profiles table exists and has proper FK
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu 
          ON tc.constraint_name = kcu.constraint_name
        WHERE tc.table_name = 'profiles'
        AND tc.constraint_type = 'FOREIGN KEY'
        AND kcu.column_name = 'id'
    ) THEN
        -- Add FK if it doesn't exist
        ALTER TABLE public.profiles 
        ADD CONSTRAINT profiles_id_fkey 
        FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
        
        RAISE NOTICE '✅ Added foreign key from profiles.id to auth.users.id';
    ELSE
        RAISE NOTICE '✅ profiles.id foreign key already exists';
    END IF;
END $$;

-- Option 2: Create a view that makes the relationship explicit
CREATE OR REPLACE VIEW public.challenge_messages_with_profiles AS
SELECT 
    cm.*,
    p.username,
    p.display_name,
    p.avatar_url
FROM public.challenge_messages cm
LEFT JOIN public.profiles p ON cm.user_id = p.id;

-- Grant access to the view
GRANT SELECT ON public.challenge_messages_with_profiles TO authenticated;

-- Verify the fix
SELECT 
    'profile_relationship' AS check_type,
    COUNT(*) AS foreign_keys_count
FROM information_schema.table_constraints
WHERE table_name = 'profiles'
AND constraint_type = 'FOREIGN KEY'
AND constraint_name = 'profiles_id_fkey';

SELECT '✅ Profile relationship fix complete' AS status;

