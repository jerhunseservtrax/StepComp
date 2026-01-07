-- ============================================
-- STEPCOMP WAITLIST DATABASE SETUP
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Create waitlist table
CREATE TABLE IF NOT EXISTS public.waitlist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    referral_source TEXT,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_waitlist_email ON public.waitlist(email);

-- 3. Create index on created_at for sorting
CREATE INDEX IF NOT EXISTS idx_waitlist_created_at ON public.waitlist(created_at DESC);

-- 4. Enable Row Level Security
ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;

-- 5. Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can join waitlist" ON public.waitlist;
DROP POLICY IF EXISTS "No one can read waitlist" ON public.waitlist;

-- 6. Allow public to insert (join waitlist)
CREATE POLICY "Anyone can join waitlist"
ON public.waitlist
FOR INSERT
TO public
WITH CHECK (true);

-- 7. Prevent public from reading the waitlist
-- (Only authenticated users with proper permissions can read)
CREATE POLICY "No one can read waitlist"
ON public.waitlist
FOR SELECT
TO public
USING (false);

-- 8. Create function to get waitlist count
CREATE OR REPLACE FUNCTION get_waitlist_count()
RETURNS INTEGER
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT COUNT(*)::INTEGER FROM public.waitlist;
$$;

-- 9. Grant execute permission to anon users
GRANT EXECUTE ON FUNCTION get_waitlist_count() TO anon;
GRANT EXECUTE ON FUNCTION get_waitlist_count() TO authenticated;

-- 10. Create function to get recent signups (admin only)
CREATE OR REPLACE FUNCTION get_recent_waitlist_signups(limit_count INTEGER DEFAULT 10)
RETURNS TABLE (
    id UUID,
    email TEXT,
    referral_source TEXT,
    created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT 
    id,
    email,
    referral_source,
    created_at
  FROM public.waitlist
  ORDER BY created_at DESC
  LIMIT limit_count;
$$;

-- 11. Grant execute permission only to authenticated users
GRANT EXECUTE ON FUNCTION get_recent_waitlist_signups(INTEGER) TO authenticated;

-- 12. Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_waitlist_updated_at ON public.waitlist;

CREATE TRIGGER update_waitlist_updated_at
    BEFORE UPDATE ON public.waitlist
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check if table was created
DO $$ 
BEGIN 
    RAISE NOTICE '✅ Checking waitlist table...';
END $$;

SELECT 
    'waitlist' AS table_name,
    COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'waitlist';

-- Check if RLS is enabled
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'waitlist';

-- Check if policies exist
SELECT 
    policyname,
    cmd AS command,
    roles
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'waitlist';

-- Check if functions exist
SELECT 
    routine_name AS function_name,
    routine_type AS type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('get_waitlist_count', 'get_recent_waitlist_signups');

-- ============================================
-- TEST QUERIES (Optional)
-- ============================================

-- Test: Get current waitlist count
SELECT get_waitlist_count() AS total_signups;

-- Test: Insert a test email (run this to test the setup)
-- INSERT INTO public.waitlist (email, referral_source, user_agent)
-- VALUES ('test@example.com', 'test', 'Test User Agent')
-- ON CONFLICT (email) DO NOTHING;

-- Test: Get recent signups (admin only)
-- SELECT * FROM get_recent_waitlist_signups(5);

-- ============================================
-- CLEANUP QUERIES (Run if you need to reset)
-- ============================================

-- Drop everything (use with caution!)
-- DROP TABLE IF EXISTS public.waitlist CASCADE;
-- DROP FUNCTION IF EXISTS get_waitlist_count() CASCADE;
-- DROP FUNCTION IF EXISTS get_recent_waitlist_signups(INTEGER) CASCADE;
-- DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- ============================================
-- SUCCESS!
-- ============================================

DO $$ 
BEGIN 
    RAISE NOTICE '✅ Waitlist database setup complete!';
    RAISE NOTICE '📊 Test your setup by running: SELECT get_waitlist_count();';
    RAISE NOTICE '🌐 Now update your waitlist.html with Supabase credentials';
    RAISE NOTICE '🚀 Then deploy to Netlify!';
END $$;

