-- ============================================
-- QUICK FIX: Grant INSERT Permission to Anon
-- Run this NOW in Supabase SQL Editor
-- ============================================

-- Grant INSERT to anon role
GRANT INSERT ON public.waitlist TO anon;

-- Grant sequence usage for UUID generation
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon;

-- Verify it worked
SELECT 
    grantee, 
    privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
AND table_name = 'waitlist'
AND grantee = 'anon';

-- Success message
DO $$ 
BEGIN 
    RAISE NOTICE '✅ INSERT permission granted to anon role!';
    RAISE NOTICE '🔄 Refresh your waitlist page and try again!';
END $$;

