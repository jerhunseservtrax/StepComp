-- ============================================
-- GET TEST ACCOUNT USER IDs
-- ============================================
-- Run this AFTER creating the 5 test users in Supabase Dashboard
-- This will show you the user IDs to use in CREATE_TEST_ACCOUNTS.sql
-- ============================================

-- Get all test account user IDs
SELECT 
  id,
  email,
  created_at
FROM auth.users 
WHERE email IN (
  'sarah.test@stepcomp.app',
  'mike.test@stepcomp.app',
  'emma.test@stepcomp.app',
  'alex.test@stepcomp.app',
  'jordan.test@stepcomp.app'
)
ORDER BY email;

-- If you want to see which ones already have profiles:
SELECT 
  u.id,
  u.email,
  CASE WHEN p.id IS NOT NULL THEN '✅ Profile exists' ELSE '❌ No profile' END as profile_status
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id
WHERE u.email IN (
  'sarah.test@stepcomp.app',
  'mike.test@stepcomp.app',
  'emma.test@stepcomp.app',
  'alex.test@stepcomp.app',
  'jordan.test@stepcomp.app'
)
ORDER BY u.email;

