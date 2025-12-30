# HealthKit Setup Guide

## Current Status

The app **has HealthKit integration code** but **cannot access your steps yet** because:

1. ❌ HealthKit capability is not enabled in Xcode
2. ❌ Info.plist usage descriptions are missing
3. ⚠️ The app will work with mock data until these are configured

## How to Enable HealthKit Access

### Step 1: Add HealthKit Capability in Xcode

1. Open your project in Xcode
2. Select the **StepComp** project in the navigator
3. Select the **StepComp** target
4. Go to the **Signing & Capabilities** tab
5. Click the **+ Capability** button
6. Search for and add **HealthKit**
7. This will automatically add the required entitlement

### Step 2: Add Info.plist Usage Descriptions

You need to add two keys to your `Info.plist` file:

1. In Xcode, find your `Info.plist` file (or add it if it doesn't exist)
2. Add these two keys with appropriate descriptions:

```xml
<key>NSHealthShareUsageDescription</key>
<string>StepComp needs access to your step count to track your progress in challenges.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>StepComp needs permission to save your step data for challenge tracking.</string>
```

Or if using the Info.plist editor in Xcode:
- **Privacy - Health Share Usage Description**: "StepComp needs access to your step count to track your progress in challenges."
- **Privacy - Health Update Usage Description**: "StepComp needs permission to save your step data for challenge tracking."

### Step 3: Test HealthKit Access

After adding the capability and Info.plist entries:

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Rebuild**: Product → Build (⌘B)
3. **Run the app** on a physical device (HealthKit doesn't work in simulator)
4. During onboarding, tap **"Enable Health Access"**
5. Grant permission when iOS prompts you
6. The app will then be able to read your step data

## What the App Can Access

Once configured, the app requests access to:
- ✅ **Step Count** - To track daily steps
- ✅ **Walking + Running Distance** - To calculate distance traveled
- ✅ **Active Energy Burned** - To show calories burned

## Current Behavior (Without HealthKit)

Right now, the app:
- ✅ Works without crashing (gracefully handles missing entitlements)
- ✅ Shows mock/placeholder step data (0 steps, 0 calories, etc.)
- ✅ Allows you to test all features except real step tracking
- ⚠️ Cannot read your actual step data from HealthKit

## Testing HealthKit

**Important**: HealthKit only works on **physical devices**, not simulators.

To test:
1. Connect your iPhone/iPad
2. Build and run on the device
3. Complete onboarding
4. Grant HealthKit permissions when prompted
5. Check the dashboard - it should show your actual step count

## Troubleshooting

If HealthKit still doesn't work after setup:

1. **Check Entitlements**: Make sure `com.apple.developer.healthkit` is in your entitlements file
2. **Check Info.plist**: Verify both usage descriptions are present
3. **Device Settings**: Go to Settings → Privacy → Health → StepComp and ensure permissions are granted
4. **Clean Build**: Clean build folder and rebuild
5. **Check Logs**: Look for HealthKit errors in Xcode console

## Code Status

The HealthKit integration code is complete and ready:
- ✅ `HealthKitService` handles authorization
- ✅ Requests read/write permissions for steps, distance, and calories
- ✅ Gracefully handles missing entitlements (won't crash)
- ✅ Returns 0 steps when not authorized (allows app to continue working)

