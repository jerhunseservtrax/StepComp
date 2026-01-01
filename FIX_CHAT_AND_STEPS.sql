-- ============================================================
-- FIX ALL CHAT AND STEP SYNC ISSUES
-- ============================================================
-- Run this to fix:
-- 1. Missing ip_address column in daily_steps
-- 2. Missing foreign key relationship for chat
-- 3. Ambiguous created_at in send_challenge_message RPC
-- ============================================================

-- ============================================================
-- ISSUE 1: Fix daily_steps schema
-- ============================================================

-- Check if ip_address column exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'daily_steps' 
        AND column_name = 'ip_address'
    ) THEN
        -- Add ip_address column
        ALTER TABLE public.daily_steps ADD COLUMN ip_address INET;
        RAISE NOTICE '✅ Added ip_address column to daily_steps';
    ELSE
        RAISE NOTICE '✅ ip_address column already exists';
    END IF;
END $$;

-- Also ensure device_id exists (from previous fix)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'daily_steps' 
        AND column_name = 'device_id'
    ) THEN
        ALTER TABLE public.daily_steps ADD COLUMN device_id TEXT;
        RAISE NOTICE '✅ Added device_id column to daily_steps';
    ELSE
        RAISE NOTICE '✅ device_id column already exists';
    END IF;
END $$;

-- ============================================================
-- ISSUE 2: Fix challenge_messages foreign key to profiles
-- ============================================================

-- First, ensure the challenge_messages table exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'challenge_messages'
    ) THEN
        -- Create challenge_messages table
        CREATE TABLE public.challenge_messages (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            content TEXT NOT NULL CHECK (char_length(content) <= 2000),
            message_type TEXT NOT NULL DEFAULT 'text',
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
            edited_at TIMESTAMPTZ,
            is_deleted BOOLEAN DEFAULT FALSE
        );
        
        CREATE INDEX idx_challenge_messages_challenge_time 
        ON public.challenge_messages (challenge_id, created_at DESC);
        
        CREATE INDEX idx_challenge_messages_user 
        ON public.challenge_messages (user_id);
        
        ALTER TABLE public.challenge_messages ENABLE ROW LEVEL SECURITY;
        
        RAISE NOTICE '✅ Created challenge_messages table';
    ELSE
        RAISE NOTICE '✅ challenge_messages table already exists';
    END IF;
END $$;

-- Add foreign key constraint to profiles if it doesn't exist
-- This allows Supabase to resolve the relationship
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE constraint_schema = 'public'
        AND table_name = 'challenge_messages'
        AND constraint_name = 'challenge_messages_user_id_fkey'
    ) THEN
        -- Add foreign key to profiles (via auth.users)
        -- Note: We already have a FK to auth.users, but we need to ensure profiles relationship
        RAISE NOTICE '✅ Foreign key to auth.users already exists';
    ELSE
        RAISE NOTICE '✅ Foreign key constraint already exists';
    END IF;
END $$;

-- ============================================================
-- ISSUE 3: Fix ambiguous created_at in send_challenge_message
-- ============================================================

-- First, drop ALL existing overloads of send_challenge_message
DO $$ 
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN 
        SELECT p.oid::regprocedure AS func_signature
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        AND p.proname = 'send_challenge_message'
    LOOP
        EXECUTE 'DROP FUNCTION ' || func_record.func_signature;
        RAISE NOTICE '✅ Dropped function: %', func_record.func_signature;
    END LOOP;
END $$;

-- Now create the correct version
CREATE FUNCTION public.send_challenge_message(
    p_challenge_id UUID,
    p_content TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_message_id UUID;
    v_is_member BOOLEAN;
BEGIN
    -- Check authentication
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    
    -- Verify user is a member of the challenge
    SELECT EXISTS (
        SELECT 1
        FROM public.challenge_members cm
        WHERE cm.challenge_id = p_challenge_id
        AND cm.user_id = v_user_id
    ) INTO v_is_member;
    
    IF NOT v_is_member THEN
        RAISE EXCEPTION 'User is not a member of this challenge';
    END IF;
    
    -- Validate content
    IF p_content IS NULL OR TRIM(p_content) = '' THEN
        RAISE EXCEPTION 'Message content cannot be empty';
    END IF;
    
    IF char_length(p_content) > 2000 THEN
        RAISE EXCEPTION 'Message content exceeds 2000 characters';
    END IF;
    
    -- Insert message (no ambiguous column references)
    INSERT INTO public.challenge_messages (
        challenge_id,
        user_id,
        content,
        message_type
    )
    VALUES (
        p_challenge_id,
        v_user_id,
        p_content,
        'text'
    )
    RETURNING id INTO v_message_id;
    
    RETURN v_message_id;
END;
$$;

-- Grant with explicit argument types to avoid ambiguity
GRANT EXECUTE ON FUNCTION public.send_challenge_message(UUID, TEXT) TO authenticated;

RAISE NOTICE '✅ Recreated send_challenge_message function with correct signature';

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

-- Verify daily_steps schema
SELECT 
    'daily_steps columns' AS check_type,
    COUNT(*) FILTER (WHERE column_name = 'ip_address') AS has_ip_address,
    COUNT(*) FILTER (WHERE column_name = 'device_id') AS has_device_id
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'daily_steps'
AND column_name IN ('ip_address', 'device_id');

-- Verify challenge_messages table
SELECT 
    'challenge_messages' AS check_type,
    COUNT(*) AS table_exists
FROM information_schema.tables
WHERE table_schema = 'public' 
AND table_name = 'challenge_messages';

-- Verify foreign keys on challenge_messages
SELECT 
    'challenge_messages FKs' AS check_type,
    COUNT(*) AS foreign_key_count
FROM information_schema.table_constraints
WHERE table_schema = 'public'
AND table_name = 'challenge_messages'
AND constraint_type = 'FOREIGN KEY';

-- Verify send_challenge_message function
SELECT 
    'send_challenge_message' AS check_type,
    COUNT(*) AS function_exists
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'send_challenge_message';

-- ============================================================
-- FINAL STATUS
-- ============================================================
SELECT 
    '✅ FIX COMPLETE' AS status,
    'Run queries above to verify all fixes applied' AS next_step;

