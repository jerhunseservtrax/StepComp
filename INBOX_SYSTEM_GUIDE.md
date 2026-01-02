# 🎯 INBOX & CHALLENGE INVITE SYSTEM - Implementation Guide

## 📋 Overview

This implements a complete inbox and challenge invite system with:
- Challenge invite functionality
- Friend request notifications
- Inbox with unread count badge
- Accept/decline invite actions

---

## 🗄️ Database Setup

### **Run First:** `IMPLEMENT_INBOX_SYSTEM.sql`

Creates:
1. **`challenge_invites` table** - Stores invite records
2. **`inbox_notifications` table** - General notification system
3. **RPC Functions:**
   - `send_challenge_invites(challenge_id, friend_ids[])`
   - `accept_challenge_invite(invite_id)`
   - `decline_challenge_invite(invite_id)`
   - `get_unread_inbox_count()`

---

## 📱 Swift Implementation Status

### ✅ Completed

1. **Models** (`InboxModels.swift`):
   - `InboxNotification` - Notification model
   - `ChallengeInvite` - Invite model
   - `FriendForInvite` - Friend selection model

### 🚧 TODO - Need to Create

2. **Services:**
   - `InboxService.swift` - Inbox API calls
   - Update `ChallengeService` with invite methods

3. **ViewModels:**
   - `InboxViewModel.swift` - Manage inbox state
   - `InviteFriendsViewModel.swift` - Friend selection logic

4. **Views:**
   - `InboxView.swift` - Inbox screen
   - `InviteFriendsView.swift` - Friend selection sheet
   - `InboxBadge.swift` - Unread count badge component

5. **Navigation:**
   - Add inbox button to navigation bar
   - Connect invite button in challenge details

---

## 🎨 User Flow

### **1. Inviting Friends to Challenge**
```
Challenge Details Screen
    ↓
[Invite Button] (top right)
    ↓
Friend Selection Sheet Opens
    ↓
Shows friends list with:
  - ✅ Already in challenge (disabled)
  - ➕ Not in challenge (selectable)
    ↓
User selects friends
    ↓
[Confirm] button
    ↓
Invites sent via RPC
    ↓
Inbox notifications created for invitees
```

### **2. Receiving & Accepting Invites**
```
Inbox Icon (top of screen)
Badge shows unread count
    ↓
User taps Inbox
    ↓
List of notifications:
  - Challenge Invites
  - Friend Requests
  - Achievements
    ↓
Tap on Challenge Invite
    ↓
[Accept] or [Decline] buttons
    ↓
Action processed via RPC
    ↓
User added to challenge (if accepted)
Notification marked as read
```

---

## 🔧 Implementation Steps

### **Step 1: Run SQL** ✅ DONE
```sql
-- Run IMPLEMENT_INBOX_SYSTEM.sql in Supabase
```

### **Step 2: Create Services**
```swift
// InboxService.swift
- loadNotifications()
- markAsRead(id)
- getUnreadCount()

// Update ChallengeService.swift
- inviteFriends(challengeId, friendIds)
- acceptInvite(inviteId)
- declineInvite(inviteId)
```

### **Step 3: Create ViewModels**
```swift
// InboxViewModel
- @Published var notifications: [InboxNotification]
- @Published var unreadCount: Int
- func loadNotifications()
- func acceptChallengeInvite(notificationId, inviteId)
- func declineInvite(inviteId)

// InviteFriendsViewModel
- @Published var friends: [FriendForInvite]
- @Published var selectedFriendIds: [String]
- func loadFriends(challengeId)
- func sendInvites()
```

### **Step 4: Create UI Views**
```swift
// InboxView - Main inbox screen
// InviteFriendsView - Friend selection sheet
// InboxBadge - Unread count component
```

### **Step 5: Update Navigation**
```swift
// Add inbox button to main navigation
// Connect invite button in GroupDetailsView
```

---

## 🎯 Key Features

### **Inbox Screen**
- List of all notifications
- Unread badge on icon
- Pull to refresh
- Swipe to mark as read
- Tap to view details
- Different icons per type

### **Invite Friends Sheet**
- Search friends
- Filter by already in challenge
- Multi-select with checkboxes
- Confirm button shows count
- Loading states
- Success/error messages

### **Notifications**
- 🔵 Friend requests
- 🟡 Challenge invites
- 🟣 Challenge updates
- 🟠 Achievements

---

## 🔒 Security (RLS)

All tables have proper Row Level Security:
- Users can only see their own notifications
- Only challenge members can invite friends
- Invitees can accept/decline their own invites
- Duplicate invites prevented by unique constraint

---

## 📊 Database Schema

### `challenge_invites`
```
id, challenge_id, inviter_id, invitee_id, 
status (pending/accepted/declined), 
created_at, updated_at
```

### `inbox_notifications`
```
id, user_id, type, title, message, 
related_id, is_read, created_at
```

---

## ✅ Next Steps

1. **Run SQL** - `IMPLEMENT_INBOX_SYSTEM.sql` ✅
2. **Create Swift files** - Services, ViewModels, Views
3. **Wire up UI** - Add inbox button, connect invite button
4. **Test flow** - Send invite → receive → accept → join challenge

---

## 🎉 Expected Result

After implementation:
- Inbox icon with badge in navigation
- Tap to see notifications
- Challenge invite button works
- Select friends → Send invites
- Friends receive notifications
- Accept/decline → Join challenge

---

**Status:** SQL schema ready ✅  
**Next:** Create Swift implementation  
**Priority:** High - Core social feature

