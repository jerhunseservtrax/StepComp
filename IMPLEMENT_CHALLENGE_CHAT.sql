-- ========================================
-- Challenge Group Chat Implementation
-- Secure, realtime, RLS-enforced messaging
-- ========================================

-- 1️⃣ Create challenge_messages table
CREATE TABLE IF NOT EXISTS public.challenge_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_id UUID NOT NULL REFERENCES public.challenges(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    content TEXT NOT NULL CHECK (char_length(content) <= 2000),
    message_type TEXT NOT NULL DEFAULT 'text', -- 'text', 'system', 'image' (future)
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    edited_at TIMESTAMPTZ,
    is_deleted BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    CONSTRAINT content_not_empty CHECK (char_length(trim(content)) > 0)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_challenge_messages_challenge_time 
ON public.challenge_messages (challenge_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_challenge_messages_user 
ON public.challenge_messages (user_id);

CREATE INDEX IF NOT EXISTS idx_challenge_messages_not_deleted
ON public.challenge_messages (challenge_id, created_at DESC)
WHERE is_deleted = FALSE;

-- 2️⃣ Optional: Message reads tracking (for unread badges)
CREATE TABLE IF NOT EXISTS public.challenge_message_reads (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message_id UUID NOT NULL REFERENCES public.challenge_messages(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, message_id)
);

CREATE INDEX IF NOT EXISTS idx_message_reads_user
ON public.challenge_message_reads (user_id);

-- 3️⃣ Enable Row Level Security
ALTER TABLE public.challenge_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_message_reads ENABLE ROW LEVEL SECURITY;

-- 4️⃣ RLS Policies for challenge_messages

-- READ: Can read messages if you're a challenge member
DROP POLICY IF EXISTS "Read messages in joined challenges" ON public.challenge_messages;
CREATE POLICY "Read messages in joined challenges"
ON public.challenge_messages
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM public.challenge_members cm
        WHERE cm.challenge_id = challenge_messages.challenge_id
        AND cm.user_id = auth.uid()
    )
);

-- INSERT: Can send messages if you're a challenge member
DROP POLICY IF EXISTS "Send messages in joined challenges" ON public.challenge_messages;
CREATE POLICY "Send messages in joined challenges"
ON public.challenge_messages
FOR INSERT
WITH CHECK (
    user_id = auth.uid()
    AND NOT is_deleted -- Cannot insert already-deleted messages
    AND EXISTS (
        SELECT 1
        FROM public.challenge_members cm
        WHERE cm.challenge_id = challenge_messages.challenge_id
        AND cm.user_id = auth.uid()
    )
);

-- UPDATE: Can edit/delete own messages only
DROP POLICY IF EXISTS "Edit own messages" ON public.challenge_messages;
CREATE POLICY "Edit own messages"
ON public.challenge_messages
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 5️⃣ RLS Policies for challenge_message_reads

DROP POLICY IF EXISTS "Read own message reads" ON public.challenge_message_reads;
CREATE POLICY "Read own message reads"
ON public.challenge_message_reads
FOR SELECT
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Insert own message reads" ON public.challenge_message_reads;
CREATE POLICY "Insert own message reads"
ON public.challenge_message_reads
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- 6️⃣ RPC Function: Send Message (Server-side validation)
CREATE OR REPLACE FUNCTION public.send_challenge_message(
    p_challenge_id UUID,
    p_content TEXT,
    p_message_type TEXT DEFAULT 'text'
)
RETURNS TABLE(
    message_id UUID,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_message_id UUID;
    v_created_at TIMESTAMPTZ;
    v_is_member BOOLEAN;
BEGIN
    -- Authentication check
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;
    
    -- Membership check
    SELECT EXISTS (
        SELECT 1
        FROM public.challenge_members cm
        WHERE cm.challenge_id = p_challenge_id
        AND cm.user_id = v_user_id
    ) INTO v_is_member;
    
    IF NOT v_is_member THEN
        RAISE EXCEPTION 'You must be a member of this challenge to send messages';
    END IF;
    
    -- Content validation
    IF char_length(trim(p_content)) = 0 THEN
        RAISE EXCEPTION 'Message content cannot be empty';
    END IF;
    
    IF char_length(p_content) > 2000 THEN
        RAISE EXCEPTION 'Message content cannot exceed 2000 characters';
    END IF;
    
    -- Insert message
    INSERT INTO public.challenge_messages (
        challenge_id,
        user_id,
        content,
        message_type
    )
    VALUES (
        p_challenge_id,
        v_user_id,
        trim(p_content),
        p_message_type
    )
    RETURNING id, created_at INTO v_message_id, v_created_at;
    
    -- Return result
    RETURN QUERY SELECT v_message_id, v_created_at;
END;
$$;

GRANT EXECUTE ON FUNCTION public.send_challenge_message TO authenticated;

-- 7️⃣ RPC Function: Get Unread Count
CREATE OR REPLACE FUNCTION public.get_challenge_unread_count(
    p_challenge_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_unread_count INTEGER;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN 0;
    END IF;
    
    SELECT COUNT(*)::INTEGER INTO v_unread_count
    FROM public.challenge_messages cm
    WHERE cm.challenge_id = p_challenge_id
      AND cm.is_deleted = FALSE
      AND cm.user_id != v_user_id -- Don't count own messages
      AND NOT EXISTS (
          SELECT 1
          FROM public.challenge_message_reads cmr
          WHERE cmr.message_id = cm.id
            AND cmr.user_id = v_user_id
      );
    
    RETURN COALESCE(v_unread_count, 0);
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_challenge_unread_count TO authenticated;

-- 8️⃣ Helper Function: Create System Message
CREATE OR REPLACE FUNCTION public.create_system_message(
    p_challenge_id UUID,
    p_content TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_message_id UUID;
    v_system_user_id UUID;
BEGIN
    -- Use the first challenge member or a system ID
    SELECT user_id INTO v_system_user_id
    FROM public.challenge_members
    WHERE challenge_id = p_challenge_id
    LIMIT 1;
    
    IF v_system_user_id IS NULL THEN
        RAISE EXCEPTION 'No members in challenge';
    END IF;
    
    INSERT INTO public.challenge_messages (
        challenge_id,
        user_id,
        content,
        message_type
    )
    VALUES (
        p_challenge_id,
        v_system_user_id,
        p_content,
        'system'
    )
    RETURNING id INTO v_message_id;
    
    RETURN v_message_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_system_message TO authenticated;

-- 9️⃣ Verification Queries
SELECT 
    'challenge_messages table exists' as check_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'challenge_messages'
    ) THEN 'YES' ELSE 'NO' END as result

UNION ALL

SELECT 
    'RLS enabled on challenge_messages' as check_name,
    CASE WHEN (
        SELECT relrowsecurity 
        FROM pg_class 
        WHERE relname = 'challenge_messages'
    ) THEN 'YES' ELSE 'NO' END as result

UNION ALL

SELECT 
    'Message RLS policies count' as check_name,
    COUNT(*)::TEXT as result
FROM pg_policies
WHERE tablename = 'challenge_messages'

UNION ALL

SELECT 
    'send_challenge_message RPC exists' as check_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'send_challenge_message'
    ) THEN 'YES' ELSE 'NO' END as result;

-- 🎉 All done! You can now:
-- 1. Send messages via: SELECT * FROM send_challenge_message('challenge-uuid', 'Hello!')
-- 2. Get unread count: SELECT get_challenge_unread_count('challenge-uuid')
-- 3. Subscribe to realtime updates in Swift

