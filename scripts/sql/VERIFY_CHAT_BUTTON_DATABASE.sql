-- ========================================
-- Chat Button Feature - Database Verification
-- Run this to verify all required DB components exist
-- ========================================

-- 1️⃣ Verify challenge_messages table exists
SELECT 
    'challenge_messages table' as component,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'challenge_messages'
    ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as status;

-- 2️⃣ Verify challenge_message_reads table exists
SELECT 
    'challenge_message_reads table' as component,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'challenge_message_reads'
    ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as status;

-- 3️⃣ Verify challenge_members table exists
SELECT 
    'challenge_members table' as component,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'challenge_members'
    ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as status;

-- 4️⃣ Verify get_challenge_unread_count function exists
SELECT 
    'get_challenge_unread_count function' as component,
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'get_challenge_unread_count'
    ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as status;

-- 5️⃣ Verify RLS is enabled
SELECT 
    'RLS on challenge_messages' as component,
    CASE WHEN (
        SELECT relrowsecurity 
        FROM pg_class 
        WHERE relname = 'challenge_messages'
    ) THEN '✅ ENABLED' ELSE '❌ DISABLED' END as status;

SELECT 
    'RLS on challenge_message_reads' as component,
    CASE WHEN (
        SELECT relrowsecurity 
        FROM pg_class 
        WHERE relname = 'challenge_message_reads'
    ) THEN '✅ ENABLED' ELSE '❌ DISABLED' END as status;

-- 6️⃣ Verify indexes exist
SELECT 
    'idx_challenge_messages_challenge_time' as component,
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_challenge_messages_challenge_time'
    ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as status;

SELECT 
    'idx_message_reads_user' as component,
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE indexname = 'idx_message_reads_user'
    ) THEN '✅ EXISTS' ELSE '❌ MISSING' END as status;

-- 7️⃣ Test get_challenge_unread_count function
-- This will return 0 if you're not logged in or don't have messages
-- Replace 'challenge-uuid-here' with an actual challenge ID to test
DO $$
DECLARE
    v_result INTEGER;
BEGIN
    -- This is a simple test - it should execute without errors
    -- You can replace the UUID with a real challenge ID to test properly
    SELECT public.get_challenge_unread_count('00000000-0000-0000-0000-000000000000'::uuid) INTO v_result;
    RAISE NOTICE '✅ Function executes successfully. Result: %', v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Function test failed: %', SQLERRM;
END $$;

-- 8️⃣ Summary Report
SELECT 
    '=== CHAT BUTTON DATABASE REQUIREMENTS ===' as summary
UNION ALL
SELECT 
    CASE 
        WHEN (
            -- All tables exist
            EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'challenge_messages')
            AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'challenge_message_reads')
            AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'challenge_members')
            AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'challenges')
            -- Function exists
            AND EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_challenge_unread_count')
            -- RLS enabled
            AND (SELECT relrowsecurity FROM pg_class WHERE relname = 'challenge_messages')
            AND (SELECT relrowsecurity FROM pg_class WHERE relname = 'challenge_message_reads')
        )
        THEN '✅ ALL REQUIREMENTS MET - Chat button feature ready!'
        ELSE '❌ MISSING REQUIREMENTS - Run IMPLEMENT_CHALLENGE_CHAT.sql first'
    END as summary;

-- 9️⃣ Sample test query (uncomment and modify with real IDs to test)
/*
-- Test getting unread count for a real challenge
SELECT public.get_challenge_unread_count('your-challenge-uuid-here'::uuid) as unread_count;

-- Test getting last message for a challenge
SELECT id, content, created_at 
FROM public.challenge_messages
WHERE challenge_id = 'your-challenge-uuid-here'
  AND is_deleted = false
ORDER BY created_at DESC
LIMIT 1;

-- Test getting user's challenges
SELECT c.id, c.name
FROM public.challenges c
INNER JOIN public.challenge_members cm ON c.id = cm.challenge_id
WHERE cm.user_id = auth.uid();
*/

