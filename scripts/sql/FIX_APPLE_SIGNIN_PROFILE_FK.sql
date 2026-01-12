-- ============================================
-- FIX: Apple Sign In Users Missing Profiles
-- ============================================
-- This fixes the foreign key constraint error when Apple Sign In
-- users try to add friends.
-- 
-- Error: "friendships_requester_id_fkey" violation
-- Cause: User's ID exists in auth.users but NOT in profiles table
-- ============================================

-- 1. Find Apple users without profiles
SELECT 
    au.id,
    au.email,
    au.raw_user_meta_data->>'full_name' as full_name,
    au.raw_app_meta_data->>'provider' as provider,
    au.created_at
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE p.id IS NULL
ORDER BY au.created_at DESC;

-- 2. Create profiles for orphaned Apple Sign In users
-- Run this to automatically create profiles for users without them
INSERT INTO public.profiles (
    id,
    username,
    first_name,
    last_name,
    display_name,
    email,
    avatar_url,
    is_premium,
    public_profile,
    total_steps,
    daily_step_goal,
    onboarding_completed,
    created_at,
    updated_at
)
SELECT 
    au.id,
    -- Generate unique username from full UUID
    COALESCE(
        -- Try to use email prefix if available
        LOWER(SPLIT_PART(au.email, '@', 1)),
        -- Otherwise use apple_UUID
        'apple_' || au.id::text
    ) as username,
    -- Extract first name from metadata
    au.raw_user_meta_data->>'given_name' as first_name,
    -- Extract last name from metadata
    au.raw_user_meta_data->>'family_name' as last_name,
    -- Create display name
    COALESCE(
        au.raw_user_meta_data->>'full_name',
        CONCAT(
            au.raw_user_meta_data->>'given_name',
            ' ',
            au.raw_user_meta_data->>'family_name'
        )
    ) as display_name,
    au.email,
    NULL as avatar_url,
    FALSE as is_premium,
    FALSE as public_profile,
    0 as total_steps,
    10000 as daily_step_goal,
    TRUE as onboarding_completed,
    au.created_at,
    NOW() as updated_at
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE p.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- 3. Verify all users now have profiles
SELECT 
    COUNT(*) as users_without_profiles
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE p.id IS NULL;

-- Expected result: 0

-- 4. Check if YOUR specific user has a profile
-- Replace YOUR_USER_ID with your actual user ID from the error
-- SELECT * FROM public.profiles WHERE id = 'YOUR_USER_ID';

-- ============================================
-- PREVENTION: Add Database Trigger
-- ============================================
-- This ensures ALL future users automatically get profiles

CREATE OR REPLACE FUNCTION public.handle_new_user_profile()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    username,
    first_name,
    last_name,
    display_name,
    email,
    public_profile,
    total_steps,
    daily_step_goal,
    onboarding_completed
  )
  VALUES (
    NEW.id,
    COALESCE(
      LOWER(SPLIT_PART(NEW.email, '@', 1)),
      'user_' || NEW.id::text
    ),
    NEW.raw_user_meta_data->>'given_name',
    NEW.raw_user_meta_data->>'family_name',
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'display_name'
    ),
    NEW.email,
    FALSE,
    0,
    10000,
    FALSE
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created_profile ON auth.users;

-- Create trigger
CREATE TRIGGER on_auth_user_created_profile
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user_profile();

-- ============================================
-- HOW TO USE THIS SCRIPT
-- ============================================
-- 1. Copy this entire script
-- 2. Go to Supabase Dashboard → SQL Editor
-- 3. Paste and run
-- 4. Check the query results
-- 5. If any users were found without profiles, they're now created
-- 6. Try adding friends again in your app
-- ============================================

