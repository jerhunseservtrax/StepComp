# Chat Button Implementation Guide

## Overview

This guide documents the implementation of a chat button in the dashboard header that provides quick access to all challenge chats with unread message indicators.

## Features Implemented

### 1. Chat Button in Dashboard Header
- **Location**: Next to the notification bell icon in `DashboardHeader`
- **Icon**: `bubble.left.and.bubble.right.fill`
- **Indicator**: Red dot when there are unread messages across any chat
- **Functionality**: Opens a sheet with all active chats

### 2. Chat List View
- **File**: `StepComp/Screens/Chat/ChatListView.swift`
- **Features**:
  - Displays all challenges the user is a member of
  - Shows last message preview
  - Shows timestamp of last message (e.g., "5m ago", "2h ago", "Yesterday")
  - Red badge with unread count per chat
  - Sorted by most recent message first
  - Empty state when no chats exist
  - Pull-to-refresh functionality
  - Tap to navigate to specific chat

### 3. Chat List ViewModel
- **File**: `StepComp/ViewModels/ChatListViewModel.swift`
- **Responsibilities**:
  - Fetches all challenges user is in
  - Gets unread count for each challenge
  - Gets last message for each challenge
  - Calculates total unread count across all chats
  - Provides formatted time strings

### 4. Chat Preview Model
- **File**: `StepComp/Models/ChatPreview.swift`
- **Properties**:
  - `id`: Challenge ID
  - `challengeName`: Name of the challenge
  - `lastMessage`: Content of the last message
  - `lastMessageTime`: When the last message was sent
  - `unreadCount`: Number of unread messages
  - `displayTime`: Formatted time string (computed)
  - `hasUnread`: Boolean for badge indicator (computed)

## How It Works

### User Flow
1. User sees the dashboard header with notification bell and chat bubble icons
2. If there are unread messages in any chat, a red dot appears on the chat icon
3. User taps the chat icon
4. Sheet opens showing all chats sorted by most recent activity
5. Each chat shows:
   - Challenge name
   - Last message preview
   - Time since last message
   - Unread count badge (if any)
6. User taps on a chat
7. Sheet dismisses and navigates to the specific challenge chat
8. Messages are marked as read when user views the chat

### Real-time Updates
- When a new message is received, `NotificationCenter` posts a `chatMessageReceived` notification
- `DashboardHeader` listens for this notification and refreshes the unread count
- The red dot indicator updates automatically

## Database Integration

### Tables Used
1. **challenges**: Main challenge information
2. **challenge_members**: Links users to challenges they're in
3. **challenge_messages**: All chat messages
4. **challenge_message_reads**: Tracks which messages each user has read

### Database Functions Used
1. **get_challenge_unread_count**: Returns unread message count for a challenge
   - Parameters: `p_challenge_id` (UUID)
   - Returns: INTEGER
   - Only counts messages from other users that haven't been read

### Queries
```swift
// Get user's challenges
let memberRecords = await supabase
    .from("challenge_members")
    .select()
    .eq("user_id", value: userId)
    
// Get challenge info
let challenges = await supabase
    .from("challenges")
    .select("id, name")
    .in("id", values: challengeIds)

// Get unread count per challenge
let count = await supabase
    .rpc("get_challenge_unread_count", params: ["p_challenge_id": challengeId])

// Get last message
let lastMessage = await supabase
    .from("challenge_messages")
    .select("id, content, created_at")
    .eq("challenge_id", value: challengeId)
    .eq("is_deleted", value: false)
    .order("created_at", ascending: false)
    .limit(1)
```

## Files Modified

### New Files
1. `StepComp/Models/ChatPreview.swift` - Chat preview model
2. `StepComp/ViewModels/ChatListViewModel.swift` - Chat list logic
3. `StepComp/Screens/Chat/ChatListView.swift` - Chat list UI

### Modified Files
1. `StepComp/Screens/Home/DashboardHeader.swift`
   - Added chat button next to notification button
   - Added unread count tracking for both buttons
   - Added navigation to chat list
   - Added real-time update listener
   
2. `StepComp/ViewModels/ChallengeChatViewModel.swift`
   - Added notification posting when new messages received
   - Added `Notification.Name.chatMessageReceived` extension

## UI/UX Details

