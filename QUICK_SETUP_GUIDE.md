# Quick Setup Guide - Supabase Integration

## 🚀 Complete Setup in 3 Steps

### Step 1: Add Supabase Swift Package (5 minutes)

**In Xcode:**

1. **File → Add Package Dependencies...**
2. Enter URL: `https://github.com/supabase-community/supabase-swift.git`
   - **Note**: Use `supabase-community` URL for Xcode projects (per official docs)
3. Click **Add Package**
4. Select **StepComp** target
5. Click **Add Package**

✅ **Done!** The package is now added.

---

### Step 2: Create Database Tables (5 minutes)

**In Supabase Dashboard:**

1. Go to your Supabase project: https://app.supabase.com
2. Click **SQL Editor** in the left sidebar
3. Click **New Query**
4. Copy and paste the entire contents of `SUPABASE_DATABASE_SETUP.sql`
5. Click **Run** (or press ⌘ + Enter)
6. Verify success - you should see "Success. No rows returned"

✅ **Done!** Your database tables are created.

**Tables Created:**
- ✅ `profiles` - User profiles
- ✅ `challenges` - Challenge groups
- ✅ `challenge_members` - Challenge participants & step counts
- ✅ `friends` - Friend relationships (optional)

---

### Step 3: Enable Supabase in App (1 minute)

**In Xcode:**

1. Open `StepComp/Services/AuthService.swift`
2. Find line 17:
   ```swift
   private let useSupabase = false
   ```
3. Change to:
   ```swift
   private let useSupabase = true
   ```
4. Save the file

✅ **Done!** Supabase authentication is now enabled.

---

## 🧪 Test Your Setup

### Option 1: Use the Built-in Test Tool

1. Run your app in Xcode
2. Go to **Profile** tab → **Settings**
3. Scroll to **Developer Tools** card (orange icon)
4. Tap **"Test Supabase Connection"**
5. Tap **"Test Connection"** button
6. Check results - all tests should pass ✅

### Option 2: Test Authentication

1. Run your app
2. Complete onboarding
3. Try signing up with email/password
4. Check Supabase Dashboard → **Authentication → Users**
5. You should see your new user!

---

## ✅ Verification Checklist

- [ ] Supabase Swift package added to Xcode project
- [ ] Database tables created (profiles, challenges, challenge_members)
- [ ] `useSupabase = true` in AuthService.swift
- [ ] App builds without errors
- [ ] Connection test passes
- [ ] Can sign up with email/password
- [ ] User appears in Supabase Auth dashboard

---

## 🐛 Troubleshooting

### "Unable to find module dependency: 'Supabase'"

**Solution:**
1. Product → Clean Build Folder (⇧⌘K)
2. File → Packages → Reset Package Caches
3. Product → Build (⌘B)

### "Table does not exist" error

**Solution:**
1. Go to Supabase Dashboard → SQL Editor
2. Run `SUPABASE_DATABASE_SETUP.sql` again
3. Check that tables appear in **Table Editor**

### Authentication not working

**Solution:**
1. Verify `useSupabase = true` in AuthService.swift
2. Check Supabase Dashboard → Authentication → Providers
3. Make sure **Email** provider is enabled
4. Check Supabase Dashboard → Settings → API for correct URL/key

### Connection test fails

**Solution:**
1. Verify Supabase URL and API key in `SupabaseClient.swift`
2. Check Supabase Dashboard → Settings → API
3. Make sure you're using the **anon/public** key (not service_role)
4. Verify tables exist in Supabase Dashboard → Table Editor

---

## 📚 Additional Resources

- **Supabase Dashboard**: https://app.supabase.com
- **Supabase Docs**: https://supabase.com/docs
- **Swift SDK Docs**: https://github.com/supabase/supabase-swift
- **Database Setup**: See `SUPABASE_DATABASE_SETUP.sql`
- **Package Setup**: See `ADD_SUPABASE_PACKAGE.md`

---

## 🎉 You're All Set!

Once all steps are complete:
- ✅ Real authentication works
- ✅ User data stored in Supabase
- ✅ Data syncs across devices
- ✅ Ready for App Store submission

Need help? Check the troubleshooting section above or review the detailed guides.

