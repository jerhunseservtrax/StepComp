-- =====================================================
-- ADD CHALLENGE CATEGORIES SYSTEM
-- =====================================================
-- This migration adds a category/tagging system for public challenges
-- Categories: short_term, friends, corporate, marathon, fun
--
-- Run this in Supabase SQL Editor
-- =====================================================

-- Step 1: Add category column to challenges table
ALTER TABLE public.challenges
ADD COLUMN IF NOT EXISTS category TEXT CHECK (category IN ('short_term', 'friends', 'corporate', 'marathon', 'fun'));

-- Step 2: Add comment to explain the field
COMMENT ON COLUMN public.challenges.category IS 'Challenge category for public challenges only. Options: short_term, friends, corporate, marathon, fun';

-- Step 3: Create index for better query performance on public challenges by category
CREATE INDEX IF NOT EXISTS idx_challenges_public_category 
ON public.challenges (category, is_public) 
WHERE is_public = TRUE;

-- Step 4: Create a function to get public challenges by category
CREATE OR REPLACE FUNCTION public.get_public_challenges_by_category(
    p_category TEXT DEFAULT NULL,
    p_limit INT DEFAULT 50,
    p_offset INT DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    description TEXT,
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    created_by UUID,
    is_public BOOLEAN,
    category TEXT,
    invite_code TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    creator_username TEXT,
    creator_display_name TEXT,
    creator_avatar_url TEXT,
    member_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.description,
        c.start_date,
        c.end_date,
        c.created_by,
        c.is_public,
        c.category,
        c.invite_code,
        c.created_at,
        c.updated_at,
        p.username AS creator_username,
        p.display_name AS creator_display_name,
        p.avatar_url AS creator_avatar_url,
        COUNT(DISTINCT cm.user_id) AS member_count
    FROM public.challenges c
    LEFT JOIN public.profiles p ON c.created_by = p.id
    LEFT JOIN public.challenge_members cm ON c.id = cm.challenge_id
    WHERE c.is_public = TRUE
        AND (p_category IS NULL OR c.category = p_category)
        AND c.end_date > NOW() -- Only show active/upcoming challenges
    GROUP BY c.id, p.username, p.display_name, p.avatar_url
    ORDER BY c.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_public_challenges_by_category TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_public_challenges_by_category TO anon;

-- Step 5: Create a function to get challenge statistics by category
CREATE OR REPLACE FUNCTION public.get_challenge_category_stats()
RETURNS TABLE (
    category TEXT,
    challenge_count BIGINT,
    total_members BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.category,
        COUNT(DISTINCT c.id) AS challenge_count,
        COUNT(DISTINCT cm.user_id) AS total_members
    FROM public.challenges c
    LEFT JOIN public.challenge_members cm ON c.id = cm.challenge_id
    WHERE c.is_public = TRUE
        AND c.category IS NOT NULL
        AND c.end_date > NOW()
    GROUP BY c.category
    ORDER BY challenge_count DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_challenge_category_stats TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_challenge_category_stats TO anon;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Verify the column was added
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'challenges' 
AND column_name = 'category';

-- Verify the index was created
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'challenges' 
AND indexname = 'idx_challenges_public_category';

-- Verify the functions were created
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_public_challenges_by_category', 'get_challenge_category_stats');

-- Test the function (should return empty result initially)
SELECT * FROM public.get_public_challenges_by_category(NULL, 10, 0);

-- Show all public challenges with categories
SELECT 
    id, 
    name, 
    category, 
    is_public, 
    created_at 
FROM public.challenges 
WHERE is_public = TRUE 
ORDER BY created_at DESC 
LIMIT 10;

RAISE NOTICE '✅ Challenge categories system successfully installed!';
RAISE NOTICE 'Categories available: short_term, friends, corporate, marathon, fun';
RAISE NOTICE 'Use get_public_challenges_by_category() to query public challenges by category';

