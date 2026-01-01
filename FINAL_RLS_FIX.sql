-- ========================================
-- FINAL FIX: Non-Circular RLS Policies
-- This removes the circular dependency completely
-- ========================================

-- STEP 1: Drop ALL existing policies
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'challenges') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON challenges';
    END LOOP;
    
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'challenge_members') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON challenge_members';
    END LOOP;
END $$;

-- STEP 2: Create NON-CIRCULAR policies

-- ===========================================
-- CHALLENGES TABLE POLICIES
-- ===========================================
-- These policies CAN reference challenge_members (one-way only)

CREATE POLICY "challenges_select"
ON challenges FOR SELECT
USING (
    -- User is the creator
    auth.uid() = created_by 
    OR 
    -- User is a member (one-way reference is OK)
    id IN (
        SELECT challenge_id 
        FROM challenge_members 
        WHERE user_id = auth.uid()
    )
);

CREATE POLICY "challenges_insert"
ON challenges FOR INSERT
WITH CHECK (auth.uid() = created_by);

CREATE POLICY "challenges_update"
ON challenges FOR UPDATE
USING (auth.uid() = created_by)
WITH CHECK (auth.uid() = created_by);

CREATE POLICY "challenges_delete"
ON challenges FOR DELETE
USING (auth.uid() = created_by);

-- ===========================================
-- CHALLENGE_MEMBERS TABLE POLICIES
-- ===========================================
-- These policies MUST NOT reference challenges table (break the circle!)

CREATE POLICY "challenge_members_select"
ON challenge_members FOR SELECT
USING (
    -- User can see their own membership
    user_id = auth.uid()
    -- DO NOT add: OR challenge created by user
    -- This would create recursion!
);

CREATE POLICY "challenge_members_insert"
ON challenge_members FOR INSERT
WITH CHECK (
    -- User can add themselves to any challenge
    -- OR creator can add anyone (checked via challenge.created_by in app logic)
    user_id = auth.uid()
);

CREATE POLICY "challenge_members_update"
ON challenge_members FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "challenge_members_delete"
ON challenge_members FOR DELETE
USING (user_id = auth.uid());

-- STEP 3: Add function to allow creators to manage members
-- This allows the app to add creator as member during challenge creation

CREATE OR REPLACE FUNCTION can_manage_challenge_members(challenge_uuid uuid)
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM challenges 
        WHERE id = challenge_uuid 
        AND created_by = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update INSERT policy to allow creator to add members
DROP POLICY IF EXISTS "challenge_members_insert" ON challenge_members;

CREATE POLICY "challenge_members_insert"
ON challenge_members FOR INSERT
WITH CHECK (
    -- User adding themselves
    user_id = auth.uid()
    OR
    -- OR user is the challenge creator (can add anyone)
    can_manage_challenge_members(challenge_id)
);

-- STEP 4: Add missing creators
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

-- STEP 5: Verification
SELECT 
    'Policy Count (MUST be 8)' as check_name,
    COUNT(*)::text as result
FROM pg_policies
WHERE tablename IN ('challenges', 'challenge_members')

UNION ALL

SELECT 
    'Challenges Table Policies' as check_name,
    COUNT(*)::text as result
FROM pg_policies
WHERE tablename = 'challenges'

UNION ALL

SELECT 
    'Challenge Members Policies' as check_name,
    COUNT(*)::text as result
FROM pg_policies
WHERE tablename = 'challenge_members'

UNION ALL

SELECT 
    'Orphaned Challenges (MUST be 0)' as check_name,
    COUNT(*)::text as result
FROM challenges c
LEFT JOIN challenge_members cm ON cm.challenge_id = c.id AND cm.user_id = c.created_by
WHERE cm.id IS NULL
  AND c.end_date >= NOW()

UNION ALL

SELECT 
    'Active Challenges with Members' as check_name,
    COUNT(DISTINCT c.id)::text as result
FROM challenges c
INNER JOIN challenge_members cm ON cm.challenge_id = c.id
WHERE c.end_date >= NOW();

-- Expected Results:
-- Policy Count: 8
-- Challenges Table Policies: 4
-- Challenge Members Policies: 4
-- Orphaned Challenges: 0
-- Active Challenges: 47+

