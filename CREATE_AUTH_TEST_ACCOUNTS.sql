-- ============================================
-- Create 5 Test Auth Accounts
-- ============================================
-- This script creates 5 test users in auth.users table
-- and their corresponding profiles
-- ============================================
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================

-- Note: You'll need to generate bcrypt password hashes for the passwords
-- Default password for all test accounts: "TestPassword123!"
-- You can generate hashes at: https://bcrypt-generator.com/
-- Or use: SELECT crypt('TestPassword123!', gen_salt('bf', 10));

-- Test Account 1
INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    is_sso_user,
    is_anonymous
) VALUES (
    '11111111-1111-1111-1111-111111111111'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated',
    'authenticated',
    'testuser1@stepcomp.test',
    '$2a$10$6x4YlKtQZJh2uTutCAYad.Ay5iQvaW7wMcGSiJ1P/CroUgAd4q5YO',
    NOW(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"sub": "11111111-1111-1111-1111-111111111111", "email": "testuser1@stepcomp.test", "email_verified": true, "phone_verified": false, "first_name": "Alex", "last_name": "Morgan", "username": "alex.walks"}'::jsonb,
    NOW(),
    NOW(),
    FALSE,
    FALSE
) ON CONFLICT (id) DO NOTHING;

-- Test Account 2
INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    is_sso_user,
    is_anonymous
) VALUES (
    '22222222-2222-2222-2222-222222222222'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated',
    'authenticated',
    'testuser2@stepcomp.test',
    '$2a$10$6x4YlKtQZJh2uTutCAYad.Ay5iQvaW7wMcGSiJ1P/CroUgAd4q5YO',
    NOW(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"sub": "22222222-2222-2222-2222-222222222222", "email": "testuser2@stepcomp.test", "email_verified": true, "phone_verified": false, "first_name": "Jamie", "last_name": "Chen", "username": "jamie.steps"}'::jsonb,
    NOW(),
    NOW(),
    FALSE,
    FALSE
) ON CONFLICT (id) DO NOTHING;

-- Test Account 3
INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    is_sso_user,
    is_anonymous
) VALUES (
    '33333333-3333-3333-3333-333333333333'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated',
    'authenticated',
    'testuser3@stepcomp.test',
    '$2a$10$6x4YlKtQZJh2uTutCAYad.Ay5iQvaW7wMcGSiJ1P/CroUgAd4q5YO',
    NOW(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"sub": "33333333-3333-3333-3333-333333333333", "email": "testuser3@stepcomp.test", "email_verified": true, "phone_verified": false, "first_name": "Marcus", "last_name": "Reed", "username": "marcus.fit"}'::jsonb,
    NOW(),
    NOW(),
    FALSE,
    FALSE
) ON CONFLICT (id) DO NOTHING;

-- Test Account 4
INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    is_sso_user,
    is_anonymous
) VALUES (
    '44444444-4444-4444-4444-444444444444'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated',
    'authenticated',
    'testuser4@stepcomp.test',
    '$2a$10$6x4YlKtQZJh2uTutCAYad.Ay5iQvaW7wMcGSiJ1P/CroUgAd4q5YO',
    NOW(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"sub": "44444444-4444-4444-4444-444444444444", "email": "testuser4@stepcomp.test", "email_verified": true, "phone_verified": false, "first_name": "Nina", "last_name": "Alvarez", "username": "nina.moves"}'::jsonb,
    NOW(),
    NOW(),
    FALSE,
    FALSE
) ON CONFLICT (id) DO NOTHING;

-- Test Account 5
INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    is_sso_user,
    is_anonymous
) VALUES (
    '55555555-5555-5555-5555-555555555555'::uuid,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated',
    'authenticated',
    'testuser5@stepcomp.test',
    '$2a$10$6x4YlKtQZJh2uTutCAYad.Ay5iQvaW7wMcGSiJ1P/CroUgAd4q5YO',
    NOW(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"sub": "55555555-5555-5555-5555-555555555555", "email": "testuser5@stepcomp.test", "email_verified": true, "phone_verified": false, "first_name": "Leo", "last_name": "Park", "username": "leo.stride"}'::jsonb,
    NOW(),
    NOW(),
    FALSE,
    FALSE
) ON CONFLICT (id) DO NOTHING;

-- ============================================
-- Create Profiles for Test Accounts
-- ============================================
-- This version assumes profiles use 'id' as the PK and FK to auth.users.id.
-- It will insert or update profiles accordingly.

