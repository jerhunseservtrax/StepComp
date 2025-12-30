# Google Sign-In Debugging Guide

## 🔍 Current Issue

Google Sign-In is not working. The logs don't show specific Google OAuth errors, which suggests the OAuth flow might not be initiating properly or the callback isn't being handled correctly.

## 🔧 Fixes Applied

### Fix 1: Improved OAuth Callback Handling
- Added detailed logging to track OAuth callback flow
- Improved error handling and session checking
- Added checks for OAuth tokens in URL fragments/query parameters

### Fix 2: Corrected OAuth Redirect URL
- Updated to use Supabase callback URL with `redirect_to` parameter
- Format: `https://cwrirmowykxajumjokjj.supabase.co/auth/v1/callback?redirect_to=je.stepcomp://auth-callback`

### Fix 3: Enhanced Logging
- Added console logs to track:
  - OAuth URL generation
  - Callback URL reception
  - Session establishment
  - Authentication status

## 🧪 Testing Steps

### Step 1: Check Console Logs
When you tap "Continue with Google", you should see:
1. `🔵 Google OAuth URL generated: [URL]`
2. Browser/Safari should open with Google sign-in page
3. After signing in, you should see:
   - `🔵 OAuth callback received: [URL]`
   - `✅ OAuth session established: [user-id]`
   - `✅ User authenticated successfully`

### Step 2: Verify Supabase Configuration
1. Go to: https://app.supabase.com/project/cwrirmowykxajumjokjj
2. Navigate to **Authentication → URL Configuration**
3. Verify **Site URL** is set (can be any valid URL)
4. Verify **Redirect URLs** includes:
   - `je.stepcomp://auth-callback`
   - `https://cwrirmowykxajumjokjj.supabase.co/auth/v1/callback`

### Step 3: Verify Google OAuth Configuration
1. Go to: https://console.cloud.google.com
2. Navigate to **APIs & Services → Credentials**
3. Find your OAuth 2.0 Client ID
4. Under **Authorized redirect URIs**, verify:
   - `https://cwrirmowykxajumjokjj.supabase.co/auth/v1/callback`

### Step 4: Test the Flow
1. Open the app
2. Navigate to Sign In screen
3. Tap "Continue with Google"
4. **Expected Behavior**:
   - Browser/Safari opens
   - Google sign-in page loads
   - After signing in, redirects back to app
   - App receives callback and authenticates user

## 🐛 Common Issues & Solutions

### Issue 1: Browser Doesn't Open
**Symptoms**: Nothing happens when tapping "Continue with Google"

**Possible Causes**:
- OAuth URL generation failed
- Supabase client not initialized
- Network error

**Solution**:
- Check console logs for errors
- Verify Supabase package is installed
- Check network connectivity

### Issue 2: Browser Opens But Shows Error
**Symptoms**: Browser opens but shows an error page

**Possible Causes**:
- Invalid redirect URL in Supabase Dashboard
- Google OAuth not configured correctly
- Client ID/Secret mismatch

**Solution**:
- Verify redirect URL in Supabase Dashboard matches exactly
- Check Google Cloud Console configuration
- Verify Client ID and Secret are correct

### Issue 3: Callback Not Received
**Symptoms**: Sign-in succeeds in browser but app doesn't receive callback

**Possible Causes**:
- URL scheme not configured in Info.plist
- `onOpenURL` handler not working
- Redirect URL mismatch

**Solution**:
- Verify `CFBundleURLTypes` in Info.plist includes `je.stepcomp`
- Check that `onOpenURL` handler is attached
- Verify redirect URL matches exactly

### Issue 4: Session Not Established
**Symptoms**: Callback received but user not authenticated

**Possible Causes**:
- Session processing failed
- Profile creation failed
- Database permissions issue

**Solution**:
- Check console logs for session errors
- Verify profile table exists and has correct RLS policies
- Check Supabase Dashboard for errors

## 📝 Debug Checklist

- [ ] Supabase package is installed and imported
- [ ] `useSupabase = true` in AuthService
- [ ] Google provider enabled in Supabase Dashboard
- [ ] Client ID and Secret configured in Supabase Dashboard
- [ ] Redirect URL configured in Supabase Dashboard
- [ ] Redirect URI added in Google Cloud Console
- [ ] Info.plist contains `CFBundleURLTypes` with `je.stepcomp`
- [ ] `onOpenURL` handler is attached in app
- [ ] Console logs show OAuth URL generation
- [ ] Browser opens when tapping Google Sign-In button
- [ ] Callback URL is received after Google sign-in
- [ ] Session is established after callback

## 🔗 Related Files

- `StepComp/Services/AuthService.swift` - OAuth URL generation
- `StepComp/Screens/Onboarding/SignInView.swift` - OAuth callback handling
- `StepComp/StepCompApp.swift` - App-level callback handler
- `StepComp/Services/SupabaseClient.swift` - OAuth configuration

## 📞 Next Steps

1. **Test the flow** and check console logs
2. **Share the console output** if issues persist
3. **Verify Supabase Dashboard** configuration
4. **Check Google Cloud Console** settings

---

**Note**: The HealthKit and Apple Sign-In errors in your logs are unrelated to Google Sign-In. Those are separate configuration issues that don't affect Google OAuth.

