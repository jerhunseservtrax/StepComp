-- ========================================
-- COMPLETE RLS RESET - FORCE DROP ALL POLICIES
-- This script will remove ALL policies and recreate only the correct ones
-- ========================================

-- STEP 1: DROP ALL POLICIES (not just specific ones)
DO $$ 
DECLARE
    r RECORD;
BEGIN
    -- Drop all policies on challenges table
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'challenges') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON challenges';
    END LOOP;
    
    -- Drop all policies on challenge_members table
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'challenge_members') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON challenge_members';
    END LOOP;
END $$;

-- STEP 2: Verify all policies are gone
-- You should see 0 rows for both tables
SELECT tablename, COUNT(*) as policy_count
FROM pg_policies
WHERE tablename IN ('challenges', 'challenge_members')
GROUP BY tablename;

-- STEP 3: Recreate ONLY the correct policies (NON-RECURSIVE)

-- Challenges table policies
CREATE POLICY "challenges_select_policy"
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

CREATE POLICY "challenges_insert_policy"
ON challenges FOR INSERT
WITH CHECK (auth.uid() = created_by);

CREATE POLICY "challenges_update_policy"
ON challenges FOR UPDATE
USING (auth.uid() = created_by)
WITH CHECK (auth.uid() = created_by);

CREATE POLICY "challenges_delete_policy"
ON challenges FOR DELETE
USING (auth.uid() = created_by);

-- Challenge_members table policies  
CREATE POLICY "challenge_members_select_policy"
ON challenge_members FOR SELECT
USING (
    user_id = auth.uid()
    OR
    challenge_id IN (
        SELECT id FROM challenges WHERE created_by = auth.uid()
    )
);

CREATE POLICY "challenge_members_insert_policy"
ON challenge_members FOR INSERT
WITH CHECK (
    user_id = auth.uid()
    OR
    challenge_id IN (
        SELECT id FROM challenges WHERE created_by = auth.uid()
    )
);

CREATE POLICY "challenge_members_update_policy"
ON challenge_members FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "challenge_members_delete_policy"
ON challenge_members FOR DELETE
USING (
    user_id = auth.uid()
    OR
    challenge_id IN (
        SELECT id FROM challenges WHERE created_by = auth.uid()
    )
);

-- STEP 4: Verify exactly 8 policies exist
SELECT tablename, COUNT(*) as policy_count
FROM pg_policies
WHERE tablename IN ('challenges', 'challenge_members')
GROUP BY tablename;

-- Expected result:
-- challenges: 4 policies
-- challenge_members: 4 policies
-- Total: 8 policies

-- STEP 5: Add missing creators to challenge_members (if any)
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
WHERE cm.id IS NULL
  AND c.end_date >= NOW();

-- STEP 6: Final verification
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
    'Orphaned challenges (MUST be 0)' as status,
    COUNT(c.id) as challenge_count,
    0 as total_members
FROM challenges c
LEFT JOIN challenge_members cm ON cm.challenge_id = c.id AND cm.user_id = c.created_by
WHERE cm.id IS NULL
  AND c.end_date >= NOW()
GROUP BY 1

UNION ALL

SELECT 
    'Total RLS policies (MUST be 8)' as status,
    COUNT(*) as challenge_count,
    0 as total_members
FROM pg_policies
WHERE tablename IN ('challenges', 'challenge_members')
GROUP BY 1;

-- ========================================
-- EXPECTED FINAL RESULTS:
-- ========================================
-- Row 1: "Challenges with members" - should show your challenges (46+)
-- Row 2: "Orphaned challenges" - MUST be 0
-- Row 3: "Total RLS policies" - MUST be exactly 8
--
-- If you see different numbers, report back immediately.
-- ========================================

