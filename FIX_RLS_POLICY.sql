-- ============================================
-- FIX RLS POLICY: Allow anon users to INSERT
-- Run this in Supabase SQL Editor
-- ============================================

-- Drop the existing policy
DROP POLICY IF EXISTS "Anyone can join waitlist" ON public.waitlist;

-- Create new policy specifically for anon and authenticated users
CREATE POLICY "Anyone can join waitlist"
ON public.waitlist
FOR INSERT
TO anon, authenticated  -- Explicitly allow both anon and authenticated
WITH CHECK (true);      -- No conditions - always allow

-- Verify the policy was created
SELECT 
    policyname,
    cmd,
    roles,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'waitlist';

-- Success message
DO $$ 
BEGIN 
    RAISE NOTICE '✅ RLS policy fixed for anon users!';
    RAISE NOTICE '🔄 Refresh your waitlist page and try again!';
    RAISE NOTICE '📧 Email submissions should work now!';
END $$;