### Visual Design
- **Chat Icon**: Two speech bubbles (matches messaging theme)
- **Unread Indicator**: Small red dot (minimalist, non-intrusive)
- **List Style**: iOS standard inset grouped list
- **Empty State**: Icon, title, description (consistent with app design)
- **Color Scheme**: Primary yellow accents, system colors

### Interaction Design
- **Tap Areas**: 40x40pt minimum (accessibility)
- **Badges**: Circular with count (standard iOS pattern)
- **Time Format**: Relative times (5m ago, 2h ago, etc.)
- **Message Preview**: 2-line truncation with ellipsis
- **Loading State**: Yellow spinner (brand consistency)

## Testing Checklist

- [ ] Chat button appears in dashboard header
- [ ] Red dot shows when there are unread messages
- [ ] Red dot hides when all messages are read
- [ ] Tapping chat button opens chat list
- [ ] Chat list shows all challenges user is in
- [ ] Chats are sorted by most recent message
- [ ] Last message preview displays correctly
- [ ] Timestamp shows relative time correctly
- [ ] Unread badge shows correct count per chat
- [ ] Tapping a chat opens that challenge's chat
- [ ] Messages are marked as read when chat is opened
- [ ] Pull-to-refresh works in chat list
- [ ] Empty state shows when user has no chats
- [ ] Real-time updates work (red dot updates on new message)

## Performance Considerations

### Optimizations
1. **Caching**: Chat listViewModel stores results in memory
2. **Efficient Queries**: Only fetches necessary fields (id, name, content, created_at)
3. **Lazy Loading**: Uses `LazyVStack` for chat list
4. **Debouncing**: Real-time updates are throttled via NotificationCenter

### Database Indexes
The following indexes ensure fast queries:
- `idx_challenge_messages_challenge_time` on `challenge_messages(challenge_id, created_at DESC)`
- `idx_message_reads_user` on `challenge_message_reads(user_id)`
- `idx_challenge_messages_not_deleted` on `challenge_messages` WHERE `is_deleted = FALSE`

## Future Enhancements

### Potential Improvements
1. **Typing Indicators**: Show "User is typing..." in preview
2. **Read Receipts**: Show checkmarks when message is read
3. **Push Notifications**: Alert user of new messages when app is closed
4. **Message Reactions**: Quick emoji reactions in preview
5. **Challenge Avatars**: Display challenge image or participant avatars
6. **Search**: Search across all chat messages
7. **Pinned Chats**: Pin important chats to top of list
8. **Archive**: Archive old or inactive chats
9. **Mute**: Mute notifications for specific chats

## Troubleshooting

### Issue: Red dot not updating
**Solution**: Check that `NotificationCenter.default.post(name: .chatMessageReceived, object: nil)` is being called when messages are received

### Issue: Unread count incorrect
**Solution**: Verify `challenge_message_reads` table is being populated correctly when messages are marked as read

### Issue: Chat list empty but user is in challenges
**Solution**: Check that `challenge_members` table has entries for the user

### Issue: Last message not showing
**Solution**: Ensure messages have `is_deleted = false` and `created_at` timestamp

## Code Examples

### Opening Chat Programmatically
```swift
// From any view with access to navigationPath
navigationPath.append(ChatDestination.chat(
    challengeId: "challenge-uuid",
    challengeName: "Challenge Name"
))
```

### Getting Total Unread Count
```swift
let viewModel = ChatListViewModel(userId: currentUserId)
await viewModel.loadChats()
let totalUnread = viewModel.totalUnreadCount
```

### Marking All Messages as Read
```swift
// Called automatically in ChallengeChatView.onAppear
await chatViewModel.markAllAsRead()
```

## Integration Notes

### Prerequisites
- User must be authenticated (have valid session)
- User must be a member of at least one challenge
- Database tables must exist (`challenge_messages`, `challenge_message_reads`)
- RPC function `get_challenge_unread_count` must be deployed

### Dependencies
- **Supabase**: For database queries and real-time
- **SwiftUI**: For UI components
- **Foundation**: For date formatting and notifications

## Summary

The chat button implementation provides users with:
✅ Quick access to all their chats from the dashboard
✅ Visual indicator for unread messages
✅ Preview of recent activity per chat
✅ One-tap navigation to specific chats
✅ Real-time updates of unread status

This improves user engagement by making chat more accessible and reducing the steps needed to view messages.

