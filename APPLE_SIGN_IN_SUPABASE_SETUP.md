# Apple Sign In with Supabase - Complete Setup Guide

## ✅ Code Implementation Complete

The app now has **full Supabase integration** for Apple Sign In! The code:
- ✅ Extracts identity token from Apple credential
- ✅ Uses Supabase OAuth to authenticate
- ✅ Creates/updates user profile automatically
- ✅ Handles first-time and returning users

## 🔧 Required Setup Steps

### Step 1: Enable Sign in with Apple Capability in Xcode

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
3. Select **Identifiers** → Your App ID (e.g., `JE.StepComp`)
4. Enable **Sign in with Apple** capability
5. Click **Configure** next to Sign in with Apple
6. Select **Enable as a primary App ID**
7. Click **Save**
8. Click **Continue** and **Register**

### Step 3: Create a Services ID for Sign in with Apple

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Identifiers**
4. Click the **+** button to create a new identifier
5. Select **Services IDs** and click **Continue**
6. Enter a **Description** (e.g., "StepComp Web Sign In")
7. Enter an **Identifier** (e.g., `com.stepcomp.web` or `je.stepcomp.web`)
8. Click **Continue** and **Register**
9. Click on the newly created Services ID
10. Enable **Sign in with Apple**
11. Click **Configure**
12. Select your **Primary App ID** (e.g., `JE.StepComp`)
13. Under **Website URLs**, add:
    - **Domains**: `cwrirmowykxajumjokjj.supabase.co`
    - **Return URLs**: `https://cwrirmowykxajumjokjj.supabase.co/auth/v1/callback`
14. Click **Save**, then **Continue**, then **Register**

