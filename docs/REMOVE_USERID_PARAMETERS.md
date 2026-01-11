# 🔧 Remove userId Parameters - Complete Guide

## Why This Matters

**Security Principle:** Never trust client-provided user IDs.

**Current Risk:**
```swift
// ❌ Client can lie about userId
func syncSteps(userId: "someone_elses_id") {
    // Oops! Just updated wrong user
}
```

**Secure Approach:**
```swift
// ✅ Server derives userId from JWT
func syncSteps() {
    // Server knows who you are from token
}
```

---

## Files to Update

### 1. StepSyncService.swift ✅ DONE

**Before:**
```swift
func syncTodayStepsToProfile(userId: String) async
func syncStepsToChallenges(userId: String, challengeService: ChallengeService) async
func syncAll(userId: String, challengeService: ChallengeService) async
```

**After:**
```swift
func syncTodayStepsToProfile() async
func syncStepsToChallenges(challengeService: ChallengeService) async
func syncAll(challengeService: ChallengeService) async
```

---

### 2. DashboardViewModel.swift

**Location:** `StepComp/ViewModels/DashboardViewModel.swift`

**Find:**
```swift
private var userId: String
```

**Action:** Keep for now (used for filtering), but ensure it's only used for READ operations, never WRITE.

**Find:**
```swift
await stepSyncService.syncAll(userId: userId, challengeService: challengeService)
```

**Replace with:**
```swift
await stepSyncService.syncAll(challengeService: challengeService)
```

---

### 3. ChallengesViewModel.swift

**Location:** `StepComp/ViewModels/ChallengesViewModel.swift`

**Find:**
```swift
private let userId: String

init(challengeService: ChallengeService, userId: String) {
    self.userId = userId
}
```

**Keep:** This is OK for filtering (read operations)

**But ensure:** All database writes use RPC functions that derive userId from JWT

---

### 4. ChallengeService.swift

**Location:** `StepComp/Services/ChallengeService.swift`

#### 4.1 Remove userId from sync functions

**Find:**
```swift
func syncTodayStepsToAllChallenges(userId: String, healthKitService: HealthKitService) async
```

**Replace with:**
```swift
func syncTodayStepsToAllChallenges(healthKitService: HealthKitService) async {
    // Get userId from current session
    #if canImport(Supabase)
    guard let session = try? await supabase.auth.session else {
        print("⚠️ No active session")
        return
    }
    let userId = session.user.id.uuidString
    // ... rest of function
    #endif
}
```

#### 4.2 Replace direct writes with RPC

**Find:**
```swift
try await supabase
    .from("challenge_members")
    .update(["total_steps": totalSteps, "daily_steps": dailyStepsJson])
    .eq("challenge_id", value: challengeId)
    .eq("user_id", value: userId)
    .execute()
```

**Replace with:**
```swift
// This is now handled by sync_daily_steps() RPC
// No need to manually update challenge_members
```

---

### 5. LeaderboardViewModel.swift

**Location:** `StepComp/ViewModels/LeaderboardViewModel.swift`

**Find:**
```swift
func loadLeaderboard() async {
    let entries = await challengeService.getLeaderboard(
        challengeId: challengeId,
        scope: selectedScope
    )
}
```

**Update ChallengeService.getLeaderboard() to use RPC:**

```swift
func getLeaderboard(challengeId: String, scope: LeaderboardScope) async -> [LeaderboardEntry] {
    #if canImport(Supabase)
    do {
        let functionName = scope == .daily 
            ? "get_challenge_leaderboard_today" 
            : "get_challenge_leaderboard"
        
        let result: [LeaderboardEntry] = try await supabase
            .rpc(functionName, params: ["p_challenge_id": challengeId])
            .execute()
            .value
        
        return result
    } catch {
        print("⚠️ Error loading leaderboard: \(error)")
        return []
    }
    #else
    return []
    #endif
}
```

---

### 6. ProfileViewModel.swift

**Location:** `StepComp/ViewModels/ProfileViewModel.swift`

**Find:**
```swift
// Any direct profile updates
```

**Ensure:** All updates go through AuthService, which should use RPC for sensitive fields

---

### 7. FriendsViewModel.swift

**Location:** `StepComp/ViewModels/FriendsViewModel.swift`

**Find:**
```swift
private let myUserId: String
```

**Keep:** This is OK - used for filtering friend lists (read-only)

**But ensure:** Friend requests use RLS policies that check `auth.uid()`

---

## Pattern to Follow

### ❌ BAD: Client-Authoritative

```swift
func updateUserData(userId: String, data: [String: Any]) async {
    try await supabase
        .from("profiles")
        .update(data)
        .eq("id", value: userId)  // ❌ Client provides userId
        .execute()
}
```

### ✅ GOOD: Server-Authoritative

```swift
func updateUserData(data: [String: Any]) async {
    try await supabase
        .rpc("update_user_profile", params: data)
        // ✅ Server derives userId from JWT
}

// SQL Function:
CREATE FUNCTION update_user_profile(p_data jsonb)
RETURNS void AS $$
BEGIN
    UPDATE profiles 
    SET ... 
    WHERE id = auth.uid();  -- ✅ From JWT, not client
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Verification Checklist

After updates, search codebase for:

### 1. Direct Profile Writes

```bash
grep -r "\.from(\"profiles\").*\.update" StepComp/
```

**Expected:** 0 results (or only in AuthService for non-sensitive fields)

### 2. Direct Challenge Member Writes

```bash
grep -r "\.from(\"challenge_members\").*\.update" StepComp/
```

**Expected:** 0 results (handled by sync_daily_steps RPC)

### 3. userId Parameters in Write Functions

```bash
grep -r "func.*userId.*String.*async" StepComp/Services/
```

**Expected:** Only in read/filter functions, not write functions

---

## Testing

### Test 1: Step Sync Without userId

```swift
// Should work without passing userId
await stepSyncService.syncTodayStepsToProfile()
```

### Test 2: Leaderboard Without userId

```swift
// Should work - server derives participants from challenge_members
let leaderboard = await challengeService.getLeaderboard(
    challengeId: "challenge-id",
    scope: .daily
)
```

### Test 3: Cannot Update Other Users

```swift
// Even if you try to hack it, RLS blocks you
try await supabase
    .from("profiles")
    .update(["total_steps": 999999])
    .eq("id", value: "someone_elses_id")
    .execute()

// Result: RLS policy blocks (no rows updated)
```

---

## Summary

### What Changed:

1. ✅ `StepSyncService` no longer accepts `userId`
2. ✅ All step writes go through Edge Function → RPC
3. ✅ Leaderboards computed server-side from `daily_steps`
4. ✅ RLS policies enforce `auth.uid()` checks
5. ✅ No client can modify other users' data

### What Stayed:

- ✅ ViewModels can still store `userId` for filtering (read operations)
- ✅ Challenge lists still filtered by user participation
- ✅ Friend lists still filtered by user relationships

### Security Improvement:

**Before:** Client could potentially manipulate any user's data
**After:** Server enforces identity from JWT, client cannot lie

---

## Next Steps

1. Apply these changes to all services
2. Test thoroughly
3. Deploy to production
4. Monitor for any auth errors
5. Celebrate secure architecture! 🎉

