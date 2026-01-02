# Account Deletion Feature

## Overview
Complete account deletion system that permanently removes all user data from the database, including friendships, challenge memberships, and step history.

## User Flow

### 1. Settings Page
- Red "Delete Account" button at the bottom
- Located below the "Log Out" button
- Clearly labeled with trash icon

### 2. Initial Warning Alert
When user taps "Delete Account":
- **Title**: "Delete Account"
- **Message**: "This action cannot be undone. Your account, friendships, challenge memberships, and all data will be permanently deleted."
- **Actions**: Cancel or Continue

### 3. Confirmation Sheet
If user taps "Continue":
- Full-screen modal with detailed warnings
- Lists all data that will be deleted:
  - All friendships and friend requests
  - Challenge memberships and history
  - All step data and statistics
  - Challenge messages and chats
  - Notifications and invites
  - Profile and account

- **Confirmation Required**: User must type "DELETE" (case-insensitive)
- **Button States**:
  - Disabled (gray) until "DELETE" is typed
  - Enabled (red) when confirmation text matches
  - Shows loading spinner during deletion
  - "Cancel" button to abort

### 4. Deletion Process
When user confirms:
1. Shows loading indicator
2. Calls `delete_user_account()` RPC function
3. Backend cascades through all related tables
4. Signs out user locally
5. Dismisses settings view
6. Returns to login screen

## Backend Implementation

### Database Function: `delete_user_account()`

**Location**: `DELETE_ACCOUNT_FUNCTION.sql`

**Security**:
- `SECURITY DEFINER` - Elevated permissions for cleanup
- Protected by `auth.uid()` check
- Users can only delete their own account

**What Gets Deleted**:

1. **Friendships** (`friendships` table)
   - Deletes both directions (user_id and friend_id)
   - Removes from all friends' lists

2. **Challenge Memberships** (`challenge_members` table)
   - Removes user from all active challenges
   - Updates challenge participant counts

3. **Challenge Messages** (`challenge_messages` table)
   - Soft-deleted (is_deleted = true)
   - Content replaced with '[deleted]'
   - Preserves chat history integrity

4. **Daily Steps** (`daily_steps` table)
   - Hard deletes all step records
   - Removes user from leaderboards

5. **Challenge Invites** (`challenge_invites` table)
   - Deletes sent and received invites
   - Cleans up pending notifications

6. **Inbox Notifications** (`inbox_notifications` table)
   - Removes all user notifications

7. **Message Read Tracking** (`challenge_message_reads` table)
   - Cleans up read receipts

8. **User Profile** (`profiles` table)
   - Deletes public profile data

9. **Auth User** (`auth.users` table)
   - Final deletion of authentication record
   - **Must be last** due to foreign key constraints

**Optional**:
- Challenges created by user can be preserved or deleted
- Currently configured to preserve (commented out)

### RPC Call Structure

```swift
try await supabase
    .rpc("delete_user_account", params: [:])
    .execute()
```

**Returns**: JSON summary of deletion
```json
{
  "user_id": "uuid",
  "friendships_deleted": 5,
  "challenge_memberships_deleted": 3,
  "messages_soft_deleted": 42,
  "steps_records_deleted": 180,
  "invites_deleted": 2,
  "notifications_deleted": 15,
  "deleted_at": "2026-01-02T..."
}
```

## Files Modified

### Swift Files
1. **SettingsView.swift**
   - Added state variables for deletion flow
   - Added "Delete Account" button
   - Added initial warning alert
   - Added `deleteAccount()` async function
   - Integrated confirmation sheet

2. **DeleteAccountConfirmationView.swift** (NEW)
   - Custom SwiftUI view for detailed confirmation
   - Text field for "DELETE" confirmation
   - Animated warning icons
   - Detailed list of what gets deleted
   - Loading states during deletion

### SQL Files
3. **DELETE_ACCOUNT_FUNCTION.sql** (NEW)
   - Complete deletion logic
   - Cascade deletes with logging
   - Security definer function
   - Error handling

## Safety Features

### Multi-Step Confirmation
1. Button tap (intentional action)
2. Initial alert (first warning)
3. Full-screen modal (detailed info)
4. Type "DELETE" (explicit confirmation)
5. Final button tap (execution)

### UI Safeguards
- Red color coding throughout
- Warning icons and language
- Disabled during deletion (prevents double-tap)
- Cannot dismiss during deletion
- Clear "Cannot be undone" messaging

### Backend Safeguards
- `SECURITY DEFINER` but auth-protected
- Transaction-based (all or nothing)
- Extensive logging for debugging
- Soft-delete for messages (preserves history)
- Error handling with rollback

