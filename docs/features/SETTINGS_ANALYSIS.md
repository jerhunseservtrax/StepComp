# Settings Page Analysis - Active vs Static Elements

## ✅ ACTIVE ELEMENTS (Working)

### Profile Section
- ✅ **Avatar Display** - Shows user avatar/initials
- ✅ **Display Name** - Shows user's name
- ✅ **Stats Cards** - Shows total steps, distance, streak, avg steps
- ✅ **Edit Profile Button** - Opens ProfileSettingsView sheet
- ✅ **Auto-refresh** - Updates every 30 seconds

### Connectivity Card
- ⚠️ **HealthKit Toggle** - Partially working (shows state, but doesn't actually enable/disable)
- ⚠️ **Apple Watch Setup** - Partially working (just toggles local state, no actual setup)

### Notifications Card
- ⚠️ **Daily Recap Toggle** - Static (changes local state only, not persisted)
- ⚠️ **Leaderboard Alerts Toggle** - Static (changes local state only, not persisted)
- ⚠️ **Motivational Nudges Toggle** - Static (changes local state only, not persisted)

### Preferences Card
- ✅ **Dark Mode Toggle** - ACTIVE (syncs with ThemeManager)
- ⚠️ **Unit System Selector** - Static (changes local state only, not persisted)
- ✅ **Public Profile Toggle** - ACTIVE (calls FriendsService.setPublicProfile)
- ✅ **Height & Weight Editor** - ACTIVE (opens EditHeightWeightSheet, syncs with HealthKit)
- ✅ **Daily Step Goal Editor** - ACTIVE (opens EditDailyStepGoalSheet, full functionality)

### Support & Legal Card
- ✅ **Feedback Board** - ACTIVE (opens FeedbackBoardView)
- ✅ **FAQ / Help Center** - ACTIVE (opens FAQView)
- ✅ **Privacy Policy** - ACTIVE (opens PrivacyPolicyView)
- ✅ **About Us** - ACTIVE (opens AboutUsView)

### Developer Card
- ✅ **Test Supabase Connection** - ACTIVE (opens SupabaseTestView)
- ✅ **Test HealthKit Connection** - ACTIVE (opens HealthKitTestView)

### Account Actions
- ⚠️ **Log Out Button (iPad)** - ACTIVE in header (line 597), but...
- ❌ **Log Out Button (Main Content)** - BROKEN (line 670) - references undefined `showingSignOutAlert`
- ❌ **Delete Account Button** - BROKEN (line 693) - references undefined `showingDeleteAccountAlert` and `isDeletingAccount`

## ❌ STATIC/BROKEN ELEMENTS (Not Working)

### 1. HealthKit Toggle (Line 747)
**Issue**: Toggle changes `@Binding var healthKitEnabled` but doesn't actually request/revoke HealthKit permissions
**Fix Needed**: 
- Add HealthKitService method to request permissions
- Handle authorization callback
- Update toggle based on actual authorization status

### 2. Apple Watch Setup (Line 758)
**Issue**: Just toggles a local boolean, no actual WatchOS communication
**Fix Needed**:
- Check for paired Apple Watch
- Show instructions or open Watch app
- Or remove feature if not implemented

### 3. Notification Toggles (Lines 797, 806, 815)
**Issue**: Changes only local `@State` variables, not persisted to UserDefaults or database
**Fix Needed**:
- Save preferences to UserDefaults
- Optionally sync to database (profiles table)
- Load on app start

### 4. Unit System Selector (Line 871-889)
**Issue**: Changes only local `@State` variable, not persisted
**Fix Needed**:
- Save to UserDefaults
- Apply throughout app (distance displays, etc.)
- Load on app start

### 5. Logout Button in Main Content (Line 670-690)
**Issue**: References `showingSignOutAlert` which doesn't exist in `SettingsMainContent` scope
**Current Code**:
```swift
Button(action: {
    showingSignOutAlert = true  // ❌ Not defined here
}) {
    // ... UI code
}
```
**Fix**: Use the `onSignOut` closure that's passed in

### 6. Delete Account Button in Main Content (Line 693-710)
**Issue**: References `showingDeleteAccountAlert` and `isDeletingAccount` which don't exist in `SettingsMainContent` scope
**Fix**: Pass these as parameters or use closure

## 🔧 FIXES REQUIRED

### Priority 1: Critical Functionality
1. ✅ Fix logout button in main content
2. ✅ Fix delete account button in main content

### Priority 2: User Preferences (Should Persist)
3. ⚠️ Implement notification preferences persistence
4. ⚠️ Implement unit system persistence
5. ⚠️ Fix HealthKit toggle to actually control permissions

### Priority 3: Optional/Future
6. ⚠️ Implement Apple Watch pairing/setup (or remove)

## DETAILED FIX PLAN

### Fix 1: Logout Button (CRITICAL)
**File**: `SettingsView.swift` Line 670
**Change**:
```swift
// OLD
Button(action: {
    showingSignOutAlert = true
})

// NEW
Button(action: onSignOut)
```

### Fix 2: Delete Account Button (CRITICAL)
**File**: `SettingsView.swift` Line 693
**Approach**: Pass required state/closures as parameters to `SettingsMainContent`

**Update `SettingsMainContent` signature**:
```swift
struct SettingsMainContent: View {
    // ... existing bindings
    let sessionViewModel: SessionViewModel?
    let onSignOut: () -> Void
    let onDeleteAccount: () -> Void  // ADD THIS
    let isDeletingAccount: Bool      // ADD THIS
```

### Fix 3: Notification Preferences
**File**: `SettingsView.swift`
**Add to `onAppear`**:
```swift
.onAppear {
    // Load saved preferences
    dailyRecap = UserDefaults.standard.bool(forKey: "notif_dailyRecap")
    leaderboardAlerts = UserDefaults.standard.bool(forKey: "notif_leaderboardAlerts")
    motivationalNudges = UserDefaults.standard.bool(forKey: "notif_motivationalNudges")
}
```

**Add onChange handlers**:
```swift
.onChange(of: dailyRecap) { _, newValue in
    UserDefaults.standard.set(newValue, forKey: "notif_dailyRecap")
}
.onChange(of: leaderboardAlerts) { _, newValue in
    UserDefaults.standard.set(newValue, forKey: "notif_leaderboardAlerts")
}
.onChange(of: motivationalNudges) { _, newValue in
    UserDefaults.standard.set(newValue, forKey: "notif_motivationalNudges")
}
```

### Fix 4: Unit System Persistence
**File**: `SettingsView.swift`
**Add to `onAppear`**:
```swift
.onAppear {
    // Load saved unit system
    if let saved = UserDefaults.standard.string(forKey: "unitSystem") {
        unitSystem = saved == "metric" ? .metric : .imperial
    }
}
```

**Add onChange handler**:
```swift
.onChange(of: unitSystem) { _, newValue in
    UserDefaults.standard.set(
        newValue == .metric ? "metric" : "imperial",
        forKey: "unitSystem"
    )
}
```

### Fix 5: HealthKit Toggle
**File**: `SettingsView.swift` / `ConnectivityCard`
**Current Issue**: Toggle changes binding but doesn't request permissions

**Option A** (Simple): Make it read-only, redirect to Settings app
```swift
Toggle("", isOn: .constant(healthKitEnabled))
    .disabled(true)
// Add button to open Settings
Button("Open Settings") {
    if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
    }
}
```

**Option B** (Functional): Request permissions on toggle
```swift
Toggle("", isOn: Binding(
    get: { healthKitEnabled },
    set: { newValue in
        if newValue {
            Task {
                await healthKitService.requestAuthorization()
                healthKitEnabled = healthKitService.isAuthorized
            }
        } else {
            // Can't revoke, must redirect to Settings
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }
))
```

### Fix 6: Apple Watch Setup
**Recommendation**: Remove or implement properly

**Option A** (Remove): Delete the row entirely
**Option B** (Stub): Show "Coming Soon" message
**Option C** (Implement): Use WatchConnectivity framework

## SUMMARY

| Category | Total | Active | Static | Broken |
|----------|-------|--------|--------|--------|
| Toggles | 7 | 2 | 5 | 0 |
| Buttons | 10 | 7 | 0 | 3 |
| Editors | 2 | 2 | 0 | 0 |
| Links | 4 | 4 | 0 | 0 |
| **TOTAL** | **23** | **15** | **5** | **3** |

**Active Rate**: 65% (15/23)
**Broken Rate**: 13% (3/23)
**Static Rate**: 22% (5/23)

## IMPLEMENTATION ORDER

1. ✅ Fix critical broken buttons (logout, delete account)
2. ✅ Add persistence for notification preferences
3. ✅ Add persistence for unit system
4. ⚠️ Decide on HealthKit toggle approach (read-only vs functional)
5. ⚠️ Decide on Apple Watch feature (remove vs implement vs stub)

