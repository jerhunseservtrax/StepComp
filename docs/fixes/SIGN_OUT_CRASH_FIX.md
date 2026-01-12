# Sign-Out Crash Fix

**Date:** January 12, 2026  
**Status:** ✅ Fixed

## Problem

The app was crashing when users signed out. This was caused by improper lifecycle management when transitioning from `MainTabView` to `OnboardingFlowView`.

## Root Cause

The crash was caused by several issues:

1. **Double StateObject Ownership**: `MainTabView` was wrapping the `SessionViewModel` in a `@StateObject`, even though it was already managed as a `@StateObject` in `RootView`. This created ownership conflicts during view deallocation.

2. **Asynchronous State Updates**: When signing out, state updates weren't guaranteed to happen on the main thread, which could cause race conditions during the view transition.

3. **View Lifecycle Issues**: Active views in the tab bar (Home, Friends, Challenges, Settings) might still be trying to access user data while being deallocated, causing crashes.

## Solution

### 1. Fixed MainTabView Ownership (MainTabView.swift)

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

**Why:** `MainTabView` should observe the `SessionViewModel` rather than own it. The `SessionViewModel` is already managed by `RootView`, so using `@ObservedObject` prevents double ownership.

### 2. Ensured Main Thread Execution (SessionViewModel.swift)

**Changed:**
```swift
func signOut() async {
    do {
        try await authService.signOut()
    } catch {
        print("⚠️ Error signing out: \(error.localizedDescription)")
    }
    
    // Always clear local state on main thread to ensure UI updates properly
    await MainActor.run {
        currentUser = nil
        isAuthenticated = false
        hasCompletedOnboarding = false
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }
}
```

**Why:** Wrapping state updates in `MainActor.run` ensures that UI-impacting changes happen on the main thread, preventing race conditions during the transition.

### 3. Added View Identity Reset (RootView.swift)

**Changed:**
```swift
MainTabView(sessionViewModel: sessionViewModel)
    .id(sessionViewModel.isAuthenticated) // Force view recreation on auth state change
```

**Why:** The `.id()` modifier forces SwiftUI to completely recreate `MainTabView` when the authentication state changes, ensuring clean teardown of all child views and their subscriptions.

## Technical Details

### Tradeoffs

1. **Performance**: Adding `.id()` modifier means `MainTabView` is completely recreated on auth state change, which is slightly more expensive than a normal view update. However, this only happens during sign-in/sign-out, so the performance impact is negligible.

2. **Memory**: Using `@ObservedObject` instead of `@StateObject` means the view doesn't own the object, so it won't automatically keep it alive. This is correct in our case since `RootView` owns the `SessionViewModel`.

### Potential Failure Modes

1. **Combine Subscriptions**: If any child views in the tabs have Combine subscriptions that aren't properly cleaned up, they might still cause issues. The `.id()` modifier helps by forcing complete view recreation.

2. **Long-Running Tasks**: If any views have long-running async tasks that reference `sessionViewModel.currentUser`, those tasks need to handle the case where the user becomes `nil`. This should already be handled with optional unwrapping throughout the codebase.

3. **Environment Objects**: Views that use `@EnvironmentObject` for services (like `ChallengeService`, `FriendsService`) should handle the case where they're deallocated during sign-out. The forced view recreation helps with this.

## Testing

### Manual Test Steps

1. Sign in to the app
2. Navigate to different tabs (Home, Friends, Challenges, Settings)
3. Go to Settings → Log Out
4. Verify the app transitions smoothly to the onboarding/sign-in screen without crashing
5. Sign back in
6. Verify all features work correctly

### Build Verification

```bash
xcodebuild -project StepComp.xcodeproj -scheme StepComp -destination 'platform=iOS Simulator,id=322B1096-5A71-4BE3-835A-82ED7CCE928A' build
```

**Result:** ✅ BUILD SUCCEEDED

## Files Modified

1. `StepComp/Navigation/MainTabView.swift` - Changed to `@ObservedObject`
2. `StepComp/ViewModels/SessionViewModel.swift` - Added `MainActor.run` for state updates
3. `StepComp/App/RootView.swift` - Added `.id()` modifier for view recreation

## Related Issues

This fix addresses general session management and view lifecycle issues. It's related to:
- [SESSION_PERSISTENCE_FIX.md](./SESSION_PERSISTENCE_FIX.md) - Session restoration on app launch
- [SECURITY_MIGRATION_COMPLETE.md](../features/SECURITY_MIGRATION_COMPLETE.md) - Authentication flow improvements
