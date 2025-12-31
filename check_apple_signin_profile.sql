-- Check if Apple Sign In users have profiles created correctly

-- 1. Check all auth users and their profiles
SELECT 
    au.id as auth_user_id,
    au.email,
    au.provider,
    au.created_at as auth_created,
    p.id as profile_id,
    p.username,
    p.first_name,
    p.last_name,
    p.onboarding_completed,
    p.created_at as profile_created
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
ORDER BY au.created_at DESC
LIMIT 10;

-- 2. Check for users with auth but NO profile
SELECT 
    au.id,
    au.email,
    au.provider,
    au.created_at
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE p.id IS NULL
ORDER BY au.created_at DESC;

-- 3. Check profiles table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'profiles'
ORDER BY ordinal_position;