DO $$
DECLARE
    has_display_name_column BOOLEAN;
    has_public_profile_column BOOLEAN;
    has_email_column BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'display_name'
    ) INTO has_display_name_column;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'public_profile'
    ) INTO has_public_profile_column;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'email'
    ) INTO has_email_column;

    IF has_email_column AND has_public_profile_column AND has_display_name_column THEN
        INSERT INTO public.profiles (id, username, display_name, first_name, last_name, email, public_profile, avatar_url, created_at, updated_at)
        VALUES
            ('11111111-1111-1111-1111-111111111111'::uuid, 'alex.walks', 'Alex Morgan', 'Alex', 'Morgan', 'testuser1@stepcomp.test', TRUE, '🤖', NOW(), NOW()),
            ('22222222-2222-2222-2222-222222222222'::uuid, 'jamie.steps', 'Jamie Chen', 'Jamie', 'Chen', 'testuser2@stepcomp.test', TRUE, '🐱', NOW(), NOW()),
            ('33333333-3333-3333-3333-333333333333'::uuid, 'marcus.fit', 'Marcus Reed', 'Marcus', 'Reed', 'testuser3@stepcomp.test', TRUE, '👽', NOW(), NOW()),
            ('44444444-4444-4444-4444-444444444444'::uuid, 'nina.moves', 'Nina Alvarez', 'Nina', 'Alvarez', 'testuser4@stepcomp.test', FALSE, '🦊', NOW(), NOW()),
            ('55555555-5555-5555-5555-555555555555'::uuid, 'leo.stride', 'Leo Park', 'Leo', 'Park', 'testuser5@stepcomp.test', FALSE, '🥷', NOW(), NOW())
        ON CONFLICT (id) DO UPDATE SET
            username = EXCLUDED.username,
            display_name = EXCLUDED.display_name,
            first_name = EXCLUDED.first_name,
            last_name = EXCLUDED.last_name,
            email = EXCLUDED.email,
            avatar_url = EXCLUDED.avatar_url,
            updated_at = NOW();
    ELSIF has_email_column THEN
        INSERT INTO public.profiles (id, username, display_name, first_name, last_name, email, avatar_url, created_at, updated_at)
        VALUES
            ('11111111-1111-1111-1111-111111111111'::uuid, 'alex.walks', 'Alex Morgan', 'Alex', 'Morgan', 'testuser1@stepcomp.test', '🤖', NOW(), NOW()),
            ('22222222-2222-2222-2222-222222222222'::uuid, 'jamie.steps', 'Jamie Chen', 'Jamie', 'Chen', 'testuser2@stepcomp.test', '🐱', NOW(), NOW()),
            ('33333333-3333-3333-3333-333333333333'::uuid, 'marcus.fit', 'Marcus Reed', 'Marcus', 'Reed', 'testuser3@stepcomp.test', '👽', NOW(), NOW()),
            ('44444444-4444-4444-4444-444444444444'::uuid, 'nina.moves', 'Nina Alvarez', 'Nina', 'Alvarez', 'testuser4@stepcomp.test', '🦊', NOW(), NOW()),
            ('55555555-5555-5555-5555-555555555555'::uuid, 'leo.stride', 'Leo Park', 'Leo', 'Park', 'testuser5@stepcomp.test', '🥷', NOW(), NOW())
        ON CONFLICT (id) DO UPDATE SET
            username = EXCLUDED.username,
            display_name = EXCLUDED.display_name,
            first_name = EXCLUDED.first_name,
            last_name = EXCLUDED.last_name,
            email = EXCLUDED.email,
            avatar_url = EXCLUDED.avatar_url,
            updated_at = NOW();
    ELSIF has_display_name_column AND has_public_profile_column THEN
        INSERT INTO public.profiles (id, username, display_name, first_name, last_name, public_profile, avatar_url, created_at, updated_at)
        VALUES
            ('11111111-1111-1111-1111-111111111111'::uuid, 'alex.walks', 'Alex Morgan', 'Alex', 'Morgan', TRUE, '🤖', NOW(), NOW()),
            ('22222222-2222-2222-2222-222222222222'::uuid, 'jamie.steps', 'Jamie Chen', 'Jamie', 'Chen', TRUE, '🐱', NOW(), NOW()),
            ('33333333-3333-3333-3333-333333333333'::uuid, 'marcus.fit', 'Marcus Reed', 'Marcus', 'Reed', TRUE, '👽', NOW(), NOW()),
            ('44444444-4444-4444-4444-444444444444'::uuid, 'nina.moves', 'Nina Alvarez', 'Nina', 'Alvarez', FALSE, '🦊', NOW(), NOW()),
            ('55555555-5555-5555-5555-555555555555'::uuid, 'leo.stride', 'Leo Park', 'Leo', 'Park', FALSE, '🥷', NOW(), NOW())
        ON CONFLICT (id) DO UPDATE SET
            username = EXCLUDED.username,
            display_name = EXCLUDED.display_name,
            first_name = EXCLUDED.first_name,
            last_name = EXCLUDED.last_name,
            avatar_url = EXCLUDED.avatar_url,
            updated_at = NOW();
    ELSE
        -- Minimal schema
        INSERT INTO public.profiles (id, username, first_name, last_name, avatar_url, created_at, updated_at)
        VALUES
            ('11111111-1111-1111-1111-111111111111'::uuid, 'alex.walks', 'Alex', 'Morgan', '🤖', NOW(), NOW()),
            ('22222222-2222-2222-2222-222222222222'::uuid, 'jamie.steps', 'Jamie', 'Chen', '🐱', NOW(), NOW()),
            ('33333333-3333-3333-3333-333333333333'::uuid, 'marcus.fit', 'Marcus', 'Reed', '👽', NOW(), NOW()),
            ('44444444-4444-4444-4444-444444444444'::uuid, 'nina.moves', 'Nina', 'Alvarez', '🦊', NOW(), NOW()),
            ('55555555-5555-5555-5555-555555555555'::uuid, 'leo.stride', 'Leo', 'Park', '🥷', NOW(), NOW())
        ON CONFLICT (id) DO UPDATE SET
            username = EXCLUDED.username,
            first_name = EXCLUDED.first_name,
            last_name = EXCLUDED.last_name,
            avatar_url = EXCLUDED.avatar_url,
            updated_at = NOW();
    END IF;
