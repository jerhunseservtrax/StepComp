-- ============================================
-- CREATE 5 TEST ACCOUNTS FOR FRIENDS FEATURE
-- ============================================
-- This script creates 5 test accounts that can be used to test the add friend feature
-- 
-- IMPORTANT: You cannot create auth users directly via SQL in Supabase.
-- You need to create them via the Supabase Dashboard or Admin API first,
-- then run this script to create their profiles.
--
-- Steps:
-- 1. Create users in Supabase Dashboard: Authentication > Users > Add User
-- 2. Copy the user IDs from the dashboard
-- 3. Update the user_id values in this script
-- 4. Run this script in the Supabase SQL Editor
--
-- OR use the Python script: CREATE_TEST_ACCOUNTS.py (recommended)

-- Test Account 1: Sarah Chen
-- Email: sarah.test@stepcomp.app
-- Password: TestPassword123!
-- NOTE: Replace the UUID with actual user_id from auth.users after creating the auth user
INSERT INTO profiles (id, username, email, first_name, last_name, avatar, is_premium, height, weight)
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
ON CONFLICT (user_id) DO UPDATE SET
  username = EXCLUDED.username,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  avatar = EXCLUDED.avatar;

-- Test Account 2: Mike Johnson
-- Email: mike.test@stepcomp.app
-- Password: TestPassword123!
INSERT INTO profiles (user_id, username, first_name, last_name, avatar, is_premium, height, weight)
VALUES (
  '00000000-0000-0000-0000-000000000002'::uuid, -- Replace with actual user_id from auth.users
  'mikejohnson',
  'Mike',
  'Johnson',
  'https://i.pravatar.cc/150?img=5',
  false,
  180, -- 180 cm
  75   -- 75 kg
)
ON CONFLICT (user_id) DO UPDATE SET
  username = EXCLUDED.username,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  avatar = EXCLUDED.avatar;

-- Test Account 3: Emma Wilson
-- Email: emma.test@stepcomp.app
-- Password: TestPassword123!
INSERT INTO profiles (user_id, username, first_name, last_name, avatar, is_premium, height, weight)
VALUES (
  '00000000-0000-0000-0000-000000000003'::uuid, -- Replace with actual user_id from auth.users
  'emmawilson',
  'Emma',
  'Wilson',
  'https://i.pravatar.cc/150?img=9',
  false,
  170, -- 170 cm
  65   -- 65 kg
)
ON CONFLICT (user_id) DO UPDATE SET
  username = EXCLUDED.username,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  avatar = EXCLUDED.avatar;

-- Test Account 4: Alex Rivera
-- Email: alex.test@stepcomp.app
-- Password: TestPassword123!
INSERT INTO profiles (user_id, username, first_name, last_name, avatar, is_premium, height, weight)
VALUES (
  '00000000-0000-0000-0000-000000000004'::uuid, -- Replace with actual user_id from auth.users
  'alexrivera',
  'Alex',
  'Rivera',
  'https://i.pravatar.cc/150?img=12',
  false,
  175, -- 175 cm
  70   -- 70 kg
)
ON CONFLICT (user_id) DO UPDATE SET
  username = EXCLUDED.username,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  avatar = EXCLUDED.avatar;

-- Test Account 5: Jordan Taylor
-- Email: jordan.test@stepcomp.app
-- Password: TestPassword123!
INSERT INTO profiles (user_id, username, first_name, last_name, avatar, is_premium, height, weight)
VALUES (
  '00000000-0000-0000-0000-000000000005'::uuid, -- Replace with actual user_id from auth.users
  'jordantaylor',
  'Jordan',
  'Taylor',
  'https://i.pravatar.cc/150?img=15',
  false,
  172, -- 172 cm
  68   -- 68 kg
)
ON CONFLICT (user_id) DO UPDATE SET
  username = EXCLUDED.username,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  avatar = EXCLUDED.avatar;

