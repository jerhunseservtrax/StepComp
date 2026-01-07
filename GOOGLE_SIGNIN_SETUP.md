# Google Sign-In Setup Guide for StepComp

## ✅ Current Status
Google Sign-In is **already implemented in the code** but needs backend configuration.

## 📋 Prerequisites
- Supabase project
- Google Cloud Console account
- Xcode with your StepComp project

---

## 🔧 Step 1: Configure Google Cloud Console

### 1.1 Create OAuth Client ID
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select your existing one
3. Navigate to **APIs & Services** → **Credentials**
4. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
5. Select **Web application** as the application type (NOT iOS - Supabase handles OAuth server-side)
6. Enter your app details:
   - **Name**: StepComp
7. **CRITICAL - Add Authorized redirect URI**:
   ```
   https://cwrirmowykxajumjokjj.supabase.co/auth/v1/callback
   ```
   ⚠️ **Without this, you'll get Error 400: redirect_uri_mismatch**
8. Click **Create**
9. **Save the Client ID AND Client Secret** (you'll need both for Supabase)

### 1.2 Get Your Bundle ID
In Xcode:
1. Select your project in the Navigator
2. Select the StepComp target
3. Go to **General** tab
4. Copy the **Bundle Identifier**

---

## 🗄️ Step 2: Configure Supabase

### 2.1 Enable Google Provider
1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your StepComp project
3. Navigate to **Authentication** → **Providers**
4. Find **Google** in the list
5. Toggle it **ON** (should turn green/enabled)
6. Enter the configuration **EXACTLY as shown**:
   - **Client ID (for OAuth)**: `704127110518-d0du7lnccucpq3015ahkg4a2eqivrtkp.apps.googleusercontent.com`
   - **Client Secret (for OAuth)**: `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`
   
   ⚠️ **CRITICAL**: These values must match your Google Cloud Console OAuth client EXACTLY
   ⚠️ **Common mistake**: Using an old/different Client ID will cause "Error 401: deleted_client"

7. Click **Save**
8. Wait 1-2 minutes for changes to propagate

### 2.2 Configure Redirect URLs ⚠️ CRITICAL
In Supabase Dashboard:
1. Go to **Authentication** → **URL Configuration**
2. Under **Redirect URLs**, add your app's custom URL scheme:
   ```
   stepcomp://auth-callback
   ```
   ⚠️ **Without this, you'll get "Safari cannot open the page because the address is invalid"**
   
3. The URL must be **exact** - no trailing slashes, correct scheme
4. Click **Save**
5. Wait 1 minute for changes to propagate

**Why this is needed:** After Google authenticates the user, Supabase needs to redirect back to your app. This redirect URL tells Supabase which custom URL scheme to use.

---

## 📱 Step 3: Configure iOS App

### 3.1 Add URL Scheme
1. In Xcode, select your **StepComp** target
2. Go to **Info** tab
3. Expand **URL Types**
4. Click **+** to add a new URL Type
5. Enter:
   - **Identifier**: `com.yourcompany.StepComp.auth`
   - **URL Schemes**: `stepcomp`
   - **Role**: Editor

### 3.2 Verify SupabaseConfig
✅ Your `SupabaseConfig.swift` is already configured correctly:

```swift
static let supabaseURL = "https://cwrirmowykxajumjokjj.supabase.co"
static let supabaseOAuthCallbackURL = "https://cwrirmowykxajumjokjj.supabase.co/auth/v1/callback"
static let oauthRedirectURL = URL(string: "stepcomp://auth-callback")!
```

No changes needed here! ✅

---

## 🧪 Step 4: Test the Implementation

### 4.1 Run the App
1. Build and run the app in Xcode
2. Navigate to the Sign-In screen
3. Tap **"Sign in with Google"**
4. You should see:
   - Safari opens with Google sign-in page
   - Sign in with your Google account
   - App redirects back with authentication

### 4.2 Debugging
If it doesn't work, check Xcode console for logs:
- Look for lines starting with `🔵` (info)
- Look for lines starting with `❌` (errors)
- Look for lines starting with `✅` (success)

Common issues:
- **"Invalid redirect URL"**: Check URL scheme in Xcode matches Supabase
- **"OAuth configuration missing"**: Verify Google provider is enabled in Supabase
- **"Client ID invalid"**: Double-check Client ID in Supabase matches Google Console

---

## 📝 What's Already Implemented

### ✅ In `AuthService.swift`:
- `signInWithGoogle()` - Generates OAuth URL
- OAuth callback handling
- User profile creation after sign-in

### ✅ In `SignInView.swift`:
- Google Sign-In button UI
- `handleGoogleSignIn()` function
- OAuth flow with `ASWebAuthenticationSession`

### ✅ In `SessionViewModel.swift`:
- OAuth callback handling
- Session management after Google sign-in

---

## 🎯 Expected Flow

```
User taps "Sign in with Google"
    ↓
App generates OAuth URL via Supabase
    ↓
ASWebAuthenticationSession opens Safari
    ↓
User signs in with Google
    ↓
Google redirects to Supabase callback
    ↓
Supabase processes OAuth
    ↓
Redirects to stepcomp://auth-callback
    ↓
App receives callback
    ↓
SessionViewModel handles authentication
    ↓
User is signed in ✅
```

---

## 🚨 Important Notes

1. **Testing on Simulator**: OAuth flows work better on a real device
2. **Bundle ID**: Must match exactly between Xcode and Google Console
3. **URL Scheme**: Must be lowercase and match Supabase configuration
4. **First-time setup**: You'll need to enable "Less secure app access" for the Google account used in testing (or use a test account)

---

## 🐛 Troubleshooting

### Issue: "Error 400: redirect_uri_mismatch"
**Solution**: Add the Supabase callback URL to Google Cloud Console:
1. Go to Google Cloud Console → APIs & Services → Credentials
2. Edit your OAuth 2.0 Client ID
3. Add this to **Authorized redirect URIs**:
   ```
   https://cwrirmowykxajumjokjj.supabase.co/auth/v1/callback
   ```
4. Save and wait 5 minutes for changes to propagate

### Issue: "Invalid redirect URI"
**Solution**: Ensure `stepcomp://auth-callback` is added to Supabase's Redirect URLs

### Issue: Button doesn't respond
**Solution**: Already fixed in the latest code - button now has explicit action closure

### Issue: "Session not found" after redirect
**Solution**: Check that `SessionViewModel` has the OAuth callback handler properly set up

### Issue: Google sign-in opens but doesn't return to app
**Solution**: 
1. Verify URL scheme is registered in Info.plist
2. Check that `SceneDelegate` or `AppDelegate` handles the custom URL scheme

---

## 📞 Need Help?

Check the logs in Xcode console when testing:
```
🔵 signInWithGoogle called
🔵 Using Supabase OAuth for Google Sign-In
🔵 Calling supabase.auth.getOAuthSignInURL...
✅ Google OAuth URL generated: [URL]
```

If you see errors, they'll be logged with `❌` or `⚠️` prefixes.

---

## ✨ After Setup

Once configured, users can:
- Sign in with their Google account
- Create a new account using Google
- Link existing accounts (future feature)

The Google Sign-In button is ready to use - just complete the backend configuration! 🚀

