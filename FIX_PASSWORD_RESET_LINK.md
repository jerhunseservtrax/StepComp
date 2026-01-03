# 🔧 Fix Password Reset Link - "Safari cannot open the page"

## 🚨 Problem
Password reset emails contain an invalid URL that Safari can't open, showing:
> "Safari cannot open the page because the address is invalid."

## ✅ Solution

### Step 1: Configure Supabase Redirect URL

1. **Go to Supabase Dashboard**:
   - Open https://app.supabase.com
   - Select your project (cwrirmowykxajumjokjj)

2. **Navigate to Authentication Settings**:
   - Click **Authentication** in left sidebar
   - Click **URL Configuration**

3. **Add Redirect URLs**:
   In the "Redirect URLs" section, add:
   ```
   je.stepcomp://reset-password
   ```

4. **Click "Save"**

### Step 2: Update Email Template (Optional but Recommended)

While in **Authentication** → **Email Templates** → **Reset Password**:

Change the button URL from:
```
{{ .ConfirmationURL }}
```

To:
```
je.stepcomp://reset-password#{{ .TokenHash }}
```

This ensures the email link uses your app's custom URL scheme.

---

## 🧪 Testing the Fix

### Test 1: Request Password Reset

1. Open the app
2. Tap "Forgot password?"
3. Enter your email
4. Tap "Send Reset Link"

### Test 2: Check Email

You should receive an email with a link like:
```
je.stepcomp://reset-password#access_token=...&type=recovery
```

### Test 3: Tap the Link

- The link should open the StepComp app
- You should see the "Reset Your Password" screen
- Enter a new password (min 8 chars, 1 letter, 1 number)
- Tap "Reset Password"
- Should show success and return to sign-in

---

## 🔍 Verification Checklist

Run this command to verify the URL scheme is configured in your app:

```bash
cd /Users/jefferyerhunse/GitRepos/StepComp
grep -r "je.stepcomp" StepComp/
```

You should see references in:
- ✅ `DeepLinkRouter.swift` - Handles the URL
- ✅ `SignInView.swift` - Sends the reset request
- ✅ `StepCompApp.swift` - Registers the URL scheme handler

---

## 📱 What Happens Behind the Scenes

### Current Flow (Broken):
```
1. User requests reset
2. Supabase sends email with: https://cwrirmowykxajumjokjj.supabase.co/...
3. User taps link
4. ❌ Safari tries to open it → "Invalid address"
```

### Fixed Flow:
```
1. User requests reset
2. Supabase sends email with: je.stepcomp://reset-password#...
3. User taps link
4. ✅ iOS opens StepComp app
5. ✅ App shows password reset screen
6. ✅ User enters new password
7. ✅ Password updated in Supabase
```

---

## 🛠️ Alternative: Quick Script Fix

If you have Supabase CLI installed, you can run:

```bash
cd /Users/jefferyerhunse/GitRepos/StepComp
./update_redirect_urls.sh
```

This will automatically add the redirect URL via API.

---

## ⚠️ Common Issues

### Issue: "URL scheme not registered"
**Solution**: Make sure `je.stepcomp` is in your Info.plist under `CFBundleURLTypes`

### Issue: "Link opens Safari instead of app"
**Solution**: iOS caches URL scheme handlers. Restart your device.

### Issue: "Access token expired"
**Solution**: Reset links expire after 1 hour. Request a new one.

---

## 📞 Need Help?

If the issue persists:

1. **Check Supabase Dashboard**:
   - Go to Authentication → URL Configuration
   - Verify `je.stepcomp://reset-password` is listed

2. **Check App Logs**:
   - Run the app in Xcode
   - Tap the reset link
   - Look for: `🔑 Password reset URL detected` in console

3. **Manual Test**:
   ```bash
   # Open this in Safari (replace TOKEN):
   je.stepcomp://reset-password#access_token=test123&type=recovery
   
   # Should open your app
   ```

---

## ✅ Success Criteria

Password reset is working when:
- ✅ Email arrives within 1 minute
- ✅ Link opens the StepComp app (not Safari error)
- ✅ Password reset screen appears
- ✅ New password saves successfully
- ✅ You can sign in with the new password

---

## 🎯 Final Configuration Summary

**Supabase Dashboard Settings:**
```
Project: cwrirmowykxajumjokjj
Authentication → URL Configuration → Redirect URLs:
  - je.stepcomp://reset-password ✅
```

**App Configuration:**
```
Bundle ID: JE.StepComp
URL Scheme: je.stepcomp ✅ (configured in Xcode)
Deep Link Handler: DeepLinkRouter ✅
Password Reset View: PasswordResetView ✅
```

All the code is already in place - you just need to add the redirect URL in Supabase! 🚀

