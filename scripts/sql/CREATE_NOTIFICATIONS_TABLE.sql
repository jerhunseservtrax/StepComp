-- ========================================
-- CREATE NOTIFICATIONS TABLE
-- ========================================
-- This table stores in-app notifications for users
-- including challenge joins, friend requests, achievements, etc.

-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('friend_request', 'challenge_invite', 'challenge_update', 'challenge_joined', 'achievement')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    related_id TEXT, -- Challenge ID, Friend ID, etc.
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id, is_read) WHERE is_read = FALSE;

-- Enable Row Level Security
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- ========================================
-- RLS POLICIES
-- ========================================

-- Users can read their own notifications
CREATE POLICY "Users can read own notifications"
ON public.notifications
FOR SELECT
USING (auth.uid() = user_id);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
ON public.notifications
FOR UPDATE
USING (auth.uid() = user_id);

-- System can insert notifications for any user
-- Note: In production, this should be restricted to service role
CREATE POLICY "Authenticated users can insert notifications"
ON public.notifications
FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
ON public.notifications
FOR DELETE
USING (auth.uid() = user_id);

-- ========================================
-- FUNCTION TO MARK NOTIFICATIONS AS READ
-- ========================================

CREATE OR REPLACE FUNCTION mark_notification_read(notification_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.notifications
    SET is_read = TRUE, updated_at = NOW()
    WHERE id = notification_id
      AND user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- FUNCTION TO MARK ALL NOTIFICATIONS AS READ
-- ========================================

CREATE OR REPLACE FUNCTION mark_all_notifications_read()
RETURNS VOID AS $$
BEGIN
    UPDATE public.notifications
    SET is_read = TRUE, updated_at = NOW()
    WHERE user_id = auth.uid()
      AND is_read = FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- FUNCTION TO DELETE OLD READ NOTIFICATIONS
-- ========================================
-- Automatically delete read notifications older than 30 days

CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS VOID AS $$
BEGIN
    DELETE FROM public.notifications
    WHERE is_read = TRUE
      AND created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- GRANT PERMISSIONS
-- ========================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.notifications TO authenticated;
GRANT EXECUTE ON FUNCTION mark_notification_read TO authenticated;
GRANT EXECUTE ON FUNCTION mark_all_notifications_read TO authenticated;

-- ========================================
-- VERIFICATION QUERIES
-- ========================================

-- Check if table was created
SELECT 
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name = 'notifications';

-- Check RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'notifications';

-- Check indexes
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'notifications'
  AND schemaname = 'public';

