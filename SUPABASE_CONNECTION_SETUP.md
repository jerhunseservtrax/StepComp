# Supabase Connection Setup Guide

## 🔗 Supabase Connection Details

Supabase doesn't use a traditional "connection string" like databases. Instead, it uses:
1. **Project URL** - Your Supabase project endpoint
2. **API Key** - Your anonymous/public key (safe to use in client apps)

## 📍 Where to Find Your Supabase Credentials

### Step 1: Go to Your Supabase Project

1. Visit [https://app.supabase.com](https://app.supabase.com)
2. Sign in to your account
3. Select your project (or create a new one)

### Step 2: Get Your Project URL and API Key

1. In your Supabase project dashboard, click **Settings** (gear icon) in the left sidebar
2. Click **API** in the settings menu
3. You'll see:
   - **Project URL** - Something like `https://xxxxxxxxxxxxx.supabase.co`
   - **anon/public key** - A long string starting with `eyJ...`

## 🔧 How to Configure in Your App

### Location: `StepComp/Services/SupabaseClient.swift`

Update these two values:

```swift
enum SupabaseConfig {
    // Replace with your actual Supabase project URL
    static let supabaseURL = "https://YOUR_PROJECT.supabase.co"
    
    // Replace with your actual Supabase anon/public key
    static let supabaseAnonKey = "YOUR_ANON_KEY"
}
```

### Example:

```swift
enum SupabaseConfig {
    static let supabaseURL = "https://abcdefghijklmnop.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYzODk2NzI4MCwiZXhwIjoxOTU0NTQzMjgwfQ.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}
```

## ⚠️ Important Security Notes

### ✅ Safe to Use (anon/public key):
- The **anon/public key** is safe to include in your app
- It's designed for client-side use
- It's restricted by Row Level Security (RLS) policies
- Users can only access data they're allowed to see

### ❌ Never Use (service_role key):
- **DO NOT** use the `service_role` key in your app
- This key bypasses RLS and has full database access
- Only use it in secure server-side code
- If exposed, it's a security risk

## 🔄 Enable Supabase in Your App

After adding your credentials:

1. **Set `useSupabase = true`** in `AuthService.swift`:
   ```swift
   private let useSupabase = true // Change from false to true
   ```

2. **Add Supabase Swift Package** (if not already added):
   - In Xcode: **File → Add Package Dependencies**
   - URL: `https://github.com/supabase/supabase-swift`
   - Version: Latest

3. **Rebuild your app**

## 📋 Complete Setup Checklist

- [ ] Created Supabase project at [app.supabase.com](https://app.supabase.com)
- [ ] Got Project URL from Settings → API
- [ ] Got anon/public key from Settings → API
- [ ] Updated `supabaseURL` in `SupabaseClient.swift`
- [ ] Updated `supabaseAnonKey` in `SupabaseClient.swift`
- [ ] Set `useSupabase = true` in `AuthService.swift`
- [ ] Added Supabase Swift Package to Xcode
- [ ] Set up database tables (see database setup guide)
- [ ] Configured Row Level Security (RLS) policies
- [ ] Tested authentication flow

## 🗄️ Database Tables Needed

Make sure you have these tables set up in Supabase:

1. **profiles** table
2. **challenges** table  
3. **challenge_members** table

See `USER_PROFILES_AND_AUTH_EXPLAINED.md` for database schema details.

## 🧪 Testing Your Connection

After configuration:

1. Run the app
2. Try signing up with email/password
3. Check your Supabase dashboard → **Authentication → Users**
4. You should see the new user created

## 📞 Need Help?

- **Supabase Docs**: [https://supabase.com/docs](https://supabase.com/docs)
- **Swift SDK Docs**: [https://github.com/supabase/supabase-swift](https://github.com/supabase/supabase-swift)
- **Supabase Dashboard**: [https://app.supabase.com](https://app.supabase.com)

