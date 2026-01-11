# Password Reset Guide

## ✅ Implementation Complete

Password reset functionality is **fully implemented** for users who signed up with email/password.

## How It Works

### Step 1: User Requests Password Reset

1. User taps **"Forgot Password?"** on the sign-in screen
2. Enters their email address
3. Taps **"Send Reset Link"**
4. Supabase sends a password reset email

### Step 2: User Clicks Reset Link

1. User receives email with reset link
2. Clicks the link (opens in browser, then redirects to app)
3. App detects the password reset callback URL
4. Shows password reset screen

### Step 3: User Sets New Password

1. User enters new password
2. Confirms password
3. Taps **"Reset Password"**
4. Password is updated in Supabase
5. User is signed out and can sign in with new password

## User Flow

```
Sign In Screen
    ↓
"Forgot Password?" button
    ↓
Enter email → Send Reset Link
    ↓
Check email → Click reset link
    ↓
App opens → Password Reset Screen
    ↓
Enter new password → Reset Password
    ↓
Success → Return to Sign In
```

## Code Implementation

### 1. Forgot Password Sheet
- Location: `SignInView.swift` → `ForgotPasswordSheet`
- Function: Sends password reset email via Supabase
- Uses: `supabase.auth.resetPasswordForEmail()`

### 2. Password Reset View
- Location: `SignInView.swift` → `PasswordResetView`
- Function: Allows user to set new password after clicking reset link
- Uses: `authService.updatePassword()`

### 3. URL Handler
- Location: `StepCompApp.swift` → `handleOAuthCallback()`
- Function: Detects password reset callbacks and shows reset screen
- Detects: URLs containing `type=recovery` or `recovery`

### 4. Auth Service Method
- Location: `AuthService.swift` → `updatePassword()`
- Function: Updates user's password in Supabase
- Uses: `supabase.auth.update(user: UserAttributes(password:))`

## Configuration

### Supabase Settings

1. Go to Supabase Dashboard → Authentication → URL Configuration
2. Add your app's redirect URL:
   - `je.stepcomp://auth-callback`
   - Or your custom URL scheme

### Email Templates (Optional)

You can customize the password reset email in:
- Supabase Dashboard → Authentication → Email Templates
- Template: "Reset Password"

## Testing

### Test Password Reset:

1. **Request Reset**:
   - Sign out if signed in
   - Go to Sign In screen
   - Tap "Forgot Password?"
   - Enter your email
   - Tap "Send Reset Link"

2. **Check Email**:
   - Open your email inbox
   - Find email from Supabase
   - Click the reset link

3. **Reset Password**:
   - App should open to password reset screen
   - Enter new password
   - Confirm password
   - Tap "Reset Password"

4. **Sign In**:
   - Should see success message
   - Return to sign in screen
   - Sign in with new password

## Troubleshooting

### Reset link doesn't open app

**Solution**:
- Check that redirect URL is configured in Supabase
- Verify URL scheme is set in Xcode (Info.plist)
- Make sure the link uses your app's URL scheme

### "Invalid reset link" error

**Solution**:
- Reset links expire after a certain time (usually 1 hour)
- Request a new reset email
- Make sure you're clicking the link from the most recent email

### Password update fails

**Solution**:
- Check that the reset link hasn't expired
- Verify you're connected to internet
- Check Xcode console for error messages
- Make sure password meets requirements (at least 6 characters)

### Reset screen doesn't appear

**Solution**:
- Check that URL handler is working
- Verify notification is being posted correctly
- Check Xcode console for callback URL logs

## Security Notes

- Reset links expire after a set time (configured in Supabase)
- Links are single-use (can only be used once)
- User must sign in again after password reset
- Password must meet minimum requirements (6+ characters)

## Current Status

✅ **Fully Implemented**:
- Forgot password UI
- Email sending via Supabase
- Reset link handling
- Password reset screen
- Password update functionality
- Success/error handling

## Next Steps (Optional Enhancements)

1. **Email customization**: Customize the reset email template in Supabase
2. **Password strength meter**: Add visual feedback for password strength
3. **Auto-sign-in**: Optionally sign user in after successful reset
4. **Rate limiting**: Already handled by Supabase (prevents abuse)

---

**Password reset is ready to use!** Users can now recover their accounts if they forget their password.

