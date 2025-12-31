-- ============================================
-- WAITLIST TABLE
-- ============================================
-- Stores email addresses of people interested in the app

CREATE TABLE IF NOT EXISTS public.waitlist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL UNIQUE,
    referral_source TEXT, -- How they found us (optional)
    ip_address INET, -- For spam prevention
    user_agent TEXT, -- Device info
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notified_at TIMESTAMPTZ, -- When we sent them the app link
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_waitlist_email ON public.waitlist(email);
CREATE INDEX IF NOT EXISTS idx_waitlist_created_at ON public.waitlist(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can insert (sign up for waitlist)
-- But cannot read other people's emails (privacy)
CREATE POLICY "Anyone can join waitlist"
ON public.waitlist FOR INSERT
WITH CHECK (true);

-- Policy: Only admins can read waitlist (service role only)
-- No public SELECT policy - keeps emails private
-- Access via Supabase Dashboard or service role only

-- Grant permissions
GRANT SELECT ON public.waitlist TO service_role;
GRANT INSERT ON public.waitlist TO anon, authenticated;

-- Function to get waitlist count (public, privacy-safe)
CREATE OR REPLACE FUNCTION public.get_waitlist_count()
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT COUNT(*) FROM public.waitlist);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.get_waitlist_count() TO anon, authenticated;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check table structure
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'waitlist'
-- ORDER BY ordinal_position;

-- Get current waitlist count
-- SELECT public.get_waitlist_count();

-- View all waitlist entries (service role only)
-- SELECT id, email, created_at, notified_at
-- FROM public.waitlist
-- ORDER BY created_at DESC;

