# 🛡️ Security Overhaul Deployment Guide

This guide implements **Backend as Source of Truth** for StepComp, addressing the #1 critical security vulnerability (client-authoritative step data).

## 📋 What This Fixes

### Before (Vulnerable):
```
Client ──steps: 999999──> Database ❌
        (no validation)
```

### After (Secure):
```
Client ──steps──> Edge Function ──validate──> RPC ──audit──> Database ✅
                  (rate limit)    (fraud)     (log)
```

---

## 🚀 Deployment Steps

### Step 1: Database Migration (5 minutes)

```bash
# Run in Supabase Dashboard → SQL Editor
```

Execute `IMPLEMENT_SECURITY_OVERHAUL.sql`

**This creates:**
- ✅ `daily_steps` table (audit trail)
- ✅ `rate_limits` table (API throttling)
- ✅ `sync_daily_steps()` RPC (server-side validation)
- ✅ `get_challenge_leaderboard()` RPC (computed from daily_steps)
- ✅ `get_challenge_leaderboard_today()` RPC
- ✅ All RLS policies

**Verify:**
```sql
-- Should return 2 tables
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('daily_steps', 'rate_limits');

-- Should return 6 functions
SELECT routine_name FROM information_schema.routines
WHERE routine_name LIKE '%daily_steps%' OR routine_name LIKE '%leaderboard%';
```

---

### Step 2: Deploy Edge Function (3 minutes)

```bash
# Install Supabase CLI if not already installed
brew install supabase/tap/supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy the Edge Function
supabase functions deploy sync-steps

# Verify deployment
supabase functions list
```

**Expected output:**
```
┌─────────────┬────────┬─────────────────┐
│ Name        │ Status │ Updated         │
├─────────────┼────────┼─────────────────┤
│ sync-steps  │ Active │ 2025-01-01 ...  │
└─────────────┴────────┴─────────────────┘
```

---

### Step 3: Test Edge Function (2 minutes)

```bash
# Test with curl
curl -X POST \
  'https://YOUR_PROJECT_REF.supabase.co/functions/v1/sync-steps' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "day": "2025-01-01",
    "steps": 5000,
    "device_id": "test-device"
  }'
```

**Expected response:**
```json
{
  "success": true,
  "data": {
    "accepted_steps": 5000,
    "day": "2025-01-01",
    "is_suspicious": false,
    "message": "Steps synced successfully"
  }
}
```

---

### Step 4: Update iOS App (10 minutes)

#### 4.1 Update StepSyncService ✅ Already Done

The new `StepSyncService.swift` now:
- ✅ Calls Edge Function instead of direct database write
- ✅ No longer accepts `userId` parameter (server derives from JWT)
- ✅ Includes device fingerprinting
- ✅ Handles rate limiting errors

#### 4.2 Update DashboardViewModel

**Find and replace:**

```swift
// OLD (remove userId parameter)
await stepSyncService.syncTodayStepsToProfile(userId: userId)

// NEW
await stepSyncService.syncTodayStepsToProfile()
```

**Files to update:**
- `StepComp/ViewModels/DashboardViewModel.swift`
- `StepComp/Screens/Home/HomeDashboardView.swift`
- `StepComp/Screens/Settings/SettingsView.swift`

#### 4.3 Update ChallengeService (Leaderboard)

Replace direct queries with RPC calls:

```swift
// OLD
let members: [ChallengeMember] = try await supabase
    .from("challenge_members")
    .select()
    .eq("challenge_id", value: challengeId)
    .execute()
    .value

// NEW
struct LeaderboardEntry: Codable {
    let userId: UUID
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let steps: Int
    let rank: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case steps
        case rank
    }
}

let leaderboard: [LeaderboardEntry] = try await supabase
    .rpc("get_challenge_leaderboard", params: ["p_challenge_id": challengeId])
    .execute()
    .value
```

---

### Step 5: Remove Vulnerable Code (Critical)

**Search for and remove ALL instances of:**

```swift
// ❌ DANGEROUS - Client provides userId
.eq("id", value: userId)
.update(["total_steps": steps])

// ❌ DANGEROUS - Direct writes to profiles
try await supabase
    .from("profiles")
    .update(...)
    .execute()

// ❌ DANGEROUS - Direct writes to challenge_members
try await supabase
    .from("challenge_members")
    .update(...)
    .execute()
```

**Replace with:**

```swift
// ✅ SAFE - Server derives userId from JWT
try await supabase.rpc("sync_daily_steps", params: [...])

// ✅ SAFE - Server-side leaderboard calculation
try await supabase.rpc("get_challenge_leaderboard", params: [...])
```

---

## 🧪 Testing Checklist

