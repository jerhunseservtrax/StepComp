-- ============================================
-- CREATE 5 TEST ACCOUNTS FOR FRIENDS FEATURE
-- ============================================
-- This script creates 5 test accounts that can be used to test the add friend feature
-- 
-- IMPORTANT: You cannot create auth users directly via SQL in Supabase.
-- You need to create them via the Supabase Dashboard or Admin API first,
-- then run this script to create their profiles.
--
-- ============================================
-- STEP 1: CREATE AUTH USERS IN SUPABASE DASHBOARD
-- ============================================
-- Go to: Authentication > Users > Add User
-- Create these 5 users with the following credentials:
--
-- 1. Email: sarah.test@fitcomp.app
-- 2. Email: mike.test@fitcomp.app
-- 3. Email: emma.test@fitcomp.app
-- 4. Email: alex.test@fitcomp.app
-- 5. Email: jordan.test@fitcomp.app
--
-- ============================================
-- STEP 2: GET THE USER IDs
-- ============================================
-- After creating the users, run this query to get their IDs:
-- 
-- SELECT id, email FROM auth.users WHERE email IN (
--   'sarah.test@fitcomp.app',
--   'mike.test@fitcomp.app',
--   'emma.test@fitcomp.app',
--   'alex.test@fitcomp.app',
--   'jordan.test@fitcomp.app'
-- ) ORDER BY email;
--
-- Copy the IDs and replace the placeholder UUIDs below.
--
-- ============================================
-- STEP 3: UPDATE THE UUIDs BELOW AND RUN THIS SCRIPT
-- ============================================
--
-- OR use the Python script: CREATE_TEST_ACCOUNTS.py (recommended)
-- The Python script creates auth users AND profiles automatically.
--
-- NOTE: If you get an error about the 'email' column not existing, run this first:
-- ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email TEXT;

-- Test Account 1: Sarah Chen
-- Email: sarah.test@fitcomp.app
-- Password: TestPassword123!
-- NOTE: Replace the UUID with actual id from auth.users after creating the auth user
INSERT INTO profiles (id, username, first_name, last_name, avatar, is_premium, height, weight)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid, -- Replace with actual id from auth.users
  'sarahchen',
  'Sarah',
  'Chen',
  'https://i.pravatar.cc/150?img=1',
  false,
  165, -- 165 cm
  60   -- 60 kg
)
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  avatar = EXCLUDED.avatar,
  height = EXCLUDED.height,
  weight = EXCLUDED.weight;

-- Test Account 2: Mike Johnson
-- Email: mike.test@fitcomp.app
-- Password: TestPassword123!
INSERT INTO profiles (id, username, first_name, last_name, avatar, is_premium, height, weight)
VALUES (
  '00000000-0000-0000-0000-000000000002'::uuid, -- Replace with actual id from auth.users
  'mikejohnson',
  'Mike',
  'Johnson',
  'https://i.pravatar.cc/150?img=5',
  false,
  180, -- 180 cm
  75   -- 75 kg
)
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  avatar = EXCLUDED.avatar,
  height = EXCLUDED.height,
  weight = EXCLUDED.weight;

-- Test Account 3: Emma Wilson
-- Email: emma.test@fitcomp.app
-- Password: TestPassword123!
INSERT INTO profiles (id, username, first_name, last_name, avatar, is_premium, height, weight)
VALUES (
  '00000000-0000-0000-0000-000000000003'::uuid, -- Replace with actual id from auth.users
  'emmawilson',
  'Emma',
  'Wilson',
  'https://i.pravatar.cc/150?img=9',
  false,
  170, -- 170 cm
  65   -- 65 kg
)
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  avatar = EXCLUDED.avatar,
  height = EXCLUDED.height,
  weight = EXCLUDED.weight;

-- Test Account 4: Alex Rivera
-- Email: alex.test@fitcomp.app
-- Password: TestPassword123!
INSERT INTO profiles (id, username, first_name, last_name, avatar, is_premium, height, weight)
VALUES (
  '00000000-0000-0000-0000-000000000004'::uuid, -- Replace with actual id from auth.users
  'alexrivera',
  'Alex',
  'Rivera',
  'https://i.pravatar.cc/150?img=12',
  false,
  175, -- 175 cm
  70   -- 70 kg
)
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  avatar = EXCLUDED.avatar,
  height = EXCLUDED.height,
  weight = EXCLUDED.weight;

-- Test Account 5: Jordan Taylor
-- Email: jordan.test@fitcomp.app
-- Password: TestPassword123!
INSERT INTO profiles (id, username, first_name, last_name, avatar, is_premium, height, weight)
VALUES (
  '00000000-0000-0000-0000-000000000005'::uuid, -- Replace with actual id from auth.users
  'jordantaylor',
  'Jordan',
  'Taylor',
  'https://i.pravatar.cc/150?img=15',
  false,
  172, -- 172 cm
  68   -- 68 kg
)
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  avatar = EXCLUDED.avatar,
  height = EXCLUDED.height,
  weight = EXCLUDED.weight;

