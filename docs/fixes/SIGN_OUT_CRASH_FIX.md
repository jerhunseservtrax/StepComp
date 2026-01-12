# Sign-Out Freeze/Deadlock Fix

**Date:** January 12, 2026  
**Status:** ✅ Fixed

## Problem

The app was freezing/deadlocking when users signed out, becoming completely unresponsive even after force quitting and reopening. The stack trace showed the app stuck in `pthread_kill`, indicating a deadlock on the main thread. Error messages revealed:

```
Object 0x132eaee00 of class DashboardViewModel deallocated with non-zero retain count 2. 
This object's deinit, or something called from it, may have created a strong reference 
to self which outlived deinit, resulting in a dangling reference.
```

## Root Cause

The freeze was caused by **multiple retain cycles and deadlocks**:

### 1. @MainActor Deadlock
Both `SessionViewModel` and `AuthService` are marked with `@MainActor`, meaning all their methods already run on the main actor. Calling `await MainActor.run` from within these methods causes a deadlock because:
- The code is already running on the main actor
- It tries to schedule work on the main actor and wait for it
- But the main actor is blocked waiting for this work to complete
- This creates a circular wait = deadlock

### 2. Retain Cycle in deinit
`DashboardViewModel.deinit` was calling `stopAutoRefresh()`, which was marked as `nonisolated` and created a `Task { @MainActor in ... }` that captured `self`. This caused:
- `deinit` is called when retain count should be 0
- `stopAutoRefresh()` creates a Task that captures `self`
- This increases the retain count back up while the object is being deallocated
- Result: "deallocated with non-zero retain count" and memory corruption

### 3. Unnecessary dismiss() Call
The SettingsView was calling `dismiss()` after sign-out, trying to manually dismiss a view that was already being removed as part of the view hierarchy transition.

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

**Why:** Since `SessionViewModel` is marked with `@MainActor`, all its methods already execute on the main actor.

### 2. Fixed Retain Cycle in deinit (DashboardViewModel.swift & ProfileViewModel.swift)

**Changed:**
```swift
// Before - RETAIN CYCLE
deinit {
    stopAutoRefresh()  // ❌ Calls nonisolated function that creates Task
}

nonisolated private func stopAutoRefresh() {
    Task { @MainActor in  // ❌ Captures self, increases retain count during dealloc
        refreshTimer?.invalidate()
        refreshTimer = nil
        cancellables.removeAll()
    }
}

// After - FIXED
deinit {
    // Immediately invalidate timer - don't create async tasks in deinit
    refreshTimer?.invalidate()
    refreshTimer = nil
    cancellables.removeAll()
}

private func stopAutoRefresh() {
    refreshTimer?.invalidate()
    refreshTimer = nil
    cancellables.removeAll()
}
```

**Why:** Never create async Tasks or capture `self` in `deinit`. Timer invalidation is synchronous and safe to call directly.

### 3. Removed Unnecessary dismiss() Call (SettingsView.swift)

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

**Why:** When `isAuthenticated` becomes `false`, RootView automatically transitions from `MainTabView` to `OnboardingFlowView`.

### 4. Fixed MainTabView Ownership (MainTabView.swift)

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

**Why:** `MainTabView` should observe the `SessionViewModel` rather than own it.

### 5. Added View Identity Reset (RootView.swift)

**Changed:**
```swift
MainTabView(sessionViewModel: sessionViewModel)
    .id(sessionViewModel.isAuthenticated) // Force view recreation on auth state change
```

**Why:** Forces SwiftUI to completely recreate `MainTabView` when authentication state changes, ensuring clean teardown.

## Technical Details

### Understanding deinit and Retain Cycles

**CRITICAL RULES:**
1. **Never create async Tasks in `deinit`** - They capture `self` and increase retain count during deallocation
2. **Never call `await` in `deinit`** - deinit is synchronous
3. **Never use `nonisolated` functions that create Tasks from `deinit`** - Same retain cycle problem
4. **Timer invalidation is synchronous and safe** - Can be called directly in deinit

### Understanding @MainActor

- `@MainActor` is a Swift concurrency attribute that ensures all code runs on the main thread
- When you're already in a `@MainActor` context, you **don't** need `await MainActor.run`
- Using `await MainActor.run` from within `@MainActor` causes a deadlock

### Tradeoffs

1. **Simplicity**: Direct timer invalidation in deinit is simpler and avoids all async complexity
2. **Safety**: Removing async operations from deinit prevents retain cycles and memory corruption

### Potential Failure Modes

1. **Timer Thread Safety**: Timer invalidation must happen on the thread that created it. Since our timers are created on the main thread and our ViewModels are @MainActor, this is guaranteed safe.

2. **Race Conditions**: If timer fires during deallocation, the weak self check in the timer closure will catch it and prevent crashes.

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
2. `StepComp/ViewModels/DashboardViewModel.swift` - Fixed retain cycle in deinit
3. `StepComp/ViewModels/ProfileViewModel.swift` - Fixed retain cycle in deinit
4. `StepComp/Screens/Settings/SettingsView.swift` - Removed unnecessary `dismiss()` call
5. `StepComp/Navigation/MainTabView.swift` - Changed to `@ObservedObject`
6. `StepComp/App/RootView.swift` - Added `.id()` modifier for view recreation

## Related Issues

This fix addresses critical concurrency and memory management issues. Related documentation:
- [SESSION_PERSISTENCE_FIX.md](./SESSION_PERSISTENCE_FIX.md) - Session restoration on app launch
- [SECURITY_MIGRATION_COMPLETE.md](../features/SECURITY_MIGRATION_COMPLETE.md) - Authentication flow improvements

## Key Lessons

1. **Never call `await MainActor.run` from within a `@MainActor` context** - it will cause a deadlock
2. **Never create async Tasks in `deinit`** - they capture self and create retain cycles
3. **Keep deinit synchronous and simple** - just cleanup, no async work
4. **Timer.invalidate() is synchronous** - safe to call in deinit
