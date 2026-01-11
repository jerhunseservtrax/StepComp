# HealthKit Step Sync Setup Guide

## Overview
Your app now automatically syncs HealthKit step data to your Supabase account! This guide explains how to set it up and how it works.

## What's Been Implemented

### 1. StepSyncService
A new service (`StepSyncService.swift`) that:
- Reads today's steps from HealthKit
- Syncs steps to your user profile in Supabase
- Syncs steps to all active challenges you're participating in
- Runs automatically when you open the app or refresh the home screen

### 2. Automatic Sync
Steps are automatically synced:
- ✅ When you open the home screen
- ✅ When you pull to refresh on the home screen
- ✅ When HealthKit data is loaded in DashboardViewModel
- ✅ To your user profile (`profiles.total_steps`)
- ✅ To all active challenges (`challenge_members.daily_steps`)

## Setup Steps

### Step 1: Add `total_steps` Column to Database

Run this SQL in your Supabase SQL Editor:

```sql
-- Add total_steps column to profiles table
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS total_steps INTEGER DEFAULT 0;

-- Create an index for faster queries
CREATE INDEX IF NOT EXISTS idx_profiles_total_steps ON profiles(total_steps DESC);
```

**How to run:**
1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Click **New Query**
4. Paste the SQL above
5. Click **Run**

### Step 2: Enable HealthKit (If Not Already Done)

1. **Add HealthKit Capability in Xcode:**
   - Open Xcode → Select your project
   - Go to **Signing & Capabilities** tab
   - Click **+ Capability**
   - Add **HealthKit**

2. **Add Info.plist Entries:**
   - In Xcode, find your `Info.plist`
   - Add these keys:
     - `NSHealthShareUsageDescription`: "StepComp needs access to your step count to track your progress in challenges."
     - `NSHealthUpdateUsageDescription`: "StepComp needs permission to save your step data for challenge tracking."

### Step 3: Grant HealthKit Permissions

1. **During Onboarding:**
   - When you see the Health Permission screen, tap **"Enable Health Access"**
   - Grant permissions when iOS prompts you

2. **Or Later in Settings:**
   - Go to **Settings** → **Developer Tools** → **Test HealthKit Connection**
   - Tap **"Request Access"** if not already authorized

### Step 4: Test the Sync

1. **Build and run the app** on a real iPhone (HealthKit doesn't work in simulator)
2. **Walk around** to generate step data (or use the Health app to add test data)
3. **Open the app** and go to the **Home** screen
4. **Pull down to refresh** - this triggers step sync
5. **Check the console logs** - you should see:
   - `🔄 Syncing X steps to profile for user...`
   - `✅ Successfully synced X steps to profile`
   - `✅ Synced steps to all active challenges`

## How It Works

### Step Flow

1. **App Opens** → `HomeDashboardView.onAppear` triggers
2. **DashboardViewModel** loads step data from HealthKit
3. **StepSyncService** automatically syncs:
   - Steps to `profiles.total_steps` (your profile)
   - Steps to `challenge_members.daily_steps` (all your challenges)
4. **UI Updates** with your current step count

### Data Storage

- **User Profile**: `profiles.total_steps` - Your total steps (updated daily)
- **Challenges**: `challenge_members.daily_steps` - JSONB object with daily breakdown
  ```json
  {
    "2025-01-15": 8500,
    "2025-01-16": 9200,
    ...
  }
  ```

## Verification

### Check Your Profile in Supabase

1. Go to Supabase Dashboard → **Table Editor** → `profiles`
2. Find your user row
3. Check the `total_steps` column - it should show your current step count

### Check Challenge Data

1. Go to **Table Editor** → `challenge_members`
2. Find your user's entries
3. Check the `daily_steps` JSONB column - it should contain today's date and step count

### Check in the App

1. **Home Screen**: Your step count should display in the dashboard
2. **Leaderboard**: Your steps should appear in challenge leaderboards
3. **Profile**: Your total steps should be visible in your profile

## Troubleshooting

### Steps Not Syncing

**Check:**
1. ✅ HealthKit is authorized (Settings → Developer Tools → Test HealthKit Connection)
2. ✅ You have step data in the Health app
3. ✅ You're running on a real device (not simulator)
4. ✅ `total_steps` column exists in `profiles` table
5. ✅ Check console logs for error messages

### "Field may not exist" Warning

**Solution:**
- Run the SQL migration from Step 1 above
- The `total_steps` column needs to exist in the `profiles` table

### Steps Show as 0

**Possible causes:**
- HealthKit not authorized
- No step data in Health app
- Running on simulator (HealthKit doesn't work there)
- Steps haven't synced yet (try pull-to-refresh)

**Solution:**
1. Grant HealthKit permissions
2. Walk around or add test data in Health app
3. Pull down to refresh on home screen
4. Check console logs

### Sync Not Happening Automatically

**Solution:**
- Steps sync when:
  - Home screen appears
  - You pull to refresh
  - DashboardViewModel loads data
- If it's not syncing, manually trigger by pulling down to refresh

## Manual Sync

You can also manually trigger a sync:

1. **Pull to refresh** on the home screen
2. **Or** go to Settings → Developer Tools → Test HealthKit Connection → Tap "Read Today's Steps"

## Next Steps

- ✅ Steps now sync automatically to your account
- ✅ Steps appear in challenges and leaderboards
- ✅ Your profile shows your total steps
- ✅ All active challenges update with your daily steps

Your HealthKit data is now fully integrated with your StepComp account! 🎉

