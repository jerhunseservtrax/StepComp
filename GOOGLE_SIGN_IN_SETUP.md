# Google Sign-In Setup Guide

## 🔑 Your Google Client ID

**Client ID:** `704127110518-fcj9p8s8na0oo9h5e4rv93b7victn1ge.apps.googleusercontent.com`

---

## 📋 Setup Steps

### Step 1: Configure in Supabase Dashboard

1. Go to: https://app.supabase.com/project/cwrirmowykxajumjokjj
2. Click **Authentication → Providers** in the left sidebar
3. Find **Google** in the list
4. Click **Enable** Google provider
5. Enter your credentials:
   - **Client ID (for OAuth)**: `704127110518-fcj9p8s8na0oo9h5e4rv93b7victn1ge.apps.googleusercontent.com`
   - **Client Secret**: Get this from Google Cloud Console (see below)

### Step 2: Get Client Secret from Google Cloud Console

1. Go to: https://console.cloud.google.com
2. Select your project (or create one)
3. Go to **APIs & Services → Credentials**
4. Find your OAuth 2.0 Client ID: `704127110518-fcj9p8s8na0oo9h5e4rv93b7victn1ge`
5. Click to view details
6. Copy the **Client Secret**
7. Paste it into Supabase Dashboard → Authentication → Providers → Google

### Step 3: Configure Authorized Redirect URIs

In Google Cloud Console → Credentials → Your OAuth Client:

**Add these Authorized Redirect URIs:**

```
https://cwrirmowykxajumjokjj.supabase.co/auth/v1/callback
```

**For iOS (if using native Google Sign-In SDK):**
```
com.googleusercontent.apps.704127110518-fcj9p8s8na0oo9h5e4rv93b7victn1ge:/oauth2redirect
```

### Step 4: Update App Code

The app code needs to be updated to use Google Sign-In SDK or Supabase's OAuth flow.

**Option A: Use Supabase OAuth (Recommended)**
- Simpler - uses Supabase's built-in OAuth
- No additional SDK needed
- Works with web-based flow

**Option B: Use Google Sign-In SDK**
- Native iOS experience
- Requires Google Sign-In SDK installation
- Better UX on iOS

---

## 🔧 Current Implementation Status

### Current Code:
- `AuthService.signInWithGoogle()` - Mock implementation
- `SignInView` - Has Google button but uses mock

### What Needs to Be Done:

1. **Install Google Sign-In SDK** (if using native approach)
   - Add via Swift Package Manager
   - Or use Supabase OAuth (no SDK needed)

2. **Update AuthService**
   - Implement real Google Sign-In flow
   - Connect to Supabase Auth

3. **Update SignInView**
   - Handle Google Sign-In button tap
   - Show loading state
   - Handle errors

---

## 📱 Implementation Options

### Option 1: Supabase OAuth (Web-based)

**Pros:**
- ✅ No additional SDK needed
- ✅ Works immediately
- ✅ Simpler implementation

**Cons:**
- ⚠️ Opens web browser/Safari
- ⚠️ Less native feel

**Implementation:**
```swift
// In AuthService
func signInWithGoogle() async throws {
    let url = try await supabase.auth.signInWithOAuth(
        provider: .google,
        redirectTo: URL(string: "stepcomp://auth-callback")!
    )
    // Open URL in Safari/ASWebAuthenticationSession
}
```

### Option 2: Google Sign-In SDK (Native)

**Pros:**
- ✅ Native iOS experience
- ✅ Better UX
- ✅ No browser redirect

**Cons:**
- ⚠️ Requires Google Sign-In SDK
- ⚠️ More setup

**Implementation:**
1. Add Google Sign-In SDK
2. Configure in Xcode
3. Use Google SDK to get ID token
4. Sign in to Supabase with ID token

---

## 🎯 Recommended Approach

For now, I recommend **Option 1 (Supabase OAuth)** because:
- ✅ Already have Supabase configured
- ✅ No additional SDK needed
- ✅ Faster to implement
- ✅ Works immediately

You can upgrade to native Google Sign-In SDK later if needed.

---

## 📝 Next Steps

1. **Configure in Supabase Dashboard** (see Step 1-2 above)
2. **Add redirect URI** in Google Cloud Console
3. **Update AuthService** to use Supabase OAuth
4. **Update SignInView** to handle OAuth flow
5. **Test Google Sign-In**

---

## 🔍 Verify Configuration

After setup, test:
1. Run the app
2. Tap "Continue with Google"
3. Should open browser/Safari
4. Sign in with Google account
5. Should redirect back to app
6. User should be authenticated

---

## 📚 Resources

- **Supabase Auth Docs**: https://supabase.com/docs/guides/auth/social-login/auth-google
- **Google Cloud Console**: https://console.cloud.google.com
- **Supabase Dashboard**: https://app.supabase.com/project/cwrirmowykxajumjokjj

---

## ⚠️ Important Notes

1. **Client Secret** is required - get it from Google Cloud Console
2. **Redirect URI** must match exactly in both Google Console and Supabase
3. **Bundle ID** must match: `JE.StepComp`
4. **OAuth Consent Screen** must be configured in Google Cloud Console

---

Would you like me to implement the Google Sign-In flow using Supabase OAuth?

