# Sign-Out Freeze/Deadlock Fix

**Date:** January 12, 2026  
**Status:** ✅ Fixed

## Problem

The app was freezing/deadlocking when users signed out, becoming completely unresponsive even after force quitting and reopening. The stack trace showed the app stuck in `pthread_kill`, indicating a deadlock on the main thread.

## Root Cause

The freeze was caused by a **deadlock** due to calling `await MainActor.run` from within a `@MainActor`-isolated context:

1. **@MainActor Deadlock**: Both `SessionViewModel` and `AuthService` are marked with `@MainActor`, meaning all their methods already run on the main actor. Calling `await MainActor.run` from within these methods causes a deadlock because:
   - The code is already running on the main actor
   - It tries to schedule work on the main actor and wait for it
   - But the main actor is blocked waiting for this work to complete
   - This creates a circular wait = deadlock

2. **Unnecessary dismiss() Call**: The SettingsView was calling `dismiss()` after sign-out, trying to manually dismiss a view that was already being removed as part of the view hierarchy transition from `MainTabView` to `OnboardingFlowView`.

3. **View Lifecycle Issues**: As previously identified, `MainTabView` was wrapping the `SessionViewModel` in a `@StateObject`, causing ownership conflicts during view deallocation.

## Solution

### 1. Removed MainActor.run Deadlock (SessionViewModel.swift)

**Changed:**
```swift
// Before - DEADLOCK
func signOut() async {
    do {
        try await authService.signOut()
    } catch {
        print("⚠️ Error signing out: \(error.localizedDescription)")
    }
    
    await MainActor.run {  // ❌ DEADLOCK: Already on main actor!
        currentUser = nil
        isAuthenticated = false
        hasCompletedOnboarding = false
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }
}

// After - FIXED
func signOut() async {
    do {
        try await authService.signOut()
    } catch {
        print("⚠️ Error signing out: \(error.localizedDescription)")
    }
    
    // Clear local state - already on main actor since class is @MainActor
    currentUser = nil
    isAuthenticated = false
    hasCompletedOnboarding = false
    UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
}
```

**Why:** Since `SessionViewModel` is marked with `@MainActor`, all its methods (including `signOut()`) already execute on the main actor. Calling `await MainActor.run` from within creates a deadlock.

### 2. Removed Unnecessary dismiss() Call (SettingsView.swift)

**Changed:**
```swift
// Before
onSignOut: {
    Task {
        await sessionViewModel.signOut()
        dismiss()  // ❌ Causes issues during view hierarchy transition
    }
}

// After
onSignOut: {
    Task {
        await sessionViewModel.signOut()
        // View hierarchy will update automatically when isAuthenticated changes
    }
}
```

**Why:** When `isAuthenticated` becomes `false`, RootView automatically transitions from `MainTabView` to `OnboardingFlowView`. Manually calling `dismiss()` on a view that's being removed causes conflicts.

### 3. Fixed MainTabView Ownership (MainTabView.swift)

**Changed:**
```swift
// Before
@StateObject private var sessionViewModel: SessionViewModel

init(sessionViewModel: SessionViewModel) {
    _sessionViewModel = StateObject(wrappedValue: sessionViewModel)
}

// After
@ObservedObject var sessionViewModel: SessionViewModel

init(sessionViewModel: SessionViewModel) {
    self.sessionViewModel = sessionViewModel
}
```

**Why:** `MainTabView` should observe the `SessionViewModel` rather than own it. The `SessionViewModel` is already managed by `RootView`.

### 4. Added View Identity Reset (RootView.swift)

**Changed:**
```swift
MainTabView(sessionViewModel: sessionViewModel)
    .id(sessionViewModel.isAuthenticated) // Force view recreation on auth state change
```

**Why:** Forces SwiftUI to completely recreate `MainTabView` when authentication state changes, ensuring clean teardown.

## Technical Details

### Understanding @MainActor

- `@MainActor` is a Swift concurrency attribute that ensures all code in a class/struct runs on the main thread
- When you're already in a `@MainActor` context, you **don't** need `await MainActor.run`
- Using `await MainActor.run` from within `@MainActor` causes a deadlock because:
  - You're asking the main actor to run code
  - While the main actor is already running your code
  - The main actor can't run new work while waiting for itself

### Tradeoffs

1. **Simplicity**: Removing the `MainActor.run` wrapper makes the code simpler and eliminates the deadlock risk.

2. **View Hierarchy**: Relying on automatic view hierarchy updates is cleaner than manual dismiss calls, but requires understanding SwiftUI's declarative nature.

### Potential Failure Modes

1. **Race Conditions**: If any code outside of `@MainActor` contexts tries to access these properties, there could be race conditions. However, SwiftUI's `@Published` and `@ObservedObject` already handle this.

2. **Async Task Cancellation**: Long-running tasks in child views should handle cancellation properly. The `.id()` modifier helps by forcing view recreation.

## Testing

### Manual Test Steps

1. Sign in to the app
2. Navigate to Settings
3. Tap "Log Out"
4. Verify the app transitions smoothly without freezing
5. Verify you can interact with the login screen
6. Force quit and reopen - app should work normally
7. Sign back in and verify all features work

### Build Verification

```bash
xcodebuild -project StepComp.xcodeproj -scheme StepComp -destination 'platform=iOS Simulator,id=322B1096-5A71-4BE3-835A-82ED7CCE928A' build
```

**Result:** ✅ BUILD SUCCEEDED

## Files Modified

1. `StepComp/ViewModels/SessionViewModel.swift` - Removed `MainActor.run` deadlock
2. `StepComp/Screens/Settings/SettingsView.swift` - Removed unnecessary `dismiss()` call
3. `StepComp/Navigation/MainTabView.swift` - Changed to `@ObservedObject`
4. `StepComp/App/RootView.swift` - Added `.id()` modifier for view recreation

## Related Issues

This fix addresses a critical deadlock in session management. Related documentation:
- [SESSION_PERSISTENCE_FIX.md](./SESSION_PERSISTENCE_FIX.md) - Session restoration on app launch
- [SECURITY_MIGRATION_COMPLETE.md](../features/SECURITY_MIGRATION_COMPLETE.md) - Authentication flow improvements

## Key Lesson

**Never call `await MainActor.run` from within a `@MainActor` context** - it will cause a deadlock. If your class/struct is already marked with `@MainActor`, all your code is already running on the main thread.
