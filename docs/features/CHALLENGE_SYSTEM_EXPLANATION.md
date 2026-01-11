# Challenge System Architecture Explanation

## Overview

This document explains how challenges are created, how users join groups, how steps are tracked, and how leaderboard positions are determined in the StepComp app.

---

## 1. Challenge Creation

### Current Implementation (Local Storage)
**Status**: ⚠️ Currently using **UserDefaults** (local storage only)

When a challenge is created:
- A new `Challenge` object is created with:
  - `id`: Unique UUID
  - `name`: Challenge name
  - `description`: Challenge description
  - `startDate` & `endDate`: Challenge duration
  - `targetSteps`: Goal steps
  - `creatorId`: User who created it
  - `participantIds`: Array of user IDs
- The challenge is stored in **UserDefaults** (local device storage)
- **NOT currently saved to Supabase database**

### Database Schema (Available but Not Used)
The Supabase database has a `challenges` table ready:

```sql
CREATE TABLE challenges (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,
  created_by UUID REFERENCES auth.users(id),
  is_public BOOLEAN DEFAULT TRUE,
  invite_code TEXT UNIQUE,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE
);
```

**Note**: The app currently doesn't use this table - challenges are only stored locally.

---

## 2. Users Joining Challenges

### Current Implementation
**Status**: ⚠️ Using local storage only

When a user joins a challenge:
1. The `joinChallenge()` method in `ChallengeService` is called
2. The user's ID is added to the challenge's `participantIds` array
3. The updated challenge is saved to **UserDefaults**
4. **NOT saved to Supabase database**

### Database Schema (Available but Not Used)
The database has a `challenge_members` table ready:

```sql
CREATE TABLE challenge_members (
  id UUID PRIMARY KEY,
  challenge_id UUID REFERENCES challenges(id),
  user_id UUID REFERENCES auth.users(id),
  total_steps INTEGER DEFAULT 0,
  daily_steps JSONB DEFAULT '{}',
  joined_at TIMESTAMP WITH TIME ZONE,
  last_updated TIMESTAMP WITH TIME ZONE,
  UNIQUE(challenge_id, user_id)
);
```

**Note**: This table is designed to track membership and steps, but the app doesn't use it yet.

---

## 3. Step Tracking During Competitions

### Current Implementation
**Status**: ⚠️ **NOT IMPLEMENTED** - Steps are not automatically tracked

**Problem**: The app currently has:
- No automatic step syncing from HealthKit to challenges
- No background updates
- No real-time step tracking for challenges

### How It Should Work (Database Design)

The `challenge_members` table is designed to track steps:

1. **Total Steps**: `total_steps` column stores cumulative steps for the challenge
2. **Daily Steps**: `daily_steps` JSONB column stores daily breakdown:
   ```json
   {
     "2024-12-30": 8500,
     "2024-12-31": 12000,
     "2025-01-01": 9500
   }
   ```

### Missing Implementation

The app needs:
1. **HealthKit Integration**: Sync steps from HealthKit to `challenge_members.total_steps`
2. **Background Updates**: Update steps periodically (every hour or when app opens)
3. **Daily Tracking**: Store daily step counts in `daily_steps` JSONB field
4. **Real-time Updates**: Use Supabase Realtime to update leaderboards live

---

## 4. Leaderboard Position Logic

### Current Implementation
**Status**: ⚠️ Using local storage with basic sorting

The `updateLeaderboardEntry()` method in `ChallengeService`:

```swift
func updateLeaderboardEntry(_ entry: LeaderboardEntry) {
    // 1. Get or create entries array for challenge
    var entries = leaderboardEntries[challengeId] ?? []
    
    // 2. Update or add entry
    if let index = entries.firstIndex(where: { $0.userId == entry.userId }) {
        entries[index] = entry  // Update existing
    } else {
        entries.append(entry)   // Add new
    }
    
    // 3. Sort by steps (descending - highest first)
    entries.sort { $0.steps > $1.steps }
    
    // 4. Assign ranks (1st, 2nd, 3rd, etc.)
    for (index, _) in entries.enumerated() {
        entries[index].rank = index + 1
    }
    
    // 5. Save to UserDefaults
    leaderboardEntries[challengeId] = entries
    saveLeaderboards()
}
```

