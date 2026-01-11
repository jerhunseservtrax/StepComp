# 🚀 Deploy Security Overhaul - Quick Start

## ⏱️ Total Time: ~15 minutes

---

## Step 1: Database Migration (5 minutes)

1. Open Supabase Dashboard: https://supabase.com/dashboard
2. Navigate to: **SQL Editor**
3. Click: **New Query**
4. Copy/paste contents of: `IMPLEMENT_SECURITY_OVERHAUL_V2_SAFE.sql` ⭐
5. Click: **Run**

**⚠️ Use V2 (not V1):** V2 is production-hardened and fixes:
- RLS recursion risk
- Performance issues
- Security vulnerabilities
- See `SECURITY_REVIEW_FIXES.md` for details

**Expected output:**
```
✅ Security overhaul complete!
   - daily_steps table created (audit trail)
   - rate_limits table created
   - sync_daily_steps() function ready
   - Leaderboard functions ready
   - All RLS policies applied
```

**Verify:**
```sql
-- Should return 2 tables
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('daily_steps', 'rate_limits');

-- Should return 6 functions
SELECT routine_name FROM information_schema.routines
WHERE routine_name LIKE '%daily_steps%' 
   OR routine_name LIKE '%leaderboard%'
   OR routine_name LIKE '%rate_limit%';
```

---

## Step 2: Deploy Edge Function (3 minutes)

```bash
# 1. Install Supabase CLI (if not installed)
brew install supabase/tap/supabase

# 2. Login
supabase login

# 3. Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# 4. Deploy the Edge Function
cd /Users/jefferyerhunse/GitRepos/StepComp
supabase functions deploy sync-steps

# 5. Verify
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

## Step 3: Test Edge Function (2 minutes)

### Get your JWT token:
```bash
# In Supabase Dashboard → Settings → API
# Copy the "service_role" key for testing
```

### Test the function:
```bash
curl -X POST \
  'https://YOUR_PROJECT_REF.supabase.co/functions/v1/sync-steps' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
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
    "is_suspicious": false,
    "message": "Steps synced successfully"
  }
}
```

---

## Step 4: Rebuild iOS App (5 minutes)

```bash
# 1. Open Xcode
open /Users/jefferyerhunse/GitRepos/StepComp/StepComp.xcodeproj

# 2. Clean build folder
# Cmd + Shift + K

# 3. Build
# Cmd + B

# 4. Run on device/simulator
# Cmd + R
```

**Test:**
1. Open app
2. Sync steps (should work normally)
3. Check console for: `✅ Edge Function sync successful`
4. View leaderboard (should display correctly)

---

## Step 5: Verify Security (2 minutes)

### Test Rate Limiting:
1. Sync steps rapidly (click refresh 35 times in 1 minute)
2. Should see error after 30 requests:
   ```
   Rate limit exceeded. Limit: 30 per minute.
   ```

### Test Fraud Detection:
```bash
# Try to send impossible step count
curl -X POST \
  'https://YOUR_PROJECT_REF.supabase.co/functions/v1/sync-steps' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "steps": 999999
  }'
```

**Expected response:**
```json
{
  "error": "Suspicious step count",
  "message": "Step count exceeds reasonable daily maximum"
}
```

---

## ✅ Success Checklist

- [ ] Database migration completed
- [ ] Edge Function deployed
- [ ] Edge Function responds to curl test
- [ ] iOS app builds without errors
- [ ] Steps sync successfully
- [ ] Leaderboards display correctly
- [ ] Rate limiting works
- [ ] Fraud detection works
- [ ] Console shows `✅ Edge Function sync successful`

---

## 🚨 If Something Goes Wrong

### Database migration failed:
- Check for syntax errors
- Ensure you're connected to correct project
- Try running in smaller chunks

### Edge Function won't deploy:
```bash
# Check your Supabase project
supabase projects list

# Re-link
supabase link --project-ref YOUR_PROJECT_REF

# Try again
supabase functions deploy sync-steps --no-verify-jwt
```

### iOS app errors:
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reinstall packages
cd /Users/jefferyerhunse/GitRepos/StepComp
swift package resolve
swift package update
```

### Edge Function returns errors:
- Check Supabase Dashboard → Logs → Edge Functions
- Look for error messages
- Verify JWT token is valid

---

## 📊 Monitor After Deployment

### Check Logs (Supabase Dashboard):
1. **Edge Functions Logs**
   - Dashboard → Logs → Edge Functions
   - Filter: `sync-steps`
   - Look for errors

2. **Database Logs**
   - Dashboard → Logs → Database
   - Look for RLS policy violations

### Check for Suspicious Activity:
```sql
-- In SQL Editor
SELECT 
    ds.user_id,
    p.username,
    ds.day,
    ds.steps,
    ds.created_at,
    ds.ip_address
FROM daily_steps ds
JOIN profiles p ON p.id = ds.user_id
WHERE ds.is_suspicious = TRUE
ORDER BY ds.created_at DESC
LIMIT 20;
```

### Check Rate Limits:
```sql
-- In SQL Editor
SELECT 
    user_id,
    bucket,
    count,
    reset_at
FROM rate_limits
WHERE reset_at > NOW() - INTERVAL '1 hour'
ORDER BY count DESC
LIMIT 20;
```

---

## 🎉 You're Done!

Your app now has:
- ✅ Secure step validation
- ✅ Rate limiting (30/min, 4/hour)
- ✅ Fraud detection
- ✅ Full audit trail
- ✅ Server-authoritative architecture

**Time to celebrate!** 🎊

Next steps:
1. Monitor for 24 hours
2. Review logs for any issues
3. Adjust rate limits if needed
4. Deploy to App Store!

---

## 🆘 Need Help?

Check these files for more details:
- `SECURITY_MIGRATION_COMPLETE.md` - Full overview
- `SECURITY_OVERHAUL_DEPLOYMENT_GUIDE.md` - Detailed guide
- `REMOVE_USERID_PARAMETERS.md` - Architecture changes

Or review:
- Supabase Edge Functions docs: https://supabase.com/docs/guides/functions
- Supabase RLS docs: https://supabase.com/docs/guides/auth/row-level-security

