# Authentication Status Check

## ✅ Current Implementation Status

### Email Sign-In/Sign-Up
- ✅ **Implemented**: Uses Supabase Auth (`signInWithSupabase`, `signUpWithSupabase`)
- ✅ **Profile Creation**: Automatically creates profile in `profiles` table on sign-up
- ✅ **Session Management**: Checks Supabase session on app launch
- ✅ **User Loading**: Loads user profile from database after authentication

### Google Sign-In
- ✅ **OAuth Flow**: Uses Supabase OAuth (`signInWithOAuth`)
- ✅ **URL Handling**: OAuth callback handled via `onOpenURL` in SignInView
- ⚠️ **Potential Issue**: OAuth callback might need app-level handling (see below)

## 🔍 Issues Found & Fixes Needed

### Issue 1: OAuth Callback Handling
**Problem**: OAuth callback (`onOpenURL`) is only in `SignInView`, but the callback might arrive when the user is redirected back to the app, potentially after the view has changed.

**Fix Needed**: Add OAuth callback handling at the app level (`StepCompApp` or `RootView`) to ensure callbacks are always handled.

### Issue 2: Google OAuth Session Processing
**Problem**: After OAuth callback, the code waits and checks session, but Supabase might need explicit session processing.

**Fix Needed**: After OAuth callback, explicitly process the session token from the callback URL.

### Issue 3: Email Loading in Profile
**Problem**: `loadUserProfile` sets `email: nil` because "Email comes from auth, not profile", but we should fetch it from the auth user.

**Fix Needed**: Fetch email from `supabase.auth.session.user.email` when loading profile.

## 🛠️ Recommended Fixes

### Fix 1: Add App-Level OAuth Callback Handler

Add to `StepCompApp.swift`:

```swift
.onOpenURL { url in
    // Handle OAuth callback at app level
    Task {
        await handleOAuthCallback(url: url)
    }
}
```

### Fix 2: Process OAuth Callback Properly

Update `handleOAuthCallback` to explicitly process the session:

```swift
private func handleOAuthCallback(url: URL) async {
    #if canImport(Supabase)
    // Supabase processes the callback URL automatically
    // We just need to wait for the session to be established
    do {
        // Wait for Supabase to process the callback
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Get the session - Supabase should have processed the callback
        let session = try await supabase.auth.session
        if let session = session {
            // Session is established, load user profile
            await authService.loadUserProfile(userId: session.user.id.uuidString)
        }
    } catch {
        print("⚠️ Error processing OAuth callback: \(error.localizedDescription)")
    }
    #endif
}
```

### Fix 3: Load Email from Auth User

Update `loadUserProfile` in `AuthService.swift`:

```swift
private func loadUserProfile(userId: String) async {
    do {
        // Get email from auth session
        let session = try await supabase.auth.session
        let email = session?.user.email
        
        // Fetch profile from database
        let profile: UserProfile = try await supabase
            .from("profiles")
            .select()
            .eq("user_id", value: userId)
            .single()
            .execute()
            .value
        
        // Convert to app User model
        let user = User(
            id: profile.id,
            displayName: profile.username,
            avatarURL: profile.avatar,
            email: email, // Now includes email from auth
            totalSteps: 0,
            totalChallenges: 0
        )
        
        currentUser = user
        isAuthenticated = true
        saveUser()
    } catch {
        // ... error handling
    }
}
```

## 🧪 Testing Checklist

### Email Sign-In
- [ ] Create new account with email/password
- [ ] Sign in with existing email/password
- [ ] Verify profile is created in Supabase `profiles` table
- [ ] Verify user can access app after sign-in
- [ ] Verify email is displayed correctly

### Google Sign-In
- [ ] Tap "Continue with Google" button
- [ ] Verify OAuth flow opens in browser/Safari
- [ ] Sign in with Google account
- [ ] Verify redirect back to app
- [ ] Verify user is authenticated
- [ ] Verify profile is created/loaded
- [ ] Verify user can access app after sign-in

### Session Persistence
- [ ] Close app completely
- [ ] Reopen app
- [ ] Verify user is still authenticated (session persisted)
- [ ] Verify user profile loads correctly

## 📝 Next Steps

1. **Add app-level OAuth callback handler** (Fix 1)
2. **Update OAuth callback processing** (Fix 2)
3. **Load email from auth user** (Fix 3)
4. **Test both email and Google sign-in**
5. **Verify session persistence**

## 🔗 Related Files

- `StepComp/Services/AuthService.swift` - Authentication logic
- `StepComp/Screens/Onboarding/SignInView.swift` - Sign-in UI and OAuth handling
- `StepComp/App/RootView.swift` - Root view with session management
- `StepComp/StepCompApp.swift` - App entry point
- `StepComp/Services/SupabaseClient.swift` - Supabase configuration