### Ranking Logic
1. **Sort by steps**: Highest steps = rank 1
2. **Tie-breaking**: Currently no tie-breaking logic (first user with same steps gets higher rank)
3. **Rank assignment**: Sequential (1, 2, 3, 4...)

### Database Function (Available but Not Used)

The database has a `get_challenge_leaderboard()` function:

```sql
CREATE FUNCTION get_challenge_leaderboard(p_challenge_id UUID)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  avatar TEXT,
  total_steps INTEGER,
  rank BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cm.user_id,
    p.username,
    p.avatar,
    cm.total_steps,
    RANK() OVER (ORDER BY cm.total_steps DESC) as rank
  FROM challenge_members cm
  JOIN profiles p ON p.user_id = cm.user_id
  WHERE cm.challenge_id = p_challenge_id
  ORDER BY cm.total_steps DESC;
END;
$$;
```

This uses SQL `RANK()` which handles ties properly (users with same steps get same rank).

---

## Current Architecture Summary

### What Works (Local Storage)
✅ Challenge creation (stored locally)  
✅ User joining challenges (stored locally)  
✅ Basic leaderboard sorting (local)  
✅ Leaderboard rank calculation (local)

### What's Missing (Supabase Integration)
❌ Challenges not saved to database  
❌ Challenge members not tracked in database  
❌ Steps not synced from HealthKit to database  
❌ No real-time leaderboard updates  
❌ No daily/weekly step tracking  
❌ No background step syncing

---

## Recommended Implementation Path

### Phase 1: Database Integration
1. **Update `ChallengeService.createChallenge()`** to save to Supabase `challenges` table
2. **Update `ChallengeService.joinChallenge()`** to insert into `challenge_members` table
3. **Load challenges from database** on app startup

### Phase 2: Step Tracking
1. **Create step sync service** that:
   - Reads steps from HealthKit
   - Updates `challenge_members.total_steps`
   - Stores daily breakdown in `daily_steps` JSONB
2. **Background sync**: Update steps every hour or on app open
3. **Real-time updates**: Use Supabase Realtime subscriptions

### Phase 3: Leaderboard
1. **Use database function** `get_challenge_leaderboard()` for accurate rankings
2. **Implement scope filtering** (daily/weekly/all-time) using `daily_steps` JSONB
3. **Real-time leaderboard** updates via Supabase Realtime

---

## Database Tables Overview

### `challenges` Table
- Stores challenge metadata
- Links to creator via `created_by`
- Has `invite_code` for joining

### `challenge_members` Table
- Tracks which users are in which challenges
- Stores `total_steps` for each user in each challenge
- Stores `daily_steps` JSONB for daily breakdown
- Has indexes for fast leaderboard queries

### Helper Functions
- `get_challenge_leaderboard()`: Returns ranked leaderboard
- `get_user_total_steps()`: Gets user's total steps across all challenges

---

## Example: How It Should Work

### Creating a Challenge
1. User creates challenge → Saved to `challenges` table
2. Creator automatically added to `challenge_members` table
3. `total_steps` initialized to 0

### Joining a Challenge
1. User joins via invite code → Row inserted into `challenge_members`
2. `total_steps` initialized to 0
3. `joined_at` timestamp recorded

### Tracking Steps
1. HealthKit provides daily steps
2. App syncs to `challenge_members.total_steps` (cumulative)
3. Daily value stored in `daily_steps` JSONB
4. `last_updated` timestamp updated

### Leaderboard
1. Query `get_challenge_leaderboard(challenge_id)`
2. Returns users sorted by `total_steps DESC`
3. SQL `RANK()` handles ties automatically
4. Real-time updates via Supabase subscriptions

---

## Next Steps

To fully implement the challenge system:

1. **Migrate ChallengeService** to use Supabase instead of UserDefaults
2. **Implement step syncing** from HealthKit to database
3. **Add real-time subscriptions** for live leaderboard updates
4. **Implement daily/weekly filtering** using `daily_steps` JSONB data

The database schema is ready - the app just needs to use it!

