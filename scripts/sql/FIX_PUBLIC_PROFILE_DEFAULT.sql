-- ============================================
-- Fix Public Profile Default - Make Users Discoverable
-- ============================================
-- Problem: All users were created with public_profile = FALSE
--          This prevented them from showing up in the Discover search
-- Solution: Update all existing users to TRUE and change default
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Update all existing users to have public profiles
UPDATE public.profiles
SET public_profile = TRUE
WHERE public_profile = FALSE;

-- Step 2: Change the default value for future users
ALTER TABLE public.profiles 
ALTER COLUMN public_profile SET DEFAULT TRUE;

-- Verification
SELECT 
    '✅ Migration Complete' as status,
    COUNT(*) as total_public_users
FROM public.profiles
WHERE public_profile = TRUE;

-- Show sample of updated users
SELECT 
    username,
    display_name,
    public_profile,
    created_at
FROM public.profiles
ORDER BY created_at DESC
LIMIT 5;
