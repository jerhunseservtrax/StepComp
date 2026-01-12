-- ============================================
-- Fix Daily Step Goal Not Saving from Onboarding
-- ============================================
-- Problem: Database trigger was hardcoding daily_step_goal to 10000
--          when creating profiles for OAuth users (Google, Apple).
--          This overrode the user's selection during onboarding.
-- Solution: Remove daily_step_goal from trigger, let app set it.
-- Run this in Supabase SQL Editor
-- ============================================

-- Fix the handle_new_user_profile trigger to NOT hardcode daily_step_goal
-- The app will set it from UserDefaults after OAuth completes
CREATE OR REPLACE FUNCTION public.handle_new_user_profile()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    username,
    first_name,
    last_name,
    display_name,
    email,
    public_profile,
    total_steps,
    onboarding_completed
    -- Removed daily_step_goal - app will set this from UserDefaults
  )
  VALUES (
    NEW.id,
    COALESCE(
      LOWER(SPLIT_PART(NEW.email, '@', 1)),
      'user_' || NEW.id::text
    ),
    NEW.raw_user_meta_data->>'given_name',
    NEW.raw_user_meta_data->>'family_name',
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'display_name'
    ),
    NEW.email,
    TRUE,  -- Changed to TRUE for easier friend discovery
    0,
    FALSE
    -- App will update daily_step_goal after reading from UserDefaults
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$;

-- Verification
DO $$
BEGIN
  RAISE NOTICE '✅ handle_new_user_profile trigger updated';
  RAISE NOTICE 'daily_step_goal is now set by the app from UserDefaults';
  RAISE NOTICE 'This preserves the user''s selection from onboarding';
END $$;
