# HealthKit Setup Instructions

## Current Issue
The app is crashing because HealthKit requires:
1. ❌ Info.plist usage description keys
2. ❌ HealthKit capability in Xcode project settings

## Quick Fix (Recommended)

### Step 1: Add Info.plist Keys in Xcode

1. Open Xcode
2. Select your project in Project Navigator
3. Select the **StepComp** target
4. Go to the **Info** tab
5. Click the **"+"** button to add a new key
6. Add these two keys:

   **Key 1:**
   - Click **"+"** → Search for **"Privacy - Health Share Usage Description"**
   - Value: `StepComp needs access to your step count, distance, and calories to track your progress in challenges and display your stats on the leaderboard.`

   **Key 2:**
   - Click **"+"** → Search for **"Privacy - Health Update Usage Description"**
   - Value: `StepComp needs permission to save your step data so you can compete in challenges and track your fitness goals.`

### Step 2: Add HealthKit Capability

1. With **StepComp** target selected, go to **Signing & Capabilities** tab
2. Click the **"+ Capability"** button (top left)
3. Search for and add **"HealthKit"**
4. This will automatically add the required entitlement

### 4. Verify Info.plist Entries

The Info.plist should contain:
- `NSHealthShareUsageDescription` - Description for reading health data
- `NSHealthUpdateUsageDescription` - Description for writing health data

Both are already in the file with appropriate descriptions.

## Alternative: Add Keys to Target Settings

If you prefer not to use a separate Info.plist file:

1. Select **StepComp** target
2. Go to **Info** tab
3. Click **"+"** to add new key
4. Add:
   - Key: `Privacy - Health Share Usage Description`
     Value: `StepComp needs access to your step count, distance, and calories to track your progress in challenges and display your stats on the leaderboard.`
   - Key: `Privacy - Health Update Usage Description`
     Value: `StepComp needs permission to save your step data so you can compete in challenges and track your fitness goals.`

## Testing

After setup:
1. Clean Build Folder: **Product → Clean Build Folder** (⇧⌘K)
2. Build and run on a **physical device** (HealthKit doesn't work in simulator)
3. The app should no longer crash when requesting HealthKit authorization

## Current Behavior

The app has been updated to:
- ✅ Check for Info.plist entries before requesting authorization
- ✅ Gracefully handle missing entitlements (won't crash)
- ✅ Show warnings in console instead of crashing
- ✅ Continue working without HealthKit (uses mock data)

## Notes

- HealthKit **only works on physical devices**, not simulators
- The app will work without HealthKit (with mock step data)
- You can skip HealthKit permission during onboarding
- The app won't crash if HealthKit isn't configured properly

