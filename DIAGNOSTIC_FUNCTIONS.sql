-- ============================================================
-- DIAGNOSTIC: List all send_challenge_message function overloads
-- ============================================================
-- Run this BEFORE running FIX_CHAT_AND_STEPS.sql to see what exists
-- ============================================================

SELECT 
    n.nspname AS schema,
    p.proname AS function_name,
    pg_get_function_identity_arguments(p.oid) AS arguments,
    pg_get_function_result(p.oid) AS return_type,
    p.oid::regprocedure AS full_signature
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'send_challenge_message'
ORDER BY arguments;

-- ============================================================
-- Expected output AFTER running FIX_CHAT_AND_STEPS.sql:
-- Should show only ONE function:
--   schema | function_name           | arguments      | return_type | full_signature
--   public | send_challenge_message  | uuid, text     | uuid        | public.send_challenge_message(uuid,text)
-- ============================================================

