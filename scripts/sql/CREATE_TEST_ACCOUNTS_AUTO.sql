-- ============================================
-- CREATE 5 TEST ACCOUNTS (AUTOMATIC VERSION)
-- ============================================
-- This version automatically looks up user IDs by email
-- 
-- IMPORTANT: You must create the auth users FIRST in Supabase Dashboard:
-- Authentication > Users > Add User
--
-- Create these 5 users:
-- 1. Email: sarah.test@fitcomp.app
-- 2. Email: mike.test@fitcomp.app
-- 3. Email: emma.test@fitcomp.app
-- 4. Email: alex.test@fitcomp.app
-- 5. Email: jordan.test@fitcomp.app
--
-- Then run this script - it will automatically find the user IDs by email.
-- ============================================

-- Test Account 1: Sarah Chen
INSERT INTO profiles (id, username, first_name, last_name, avatar, is_premium, height, weight)
SELECT 
  u.id,
  'sarahchen',
  'Sarah',
  'Chen',
  'https://i.pravatar.cc/150?img=1',
  false,
  165, -- 165 cm
  60   -- 60 kg
FROM auth.users u
WHERE u.email = 'sarah.test@fitcomp.app'
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  avatar = EXCLUDED.avatar,
  height = EXCLUDED.height,
  weight = EXCLUDED.weight;

-- Test Account 2: Mike Johnson
INSERT INTO profiles (id, username, first_name, last_name, avatar, is_premium, height, weight)
SELECT 
  u.id,
  'mikejohnson',
  'Mike',
  'Johnson',
  'https://i.pravatar.cc/150?img=5',
  false,
  180, -- 180 cm
  75   -- 75 kg
FROM auth.users u
WHERE u.email = 'mike.test@fitcomp.app'
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  avatar = EXCLUDED.avatar,
  height = EXCLUDED.height,
  weight = EXCLUDED.weight;

-- Test Account 3: Emma Wilson
INSERT INTO profiles (id, username, first_name, last_name, avatar, is_premium, height, weight)
SELECT 
  u.id,
  'emmawilson',
  'Emma',
  'Wilson',
  'https://i.pravatar.cc/150?img=9',
  false,
  170, -- 170 cm
  65   -- 65 kg
FROM auth.users u
WHERE u.email = 'emma.test@fitcomp.app'
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  avatar = EXCLUDED.avatar,
  height = EXCLUDED.height,
  weight = EXCLUDED.weight;

-- Test Account 4: Alex Rivera
INSERT INTO profiles (id, username, first_name, last_name, avatar, is_premium, height, weight)
SELECT 
  u.id,
  'alexrivera',
  'Alex',
  'Rivera',
  'https://i.pravatar.cc/150?img=12',
  false,
  175, -- 175 cm
  70   -- 70 kg
FROM auth.users u
WHERE u.email = 'alex.test@fitcomp.app'
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  avatar = EXCLUDED.avatar,
  height = EXCLUDED.height,
  weight = EXCLUDED.weight;

-- Test Account 5: Jordan Taylor
INSERT INTO profiles (id, username, first_name, last_name, avatar, is_premium, height, weight)
SELECT 
  u.id,
  'jordantaylor',
  'Jordan',
  'Taylor',
  'https://i.pravatar.cc/150?img=15',
  false,
  172, -- 172 cm
  68   -- 68 kg
FROM auth.users u
WHERE u.email = 'jordan.test@fitcomp.app'
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  avatar = EXCLUDED.avatar,
  height = EXCLUDED.height,
  weight = EXCLUDED.weight;

-- Verify the profiles were created
SELECT 
  p.id,
  p.username,
  p.first_name,
  p.last_name,
  u.email
FROM profiles p
JOIN auth.users u ON p.id = u.id
WHERE u.email IN (
  'sarah.test@fitcomp.app',
  'mike.test@fitcomp.app',
  'emma.test@fitcomp.app',
  'alex.test@fitcomp.app',
  'jordan.test@fitcomp.app'
)
ORDER BY u.email;

