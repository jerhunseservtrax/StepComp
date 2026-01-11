# Notification Badge Refresh Fix - January 6, 2026

## Issue
When users tapped and cleared notifications in the Inbox, the red notification badge on the home screen remained visible, even though the notifications had been marked as read.

## Root Causes

### 1. Wrong Database Table Name
**File:** `StepComp/Screens/Inbox/InboxView.swift` (Line 342)

The code was trying to update the wrong table:
- **Wrong:** `inbox_notifications`
- **Correct:** `notifications`

This meant the database was never being updated when notifications were marked as read.

### 2. Missing Badge Refresh Trigger
After marking notifications as read, the DashboardHeader (which displays the badge) was never notified to refresh its count. The badge count was only refreshed when:
- The view first loaded
- A new notification was created

But NOT when notifications were marked as read or when the inbox was dismissed.

## Solution

### 1. Fixed Database Table Name
Updated `InboxView.swift` line 341 to use the correct table:

```swift
try await supabase
    .from("notifications")  // Changed from "inbox_notifications"
    .update(NotificationUpdate(is_read: true))
    .eq("id", value: notification.id)
    .execute()
```

### 2. Added New Notification Event
**File:** `StepComp/Utilities/NotificationNames.swift`

Added a new NotificationCenter event:
```swift
static let notificationBadgeNeedsRefresh = Notification.Name("notificationBadgeNeedsRefresh")
```

### 3. Post Badge Refresh Event
**File:** `StepComp/Screens/Inbox/InboxView.swift`

Post the refresh event in three places:

#### A. When a notification is tapped and marked as read:
```swift
private func markNotificationAsRead(notification: InboxNotification) async {
    // ... mark as read in database ...
    
    // Notify the badge to refresh
    NotificationCenter.default.post(name: .notificationBadgeNeedsRefresh, object: nil)
}
```

#### B. When a challenge invite is accepted:
```swift
private func acceptChallengeInvite(notification: InboxNotification) async {
    // ... accept invite ...
    await loadNotifications()
    
    // Notify badge to refresh
    NotificationCenter.default.post(name: .notificationBadgeNeedsRefresh, object: nil)
}
```

#### C. When a challenge invite is declined:
```swift
private func declineChallengeInvite(notification: InboxNotification) async {
    // ... decline invite ...
    await loadNotifications()
    
    // Notify badge to refresh
    NotificationCenter.default.post(name: .notificationBadgeNeedsRefresh, object: nil)
}
```

#### D. When the inbox is dismissed:
```swift
.onDisappear {
    // Refresh badge count when inbox is dismissed
    NotificationCenter.default.post(name: .notificationBadgeNeedsRefresh, object: nil)
}
```

### 4. Listen for Badge Refresh Event
**File:** `StepComp/Screens/Home/DashboardHeader.swift`

Added listener to refresh badge count:
```swift
.onReceive(NotificationCenter.default.publisher(for: .notificationBadgeNeedsRefresh)) { _ in
    // Refresh notification count when notifications are marked as read
    Task {
        await loadNotificationUnreadCount()
    }
}
```

## How It Works Now

1. **User opens Inbox** → Notifications load from database
2. **User taps a notification** → 
   - Database updated: `is_read = true` ✅
   - Badge refresh event posted ✅
   - DashboardHeader receives event ✅
   - Badge count reloaded from database ✅
3. **User accepts/declines invite** →
   - Invite processed
   - Notifications reloaded
   - Badge refresh event posted ✅
4. **User closes Inbox** →
   - Badge refresh event posted ✅
   - Badge updates to show correct count ✅

## Testing Checklist

- [ ] Open app with unread notifications (red badge visible)
- [ ] Tap notification icon to open Inbox
- [ ] Tap on a notification to mark it as read
- [ ] Verify notification disappears from list
- [ ] Close Inbox
- [ ] Verify red badge count decreases or disappears
- [ ] Accept a challenge invite
- [ ] Verify badge count updates
- [ ] Decline a challenge invite
- [ ] Verify badge count updates

## Files Modified

1. `StepComp/Screens/Inbox/InboxView.swift`
   - Fixed table name from `inbox_notifications` to `notifications`
   - Added badge refresh notifications in 4 places
   
2. `StepComp/Utilities/NotificationNames.swift`
   - Added `.notificationBadgeNeedsRefresh` event

3. `StepComp/Screens/Home/DashboardHeader.swift`
   - Added listener for badge refresh event

## Related Database

The notification badge queries:
```sql
SELECT COUNT(*) 
FROM notifications 
WHERE user_id = auth.uid() 
  AND is_read = FALSE
```

This query runs:
- On app launch
- When inbox opens
- When a new notification is created
- **NEW:** When notifications are marked as read
- **NEW:** When inbox is dismissed

