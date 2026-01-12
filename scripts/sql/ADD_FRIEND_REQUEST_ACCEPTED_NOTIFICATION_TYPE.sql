-- ========================================
-- ADD FRIEND_REQUEST_ACCEPTED NOTIFICATION TYPE
-- ========================================
-- This migration adds the 'friend_request_accepted' notification type
-- to the notifications table CHECK constraint

-- Drop the old constraint
ALTER TABLE public.notifications
DROP CONSTRAINT IF EXISTS notifications_type_check;

-- Add the new constraint with the additional notification type
ALTER TABLE public.notifications
ADD CONSTRAINT notifications_type_check 
CHECK (type IN (
    'friend_request',
    'friend_request_accepted',
    'challenge_invite',
    'challenge_update',
    'challenge_joined',
    'achievement'
));

-- Verify the constraint was updated
SELECT 
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.notifications'::regclass
  AND conname = 'notifications_type_check';

-- ========================================
-- VERIFICATION
-- ========================================
SELECT '✅ Notification type "friend_request_accepted" added successfully!' as status;
