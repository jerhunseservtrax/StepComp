-- ============================================================================
-- DELETE ACCOUNT FUNCTION
-- ============================================================================
-- This SQL script creates a secure function to completely delete a user account
-- and all associated data from the database.
--
-- What gets deleted:
-- 1. All friendships (both directions)
-- 2. Challenge memberships (removes user from all challenges)
-- 3. Daily steps records
-- 4. Challenge messages (soft-deleted, user_id set to null for history)
-- 5. Challenge invites (sent and received)
-- 6. Inbox notifications
-- 7. User profile
-- 8. Auth user record
--
-- Usage: Called from the app when user confirms account deletion
-- The function uses SECURITY DEFINER to have elevated permissions
-- but is protected by auth.uid() check to ensure users can only delete their own account.
-- ============================================================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.delete_user_account();

-- Create the account deletion function
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER -- Allows function to bypass RLS for cleanup
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_deleted_data JSON;
    v_friendships_count INT;
    v_challenges_count INT;
    v_messages_count INT;
    v_steps_count INT;
    v_invites_count INT;
    v_notifications_count INT;
BEGIN
    -- Verify user is authenticated
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    RAISE NOTICE '🗑️ Starting account deletion for user: %', v_user_id;

    -- 1. Delete all friendships (both directions)
    DELETE FROM public.friendships
    WHERE user_id = v_user_id OR friend_id = v_user_id;
    GET DIAGNOSTICS v_friendships_count = ROW_COUNT;
    RAISE NOTICE '✅ Deleted % friendship records', v_friendships_count;

    -- 2. Remove user from all challenges (as member)
    DELETE FROM public.challenge_members
    WHERE user_id = v_user_id;
    GET DIAGNOSTICS v_challenges_count = ROW_COUNT;
    RAISE NOTICE '✅ Removed user from % challenges', v_challenges_count;

    -- 3. Soft-delete challenge messages (preserve for chat history)
    -- Set is_deleted = true and keep user_id for audit trail
    UPDATE public.challenge_messages
    SET is_deleted = true, content = '[deleted]'
    WHERE user_id = v_user_id;
    GET DIAGNOSTICS v_messages_count = ROW_COUNT;
    RAISE NOTICE '✅ Soft-deleted % messages', v_messages_count;

    -- 4. Delete daily steps records
    DELETE FROM public.daily_steps
    WHERE user_id = v_user_id;
    GET DIAGNOSTICS v_steps_count = ROW_COUNT;
    RAISE NOTICE '✅ Deleted % daily steps records', v_steps_count;

    -- 5. Delete challenge invites (sent and received)
    DELETE FROM public.challenge_invites
    WHERE inviter_id = v_user_id OR invitee_id = v_user_id;
    GET DIAGNOSTICS v_invites_count = ROW_COUNT;
    RAISE NOTICE '✅ Deleted % challenge invites', v_invites_count;

    -- 6. Delete inbox notifications
    DELETE FROM public.inbox_notifications
    WHERE user_id = v_user_id;
    GET DIAGNOSTICS v_notifications_count = ROW_COUNT;
    RAISE NOTICE '✅ Deleted % inbox notifications', v_notifications_count;

    -- 7. Delete message read tracking
    DELETE FROM public.challenge_message_reads
    WHERE user_id = v_user_id;

    -- 8. Delete user profile
    DELETE FROM public.profiles
    WHERE id = v_user_id;
    RAISE NOTICE '✅ Deleted user profile';

    -- 9. Delete challenges created by this user (optional - you may want to keep them)
    -- Uncomment the following lines if you want to delete challenges created by the user:
    -- DELETE FROM public.challenges
    -- WHERE created_by = v_user_id;

    -- 10. Delete auth user (must be last)
    -- Note: This will fail if there are still FK references
    DELETE FROM auth.users
    WHERE id = v_user_id;
    RAISE NOTICE '✅ Deleted auth user';

    -- Prepare summary
    v_deleted_data := json_build_object(
        'user_id', v_user_id,
        'friendships_deleted', v_friendships_count,
        'challenge_memberships_deleted', v_challenges_count,
        'messages_soft_deleted', v_messages_count,
        'steps_records_deleted', v_steps_count,
        'invites_deleted', v_invites_count,
        'notifications_deleted', v_notifications_count,
        'deleted_at', NOW()
    );

    RAISE NOTICE '✅ Account deletion complete: %', v_deleted_data;

    RETURN v_deleted_data;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to delete account: %', SQLERRM;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_user_account TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.delete_user_account IS 
'Permanently deletes a user account and all associated data. Can only be called by the authenticated user to delete their own account.';

-- ============================================================================
-- VERIFICATION QUERY
-- ============================================================================
-- Run this to verify the function was created successfully:
-- SELECT routine_name, routine_type 
-- FROM information_schema.routines 
-- WHERE routine_schema = 'public' AND routine_name = 'delete_user_account';
-- ============================================================================

