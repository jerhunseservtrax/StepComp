# Friends System Implementation Guide

## Overview
This document describes the complete friends system implementation with public profiles, friend requests, and invite links.

## Database Setup

### 1. Run the Migration SQL
Execute `FRIENDS_SYSTEM_MIGRATION.sql` in your Supabase Dashboard → SQL Editor.

This creates:
- `friendships` table with duplicate prevention (`pair_low`/`pair_high`)
- `friend_invites` table for private discovery
- RLS policies for all tables
- RPC functions: `create_friend_invite()` and `consume_friend_invite()`

### 2. Key Database Features
- **Public Profile Toggle**: `profiles.public_profile` (default: false)
- **Duplicate Prevention**: Unique constraint on `(pair_low, pair_high)` prevents duplicate friendships
- **Secure Invites**: Cryptographically secure tokens with expiration
- **One-time Use**: Invites are marked as used after consumption

## Swift Implementation

### Models Created
1. **Profile.swift** - User profile with public visibility
2. **Friendship.swift** - Friend relationship with status
3. **FriendListItem.swift** - UI-friendly friend list item
4. **InviteResponses.swift** - RPC response models

### Services
- **FriendsService.swift** - All backend operations:
  - `setPublicProfile()` - Toggle public visibility
  - `searchPublicProfiles()` - Search only public profiles
  - `listMyFriendships()` - Get all friendships
  - `sendFriendRequest()` - Send friend request
  - `acceptRequest()` - Accept incoming request
  - `removeFriendship()` - Remove friend
  - `createInviteRPC()` - Generate invite token
  - `consumeInviteRPC()` - Use invite token

### ViewModels
- **FriendsViewModel.swift** - Manages:
  - Two tabs (Friends/Discover)
  - Edit mode for removing friends
  - Friend list and search results
  - Invite link generation

### Views
- **FriendsView.swift** - Main view with two tabs
- **FriendRow.swift** - Friend list item with actions
- **DiscoverProfileRow.swift** - Search result row
- **PrivateDiscoveryCard.swift** - Invite link sharing card
- **InviteAcceptView.swift** - Deep link invite acceptance

### Deep Links
- **DeepLinkRouter.swift** - Handles `je.stepcomp://friend-invite?token=...`
- Integrated into `RootView` and `StepCompApp`

## Features

### 1. Public Profile Toggle
- Located in Settings → App Preferences
- When ON: Profile appears in Discover search
- When OFF: Only link-based friending works

### 2. Two-Tab Interface
- **Friends Tab**: Shows accepted friends, incoming/outgoing requests
- **Discover Tab**: Search public profiles

### 3. Edit Mode
- Tap "Edit" button to enter edit mode
- Remove friends by tapping minus button
- Tap "Done" to exit edit mode

### 4. Invite Links
- Generate secure invite tokens via RPC
- Share via system share sheet
- Deep link handling: `je.stepcomp://friend-invite?token=...`
- One-time use with expiration (default: 7 days)

## Usage Flow

### Adding Friends (Public Profile ON)
1. Go to Friends → Discover tab
2. Search for username
3. Tap "Add" on desired profile
4. Request sent (pending status)

### Adding Friends (Public Profile OFF)
1. Go to Friends → Friends tab
2. Scroll to "Invite Link" section
3. Tap "Share Friend Invite Link"
4. Share via Messages, Email, etc.
5. Recipient opens link → Auto-creates friend request

### Accepting Requests
1. Go to Friends → Friends tab
2. See incoming requests at top
3. Tap "Accept" button
4. Friendship status changes to "accepted"

### Removing Friends
1. Go to Friends → Friends tab
2. Tap "Edit" button
3. Tap minus button on friend to remove
4. Tap "Done" to finish

## Security Features

1. **RLS Policies**: All tables protected by Row Level Security
2. **RPC Functions**: Secure invite creation/consumption
3. **Token Security**: Cryptographically secure random tokens
4. **Expiration**: Invites expire after 7 days (configurable)
5. **One-time Use**: Invites marked as used after consumption

## Next Steps

1. **Run the SQL migration** in Supabase Dashboard
2. **Test the implementation**:
   - Toggle public profile in Settings
   - Search for profiles in Discover tab
   - Send/accept friend requests
   - Generate and share invite links
3. **Configure URL Scheme** (if not already):
   - In Xcode: Target → Info → URL Types
   - Add: `je.stepcomp` (or your bundle ID)

## Troubleshooting

### Invite links not working
- Check URL scheme is configured in Info.plist
- Verify deep link handler in `StepCompApp.swift`
- Check token format in URL

### Profiles not appearing in search
- Verify `public_profile = true` in database
- Check RLS policy allows reading public profiles
- Ensure user is authenticated

### Friend requests not working
- Check RLS policies on `friendships` table
- Verify user IDs match between app and database
- Check for duplicate prevention errors

