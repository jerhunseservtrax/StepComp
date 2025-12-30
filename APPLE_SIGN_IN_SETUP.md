# Sign in with Apple Setup Guide

## Current Status

The app **has Sign in with Apple code** but **cannot authenticate** because:

1. ❌ Sign in with Apple capability is not enabled in Xcode
2. ❌ App needs to be properly signed with a provisioning profile
3. ⚠️ The app will show a helpful error message and suggest using email sign in instead

## Error Code 1000

The error `ASAuthorizationController credential request failed with error: Error Domain=com.apple.AuthenticationServices.AuthorizationError Code=1000` means:

- **Sign in with Apple capability is missing** from your app's entitlements
- The app needs to be configured in Apple Developer Portal
- The app needs proper code signing

## How to Enable Sign in with Apple

### Step 1: Enable Capability in Xcode

1. Open your project in Xcode
2. Select the **StepComp** project in the navigator
3. Select the **StepComp** target
4. Go to the **Signing & Capabilities** tab
5. Click the **+ Capability** button
6. Search for and add **Sign in with Apple**
7. This will automatically add the required entitlement

### Step 2: Configure in Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Identifiers** → Your App ID
4. Enable **Sign in with Apple** capability
5. Save the changes

### Step 3: Update Provisioning Profile

1. In Apple Developer Portal, go to **Profiles**
2. Edit your App Store/Development provisioning profile
3. Make sure it includes the Sign in with Apple capability
4. Download and install the updated profile
5. In Xcode, select the updated profile in **Signing & Capabilities**

### Step 4: Test

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Rebuild**: Product → Build (⌘B)
3. **Run on a physical device** (Sign in with Apple works best on real devices)
4. Try signing in with Apple

## Current Behavior

The app has been updated to:
- ✅ Handle Sign in with Apple errors gracefully
- ✅ Show helpful error messages
- ✅ Suggest using email sign in as an alternative
- ✅ Continue working even if Sign in with Apple fails

## Workaround

Until Sign in with Apple is configured:
- ✅ **Email/Password sign in works** - Users can create accounts with email
- ✅ **Google sign in works** - Mock implementation (ready for Google SDK)
- ⚠️ **Apple sign in** - Shows error message, suggests email sign in

## Notes

- Sign in with Apple requires:
  - Valid Apple Developer account
  - App ID with Sign in with Apple enabled
  - Proper provisioning profile
  - App must be signed (not just running in simulator)
  
- The error handling will guide users to use email sign in if Apple Sign In isn't configured
- Once configured, Sign in with Apple will work automatically

