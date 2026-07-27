-- ============================================================================
-- FIX: delete_user_account for live schema
-- ============================================================================
-- Production bug (2026-07-27):
--   Settings → Delete Account calls public.delete_user_account, but that RPC is
--   missing from the deployed schema cache (PostgREST PGRST202). The checked-in
--   DELETE_ACCOUNT_FUNCTION.sql is also schema-stale and would fail even if
--   deployed:
--     * friendships uses requester_id/addressee_id (not user_id/friend_id)
--     * app inbox uses notifications (inbox_notifications alone is incomplete)
--     * owned challenges / metrics tables were not cleaned up
--
-- Deploy: run this script in the Supabase SQL Editor after review.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_friendships_count INT := 0;
    v_challenges_owned_count INT := 0;
    v_challenge_memberships_count INT := 0;
    v_messages_count INT := 0;
    v_steps_count INT := 0;
    v_invites_count INT := 0;
    v_notifications_count INT := 0;
    v_inbox_notifications_count INT := 0;
    v_workout_sessions_count INT := 0;
    v_weight_log_count INT := 0;
    v_deleted_data JSON;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    -- Soft-delete challenge messages (preserve thread history for other members)
    IF to_regclass('public.challenge_messages') IS NOT NULL THEN
        UPDATE public.challenge_messages
        SET is_deleted = TRUE,
            content = '[deleted]'
        WHERE user_id = v_user_id;
        GET DIAGNOSTICS v_messages_count = ROW_COUNT;
    END IF;

    IF to_regclass('public.challenge_message_reads') IS NOT NULL THEN
        DELETE FROM public.challenge_message_reads
        WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.challenge_invites') IS NOT NULL THEN
        DELETE FROM public.challenge_invites
        WHERE inviter_id = v_user_id OR invitee_id = v_user_id;
        GET DIAGNOSTICS v_invites_count = ROW_COUNT;
    END IF;

    IF to_regclass('public.challenge_members') IS NOT NULL THEN
        DELETE FROM public.challenge_members
        WHERE user_id = v_user_id;
        GET DIAGNOSTICS v_challenge_memberships_count = ROW_COUNT;
    END IF;

    IF to_regclass('public.challenge_snapshots') IS NOT NULL THEN
        DELETE FROM public.challenge_snapshots
        WHERE user_id = v_user_id;
    END IF;

    -- Delete challenges this user created (memberships/messages cascade via FKs)
    IF to_regclass('public.challenges') IS NOT NULL THEN
        DELETE FROM public.challenges
        WHERE created_by = v_user_id;
        GET DIAGNOSTICS v_challenges_owned_count = ROW_COUNT;
    END IF;

    -- Live friendships schema: requester_id / addressee_id
    IF to_regclass('public.friendships') IS NOT NULL THEN
        DELETE FROM public.friendships
        WHERE requester_id = v_user_id OR addressee_id = v_user_id;
        GET DIAGNOSTICS v_friendships_count = ROW_COUNT;
    END IF;

    IF to_regclass('public.friend_invites') IS NOT NULL THEN
        DELETE FROM public.friend_invites
        WHERE inviter_id = v_user_id;
    END IF;

    -- App reads/writes `notifications`; also clear legacy `inbox_notifications`
    IF to_regclass('public.notifications') IS NOT NULL THEN
        DELETE FROM public.notifications
        WHERE user_id = v_user_id;
        GET DIAGNOSTICS v_notifications_count = ROW_COUNT;
    END IF;

    IF to_regclass('public.inbox_notifications') IS NOT NULL THEN
        DELETE FROM public.inbox_notifications
        WHERE user_id = v_user_id;
        GET DIAGNOSTICS v_inbox_notifications_count = ROW_COUNT;
    END IF;

    IF to_regclass('public.daily_steps') IS NOT NULL THEN
        DELETE FROM public.daily_steps
        WHERE user_id = v_user_id;
        GET DIAGNOSTICS v_steps_count = ROW_COUNT;
    END IF;

    IF to_regclass('public.step_audit_log') IS NOT NULL THEN
        DELETE FROM public.step_audit_log
        WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.workout_sessions') IS NOT NULL THEN
        -- Sets reference sessions; delete sets first when present
        IF to_regclass('public.workout_session_sets') IS NOT NULL THEN
            DELETE FROM public.workout_session_sets
            WHERE session_id IN (
                SELECT id FROM public.workout_sessions WHERE user_id = v_user_id
            );
        END IF;

        DELETE FROM public.workout_sessions
        WHERE user_id = v_user_id;
        GET DIAGNOSTICS v_workout_sessions_count = ROW_COUNT;
    END IF;

    IF to_regclass('public.weight_log') IS NOT NULL THEN
        DELETE FROM public.weight_log
        WHERE user_id = v_user_id;
        GET DIAGNOSTICS v_weight_log_count = ROW_COUNT;
    END IF;

    -- Optional metrics tables (present after comprehensive metrics migration)
    IF to_regclass('public.personal_records') IS NOT NULL THEN
        DELETE FROM public.personal_records WHERE user_id = v_user_id;
    END IF;
    IF to_regclass('public.body_metrics') IS NOT NULL THEN
        DELETE FROM public.body_metrics WHERE user_id = v_user_id;
    END IF;
    IF to_regclass('public.nutrition_log') IS NOT NULL THEN
        DELETE FROM public.nutrition_log WHERE user_id = v_user_id;
    END IF;
    IF to_regclass('public.recovery_daily') IS NOT NULL THEN
        DELETE FROM public.recovery_daily WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.feedback_votes') IS NOT NULL THEN
        DELETE FROM public.feedback_votes WHERE user_id = v_user_id;
    END IF;
    IF to_regclass('public.feedback_posts') IS NOT NULL THEN
        DELETE FROM public.feedback_posts WHERE user_id = v_user_id;
    END IF;

    IF to_regclass('public.profiles') IS NOT NULL THEN
        DELETE FROM public.profiles
        WHERE id = v_user_id;
    END IF;

    -- Final auth user deletion (must be last)
    DELETE FROM auth.users
    WHERE id = v_user_id;

    v_deleted_data := json_build_object(
        'user_id', v_user_id,
        'friendships_deleted', v_friendships_count,
        'challenges_owned_deleted', v_challenges_owned_count,
        'challenge_memberships_deleted', v_challenge_memberships_count,
        'messages_soft_deleted', v_messages_count,
        'steps_records_deleted', v_steps_count,
        'invites_deleted', v_invites_count,
        'notifications_deleted', v_notifications_count,
        'inbox_notifications_deleted', v_inbox_notifications_count,
        'workout_sessions_deleted', v_workout_sessions_count,
        'weight_log_deleted', v_weight_log_count,
        'deleted_at', NOW()
    );

    RETURN v_deleted_data;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to delete account: %', SQLERRM;
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;

COMMENT ON FUNCTION public.delete_user_account() IS
'Permanently deletes the authenticated user and associated public data. Matches live friendships/notifications/metrics schema.';

-- Keep the historical script in sync for fresh environments.
-- (Operators should prefer this FIX_ script against already-deployed DBs.)
