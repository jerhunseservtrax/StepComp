-- ========================================
-- COMPLETE FIX: Add Creators to Challenge Members + Fix RLS
-- Run this ENTIRE script in Supabase SQL Editor
-- ========================================

-- PART 1: Add creators to all orphaned challenges
-- This fixes existing challenges that don't show up in the app
-- ========================================

INSERT INTO challenge_members (id, challenge_id, user_id, total_steps, joined_at, last_updated)
SELECT 
    gen_random_uuid(),
    c.id,
    c.created_by,
    0,
    c.created_at,
    NOW()
FROM challenges c
LEFT JOIN challenge_members cm ON cm.challenge_id = c.id AND cm.user_id = c.created_by
WHERE cm.id IS NULL  -- Only add if creator is NOT already a member
  AND c.end_date >= NOW();  -- Only for active challenges

-- PART 2: Fix RLS policies to prevent future issues
-- ========================================

-- Drop existing policies that have infinite recursion
DROP POLICY IF EXISTS "Users can read own challenges or joined challenges" ON challenges;
DROP POLICY IF EXISTS "Challenge creator can insert challenges" ON challenges;
DROP POLICY IF EXISTS "Challenge creator can update" ON challenges;
DROP POLICY IF EXISTS "Challenge creator can delete" ON challenges;

DROP POLICY IF EXISTS "Users can insert own challenge members" ON challenge_members;
DROP POLICY IF EXISTS "Users can read members of their challenges" ON challenge_members;
DROP POLICY IF EXISTS "Users can update own member stats" ON challenge_members;
DROP POLICY IF EXISTS "Users can delete own membership" ON challenge_members;

-- Recreate challenges policies (NON-RECURSIVE)
CREATE POLICY "Users can read own challenges or joined challenges"
ON challenges FOR SELECT
USING (
    auth.uid() = created_by 
    OR 
    id IN (
        SELECT challenge_id 
        FROM challenge_members 
        WHERE user_id = auth.uid()
    )
);

CREATE POLICY "Challenge creator can insert challenges"
ON challenges FOR INSERT
WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Challenge creator can update"
ON challenges FOR UPDATE
USING (auth.uid() = created_by)
WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Challenge creator can delete"
ON challenges FOR DELETE
USING (auth.uid() = created_by);

-- Recreate challenge_members policies (NON-RECURSIVE)
CREATE POLICY "Users can insert own challenge members"
ON challenge_members FOR INSERT
WITH CHECK (
    user_id = auth.uid()
    OR
    challenge_id IN (
        SELECT id FROM challenges WHERE created_by = auth.uid()
    )
);

CREATE POLICY "Users can read members of their challenges"
ON challenge_members FOR SELECT
USING (
    user_id = auth.uid()
    OR
    challenge_id IN (
        SELECT id FROM challenges WHERE created_by = auth.uid()
    )
);

CREATE POLICY "Users can update own member stats"
ON challenge_members FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own membership"
ON challenge_members FOR DELETE
USING (
    user_id = auth.uid()
    OR
    challenge_id IN (
        SELECT id FROM challenges WHERE created_by = auth.uid()
    )
);

-- PART 3: Verification
-- ========================================

-- Show summary of fixes
SELECT 
    'Challenges with members' as status,
    COUNT(DISTINCT c.id) as challenge_count,
    COUNT(cm.id) as total_members
FROM challenges c
LEFT JOIN challenge_members cm ON cm.challenge_id = c.id
WHERE c.end_date >= NOW()
GROUP BY 1

UNION ALL

SELECT 
    'Orphaned challenges (should be 0)' as status,
    COUNT(c.id) as challenge_count,
    0 as total_members
FROM challenges c
LEFT JOIN challenge_members cm ON cm.challenge_id = c.id AND cm.user_id = c.created_by
WHERE cm.id IS NULL
  AND c.end_date >= NOW()
GROUP BY 1

UNION ALL

SELECT 
    'RLS policies created' as status,
    COUNT(*) as challenge_count,
    0 as total_members
FROM pg_policies
WHERE tablename IN ('challenges', 'challenge_members')
GROUP BY 1;

-- ========================================
-- EXPECTED RESULTS:
-- ========================================
-- Row 1: "Challenges with members" - should show your active challenges
-- Row 2: "Orphaned challenges" - should be 0
-- Row 3: "RLS policies created" - should be 8 (4 for challenges, 4 for challenge_members)
--
-- If you see these results, the fix was successful! ✅
-- Now rebuild your app and check the Active tab and home page.
-- ========================================

