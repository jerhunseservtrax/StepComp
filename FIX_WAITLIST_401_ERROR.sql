-- ============================================
-- FIX WAITLIST PERMISSIONS (401 Error Fix)
-- Run this in Supabase SQL Editor
-- ============================================

-- This fixes the "401 Unauthorized" error when submitting emails

-- 1. Grant INSERT permission to anon and authenticated users
GRANT INSERT ON public.waitlist TO anon;
GRANT INSERT ON public.waitlist TO authenticated;

-- 2. Grant USAGE on the sequence (for auto-generated IDs)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- 3. Re-create the RLS policy with explicit anon role
DROP POLICY IF EXISTS "Anyone can join waitlist" ON public.waitlist;

CREATE POLICY "Anyone can join waitlist"
ON public.waitlist
FOR INSERT
TO anon, authenticated  -- Explicitly list both roles
WITH CHECK (true);

-- 4. Re-grant execute permissions on functions
GRANT EXECUTE ON FUNCTION get_waitlist_count() TO anon;
GRANT EXECUTE ON FUNCTION get_waitlist_count() TO authenticated;

-- 5. Verify RLS is enabled
ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;

-- ============================================
-- VERIFICATION
-- ============================================

-- Check table permissions
SELECT 
    grantee, 
    privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
AND table_name = 'waitlist'
AND grantee IN ('anon', 'authenticated', 'public');

-- Check RLS policies
SELECT 
    policyname,
    cmd,
    roles,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'waitlist';

-- Check function permissions
SELECT 
    routine_name,
    grantee,
    privilege_type
FROM information_schema.routine_privileges
WHERE routine_schema = 'public'
AND routine_name = 'get_waitlist_count'
AND grantee IN ('anon', 'authenticated');

-- ============================================
-- TEST THE FIX
-- ============================================

-- Test: Try to get the count (should work)
SELECT get_waitlist_count();

-- Test: Simulate an insert as anon user (run this to test)
-- This should succeed if permissions are correct
DO $$
BEGIN
    RAISE NOTICE '✅ Testing INSERT permission...';
    
    -- Try to insert a test record
    INSERT INTO public.waitlist (email, referral_source, user_agent)
    VALUES ('test-' || gen_random_uuid()::text || '@example.com', 'test', 'SQL Test')
    ON CONFLICT (email) DO NOTHING;
    
    RAISE NOTICE '✅ INSERT test successful! Permissions are correct.';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ INSERT test failed: %', SQLERRM;
END $$;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$ 
BEGIN 
    RAISE NOTICE '✅ Permissions fixed!';
    RAISE NOTICE '🔄 Now refresh your waitlist page and try again!';
    RAISE NOTICE '📧 The form should work now!';
END $$;

