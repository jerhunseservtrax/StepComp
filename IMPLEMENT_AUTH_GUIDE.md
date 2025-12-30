# Implementing User Authentication with Supabase

## ✅ Current Status

Your app **already has email authentication implemented** and connected to Supabase! Here's what's in place:

### What's Already Working:
1. ✅ Supabase client configured (`SupabaseClient.swift`)
2. ✅ Auth service with sign-up and sign-in methods (`AuthService.swift`)
3. ✅ UI for email sign-up and sign-in (`SignInView.swift`)
4. ✅ Password reset functionality
5. ✅ Profile creation and loading
6. ✅ Session management

### What Needs to Be Done:
1. ⚠️ **Run the database setup SQL** to create/update tables with `first_name` and `last_name` columns
2. ⚠️ **Test the authentication flow**

---

## 🚀 Step 1: Update Database Schema

The database needs to have `first_name` and `last_name` columns in the `profiles` table. 

### Option A: Via Supabase Dashboard (Recommended)

1. Go to https://app.supabase.com
2. Select your **StepComp Project**
3. Navigate to **SQL Editor** (left sidebar)
4. Click **"New Query"**
5. Copy and paste the contents of `SUPABASE_DATABASE_SETUP_UPDATED.sql`
6. Click **"Run"** (or press Cmd/Ctrl + Enter)
7. Verify success - you should see "Success. No rows returned"

### Option B: Via Supabase CLI

Since the CLI doesn't support direct SQL execution, use the dashboard method above.

---

## 🧪 Step 2: Test Authentication

### Test Sign-Up:

1. **Run your app** in Xcode
2. Go through onboarding
3. On the Sign In screen, tap **"Use Email Address"**
4. Tap **"Sign Up"** (or switch to sign-up if on sign-in screen)
5. Fill in:
   - Full Name: `John Doe`
   - Username: `johndoe`
   - Email: `test@example.com`
   - Password: `testpassword123`
   - Confirm Password: `testpassword123`
6. Tap **"Start Walking"**
7. Check Xcode console for logs:
   - Should see: `✅ Supabase sign-up successful`
   - Should see: `✅ Profile created successfully`

### Test Sign-In:

1. **Sign out** if you're signed in
2. On Sign In screen, tap **"Use Email Address"**
3. Enter:
   - Email: `test@example.com`
   - Password: `testpassword123`
4. Tap **"Sign In"**
5. Check Xcode console:
   - Should see: `✅ Supabase sign-in successful`

### Verify in Supabase Dashboard:

1. Go to https://app.supabase.com
2. Select your project
3. Navigate to **Authentication → Users**
4. You should see the user you just created
5. Navigate to **Table Editor → profiles**
6. You should see the profile with `username`, `first_name`, and `last_name`

---

## 🔍 Troubleshooting

### Issue: "Profile creation failed"

**Solution**: Make sure you ran the SQL setup script. The `profiles` table needs to exist with the correct columns.

### Issue: "Email already exists"

**Solution**: This is expected if you try to sign up with an email that's already registered. Use a different email or sign in instead.

### Issue: "RLS policy violation"

**Solution**: The SQL script sets up Row Level Security policies. Make sure you ran the complete script.

### Issue: "Session not found"

**Solution**: 
- Check that `useSupabase = true` in `AuthService.swift` (line 20)
- Verify Supabase package is installed
- Check network connectivity

### Issue: Profile doesn't load after sign-up

**Solution**: 
- Check Xcode console for error messages
- Verify the profile was created in Supabase dashboard
- The trigger should auto-create profiles, but the code has a fallback

---

## 📋 Code Changes Made

### 1. Fixed `loadUserProfile` method

Updated to use `firstName` and `lastName` directly from the profile instead of splitting username:

```swift
// Before: Split username to get names
let nameComponents = profile.username.split(separator: " ", maxSplits: 1)

// After: Use firstName and lastName from profile
let firstName = profile.firstName ?? ""
let lastName = profile.lastName ?? ""
```

### 2. Created Updated SQL Script

Created `SUPABASE_DATABASE_SETUP_UPDATED.sql` with:
- `first_name` and `last_name` columns in profiles table
- Auto-profile creation trigger
- Proper RLS policies
- All necessary tables and functions

---

## 🎯 How It Works

### Sign-Up Flow:

1. User enters email, password, username, first name, last name
2. `AuthService.signUp()` is called
3. Supabase Auth creates the user account
4. Profile is created in `profiles` table (via trigger or manual insert)
5. User session is established
6. Profile is loaded and user is authenticated

### Sign-In Flow:

1. User enters email and password
2. `AuthService.signIn()` is called
3. Supabase Auth validates credentials
4. Session is established
5. Profile is loaded from database
6. User is authenticated

### Session Management:

- On app launch, `checkSupabaseSession()` checks for existing session
- If session exists, user profile is loaded automatically
- Session persists across app restarts

---

## ✅ Verification Checklist

- [ ] SQL script executed successfully in Supabase dashboard
- [ ] `profiles` table has `first_name` and `last_name` columns
- [ ] Can create a new account via sign-up
- [ ] Can sign in with created account
- [ ] User appears in Supabase Authentication → Users
- [ ] Profile appears in Supabase Table Editor → profiles
- [ ] Session persists after app restart
- [ ] Can sign out and sign back in

---

## 🚀 Next Steps

Once authentication is working:

1. **Test password reset** - Use the "Forgot Password" feature
2. **Test profile updates** - Update user profile and verify changes
3. **Test session persistence** - Close and reopen app
4. **Add email verification** (optional) - Require users to verify email before full access

---

## 📚 Additional Resources

- Supabase Auth Docs: https://supabase.com/docs/guides/auth
- Supabase Swift SDK: https://github.com/supabase-community/supabase-swift
- Your SQL Setup: `SUPABASE_DATABASE_SETUP_UPDATED.sql`

---

## 🎉 You're All Set!

Your email authentication is fully implemented and ready to use. Just run the SQL script and start testing!