END $$;

-- ============================================
-- Update Profiles with Enhanced Data
-- ============================================
-- This query updates the profiles with usernames, display names, avatars, and public profile settings
-- It handles cases where avatar_url or onboarding_completed columns may not exist

DO $$
DECLARE
    has_avatar_url_column BOOLEAN;
    has_onboarding_completed_column BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'avatar_url'
    ) INTO has_avatar_url_column;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'onboarding_completed'
    ) INTO has_onboarding_completed_column;

    IF has_avatar_url_column AND has_onboarding_completed_column THEN
        WITH new_values AS (
            SELECT id,
                CASE id
                    WHEN '11111111-1111-1111-1111-111111111111' THEN 'alex.walks'
                    WHEN '22222222-2222-2222-2222-222222222222' THEN 'jamie.steps'
                    WHEN '33333333-3333-3333-3333-333333333333' THEN 'marcus.fit'
                    WHEN '44444444-4444-4444-4444-444444444444' THEN 'nina.moves'
                    WHEN '55555555-5555-5555-5555-555555555555' THEN 'leo.stride'
                    ELSE username
                END AS new_username,
                CASE id
                    WHEN '11111111-1111-1111-1111-111111111111' THEN 'Alex Morgan'
                    WHEN '22222222-2222-2222-2222-222222222222' THEN 'Jamie Chen'
                    WHEN '33333333-3333-3333-3333-333333333333' THEN 'Marcus Reed'
                    WHEN '44444444-4444-4444-4444-444444444444' THEN 'Nina Alvarez'
                    WHEN '55555555-5555-5555-5555-555555555555' THEN 'Leo Park'
                    ELSE display_name
                END AS new_display_name,
                CASE id
                    WHEN '11111111-1111-1111-1111-111111111111' THEN '🤖'
                    WHEN '22222222-2222-2222-2222-222222222222' THEN '🐱'
                    WHEN '33333333-3333-3333-3333-333333333333' THEN '👽'
                    WHEN '44444444-4444-4444-4444-444444444444' THEN '🦊'
                    WHEN '55555555-5555-5555-5555-555555555555' THEN '🥷'
                    ELSE avatar_url
                END AS new_avatar_url,
                CASE id
                    WHEN '11111111-1111-1111-1111-111111111111' THEN TRUE
                    WHEN '22222222-2222-2222-2222-222222222222' THEN TRUE
                    WHEN '33333333-3333-3333-3333-333333333333' THEN TRUE
                    ELSE FALSE
                END AS new_public_profile
            FROM public.profiles
            WHERE id IN (
                '11111111-1111-1111-1111-111111111111',
                '22222222-2222-2222-2222-222222222222',
                '33333333-3333-3333-3333-333333333333',
                '44444444-4444-4444-4444-444444444444',
                '55555555-5555-5555-5555-555555555555'
            )
        )
        UPDATE public.profiles p
        SET
            username = nv.new_username,
            display_name = nv.new_display_name,
            first_name = split_part(nv.new_display_name, ' ', 1),
            last_name = split_part(nv.new_display_name, ' ', 2),
            avatar_url = nv.new_avatar_url,
            public_profile = nv.new_public_profile,
            onboarding_completed = TRUE,
            updated_at = NOW()
        FROM new_values nv
        WHERE p.id = nv.id;
    ELSIF has_avatar_url_column THEN
        WITH new_values AS (
            SELECT id,
                CASE id
                    WHEN '11111111-1111-1111-1111-111111111111' THEN 'alex.walks'
                    WHEN '22222222-2222-2222-2222-222222222222' THEN 'jamie.steps'
                    WHEN '33333333-3333-3333-3333-333333333333' THEN 'marcus.fit'
                    WHEN '44444444-4444-4444-4444-444444444444' THEN 'nina.moves'
                    WHEN '55555555-5555-5555-5555-555555555555' THEN 'leo.stride'
                    ELSE username
                END AS new_username,
                CASE id
                    WHEN '11111111-1111-1111-1111-111111111111' THEN 'Alex Morgan'
                    WHEN '22222222-2222-2222-2222-222222222222' THEN 'Jamie Chen'
                    WHEN '33333333-3333-3333-3333-333333333333' THEN 'Marcus Reed'
                    WHEN '44444444-4444-4444-4444-444444444444' THEN 'Nina Alvarez'
                    WHEN '55555555-5555-5555-5555-555555555555' THEN 'Leo Park'
                    ELSE display_name
                END AS new_display_name,
                CASE id
                    WHEN '11111111-1111-1111-1111-111111111111' THEN '🤖'
                    WHEN '22222222-2222-2222-2222-222222222222' THEN '🐱'
                    WHEN '33333333-3333-3333-3333-333333333333' THEN '👽'
                    WHEN '44444444-4444-4444-4444-444444444444' THEN '🦊'
                    WHEN '55555555-5555-5555-5555-555555555555' THEN '🥷'
                    ELSE avatar_url
                END AS new_avatar_url,
                CASE id
                    WHEN '11111111-1111-1111-1111-111111111111' THEN TRUE
                    WHEN '22222222-2222-2222-2222-222222222222' THEN TRUE
                    WHEN '33333333-3333-3333-3333-333333333333' THEN TRUE
                    ELSE FALSE
                END AS new_public_profile
            FROM public.profiles
            WHERE id IN (
                '11111111-1111-1111-1111-111111111111',
                '22222222-2222-2222-2222-222222222222',
                '33333333-3333-3333-3333-333333333333',
                '44444444-4444-4444-4444-444444444444',
                '55555555-5555-5555-5555-555555555555'
            )
        )
        UPDATE public.profiles p
        SET
            username = nv.new_username,
            display_name = nv.new_display_name,
            first_name = split_part(nv.new_display_name, ' ', 1),
            last_name = split_part(nv.new_display_name, ' ', 2),
            avatar_url = nv.new_avatar_url,
            public_profile = nv.new_public_profile,
            updated_at = NOW()
        FROM new_values nv
        WHERE p.id = nv.id;
    END IF;