### Functional Tests:

- [ ] User can sync steps from HealthKit
- [ ] Steps appear in profile
- [ ] Steps appear in challenges
- [ ] Leaderboard updates correctly
- [ ] Today's leaderboard shows correct data
- [ ] Overall leaderboard shows correct data

### Security Tests:

- [ ] Cannot send steps > 100,000 (rejected)
- [ ] Cannot send negative steps (rejected)
- [ ] Cannot sync future dates (rejected)
- [ ] Rate limit enforced (30/min, 4/hour)
- [ ] Cannot modify other users' steps (RLS blocks)
- [ ] Suspicious activity flagged (rapid increases)

### Edge Cases:

- [ ] Syncing same day multiple times (updates, doesn't duplicate)
- [ ] Network failure handling (retries)
- [ ] Token expiry during sync (refreshes)
- [ ] Multiple devices syncing (last write wins)

---

## 📊 Monitoring & Maintenance

### Check for Suspicious Activity:

```sql
-- View flagged entries
SELECT 
    ds.user_id,
    p.username,
    ds.day,
    ds.steps,
    ds.ip_address,
    ds.created_at
FROM daily_steps ds
JOIN profiles p ON p.id = ds.user_id
WHERE ds.is_suspicious = TRUE
ORDER BY ds.created_at DESC
LIMIT 50;
```

### Monitor Rate Limits:

```sql
-- Top users by API calls
SELECT 
    user_id,
    COUNT(*) as total_requests,
    MAX(count) as max_burst
FROM rate_limits
WHERE reset_at > NOW() - INTERVAL '1 hour'
GROUP BY user_id
ORDER BY total_requests DESC
LIMIT 20;
```

### Clean Up Old Rate Limits:

```sql
-- Run daily via cron
SELECT cleanup_expired_rate_limits();
```

---

## 🚨 Rollback Plan

If issues occur:

### Rollback Step 1: Disable Edge Function

```bash
supabase functions delete sync-steps
```

### Rollback Step 2: Revert iOS Code

```swift
// Temporarily allow direct writes (NOT RECOMMENDED)
try await supabase
    .from("profiles")
    .update(["total_steps": steps])
    .eq("id", value: userId)
    .execute()
```

### Rollback Step 3: Drop Tables (if needed)

```sql
-- Only if you need to start over
DROP TABLE IF EXISTS public.daily_steps CASCADE;
DROP TABLE IF EXISTS public.rate_limits CASCADE;
```

---

## 📈 Performance Optimizations

### Add Indexes (if needed):

```sql
-- If leaderboard queries are slow
CREATE INDEX idx_daily_steps_challenge_range 
ON daily_steps(user_id, day) 
WHERE is_suspicious = FALSE;

-- If rate limit checks are slow
CREATE INDEX idx_rate_limits_active 
ON rate_limits(user_id, bucket, reset_at) 
WHERE reset_at > NOW();
```

### Cache Leaderboards (optional):

```sql
-- Materialized view for public challenges
CREATE MATERIALIZED VIEW public_challenge_leaderboards AS
SELECT * FROM get_challenge_leaderboard(...);

-- Refresh every hour
REFRESH MATERIALIZED VIEW public_challenge_leaderboards;
```

---

## ✅ Success Criteria

After deployment, verify:

1. ✅ No console errors about "Could not update total_steps"
2. ✅ Steps sync successfully from HealthKit
3. ✅ Leaderboards show correct rankings
4. ✅ Rate limiting prevents API abuse
5. ✅ Suspicious activity is flagged
6. ✅ No client can modify other users' data
7. ✅ All queries use `auth.uid()` (not client-provided IDs)

---

## 🎯 Next Steps

After this deployment:

1. **Monitor for 24 hours** - Check logs for errors
2. **Review flagged entries** - Investigate suspicious activity
3. **Tune rate limits** - Adjust if too strict/loose
4. **Add push notifications** - Alert users of suspicious activity
5. **Implement appeals** - Let users dispute flags

---

## 📞 Support

If you encounter issues:

1. Check Supabase logs: Dashboard → Logs → Edge Functions
2. Check database logs: Dashboard → Logs → Database
3. Review RLS policies: Dashboard → Database → Policies
4. Test with Postman/curl before blaming iOS code

---

## 🏆 What You've Achieved

- ✅ Backend is now source of truth for all step data
- ✅ Rate limiting prevents API abuse
- ✅ Fraud detection flags suspicious activity
- ✅ Audit trail for all step updates
- ✅ Leaderboards computed from verified data
- ✅ No client can cheat or manipulate rankings
- ✅ Production-ready security architecture

**Your app is now secure for competitive play! 🎉**

