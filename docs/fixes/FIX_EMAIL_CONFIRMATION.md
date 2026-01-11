# Fix: Invalid Login Credentials After Sign-Up

## Problem

After signing up, when you try to sign in, you get "Invalid login credentials" error. This happens because **Supabase requires email confirmation by default**.

## Solution Options

### Option 1: Disable Email Confirmation (Recommended for Development)

This allows users to sign in immediately after signing up without email verification.

1. Go to https://app.supabase.com
2. Select your **StepComp Project**
3. Navigate to **Authentication → Settings** (or **Authentication → Providers → Email**)
4. Find **"Enable email confirmations"** or **"Confirm email"** setting
5. **Disable** email confirmation
6. Click **Save**

Now users can sign in immediately after signing up.

### Option 2: Keep Email Confirmation Enabled

If you want to keep email confirmation enabled (recommended for production):

1. After signing up, check your email inbox (and spam folder)
2. Click the confirmation link in the email
3. Then try signing in again

## Code Changes Made

I've updated the code to provide better error messages:

1. **Added `emailNotConfirmed` error** - Detects when email hasn't been confirmed
2. **Added `invalidCredentials` error** - Provides clearer message for wrong credentials
3. **Improved error handling** - Better detection of specific error types

The error messages will now tell you:
- If your email needs to be confirmed
- If your credentials are wrong
- Other specific error types

## Testing

After disabling email confirmation:

1. **Sign up** with a new account
2. **Sign out**
3. **Sign in** with the same credentials
4. Should work immediately! ✅

## For Production

When you're ready for production, you can:
1. Re-enable email confirmation in Supabase
2. Add a "Resend confirmation email" feature
3. Show a message after sign-up: "Please check your email to confirm your account"

## Verify in Supabase Dashboard

1. Go to **Authentication → Users**
2. Find the user you created
3. Check the **"Email Confirmed"** column
   - If it says "No" and email confirmation is enabled → User needs to confirm
   - If it says "Yes" → User should be able to sign in

## Quick Fix Command

If you want to manually confirm a user's email in Supabase:

1. Go to **Authentication → Users**
2. Click on the user
3. Click **"Confirm Email"** button (if available)
4. Or use the SQL Editor:
   ```sql
   UPDATE auth.users 
   SET email_confirmed_at = NOW() 
   WHERE email = 'user@example.com';
   ```

---

**After disabling email confirmation, try signing in again - it should work!**