END $$;

-- ============================================
-- Verification Query
-- ============================================
SELECT 
    u.id,
    u.email,
    u.email_confirmed_at,
    u.created_at,
    p.username,
    p.display_name,
    p.first_name,
    p.last_name,
    p.avatar_url,
    p.public_profile
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE u.email LIKE 'testuser%@stepcomp.test'
ORDER BY u.email;

-- ============================================
-- Test Account Credentials
-- ============================================
-- All accounts use the same password: TestPassword123!
--
-- Account 1: Alex Morgan (🤖)
--   Email: testuser1@stepcomp.test
--   Username: alex.walks
--   Display Name: Alex Morgan
--   Public Profile: TRUE
--   Password: TestPassword123!
--
-- Account 2: Jamie Chen (🐱)
--   Email: testuser2@stepcomp.test
--   Username: jamie.steps
--   Display Name: Jamie Chen
--   Public Profile: TRUE
--   Password: TestPassword123!
--
-- Account 3: Marcus Reed (👽)
--   Email: testuser3@stepcomp.test
--   Username: marcus.fit
--   Display Name: Marcus Reed
--   Public Profile: TRUE
--   Password: TestPassword123!
--
-- Account 4: Nina Alvarez (🦊)
--   Email: testuser4@stepcomp.test
--   Username: nina.moves
--   Display Name: Nina Alvarez
--   Public Profile: FALSE
--   Password: TestPassword123!
--
-- Account 5: Leo Park (🥷)
--   Email: testuser5@stepcomp.test
--   Username: leo.stride
--   Display Name: Leo Park
--   Public Profile: FALSE
--   Password: TestPassword123!
-- ============================================
