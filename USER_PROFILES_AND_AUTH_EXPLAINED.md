# User Profiles & Authentication - Complete Guide

## 📋 Table of Contents
1. [How User Profiles Are Saved](#how-user-profiles-are-saved)
2. [Why Apple Sign In & Google Auth Aren't Working](#why-apple-sign-in--google-auth-arent-working)
3. [Will These Work in the App Store?](#will-these-work-in-the-app-store)
4. [Current vs. Production Setup](#current-vs-production-setup)

---

## 🔐 How User Profiles Are Saved

### Current Implementation (Development/Mock Mode)

**Storage Method: `UserDefaults` (Local Device Storage)**

When a user signs up or signs in, their profile is saved locally on the device:

```swift
// Location: AuthService.swift - saveUser()
private func saveUser() {
    if let user = currentUser,
       let encoded = try? JSONEncoder().encode(user) {
        UserDefaults.standard.set(encoded, forKey: "currentUser")
    }
}
```

**What Gets Saved:**
- ✅ User ID (UUID)
- ✅ Display Name
- ✅ Email (if provided)
- ✅ Avatar URL (if selected)
- ✅ Total Steps
- ✅ Total Challenges
- ✅ Badges
- ✅ Created Date

**Limitations:**
- ❌ **Data is only stored on the device** - Lost if app is deleted
- ❌ **No cloud sync** - Can't access from other devices
- ❌ **No backend validation** - Anyone can create accounts
- ❌ **No password security** - Passwords aren't actually validated
- ❌ **No account recovery** - Can't reset password

### Production Implementation (When Supabase is Enabled)

**Storage Method: Supabase Database (Cloud)**

When `useSupabase = true` in `AuthService.swift`:

1. **Authentication** → Supabase Auth
   - User credentials stored securely
   - Session management handled by Supabase
   - Password hashing & security handled automatically

2. **User Profile** → Supabase `profiles` table
   ```sql
   profiles (
     user_id (UUID, FK to auth.users),
     username (TEXT),
     avatar (TEXT),
     is_premium (BOOLEAN)
   )
   ```

3. **Data Persistence**
   - ✅ **Cloud storage** - Accessible from any device
   - ✅ **Secure authentication** - Industry-standard security
   - ✅ **Account recovery** - Password reset via email
   - ✅ **Multi-device sync** - Same account on all devices
   - ✅ **Data backup** - Automatic backups by Supabase

**Current Status:**
- `useSupabase = false` → Using mock/local storage
- `useSupabase = true` → Will use Supabase (needs configuration)

---

## ❌ Why Apple Sign In & Google Auth Aren't Working

### Apple Sign In - Error Code 1000

**Problem:**
```
ASAuthorizationController credential request failed with error: 
Error Domain=com.apple.AuthenticationServices.AuthorizationError Code=1000
```

**Root Cause:**
1. ❌ **Sign in with Apple capability is NOT enabled** in Xcode
2. ❌ **App ID doesn't have Sign in with Apple** enabled in Apple Developer Portal
3. ❌ **Provisioning profile** doesn't include the capability
4. ⚠️ **App may not be properly signed** (simulator vs. device)

**Current Behavior:**
- The app shows a helpful error message
- Suggests using email sign-in instead
- App continues to work normally

**What Needs to Happen:**
1. Enable "Sign in with Apple" capability in Xcode
2. Configure in Apple Developer Portal
3. Update provisioning profile
4. Rebuild and test on a physical device

📖 **See:** `APPLE_SIGN_IN_SETUP.md` for detailed instructions

### Google Sign In

**Problem:**
- Currently using a **mock implementation**
- No actual Google Sign-In SDK integration
- Creates a fake user account locally

**Root Cause:**
- ❌ **Google Sign-In SDK not installed**
- ❌ **No Google OAuth configuration**
- ❌ **No backend integration** (Supabase Google provider)

**Current Behavior:**
- Button works and creates a mock user
- User can proceed through onboarding
- Data is saved locally (UserDefaults)

**What Needs to Happen:**
1. Install Google Sign-In SDK via Swift Package Manager
2. Configure Google OAuth in Google Cloud Console
3. Enable Google provider in Supabase
4. Implement real Google Sign-In flow

---

## 🚀 Will These Work in the App Store?

### Short Answer: **NO, not without configuration**

### Detailed Breakdown:

#### ✅ **Email/Password Sign-In**
- **Current:** Works (mock mode)
- **App Store:** ✅ **Will work** if Supabase is configured
- **Action Required:** Set `useSupabase = true` and configure Supabase

#### ❌ **Apple Sign In**
- **Current:** ❌ Not working (capability not enabled)
- **App Store:** ❌ **Will NOT work** unless:
  1. ✅ Capability is enabled in Xcode
  2. ✅ Configured in Apple Developer Portal
  3. ✅ App is properly signed
  4. ✅ Supabase Apple provider is configured (if using Supabase)

**Note:** Apple **requires** Sign in with Apple if your app offers any other third-party sign-in options (like Google). This is an App Store requirement.

#### ❌ **Google Sign In**
- **Current:** ❌ Mock implementation only
- **App Store:** ❌ **Will NOT work** unless:
  1. ✅ Google Sign-In SDK is integrated
  2. ✅ Google OAuth is configured
  3. ✅ Supabase Google provider is enabled
  4. ✅ OAuth redirect URLs are configured

### What Happens When You Submit to App Store?

**Without Proper Configuration:**
- ❌ **App Review will reject** if Sign in with Apple is shown but not working
- ❌ **Users will see errors** when trying to sign in
- ❌ **No user data persistence** across devices
- ❌ **No account recovery** options

**With Proper Configuration:**
- ✅ **All sign-in methods work**
- ✅ **User data syncs across devices**
- ✅ **Secure authentication**
- ✅ **Meets App Store requirements**

---

## 🔄 Current vs. Production Setup

### Current Setup (Development)

```
┌─────────────────────────────────────┐
│  User Signs Up/In                    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  AuthService (Mock Mode)            │
│  - Creates User object               │
│  - No real authentication           │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  UserDefaults (Local Storage)        │
│  - Saved on device only              │
│  - Lost if app deleted               │
└─────────────────────────────────────┘
```

### Production Setup (With Supabase)

```
┌─────────────────────────────────────┐
│  User Signs Up/In                    │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  AuthService (Supabase Mode)         │
│  - Validates credentials             │
│  - Creates secure session            │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Supabase Auth                       │
│  - Secure authentication             │
│  - Session management                │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Supabase Database                   │
│  - profiles table                    │
│  - challenges table                  │
│  - challenge_members table           │
└─────────────────────────────────────┘
```

---

## 📝 Action Items Before App Store Submission

### Required:
1. ✅ **Enable Sign in with Apple capability**
   - Xcode → Target → Signing & Capabilities → + Capability
   - Configure in Apple Developer Portal

2. ✅ **Configure Supabase**
   - Set `useSupabase = true` in `AuthService.swift`
   - Add Supabase URL and API key to `SupabaseClient.swift`
   - Set up database tables and RLS policies

3. ✅ **Test all authentication methods**
   - Email/Password sign-up and sign-in
   - Apple Sign In (on physical device)
   - Google Sign In (if implementing)

### Recommended:
4. ✅ **Add password reset flow**
5. ✅ **Add email verification** (if using email auth)
6. ✅ **Implement account deletion**
7. ✅ **Add error logging** for production debugging

---

## 🔍 Code Locations

**User Profile Storage:**
- `StepComp/Services/AuthService.swift` - Lines 364-379
- `StepComp/Models/User.swift` - User model definition

**Authentication Methods:**
- `StepComp/Services/AuthService.swift` - All sign-in methods
- `StepComp/Screens/Onboarding/SignInView.swift` - UI and handlers

**Supabase Configuration:**
- `StepComp/Services/SupabaseClient.swift` - Client setup
- `StepComp/Services/AuthService.swift` - Supabase integration

---

## 💡 Summary

**Current State:**
- ✅ Email sign-in works (mock mode)
- ❌ Apple Sign In not configured (error 1000)
- ❌ Google Sign In is mock only
- ✅ User profiles saved locally (UserDefaults)

**For App Store:**
- ⚠️ **Must configure Supabase** for cloud storage
- ⚠️ **Must enable Sign in with Apple** (App Store requirement)
- ⚠️ **Must implement real Google Sign-In** (if offering Google option)
- ⚠️ **Must test on physical devices** before submission

**The app is currently in development/mock mode. All authentication methods need proper backend configuration before App Store submission.**