### Step 4: Create a Client Secret (Secret Key)

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Keys** (under "Certificates")
4. Click the **+** button to create a new key
5. Enter a **Key Name** (e.g., "StepComp Apple OAuth")
6. Enable **Sign in with Apple**
7. Click **Configure**
8. Select your **Primary App ID** (e.g., `JE.StepComp`)
9. Click **Save**
10. Click **Continue** and **Register**
11. **Download the key** (`.p8` file) - **You can only download this once!**
12. Note the **Key ID** (you'll need this)
13. Note your **Team ID** (found in Apple Developer Portal → Membership)

### Step 5: Generate Client Secret

You need to generate a client secret (JWT) from your private key. You can use one of these methods:

**Option A: Using a JWT generator tool**
1. Go to https://appleid.apple.com/auth/keys or use a JWT generator
2. Use your Team ID, Key ID, Services ID, and the .p8 private key
3. Generate a JWT token (this is your client secret)

**Option B: Using a script (recommended)**
Create a script to generate the secret. Here's a Node.js example:
```javascript
const jwt = require('jsonwebtoken');
const fs = require('fs');

const teamId = 'YOUR_TEAM_ID';
const keyId = 'YOUR_KEY_ID';
const clientId = 'YOUR_SERVICES_ID'; // e.g., com.stepcomp.web
const privateKey = fs.readFileSync('path/to/your/key.p8');

const token = jwt.sign(
  {
    iss: teamId,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 86400 * 180, // 6 months
    aud: 'https://appleid.apple.com',
    sub: clientId
  },
  privateKey,
  {
    algorithm: 'ES256',
    keyid: keyId
  }
);

console.log(token);
```

**Option C: Use an online tool**
- Use a JWT generator that supports ES256 algorithm
- Input your Team ID, Key ID, Services ID, and private key

### Step 6: Configure Apple Sign In in Supabase Dashboard

1. Go to https://app.supabase.com
2. Select your **StepComp Project**
3. Navigate to **Authentication → Providers**
4. Find **Apple** in the list and click to configure
5. Fill in the fields:
   - **Enable Sign in with Apple**: Toggle ON
   - **Client IDs**: Enter your Services ID (e.g., `com.stepcomp.web`) or your iOS bundle ID (e.g., `JE.StepComp`)
     - For native iOS apps, use your bundle ID: `JE.StepComp`
     - For web OAuth, use your Services ID
     - You can add multiple IDs separated by commas
   - **Secret Key (for OAuth)**: Paste the client secret (JWT token) generated in Step 5
   - **Allow users without an email**: Toggle ON if you want to allow users who hide their email
6. The **Callback URL** is already pre-filled: `https://cwrirmowykxajumjokjj.supabase.co/auth/v1/callback`
   - Make sure this matches what you configured in Apple Developer Portal
7. Click **Save**

**Important Notes:**
- The Secret Key (client secret) expires every 6 months - you'll need to regenerate it
- For native iOS apps, you primarily need the bundle ID in Client IDs
- The Secret Key is only needed for web OAuth flows

### Step 7: Configure in Supabase Dashboard

Based on the Supabase configuration panel you're seeing:

1. **Enable Sign in with Apple**: Toggle this ON (green)

2. **Client IDs**: 
   - For native iOS app: Enter your bundle ID: `JE.StepComp`
   - You can also add your Services ID if you created one for web OAuth
   - Multiple IDs can be separated by commas

3. **Secret Key (for OAuth)**:
   - Paste the client secret (JWT token) you generated in Step 5
   - This is the JWT token, NOT the raw .p8 file contents
   - ⚠️ **Important**: This secret expires every 6 months - you'll need to regenerate it

4. **Allow users without an email**: 
   - Toggle ON if you want to allow users who choose to hide their email
   - Recommended: Keep this ON for better user experience

5. **Callback URL**: 
   - Already pre-filled: `https://cwrirmowykxajumjokjj.supabase.co/auth/v1/callback`
   - Make sure this matches what you configured in Apple Developer Portal (if using web OAuth)

6. Click **Save**

### Step 8: Test Apple Sign In

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Rebuild**: Product → Build (⌘B)
3. **Run on a physical device** (Apple Sign In works best on real devices)
4. Try signing in with Apple
5. Check Xcode console for logs:
   - Should see: `✅ Apple Sign-In successful`
   - Should see: `✅ Profile created` or `✅ Profile updated`

## 🔍 Troubleshooting

### Error: "Sign in with Apple is not configured" (Error 1000)

**Solution**: 
- Make sure Sign in with Apple capability is enabled in Xcode
- Verify your App ID has Sign in with Apple enabled in Apple Developer Portal
- Ensure your provisioning profile includes the capability

### Error: "Invalid identity token"

**Solution**:
- Verify Apple Sign In is properly configured in Supabase Dashboard
- Check that Client IDs matches your bundle ID exactly (e.g., `JE.StepComp`)
- Verify the Secret Key is the JWT token (not the raw .p8 file)
- Make sure the Secret Key hasn't expired (they expire every 6 months)
- Regenerate the client secret if needed

### Error: "Profile creation failed"

**Solution**:
- Make sure you ran the database setup SQL script
- Verify the `profiles` table exists with correct columns
- Check RLS policies allow profile creation

### User profile not created

**Solution**:
- Check Xcode console for error messages
- Verify the profile was created in Supabase Dashboard → Table Editor → profiles
- The code has automatic retry logic, but check for RLS policy issues

## 📋 Verification Checklist

- [ ] Sign in with Apple capability enabled in Xcode
- [ ] App ID has Sign in with Apple enabled in Apple Developer Portal
- [ ] Sign in with Apple key created and downloaded (.p8 file)
- [ ] Apple provider enabled in Supabase Dashboard
- [ ] Client IDs configured (bundle ID: `JE.StepComp`)
- [ ] Secret Key (JWT token) generated and added to Supabase
- [ ] Callback URL verified in Supabase
- [ ] Database tables created (profiles table exists)
- [ ] Tested on physical device
- [ ] User appears in Supabase Authentication → Users after sign-in
- [ ] Profile appears in Supabase Table Editor → profiles

## 🎯 How It Works

### First Time Sign In:
1. User taps "Sign in with Apple"
2. Apple shows authentication dialog
3. User authorizes (provides email/name on first sign-in)
4. App receives identity token from Apple
5. App sends identity token to Supabase
6. Supabase creates user account
7. App creates profile in `profiles` table
8. User is authenticated

### Returning User:
1. User taps "Sign in with Apple"
2. Apple shows authentication dialog (may use Face ID/Touch ID)
3. App receives identity token
4. App sends to Supabase
5. Supabase authenticates existing user
6. App loads user profile
7. User is authenticated

## 📚 Additional Resources

- [Supabase Apple OAuth Docs](https://supabase.com/docs/guides/auth/social-login/auth-apple)
- [Apple Sign in with Apple Docs](https://developer.apple.com/sign-in-with-apple/)
- [Your Setup Guide](APPLE_SIGN_IN_SETUP.md)

## 🎉 You're All Set!

Once you complete the setup steps above, Apple Sign In will work seamlessly with Supabase!

