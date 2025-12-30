# Supabase Setup Guide

## Phase 1: Create Supabase Project

1. Go to https://app.supabase.com
2. Click "New Project"
3. Fill in:
   - **Name**: StepComp (or your preferred name)
   - **Database Password**: (save this securely)
   - **Region**: Choose closest to your users
4. Wait for project to be created (~2 minutes)

## Phase 2: Get API Keys

1. In your Supabase project dashboard
2. Go to **Settings** → **API**
3. Copy:
   - **Project URL**: `https://YOUR_PROJECT.supabase.co`
   - **anon/public key**: (starts with `eyJ...`)

## Phase 3: Update SupabaseClient.swift

Open `StepComp/Services/SupabaseClient.swift` and replace:

```swift
static let supabaseURL = "https://YOUR_PROJECT.supabase.co"
static let supabaseAnonKey = "YOUR_ANON_KEY"
```

With your actual values.

## Phase 4: Add Supabase Swift Package

1. In Xcode, select your project
2. Go to **Package Dependencies** tab
3. Click **"+"** button
4. Enter: `https://github.com/supabase/supabase-swift`
5. Select version: **Latest** (or specific version)
6. Add to **StepComp** target

## Phase 5: Enable Auth Providers

In Supabase Dashboard:

1. Go to **Authentication** → **Providers**
2. Enable:
   - ✅ **Email** (already enabled by default)
   - ✅ **Apple** (requires Apple Developer setup - see below)

### Apple Sign In Setup (Optional)

1. In Apple Developer Portal:
   - Create App ID
   - Enable "Sign in with Apple"
   - Create Service ID
   - Configure domains and redirect URLs

2. In Supabase Dashboard:
   - Go to **Authentication** → **Providers** → **Apple**
   - Enter your Apple credentials
   - Add redirect URL: `https://YOUR_PROJECT.supabase.co/auth/v1/callback`

## Phase 6: Create Database Tables

Run these SQL commands in Supabase SQL Editor:

### 1. Users Table (handled by Supabase Auth automatically)
```sql
-- Users table is automatically created by Supabase Auth
-- Access via auth.users
```

### 2. Profiles Table
```sql
CREATE TABLE profiles (
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

### 3. Challenges Table
```sql
CREATE TABLE challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  target_steps INTEGER DEFAULT 10000,
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  is_private BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read public challenges
CREATE POLICY "Anyone can read public challenges"
  ON challenges FOR SELECT
  USING (is_private = FALSE OR created_by = auth.uid());

-- Policy: Users can create challenges
CREATE POLICY "Users can create challenges"
  ON challenges FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Policy: Challenge creators can update their challenges
CREATE POLICY "Creators can update challenges"
  ON challenges FOR UPDATE
  USING (auth.uid() = created_by);
```

### 4. Challenge Members Table
```sql
CREATE TABLE challenge_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  total_steps INTEGER DEFAULT 0,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(challenge_id, user_id)
);

-- Enable Row Level Security
ALTER TABLE challenge_members ENABLE ROW LEVEL SECURITY;

-- Policy: Members can read their own entries
CREATE POLICY "Members can read own entries"
  ON challenge_members FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Anyone can read challenge leaderboards (for public challenges)
CREATE POLICY "Anyone can read challenge leaderboards"
  ON challenge_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM challenges
      WHERE challenges.id = challenge_members.challenge_id
      AND (challenges.is_private = FALSE OR challenges.created_by = auth.uid())
    )
  );

-- Policy: Users can join challenges
CREATE POLICY "Users can join challenges"
  ON challenge_members FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own step counts
CREATE POLICY "Users can update own steps"
  ON challenge_members FOR UPDATE
  USING (auth.uid() = user_id);
```

### 5. Create Indexes (Performance)
```sql
-- Index for faster challenge lookups
CREATE INDEX idx_challenges_created_by ON challenges(created_by);
CREATE INDEX idx_challenges_dates ON challenges(start_date, end_date);

-- Index for faster member lookups
CREATE INDEX idx_challenge_members_challenge ON challenge_members(challenge_id);
CREATE INDEX idx_challenge_members_user ON challenge_members(user_id);
CREATE INDEX idx_challenge_members_steps ON challenge_members(total_steps DESC);
```

## Phase 7: Enable Supabase in App

1. Open `StepComp/Services/AuthService.swift`
2. Find: `private let useSupabase = false`
3. Change to: `private let useSupabase = true`

## Phase 8: Test Authentication

1. Build and run the app
2. Try signing up with a new email
3. Check Supabase Dashboard → **Authentication** → **Users** to see the new user
4. Check **Table Editor** → **profiles** to see the profile

## Phase 9: Update ChallengeService (Optional)

Once Supabase is working, you can update `ChallengeService` to use Supabase database instead of UserDefaults.

## Troubleshooting

### "Invalid Supabase URL" error
- Check that your URL is correct in `SupabaseClient.swift`
- Make sure there's no trailing slash

### "Invalid API key" error
- Verify you're using the **anon/public** key, not the **service_role** key
- Check that the key is copied correctly (no extra spaces)

### Authentication not working
- Check Supabase Dashboard → **Authentication** → **Logs**
- Verify email provider is enabled
- Check that RLS policies are correct

### Database errors
- Verify tables exist in Supabase Dashboard → **Table Editor**
- Check RLS policies are enabled
- Verify user has proper permissions

## Security Notes

⚠️ **Important**: 
- Never commit your Supabase keys to version control
- Use environment variables or a config file that's gitignored
- The anon key is safe for client-side use (RLS protects your data)
- Never use the service_role key in the app

## Next Steps

After Supabase is set up:
1. ✅ Test email/password authentication
2. ✅ Set up Sign in with Apple (optional)
3. ✅ Migrate ChallengeService to use Supabase
4. ✅ Set up real-time subscriptions for leaderboards
5. ✅ Add push notifications for challenge updates

