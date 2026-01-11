# HealthKit Testing Guide

## Overview
This guide explains how to test the Apple Health (HealthKit) connection in your StepComp app.

## Accessing the Test View

1. **Open the App** → Navigate to **Settings** (gear icon in bottom tab bar)
2. **Scroll down** to find the **"Developer Tools"** section (only visible in DEBUG builds)
3. **Tap "Test HealthKit Connection"** button

## What the Test View Shows

### 1. Status Header
- **Green Checkmark**: HealthKit is authorized and working
- **Orange Question Mark**: HealthKit available but not authorized
- **Red X**: HealthKit not available (missing entitlement or unsupported device)

### 2. Authorization Section
- **Current Status**: Shows authorization state (Not Determined, Denied, Authorized)
- **Request Access Button**: Appears if not authorized - tap to request HealthKit permissions
- **Refresh Status Button**: Manually check current authorization status

### 3. Step Reading Test
- **Today's Steps Display**: Shows current step count (if authorized)
- **Read Today's Steps Button**: Tests reading steps from HealthKit
- Only available when HealthKit is authorized

### 4. Test Results
Automatically runs tests on view appearance:
- ✅ **HealthKit Available**: Checks if HealthKit is available on device
- ✅ **Authorization Status**: Checks current authorization state
- ✅ **Read Today's Steps**: Tests reading step data (manual test)

### 5. Configuration Info
Displays:
- HealthKit Available: Yes/No
- Authorization Status: Current status
- Is Authorized: Yes/No
- Device Supports HealthKit: Yes/No

## Testing Steps

### Step 1: Check Availability
1. Open the HealthKit Test view
2. Check the status header - should show if HealthKit is available
3. Review test results - "HealthKit Available" should be ✅

### Step 2: Request Authorization
1. If not authorized, tap **"Request Access"** button
2. iOS will show the HealthKit permission dialog
3. Tap **"Turn All Categories On"** or select specific permissions
4. Tap **"Allow"** to grant access

### Step 3: Test Step Reading
1. After authorization, tap **"Read Today's Steps"** button
2. The app will query HealthKit for today's step count
3. Steps should display in the "Today's Steps" section
4. Test result should show ✅ with step count

### Step 4: Verify in Health App
1. Open the **Health** app on your iPhone
2. Go to **Browse** → **Activity** → **Steps**
3. Verify your step data is being tracked
4. The test view should match the Health app data

## Troubleshooting

### "HealthKit not available"
**Possible causes:**
- Missing HealthKit entitlement in Xcode
- Running on simulator (HealthKit requires real device)
- Missing Info.plist entries

**Solution:**
1. Check Xcode → Target → Signing & Capabilities → Add "HealthKit" capability
2. Ensure `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` are in Info.plist
3. Test on a real iPhone (not simulator)

### "Authorization Denied"
**Possible causes:**
- User previously denied HealthKit access
- App doesn't have proper permissions

**Solution:**
1. Go to iPhone **Settings** → **Privacy & Security** → **Health**
2. Find your app and enable **"Steps"** permission
3. Or delete and reinstall the app to reset permissions

### "No steps returned"
**Possible causes:**
- No step data in Health app
- HealthKit not tracking steps
- Date range issue

**Solution:**
1. Open Health app and verify step data exists
2. Walk around with your iPhone to generate step data
3. Wait a few minutes for data to sync
4. Try reading steps again

### "Missing Info.plist entries"
**Error message:** "HealthKit usage descriptions missing in Info.plist"

**Solution:**
1. Open Xcode → Target → Info tab
2. Add these keys:
   - `NSHealthShareUsageDescription`: "We need access to your step count to track your activity in challenges."
   - `NSHealthUpdateUsageDescription`: "We need permission to update your step data for challenges."

## Expected Behavior

### ✅ Successful Test
- Status shows "Authorized" with green checkmark
- "HealthKit Available" test: ✅
- "Authorization Status" test: ✅
- "Read Today's Steps" test: ✅ with step count
- Steps display matches Health app

### ⚠️ Partial Success
- Status shows "Not Authorized" (orange)
- "HealthKit Available" test: ✅
- "Authorization Status" test: ❌ (not authorized)
- Need to request authorization

### ❌ Failure
- Status shows "Not Available" (red)
- "HealthKit Available" test: ❌
- Check entitlements and Info.plist

## Testing on Real Device

**Important:** HealthKit **does not work on the iOS Simulator**. You must test on a real iPhone.

### Requirements:
- ✅ Real iPhone (any model with iOS 14+)
- ✅ HealthKit capability enabled in Xcode
- ✅ Info.plist entries added
- ✅ App signed with development/distribution certificate

## Quick Test Checklist

- [ ] Open HealthKit Test view
- [ ] Verify HealthKit is available
- [ ] Request authorization (if needed)
- [ ] Grant permissions in iOS dialog
- [ ] Verify authorization status shows "Authorized"
- [ ] Test reading today's steps
- [ ] Verify step count matches Health app
- [ ] Check all test results show ✅

## Additional Notes

- HealthKit data may take a few minutes to sync
- Step counts update throughout the day
- Historical data is available via `getSteps(for:)` method
- The app reads steps but doesn't write to HealthKit (read-only access)

