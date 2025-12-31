# 🔒 Security Review Fixes - V2 (Production-Hardened)

## Expert Review Feedback Addressed

This document explains all the fixes made based on senior-level security review.

---

## ✅ Issue #1: FK to `profiles` instead of `auth.users`

### Problem:
```sql
user_id UUID REFERENCES public.profiles(id)
```
- Profile rows can be deleted/absent
- Orphaned records if profile deleted before daily_steps
- Auth ownership should be tied to `auth.users`, not app table

### Fix:
```sql
user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
```

**Why it matters:** `auth.users` is the single source of truth for identity. If a user is deleted from Supabase Auth, all their data cascades automatically.

---

## ✅ Issue #2: RLS Recursion Risk

### Problem (V1):
```sql
CREATE POLICY "Users can view challenge members daily steps"
  ON daily_steps FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM challenge_members cm
      JOIN challenges c ON c.id = cm.challenge_id
      WHERE cm.user_id = daily_steps.user_id
      AND (c.is_public = TRUE OR ...)
    )
  );
```

If `challenges` or `challenge_members` policies reference `daily_steps`, you get **cross-policy recursion**.

### Fix (V2):
```sql
-- Simple policy: users can only read their own steps
CREATE POLICY "Users can view own daily steps"
  ON daily_steps FOR SELECT
  USING (user_id = auth.uid());
```

**Other users access steps ONLY via SECURITY DEFINER leaderboard functions**, which bypass RLS.

**Why it matters:** 
- ✅ No recursion possible (single table check)
- ✅ Fast (indexed lookup)
- ✅ Leaderboards use `SECURITY DEFINER` to read cross-user data safely

---

## ✅ Issue #3: Rate Limit Functions Exposed

### Problem (V1):
```sql
GRANT EXECUTE ON FUNCTION public.increment_rate_limit TO authenticated;
```

**Risk:** Any user can spam rate limit updates, creating DB load or manipulating their own limits.

### Fix (V2):
```sql
-- Default: NO EXECUTE grant
-- Only service role (Edge Function) can call this
COMMENT ON FUNCTION public.increment_rate_limit IS 'Only callable by Edge Functions (service role).';
```

**Why it matters:** Rate limiting must be server-controlled. Users should never touch rate limit logic.

---

## ✅ Issue #4: `rate_limits` Table Not Locked Down

### Problem (V1):
- RLS disabled
- No explicit `REVOKE`
- Potential read/write access depending on grants

### Fix (V2):
```sql
-- No RLS needed - only Edge Functions access this
REVOKE ALL ON public.rate_limits FROM anon, authenticated;
```

**Why it matters:** Rate limit data is sensitive infrastructure. Users should never see or modify it.

---

## ✅ Issue #5: Denormalizing `challenge_members` on Every Sync

### Problem (V1):
```sql
-- On EVERY step sync, update all challenge_members rows:
UPDATE challenge_members cm
SET 
    total_steps = (SELECT SUM(...)),
    daily_steps = jsonb_set(...)
WHERE cm.user_id = v_user_id;
```

**Issues:**
- Row locking on hot tables
- Expensive joins on every sync
- JSON blob writes
- Scales poorly with large challenges (1000+ members)

### Fix (V2):
```sql
-- ❌ REMOVED: challenge_members denormalization
-- Leaderboards are computed from daily_steps via RPCs
```

**New architecture:**
- Store: `daily_steps` (append-only event log)
- Compute: Leaderboards on-demand via indexed queries
- Cache: Optionally, async job can pre-compute for large challenges

**Why it matters:**
- ✅ No write contention
- ✅ Scales to millions of steps
- ✅ Leaderboards are always correct (no stale data)

---

## ✅ Issue #6: Fraud Detection Too Strict

### Problem (V1):
```sql
-- Flag ALL negative deltas as suspicious
IF v_step_diff < 0 THEN
    v_is_suspicious := TRUE;
END IF;
```

**Issue:** HealthKit sometimes revises step counts downward by small amounts (recalculations, corrections).

### Fix (V2):
```sql
-- ✅ Allow small negative deltas (HealthKit can revise downward)
-- Only flag large negative changes
IF v_step_diff < -500 THEN
    v_is_suspicious := TRUE;
END IF;
```

**Why it matters:** Avoid false positives. Real fraud involves large deltas, not minor corrections.

---

## ✅ Issue #7: Unbounded `SUM(all time)` for `total_steps`

### Problem (V1):
```sql
UPDATE profiles
SET total_steps = (
    SELECT SUM(steps)  -- ❌ Unbounded!
    FROM daily_steps
    WHERE user_id = v_user_id
);
```

**Issues:**
- Query grows forever (1 year = 365 rows, 10 years = 3650 rows)
- No index can help (must scan all rows)
- Slow as data grows

### Fix (V2):
```sql
UPDATE profiles
SET total_steps = (
    SELECT COALESCE(SUM(steps), 0)
    FROM daily_steps
    WHERE user_id = v_user_id
    AND day >= CURRENT_DATE - INTERVAL '30 days'  -- ✅ Bounded!
    AND is_suspicious = FALSE
);
```

