# Friends & Challenges Integration

This document explains how friends integrate with the challenge system.

## Overview

After users have friends, challenges unlock new features:
- **Friend-first invites**: Friends appear first in challenge creation
- **Friends-only challenges**: Option to restrict challenges to friends only
- **Private challenges**: Only invited participants can join
- **Friend-only leaderboards**: Filter leaderboard to show only friends
- **Friend-only stats**: View stats for friends only

## Implementation

### 1. Challenge Invites - Friends First

**Location**: `CreateChallengeView` → `InviteSectionView`

**Behavior**:
- Friends are loaded from Supabase `friends` table (accepted friendships)
- Friends appear first in the invite list
- Search filters friends by name or username
- Friends are clearly marked and easy to select

**Code**:
- `FriendsLoaderViewModel` loads friends from Supabase
- `InviteSectionView` displays friends with avatars
- Friends are prioritized in the UI

### 2. Friends Only Toggle

**Location**: `CreateChallengeView` → `InviteSectionView` → `FriendsOnlyToggleView`

**UI**:
- Toggle switch: "Friends Only"
- Description: "Only your friends can join"
- When enabled, restricts challenge to friends only

**Behavior**:
- When `isFriendsOnly = true`:
  - Only friends can see and join the challenge
  - Leaderboard can be filtered to show only friends
  - Stats can be filtered to show only friends

**Implementation**:
- `CreateChallengeViewModel.isFriendsOnly` property
- Stored in challenge metadata (can be added to database schema later)
- Used for filtering leaderboards and stats

### 3. Private Challenges

**Location**: `CreateChallengeView` → `PrivacyToggleView`

**Behavior**:
- When `isPrivate = true`:
  - Challenge is not publicly visible
  - Only invited participants can join
  - Requires invite code to join

**Database**:
- `SupabaseChallenge.isPublic = false` means private
- Private challenges are not shown in public challenge lists

### 4. Friend-Only Leaderboards

**Future Enhancement**:
- Filter leaderboard entries to show only friends
- Hide non-friend participants from leaderboard
- Show "Friends Only" badge on leaderboard

**Implementation** (when needed):
```swift
func getFriendOnlyLeaderboard(challengeId: String, userId: String) async -> [LeaderboardEntry] {
    // Get all leaderboard entries
    let allEntries = await getLeaderboard(for: challengeId)
    
    // Get user's friends
    let friends = await getFriends(userId: userId)
    let friendIds = Set(friends.map { $0.id })
    
    // Filter to only friends
    return allEntries.filter { friendIds.contains($0.userId) }
}
```

### 5. Friend-Only Stats

**Future Enhancement**:
- Filter challenge stats to show only friends' progress
- Compare your progress with friends only
- Hide non-friend participants from stats

## Database Schema

### Current Schema

**challenges table**:
- `is_public` (BOOLEAN): Controls if challenge is public or private
- `invite_code` (TEXT): Code for joining private challenges

**friends table**:
- `requester_id` (UUID): User who sent request
- `addressee_id` (UUID): User who received request
- `status` (TEXT): 'pending' or 'accepted'

### Future Schema Enhancement

To fully support friends-only challenges, consider adding:

```sql
ALTER TABLE challenges ADD COLUMN is_friends_only BOOLEAN DEFAULT FALSE;
```

This would allow:
- Storing friends-only setting in database
- Querying friends-only challenges
- Enforcing friends-only restrictions at database level

## User Flow

### Creating a Challenge with Friends

1. **User taps "Create Challenge"**
2. **Fills in challenge details** (name, duration, start date)
3. **"Who's playing?" section appears**
   - Friends are loaded from Supabase
   - Friends appear first in the list
   - User can search friends by name/username
4. **User can toggle "Friends Only"**
   - If enabled, only friends can join
5. **User selects friends to invite**
   - Taps friend avatars to select/deselect
6. **User toggles "Private Challenge"** (optional)
   - Makes challenge invite-only
7. **User taps "Launch Challenge"**
   - Challenge is created
   - Selected friends are added as participants
   - Friends receive notification (future feature)

### Joining a Friends-Only Challenge

1. **User receives invite** (via invite code or direct invite)
2. **System checks if user is friend of creator**
   - If `isFriendsOnly = true` and user is not a friend → Cannot join
   - If `isFriendsOnly = true` and user is a friend → Can join
   - If `isFriendsOnly = false` → Anyone with invite code can join

## Code Structure

### Files Modified

1. **`CreateChallengeView.swift`**
   - Added `FriendsOnlyToggleView`
   - Updated `InviteSectionView` to load friends from Supabase
   - Friends appear first in invite list

2. **`CreateChallengeViewModel.swift`**
   - Added `isFriendsOnly` property
   - Tracks friends-only setting

3. **`FriendsOnlyToggleView.swift`** (NEW)
   - Toggle UI for friends-only setting
   - `FriendsLoaderViewModel` loads friends from Supabase

4. **`ChallengeService.swift`**
   - Challenge creation respects privacy settings
   - Friends are added as participants

### Friends Loading

**`FriendsLoaderViewModel`**:
- Loads accepted friendships from Supabase
- Gets friend profiles
- Converts to `User` model for UI

**Query**:
```sql
SELECT * FROM friends
WHERE (requester_id = :user_id OR addressee_id = :user_id)
AND status = 'accepted'
```

## Permissions Unlocked

### ✅ Implemented

1. **Friend-first invites**: Friends appear first in challenge creation
2. **Friends-only toggle**: UI option to restrict to friends
3. **Private challenges**: Invite-only challenges

### 🔄 Future Enhancements

1. **Friends-only enforcement**: Database-level restriction
2. **Friend-only leaderboards**: Filter leaderboard to friends
3. **Friend-only stats**: Filter stats to friends
4. **Friend notifications**: Notify friends when invited

## Testing

To test friends integration:

1. **Create test accounts** using `CREATE_TEST_ACCOUNTS.md`
2. **Add friends** between accounts
3. **Create challenge** with friends selected
4. **Toggle "Friends Only"** and verify behavior
5. **Create private challenge** and verify invite-only access
6. **Join challenge** as friend and non-friend to test restrictions

## Notes

- Friends are loaded from Supabase `friends` table (accepted friendships only)
- Friends appear first in the invite list automatically
- "Friends Only" toggle is currently UI-only (can be enforced in join logic)
- Private challenges use `isPublic = false` in database
- Future: Add `is_friends_only` column to challenges table for full enforcement

