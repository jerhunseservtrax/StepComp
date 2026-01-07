-- ========================================
-- FIX: Allow users to discover public challenges
-- ========================================
-- 
-- PROBLEM: Users can only see challenges they created or joined
-- SOLUTION: Allow all authenticated users to see public challenges
--
-- This enables the Discover tab to show public challenges from other users

-- Drop the existing SELECT policy
DROP POLICY IF EXISTS "Users can read own challenges" ON public.challenges;
DROP POLICY IF EXISTS "Users can read challenges" ON public.challenges;
DROP POLICY IF EXISTS "Users can view challenges" ON public.challenges;

-- Create new policy that allows:
-- 1. Anyone to see PUBLIC challenges
-- 2. Users to see their own challenges (created_by)
-- 3. Users to see challenges they're participating in
CREATE POLICY "Users can read public challenges or own challenges"
ON public.challenges
FOR SELECT
USING (
    is_public = true  -- ✅ Anyone can see public challenges (for Discover tab)
    OR 
    created_by = auth.uid()  -- ✅ Can see challenges you created
    OR 
    id IN (
        SELECT challenge_id 
        FROM public.challenge_members 
        WHERE user_id = auth.uid()
    )  -- ✅ Can see challenges you joined
);

-- Verify the policy was created
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'challenges'
  AND cmd = 'SELECT';

-- Test query: Should return ALL public challenges
SELECT 
    id,
    name,
    is_public,
    created_by,
    end_date
FROM public.challenges
WHERE is_public = true
  AND end_date >= NOW()
ORDER BY created_at DESC;