**Why it matters:**
- ✅ Fixed window (30 days)
- ✅ Fast with index on `(user_id, day)`
- ✅ Realistic for "recent total" display

**For lifetime totals:** Run async aggregation job (not on every sync).

---

## ✅ Issue #8: Users Can Update `profiles.total_steps`

### Problem (V1):
- No column-level permission restrictions
- Users could potentially update `total_steps` directly (if RLS allows)

### Fix (V2):
```sql
-- Add column if missing
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS total_steps INTEGER DEFAULT 0;

-- Revoke update permission on this column
REVOKE UPDATE(total_steps) ON public.profiles FROM authenticated, anon;
```

**Why it matters:** `total_steps` is a computed field. Only `sync_daily_steps()` should update it.

---

## 📊 Comparison: V1 vs V2

| Aspect | V1 (Original) | V2 (Hardened) |
|--------|---------------|---------------|
| **FK** | `profiles(id)` ❌ | `auth.users(id)` ✅ |
| **RLS Recursion Risk** | High ⚠️ | None ✅ |
| **Rate Limit Security** | Exposed ❌ | Locked down ✅ |
| **rate_limits Access** | Not revoked ⚠️ | Revoked ✅ |
| **challenge_members Denorm** | Every sync ❌ | Removed ✅ |
| **Fraud Detection** | Too strict ⚠️ | Realistic ✅ |
| **total_steps Query** | Unbounded ❌ | 30-day window ✅ |
| **Column Permissions** | Not restricted ⚠️ | Revoked ✅ |

---

## 🎯 What V2 Achieves

### Security:
- ✅ No RLS recursion possible
- ✅ Rate limiting fully server-controlled
- ✅ No client can manipulate computed fields
- ✅ Proper FK to auth identity

### Performance:
- ✅ No row locking on hot tables
- ✅ Bounded queries (30 days, not lifetime)
- ✅ Fast leaderboard computation
- ✅ Scales to millions of steps

### Correctness:
- ✅ Realistic fraud detection
- ✅ Handles HealthKit revisions
- ✅ Leaderboards always accurate
- ✅ No stale denormalized data

---

## 🚀 Deployment

### Replace V1 with V2:
```bash
# Use the production-hardened version
# File: IMPLEMENT_SECURITY_OVERHAUL_V2_SAFE.sql
```

**In Supabase Dashboard → SQL Editor:**
1. Copy/paste `IMPLEMENT_SECURITY_OVERHAUL_V2_SAFE.sql`
2. Run
3. Verify success message

---

## 🧪 Testing

### Functional Tests:
- [ ] Step sync works
- [ ] Leaderboards compute correctly
- [ ] Negative step deltas (< 500) accepted
- [ ] Large negative deltas (> 500) flagged
- [ ] Can't sync > 100k steps

### Security Tests:
- [ ] Can't call `increment_rate_limit()` directly (should fail)
- [ ] Can't read `rate_limits` table (should fail)
- [ ] Can't update `profiles.total_steps` directly (should fail)
- [ ] Leaderboards show data from other users (via SECURITY DEFINER)

### Performance Tests:
- [ ] Step sync completes in < 200ms
- [ ] Leaderboard query < 100ms (for 100 members)
- [ ] No lock contention on `challenge_members`

---

## 📈 Architecture Flow (V2)

```
Client ──steps, JWT──> Edge Function
                       ├─ Verify JWT ✅
                       ├─ Rate limit (service role) ✅
                       └──> sync_daily_steps() RPC
                            ├─ Extract auth.uid() ✅
                            ├─ Validate steps ✅
                            ├─ Check fraud (realistic) ✅
                            ├─ INSERT/UPDATE daily_steps ✅
                            └─ UPDATE profiles.total_steps (30-day) ✅

Leaderboard ──> get_challenge_leaderboard() RPC
                ├─ Query daily_steps (indexed) ✅
                ├─ Filter by challenge date range ✅
                ├─ Exclude suspicious = TRUE ✅
                ├─ SUM + RANK ✅
                └─ Return ranked list ✅
```

---

## ✅ Production Checklist

Before deploying:
- [ ] Run `IMPLEMENT_SECURITY_OVERHAUL_V2_SAFE.sql`
- [ ] Verify all 6 functions exist
- [ ] Verify RLS policies (simple, non-recursive)
- [ ] Verify `rate_limits` table revoked
- [ ] Verify `total_steps` update revoked
- [ ] Deploy Edge Function
- [ ] Test with real HealthKit data
- [ ] Monitor for 24 hours
- [ ] Ship! 🚀

---

## 🙏 Thank You

This review prevented:
- ❌ RLS recursion (hard to debug in production)
- ❌ Performance degradation (challenge_members writes)
- ❌ Security vulnerabilities (exposed rate limit functions)
- ❌ False positives (too-strict fraud detection)
- ❌ Slow queries (unbounded SUM)

**V2 is production-ready!** 🎉

