# HealthKit Setup Fix

This guide will help you fix the HealthKit entitlement and Info.plist issues.

## Errors to Fix

1. `Missing com.apple.developer.healthkit entitlement`
2. `HealthKit usage descriptions missing in Info.plist`

## Step 1: Add HealthKit Capability in Xcode

1. Open your project in Xcode
2. Select your **StepComp** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Search for and add **HealthKit**
6. This will automatically:
   - Add the HealthKit entitlement to your app
   - Update your entitlements file

## Step 2: Add HealthKit Usage Descriptions to Info.plist

1. In Xcode, find and open **Info.plist** (or your target's Info settings)
2. Add the following keys with appropriate descriptions:

### Option A: Using Xcode UI

1. Right-click in the Info.plist editor
2. Select **Add Row**
3. Add these keys one by one:

| Key | Type | Value |
|-----|------|-------|
| `NSHealthShareUsageDescription` | String | "StepComp needs access to your step count data to track your progress in challenges and show your activity on leaderboards." |
| `NSHealthUpdateUsageDescription` | String | "StepComp needs permission to update your step count data when you sync your activity." |

### Option B: Using Raw Keys

If you're editing the raw plist file, add:

```xml
<key>NSHealthShareUsageDescription</key>
<string>StepComp needs access to your step count data to track your progress in challenges and show your activity on leaderboards.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>StepComp needs permission to update your step count data when you sync your activity.</string>
```

## Step 3: Verify Setup

1. Build and run your app
2. The HealthKit permission dialog should appear when the app requests access
3. Check that the errors are gone in the console

## Step 4: Test HealthKit Access

The app should now be able to:
- Request HealthKit authorization
- Read step count data
- Update step data (if needed)

## Troubleshooting

### If errors persist:

1. **Clean Build Folder**: Product → Clean Build Folder (Shift+Cmd+K)
2. **Delete Derived Data**: 
   - Xcode → Preferences → Locations
   - Click arrow next to Derived Data path
   - Delete the StepComp folder
3. **Rebuild**: Product → Build (Cmd+B)

### If HealthKit capability doesn't appear:

1. Make sure you're signed in with an Apple Developer account
2. Check that your Bundle Identifier is unique
3. Try restarting Xcode

## Notes

- HealthKit requires a physical device or simulator with iOS 8.0+
- The usage descriptions are required by Apple and will be shown to users when requesting permission
- Make sure your descriptions are clear and explain why you need the data