## Database Impact

### Tables Modified
- ✅ `friendships` - Hard delete
- ✅ `challenge_members` - Hard delete
- ✅ `challenge_messages` - Soft delete
- ✅ `daily_steps` - Hard delete
- ✅ `challenge_invites` - Hard delete
- ✅ `inbox_notifications` - Hard delete
- ✅ `challenge_message_reads` - Hard delete
- ✅ `profiles` - Hard delete
- ✅ `auth.users` - Hard delete

### Foreign Key Considerations
- Deletion order matters
- `auth.users` must be deleted last
- RLS policies must allow deletion
- Cascade behavior configured correctly

## Testing Checklist

### Unit Tests
- [ ] RPC function exists
- [ ] Function has correct permissions
- [ ] Auth check works
- [ ] All tables are cleaned

### Integration Tests
- [ ] UI flow works end-to-end
- [ ] Confirmation text validation
- [ ] Button states update correctly
- [ ] Loading indicators show

### Functional Tests
- [ ] Create test user with data:
  - [ ] Add friends
  - [ ] Join challenges
  - [ ] Send messages
  - [ ] Log steps
- [ ] Delete account
- [ ] Verify all data removed:
  - [ ] User not in friends' lists
  - [ ] User removed from challenges
  - [ ] Messages soft-deleted
  - [ ] Profile gone
  - [ ] Cannot sign in again

### Edge Cases
- [ ] User with active challenges
- [ ] User who created challenges
- [ ] User with pending invites
- [ ] User mid-challenge
- [ ] Network failure during deletion
- [ ] App crash during deletion

## Deployment Steps

1. **Run SQL Script**
   ```bash
   ./EXECUTE_SQL_NOW.sh DELETE_ACCOUNT_FUNCTION.sql
   ```

2. **Verify Function**
   ```sql
   SELECT routine_name, routine_type 
   FROM information_schema.routines 
   WHERE routine_schema = 'public' 
   AND routine_name = 'delete_user_account';
   ```

3. **Test with Test Account**
   - Create account
   - Add sample data
   - Delete account
   - Verify cleanup

4. **Deploy App Update**
   - Submit to TestFlight
   - Monitor crash reports
   - Watch for deletion errors

## User Support

### FAQ Responses

**Q: Can I recover my account after deletion?**
A: No, account deletion is permanent and cannot be undone.

**Q: What happens to challenges I created?**
A: Challenges you created will remain active for other participants. You'll be removed as a member.

**Q: Will my friends know I deleted my account?**
A: You'll simply disappear from their friends list. No notification is sent.

**Q: What happens to my messages?**
A: Your messages in challenge chats are marked as deleted but remain visible as "[deleted]" to preserve conversation history.

**Q: Can I use the same email address again?**
A: Yes, after deletion, your email address becomes available for new account creation.

### Support Script
If user contacts support about deletion:
1. Confirm it's permanent
2. Offer alternative (logout/deactivation)
3. If they confirm, guide through process
4. Verify in database (check auth.users)

## Privacy Compliance

### GDPR
- ✅ Right to erasure implemented
- ✅ Complete data removal
- ✅ No data retention

### CCPA
- ✅ User-initiated deletion
- ✅ Verifiable request (typed confirmation)
- ✅ Completes within reasonable time

### Data Retention
- ❌ No data retained after deletion
- ⚠️ Backup tapes may contain data (30-day retention)
- ✅ Production database cleaned immediately

## Monitoring

### Metrics to Track
- Number of deletions per day/week/month
- Time to complete deletion
- Failed deletion attempts
- User journey drop-off points

### Logs to Monitor
```
🗑️ Starting account deletion for user: [uuid]
✅ Deleted N friendship records
✅ Removed user from N challenges
✅ Soft-deleted N messages
✅ Deleted N daily steps records
✅ Deleted N challenge invites
✅ Deleted N inbox notifications
✅ Deleted user profile
✅ Deleted auth user
✅ Account deletion complete
```

### Error Scenarios
- Foreign key constraint violations
- RLS policy blocks
- Network timeouts
- Auth session expired
- Concurrent modification

## Future Enhancements

### Potential Features
- [ ] Export data before deletion
- [ ] Account deactivation (reversible)
- [ ] Scheduled deletion (7-day grace period)
- [ ] Email confirmation link
- [ ] Deletion reason survey
- [ ] Re-activation window
- [ ] Anonymize instead of delete

### Analytics
- [ ] Track deletion reasons
- [ ] Identify churn patterns
- [ ] A/B test warning language
- [ ] Measure retention impact

