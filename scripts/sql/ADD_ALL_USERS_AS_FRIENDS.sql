-- ============================================
-- Add All Users to Friends List
-- ============================================
-- This script adds all existing users as friends (accepted status)
-- Run this in Supabase Dashboard → SQL Editor
-- ============================================

-- STEP 1: Find Your User ID
-- Run this query first to find your user ID, then use it in STEP 2
-- Replace 'your-email@example.com' with your actual email
/*
SELECT 
    u.id AS user_id,
    u.email,
    p.username,
    p.display_name,
    u.created_at
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE u.email = 'your-email@example.com'  -- Replace with your email
ORDER BY u.created_at DESC;
*/

-- STEP 2: Add All Users as Friends
-- Replace 'YOUR_USER_ID_HERE' with the UUID from STEP 1
DO $$
DECLARE
    current_user_id UUID;
    other_user_id UUID;
    friendships_created INT := 0;
    friendships_updated INT := 0;
    total_users INT;
BEGIN
    -- ⚠️ REPLACE THIS WITH YOUR USER ID FROM STEP 1 ⚠️
    current_user_id := 'YOUR_USER_ID_HERE'::UUID;
    
    -- Check if user ID is valid
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = current_user_id) THEN
        RAISE EXCEPTION 'User ID not found. Please run STEP 1 to find your user ID and replace YOUR_USER_ID_HERE.';
    END IF;
    
    -- Count total users to add
    SELECT COUNT(*) INTO total_users
    FROM public.profiles 
    WHERE id != current_user_id;
    
    RAISE NOTICE 'Found % users to add as friends', total_users;
    
    -- Loop through all other users and create friendships
    FOR other_user_id IN 
        SELECT id FROM public.profiles 
        WHERE id != current_user_id
        ORDER BY created_at DESC
    LOOP
        -- Check if friendship already exists
        IF EXISTS (
            SELECT 1 FROM public.friendships 
            WHERE pair_low = LEAST(current_user_id, other_user_id) 
              AND pair_high = GREATEST(current_user_id, other_user_id)
        ) THEN
            -- Update existing friendship to accepted if it was pending
            UPDATE public.friendships
            SET status = 'accepted',
                updated_at = NOW()
            WHERE pair_low = LEAST(current_user_id, other_user_id) 
              AND pair_high = GREATEST(current_user_id, other_user_id)
              AND status = 'pending';
            
            IF FOUND THEN
                friendships_updated := friendships_updated + 1;
            END IF;
        ELSE
            -- Insert new friendship
            INSERT INTO public.friendships (requester_id, addressee_id, status)
            VALUES (current_user_id, other_user_id, 'accepted');
            
            friendships_created := friendships_created + 1;
        END IF;
    END LOOP;
    
    RAISE NOTICE '✅ Successfully processed % friendships!', friendships_created + friendships_updated;
    RAISE NOTICE '   - Created: % new friendships', friendships_created;
    RAISE NOTICE '   - Updated: % existing friendships to accepted', friendships_updated;
END $$;

-- ============================================
-- Option 2: Add All Users to a Specific User (Alternative)
-- ============================================
-- If you know the email or username, use this version
/*
DO $$
DECLARE
    current_user_id UUID;
    other_user_id UUID;
    friendships_created INT := 0;
    target_email TEXT := 'your-email@example.com';  -- Replace with your email
BEGIN
    -- Find user by email
    SELECT id INTO current_user_id
    FROM auth.users
    WHERE email = target_email;
    
    IF current_user_id IS NULL THEN
        RAISE EXCEPTION 'User with email % not found', target_email;
    END IF;
    
    -- Loop through all other users and create friendships
    FOR other_user_id IN 
        SELECT id FROM public.profiles 
        WHERE id != current_user_id
    LOOP
        INSERT INTO public.friendships (requester_id, addressee_id, status)
        VALUES (current_user_id, other_user_id, 'accepted')
        ON CONFLICT (pair_low, pair_high) 
        DO UPDATE SET status = 'accepted', updated_at = NOW()
        WHERE friendships.status = 'pending';
        
        friendships_created := friendships_created + 1;
    END LOOP;
    
    RAISE NOTICE 'Successfully added % users as friends!', friendships_created;
END $$;
*/

-- ============================================
-- STEP 3: List All Users (Helper Query)
-- ============================================
-- Run this to see all users in the system
/*
SELECT 
    u.id,
    u.email,
    p.username,
    p.display_name,
    p.public_profile,
    u.created_at
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
ORDER BY u.created_at DESC;
*/

-- ============================================
-- STEP 4: Verification - Check Your Friendships
-- ============================================
-- Run this after executing STEP 2 to verify friendships were created
-- Replace 'YOUR_USER_ID_HERE' with your user ID from STEP 1
/*
SELECT 
    f.id,
    f.status,
    f.created_at,
    f.updated_at,
    CASE 
        WHEN f.requester_id = 'YOUR_USER_ID_HERE'::UUID THEN addressee.display_name
        ELSE requester.display_name
    END AS friend_name,
    CASE 
        WHEN f.requester_id = 'YOUR_USER_ID_HERE'::UUID THEN addressee.username
        ELSE requester.username
    END AS friend_username
FROM public.friendships f
JOIN public.profiles requester ON requester.id = f.requester_id
JOIN public.profiles addressee ON addressee.id = f.addressee_id
WHERE f.requester_id = 'YOUR_USER_ID_HERE'::UUID 
   OR f.addressee_id = 'YOUR_USER_ID_HERE'::UUID
ORDER BY f.created_at DESC;
*/

-- ============================================
-- Quick Stats: Count Your Friends
-- ============================================
-- Get a quick count of your friendships
/*
SELECT 
    COUNT(*) FILTER (WHERE status = 'accepted') AS accepted_friends,
    COUNT(*) FILTER (WHERE status = 'pending' AND requester_id = 'YOUR_USER_ID_HERE'::UUID) AS pending_sent,
    COUNT(*) FILTER (WHERE status = 'pending' AND addressee_id = 'YOUR_USER_ID_HERE'::UUID) AS pending_received,
    COUNT(*) AS total_friendships
FROM public.friendships
WHERE requester_id = 'YOUR_USER_ID_HERE'::UUID 
   OR addressee_id = 'YOUR_USER_ID_HERE'::UUID;
*/

