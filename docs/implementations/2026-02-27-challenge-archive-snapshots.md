# Challenge Archive Snapshots - Implementation Summary

**Date:** February 27, 2026  
**Status:** Implementation Complete - Ready for Database Migration

## Problem Solved

Archived challenges were showing 0 participants and 0 metrics because the `challenge_members` table had missing/empty rows for ended challenges. The leaderboard RPC and fallback queries returned no data.

## Solution Implemented

Created a **challenge snapshots system** that preserves participant data when challenges end.

## Changes Made

### 1. Database Schema (`scripts/sql/CREATE_CHALLENGE_SNAPSHOTS.sql`)

Created new table and functions:

- **`challenge_snapshots` table**: Stores final participant metrics for each archived challenge
  - Columns: id, challenge_id, user_id, username, display_name, avatar_url, total_steps, rank, snapshotted_at
  - Unique constraint on (challenge_id, user_id)
  - RLS policies for secure access

- **`snapshot_challenge_results(p_challenge_id UUID)` RPC**: 
  - Computes final standings from `daily_steps` table
  - Upserts to `challenge_snapshots` (idempotent)
  - Returns ranked participant data
  
- **`has_challenge_snapshot(p_challenge_id UUID)` helper**: 
  - Quick boolean check if snapshot exists

### 2. Swift Model (`StepComp/Models/SupabaseChallenge.swift`)

Added `ChallengeSnapshot` struct:
- Codable model matching database schema
- `toLeaderboardEntry()` converter for UI display

### 3. Service Layer (`StepComp/Services/ChallengeService.swift`)

Added `ensureChallengeSnapshot(challengeId:)` method:
- Checks if snapshot exists
- Creates snapshot via RPC if missing
- Returns LeaderboardEntry array for UI

### 4. Summary View (`StepComp/Screens/Challenges/ChallengeSummaryView.swift`)

Updated `loadLeaderboardData()` with 4-tier fallback:
1. Query `challenge_snapshots` table (fastest, most reliable for archives)
2. Call `get_challenge_leaderboard` RPC (for active challenges)
3. Call `snapshot_challenge_results` RPC to create snapshot on-demand
4. Fallback to `challenge_members` direct query

### 5. ViewModel (`StepComp/ViewModels/ChallengesViewModel.swift`)

Updated `convertToChallenges()` for archived challenges:
- Queries `challenge_snapshots` to get participant list
- Calls `snapshot_challenge_results` RPC if no snapshot exists
- Falls back to `challenge_invites` table for recovery
- Ensures archive cards show correct participant counts

### 6. Cleanup

Removed all debug instrumentation:
- Debug panel UI (red box)
- Debug log functions
- Old recovery hacks from debugging session

## Deployment Steps

### IMPORTANT: Run SQL Migration First

**Before running the app**, you must apply the SQL migration to your Supabase database:

```bash
# Option 1: Using Supabase Dashboard
# Go to SQL Editor and run: scripts/sql/CREATE_CHALLENGE_SNAPSHOTS.sql

# Option 2: Using Supabase CLI (if configured)
supabase db execute --file scripts/sql/CREATE_CHALLENGE_SNAPSHOTS.sql
```

This creates:
- `challenge_snapshots` table
- `snapshot_challenge_results()` RPC function
- `has_challenge_snapshot()` helper function
- RLS policies

### Then Test the App

1. **Clean build** in Xcode (Cmd+Shift+K)
2. **Run the app**
3. **Navigate to Archive tab**
4. **Open an archived challenge summary** (e.g., "Woodstock Walkers")

### Expected Behavior

- Archive cards show correct participant counts (e.g., "4 participated" instead of "1 participated")
- Summary screen shows all participants with their final metrics
- Metrics display: Your Total Steps, Participants count, Avg Steps, Duration, Ended On
- Final Standings section lists all participants ranked by steps

### What Happens Behind the Scenes

1. App loads archived challenges → queries `challenge_snapshots`
2. If no snapshot exists → calls `snapshot_challenge_results` RPC
3. RPC computes final standings from `daily_steps` table
4. RPC saves to `challenge_snapshots` table
5. App displays snapshot data (fast, reliable)

### Future Challenges

For **new challenges created after this update**:
- The first time someone views an archived challenge summary, a snapshot is automatically created
- All subsequent views use the cached snapshot (fast)
- Snapshots are idempotent - safe to regenerate if needed

### Fixing Existing Archived Challenges

To backfill snapshots for all existing archived challenges, run this in Supabase SQL Editor:

```sql
-- Get all archived challenges
SELECT 
    id,
    name,
    snapshot_challenge_results(id) as participant_count
FROM challenges 
WHERE end_date < NOW()
ORDER BY end_date DESC;
```

This will create snapshots for all past challenges that have members in `challenge_members` table.

## Architecture

```
Archive Card Display
└── ChallengesViewModel.convertToChallenges()
    ├── Query challenge_members (if exists)
    ├── Query challenge_snapshots (if no members)
    └── Set Challenge.participantIds → "X participated"

Summary View Display  
└── ChallengeSummaryView.loadLeaderboardData()
    ├── 1. Query challenge_snapshots (Priority 1 - fastest)
    ├── 2. Call get_challenge_leaderboard RPC (Priority 2)
    ├── 3. Call snapshot_challenge_results RPC (Priority 3 - create on demand)
    └── 4. Query challenge_members directly (Priority 4 - fallback)
```

## Files Modified

- `scripts/sql/CREATE_CHALLENGE_SNAPSHOTS.sql` (new)
- `StepComp/Models/SupabaseChallenge.swift`
- `StepComp/Services/ChallengeService.swift`
- `StepComp/Screens/Challenges/ChallengeSummaryView.swift`
- `StepComp/ViewModels/ChallengesViewModel.swift`

## Testing Checklist

- [ ] SQL migration applied to Supabase database
- [ ] App builds without errors
- [ ] Archive tab loads without crashes
- [ ] Archive cards show correct participant counts
- [ ] Can open archived challenge summaries
- [ ] Summary shows all participants with metrics
- [ ] Summary shows correct "Your Total Steps"
- [ ] Summary shows correct "Participants" count
- [ ] Summary shows "Avg Steps (Per Day)"
- [ ] Summary shows "Duration" and "Ended On"
- [ ] Final Standings section lists all participants
- [ ] Participants are correctly ranked by steps
