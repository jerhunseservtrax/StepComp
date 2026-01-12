-- RPC Function to Mark Challenge Messages as Read
-- This function marks all messages in a challenge as read for the current user
-- It uses SECURITY DEFINER to bypass RLS policies

CREATE OR REPLACE FUNCTION public.mark_challenge_messages_read(
    p_challenge_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get the current user's ID from auth
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;
    
    -- Verify user is a member of the challenge
    IF NOT EXISTS (
        SELECT 1 FROM public.challenge_members
        WHERE challenge_id = p_challenge_id
        AND user_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'User is not a member of this challenge';
    END IF;
    
    -- Insert read records for all unread messages from other users
    -- Uses ON CONFLICT to handle duplicates (acts like upsert)
    -- Note: challenge_message_reads table schema is (user_id, message_id, read_at)
    INSERT INTO public.challenge_message_reads (user_id, message_id, read_at)
    SELECT 
        v_user_id,
        cm.id,
        NOW()
    FROM public.challenge_messages cm
    WHERE cm.challenge_id = p_challenge_id
    AND cm.user_id != v_user_id  -- Don't mark own messages
    AND cm.is_deleted = false
    AND NOT EXISTS (
        -- Skip messages already marked as read
        SELECT 1 FROM public.challenge_message_reads cmr
        WHERE cmr.message_id = cm.id
        AND cmr.user_id = v_user_id
    );
    
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.mark_challenge_messages_read TO authenticated;

-- Verification query
SELECT 
    'mark_challenge_messages_read RPC exists' as check_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'mark_challenge_messages_read'
    ) THEN 'YES ✅' ELSE 'NO ❌' END as result;

