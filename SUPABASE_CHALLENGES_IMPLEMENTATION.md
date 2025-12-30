# Supabase Challenges Implementation

## ✅ What Was Implemented

### 1. Database Models
- **`SupabaseChallenge`**: Maps to `challenges` table
- **`ChallengeMember`**: Maps to `challenge_members` table with JSONB `daily_steps` support
- **`LeaderboardResult`**: Result type from `get_challenge_leaderboard()` function

### 2. ChallengeService Updates

#### Challenge Creation
- ✅ `createChallenge()` now saves to Supabase `challenges` table
- ✅ Automatically generates invite codes
- ✅ Adds creator and participants to `challenge_members` table
- ✅ Falls back to local storage if Supabase unavailable

#### Challenge Loading
- ✅ `loadChallengesFromSupabase()` loads challenges where user is creator or member
- ✅ Automatically loads on service initialization
- ✅ Converts Supabase models to app `Challenge` models

#### Joining Challenges
- ✅ `joinChallenge()` inserts into `challenge_members` table
- ✅ Checks for duplicate memberships
- ✅ Updates local cache

#### Step Syncing
- ✅ `syncStepsToChallenge()` syncs steps from HealthKit to database
- ✅ Updates `total_steps` (cumulative)
- ✅ Stores daily breakdown in `daily_steps` JSONB field
- ✅ `syncTodayStepsToAllChallenges()` syncs today's steps to all active challenges

#### Leaderboard
- ✅ `getLeaderboard()` uses database function `get_challenge_leaderboard()`
- ✅ `getDailyLeaderboardFromSupabase()` filters by today's steps from JSONB
- ✅ `getWeeklyLeaderboardFromSupabase()` calculates weekly totals from JSONB
- ✅ Proper ranking with SQL `RANK()` function

### 3. ViewModel Updates
- ✅ `LeaderboardViewModel` updated to use async `getLeaderboard()`
- ✅ `GroupViewModel` updated to use async `getLeaderboard()`

---

## 🔄 How It Works Now

### Creating a Challenge
1. User creates challenge → Saved to `challenges` table
2. Creator automatically added to `challenge_members` with `total_steps = 0`
3. Selected participants added to `challenge_members`
4. Challenge cached locally for offline access

### Joining a Challenge
1. User joins via invite code → Row inserted into `challenge_members`
2. `total_steps` initialized to 0
3. `daily_steps` JSONB initialized to `{}`
4. Local cache updated

### Tracking Steps
1. HealthKit provides daily steps
2. `syncStepsToChallenge()` called with challenge ID, user ID, and steps
3. Updates `challenge_members.total_steps` (cumulative)
4. Stores daily value in `daily_steps` JSONB: `{"2024-12-30": 8500}`
5. `last_updated` timestamp updated

### Leaderboard
1. `getLeaderboard()` calls `get_challenge_leaderboard()` database function
2. Returns users sorted by `total_steps DESC` with SQL `RANK()`
3. Daily/Weekly scopes filter using `daily_steps` JSONB data
4. Results cached locally for offline access

---

## 📋 Next Steps

### Automatic Step Syncing
Add to `AppDelegate` or `SceneDelegate`:

```swift
// Sync steps every hour
Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
    Task {
        if let userId = sessionViewModel.currentUser?.id {
            await challengeService.syncTodayStepsToAllChallenges(
                userId: userId,
                healthKitService: healthKitService
            )
        }
    }
}

// Sync on app foreground
NotificationCenter.default.addObserver(
    forName: UIApplication.willEnterForegroundNotification,
    object: nil,
    queue: .main
) { _ in
    Task {
        if let userId = sessionViewModel.currentUser?.id {
            await challengeService.syncTodayStepsToAllChallenges(
                userId: userId,
                healthKitService: healthKitService
            )
        }
    }
}
```

### Real-time Updates (Optional)
Add Supabase Realtime subscriptions for live leaderboard updates:

```swift
// Subscribe to challenge_members changes
let channel = supabase.channel("challenge-\(challengeId)")
channel.on("postgres_changes", filter: "table=challenge_members") { payload in
    // Refresh leaderboard when steps update
    Task {
        await loadLeaderboard()
    }
}
await channel.subscribe()
```

---

## 🧪 Testing

1. **Create Challenge**: Verify it appears in Supabase Dashboard → `challenges` table
2. **Join Challenge**: Verify row created in `challenge_members` table
3. **Sync Steps**: Call `syncStepsToChallenge()` and verify `total_steps` and `daily_steps` update
4. **Leaderboard**: Verify rankings match database `total_steps` values
5. **Daily/Weekly**: Verify filtering works correctly from JSONB data

---

## ⚠️ Important Notes

1. **Backward Compatibility**: Service falls back to local storage if Supabase unavailable
2. **Offline Support**: Challenges cached locally for offline access
3. **Step Syncing**: Currently manual - needs to be called periodically
4. **Real-time**: Not yet implemented - leaderboard updates on refresh

---

## 🐛 Known Issues / TODOs

1. **RPC Function**: May need to verify `get_challenge_leaderboard()` function exists in database
2. **Date Formatting**: Ensure date format matches between app and database
3. **Error Handling**: Add more robust error handling for network failures
4. **Background Sync**: Implement background task for automatic step syncing

