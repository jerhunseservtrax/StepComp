# Supabase Configuration - Next Steps

## ✅ What's Been Done

Your Supabase credentials have been added to:
- **File**: `StepComp/Services/SupabaseClient.swift`
- **URL**: `https://cwrirmowykxajumjokjj.supabase.co`
- **API Key**: Configured

## 🔧 What You Need to Do Next

### Step 1: Add Supabase Swift Package (If Not Already Added)

1. Open Xcode
2. Go to **File → Add Package Dependencies**
3. Enter URL: `https://github.com/supabase/supabase-swift`
4. Select **Up to Next Major Version**
5. Click **Add Package**
6. Make sure **StepComp** target is selected
7. Click **Add Package**

### Step 2: Enable Supabase Authentication

Edit `StepComp/Services/AuthService.swift`:

Change line 17 from:
```swift
private let useSupabase = false // Set to true when Supabase is configured
```

To:
```swift
private let useSupabase = true // Supabase is now configured
```

### Step 3: Set Up Database Tables

You need to create these tables in your Supabase project:

#### 1. **profiles** table

Go to Supabase Dashboard → SQL Editor and run:

```sql
-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL,
  avatar TEXT,
  is_premium BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own profile
CREATE POLICY "Users can read own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

#### 2. **challenges** table

```sql
-- Create challenges table
CREATE TABLE IF NOT EXISTS challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  is_public BOOLEAN DEFAULT TRUE,
  invite_code TEXT UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read public challenges
CREATE POLICY "Anyone can read public challenges"
  ON challenges FOR SELECT
  USING (is_public = TRUE);

-- Policy: Users can read challenges they created
CREATE POLICY "Users can read own challenges"
  ON challenges FOR SELECT
  USING (auth.uid() = created_by);

-- Policy: Users can create challenges
CREATE POLICY "Users can create challenges"
  ON challenges FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Policy: Challenge creators can update their challenges
CREATE POLICY "Users can update own challenges"
  ON challenges FOR UPDATE
  USING (auth.uid() = created_by);
```

#### 3. **challenge_members** table

```sql
-- Create challenge_members table
CREATE TABLE IF NOT EXISTS challenge_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  total_steps INTEGER DEFAULT 0,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(challenge_id, user_id)
);

-- Enable Row Level Security
ALTER TABLE challenge_members ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read members of challenges they're in
CREATE POLICY "Users can read challenge members"
  ON challenge_members FOR SELECT
  USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM challenges
      WHERE challenges.id = challenge_members.challenge_id
      AND (challenges.is_public = TRUE OR challenges.created_by = auth.uid())
    )
  );

-- Policy: Users can join challenges
CREATE POLICY "Users can join challenges"
  ON challenge_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own step count
CREATE POLICY "Users can update own steps"
  ON challenge_members FOR UPDATE
  USING (auth.uid() = user_id);
```

### Step 4: Enable Email Authentication in Supabase

1. Go to Supabase Dashboard → **Authentication → Providers**
2. Make sure **Email** provider is enabled
3. Configure email templates if needed

### Step 5: Test Authentication

1. **Rebuild your app** in Xcode
2. **Run the app**
3. Try **signing up** with a new email/password
4. Check Supabase Dashboard → **Authentication → Users**
5. You should see the new user created

## ⚠️ Important Notes

### API Key Format

Your API key starts with `sb_publishable_` which suggests you might be using Supabase's newer authentication system. If you encounter issues:

1. Check Supabase Dashboard → **Settings → API**
2. Look for the **anon/public** key (usually starts with `eyJ...`)
3. If different, update `SupabaseClient.swift` with that key instead

### Current Status

- ✅ Supabase URL configured
- ✅ API Key configured
- ⚠️ **Supabase authentication is still disabled** (`useSupabase = false`)
- ⚠️ **Database tables need to be created**
- ⚠️ **Supabase Swift package may need to be added**

## 🧪 Testing Checklist

- [ ] Supabase Swift package added to Xcode project
- [ ] `useSupabase = true` in `AuthService.swift`
- [ ] Database tables created (`profiles`, `challenges`, `challenge_members`)
- [ ] Row Level Security policies configured
- [ ] Email authentication enabled in Supabase dashboard
- [ ] App builds successfully
- [ ] Can sign up with email/password
- [ ] User appears in Supabase Authentication → Users
- [ ] Profile created in `profiles` table

## 📞 Troubleshooting

### Build Errors

If you see errors about Supabase not being found:
- Make sure Supabase Swift package is added
- Clean build folder (⇧⌘K) and rebuild

### Authentication Errors

If sign-up/sign-in fails:
- Check Supabase Dashboard → Authentication → Users for error logs
- Verify email provider is enabled
- Check that database tables exist

### Database Errors

If you see database errors:
- Verify tables are created correctly
- Check Row Level Security policies
- Ensure user has proper permissions

## 🎉 Once Complete

After completing these steps:
- ✅ Real authentication will work
- ✅ User data will be stored in Supabase
- ✅ Data will sync across devices
- ✅ Ready for App Store submission

