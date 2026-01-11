# What Supabase is Used For in StepComp

## 🎯 Current Status

**Supabase is currently DISABLED** (`useSupabase = false` in `AuthService.swift`)

The app is currently using **mock/local storage** (UserDefaults) for all data.

---

## 🔐 What Supabase Will Be Used For

### 1. **User Authentication** 🔑
- **Email/Password Sign-In** - Secure authentication with password hashing
- **Sign in with Apple** - OAuth integration (when configured)
- **Sign in with Google** - OAuth integration (when configured)
- **Session Management** - Automatic session persistence and refresh
- **Password Reset** - Email-based password recovery

**Current (Mock Mode):**
- ❌ No real authentication
- ❌ Passwords stored in plain text (UserDefaults)
- ❌ No password security
- ❌ No account recovery

**With Supabase:**
- ✅ Industry-standard authentication
- ✅ Secure password hashing (bcrypt)
- ✅ Email verification
- ✅ Password reset functionality
- ✅ Session tokens managed automatically

---

### 2. **User Profiles Storage** 👤
- **Profile Data** - Display name, avatar, preferences
- **User Stats** - Total steps, challenges joined
- **Account Settings** - Premium status, privacy settings

**Current (Mock Mode):**
- ❌ Stored locally on device only
- ❌ Lost if app is deleted
- ❌ No sync across devices

**With Supabase:**
- ✅ Stored in cloud database (`profiles` table)
- ✅ Syncs across all devices
- ✅ Persistent even if app is deleted
- ✅ Accessible from web/admin panel

---

### 3. **Challenges Management** 🏁
- **Challenge Creation** - Store challenge details (name, dates, settings)
- **Challenge Data** - Public/private settings, invite codes
- **Challenge Metadata** - Creator info, timestamps

**Current (Mock Mode):**
- ❌ Stored locally only
- ❌ Not shareable between users
- ❌ Lost if app deleted

**With Supabase:**
- ✅ Stored in `challenges` table
- ✅ Shareable via invite codes
- ✅ Persistent across app reinstalls
- ✅ Real-time updates possible

---

### 4. **Challenge Members & Leaderboards** 📊
- **Step Tracking** - Daily and total steps per user per challenge
- **Leaderboard Data** - Rankings, progress tracking
- **Member Management** - Who's in which challenge

**Current (Mock Mode):**
- ❌ Mock data only
- ❌ No real-time updates
- ❌ Not synchronized between users

**With Supabase:**
- ✅ Stored in `challenge_members` table
- ✅ Real-time leaderboard updates (with real-time subscriptions)
- ✅ Accurate step tracking
- ✅ Multi-user synchronization

---

### 5. **Friends System** 👥
- **Friend Relationships** - Who follows whom
- **Friend Activity** - See friends' step counts
- **Social Features** - Friend discovery, invitations

**Current (Mock Mode):**
- ⚠️ Mock friends list (hardcoded)

**With Supabase:**
- ✅ Stored in `friends` table
- ✅ Real friend relationships
- ✅ Friend activity feeds
- ✅ Social features enabled

---

## 📊 Database Schema

When Supabase is enabled, these tables will be used:

### `profiles`
```sql
- user_id (UUID, Primary Key, FK to auth.users)
- username (TEXT)
- avatar (TEXT)
- is_premium (BOOLEAN)
- created_at, updated_at
```

### `challenges`
```sql
- id (UUID, Primary Key)
- name (TEXT)
- start_date, end_date (TIMESTAMP)
- created_by (UUID, FK to auth.users)
- is_public (BOOLEAN)
- invite_code (TEXT, UNIQUE)
- description (TEXT)
```

### `challenge_members`
```sql
- id (UUID, Primary Key)
- challenge_id (UUID, FK to challenges)
- user_id (UUID, FK to auth.users)
- total_steps (INTEGER)
- daily_steps (JSONB) - {"2024-12-24": 5000, ...}
- joined_at, last_updated
```

### `friends`
```sql
- id (UUID, Primary Key)
- user_id (UUID, FK to auth.users)
- friend_id (UUID, FK to auth.users)
- status (TEXT) - 'pending', 'accepted', 'blocked'
```

---

## 🔄 Current vs. Supabase Mode

### Current Mode (Mock/Local)
```
User Signs Up
    ↓
User object created
    ↓
Saved to UserDefaults (local device only)
    ↓
Data lost if app deleted
    ↓
No sync across devices
    ↓
No real authentication
```

### Supabase Mode (Production)
```
User Signs Up
    ↓
Supabase Auth creates secure account
    ↓
Profile saved to Supabase Database
    ↓
Data synced across all devices
    ↓
Persistent even if app deleted
    ↓
Real authentication with security
```

---

## 🎯 Key Benefits of Using Supabase

### Security 🔒
- ✅ Industry-standard authentication
- ✅ Password hashing (bcrypt)
- ✅ Row Level Security (RLS) policies
- ✅ Secure API keys
- ✅ HTTPS encryption

### Scalability 📈
- ✅ Handles millions of users
- ✅ Automatic scaling
- ✅ Database backups
- ✅ High availability

### Features 🚀
- ✅ Real-time subscriptions (for live leaderboards)
- ✅ Email notifications
- ✅ File storage (for avatars)
- ✅ Edge functions (for custom logic)

### Developer Experience 👨‍💻
- ✅ Auto-generated APIs
- ✅ TypeScript types
- ✅ SQL editor
- ✅ Dashboard for monitoring

---

## 📍 Where Supabase is Used in Code

### Authentication (`AuthService.swift`)
- `signInWithSupabase()` - Email/password sign in
- `signUpWithSupabase()` - User registration
- `signOut()` - Logout
- `checkSupabaseSession()` - Check if user is logged in
- `loadUserProfile()` - Load user data from database
- `updateUserProfile()` - Update user profile

### Configuration (`SupabaseClient.swift`)
- Supabase URL and API key
- Client initialization

### Future Integration Points
- `ChallengeService.swift` - Would use Supabase for challenges
- `FriendsService.swift` - Would use Supabase for friends
- Real-time leaderboard updates
- Push notifications

---

## ⚠️ Current Limitations (Without Supabase)

1. **No Real Authentication**
   - Anyone can create accounts
   - No password security
   - No account recovery

2. **Data Loss Risk**
   - All data stored locally
   - Lost if app deleted
   - No backup

3. **No Multi-Device Sync**
   - Data only on one device
   - Can't access from other devices

4. **No Real-Time Features**
   - Leaderboards don't update in real-time
   - No live challenge updates

5. **No Social Features**
   - Can't share challenges
   - No real friend system
   - No social interactions

---

## ✅ To Enable Supabase

1. **Add Supabase Swift Package** to Xcode
2. **Create database tables** (run `SUPABASE_DATABASE_SETUP.sql`)
3. **Set `useSupabase = true`** in `AuthService.swift`
4. **Test connection** using the built-in test tool

See `QUICK_SETUP_GUIDE.md` for step-by-step instructions.

---

## 🧪 Testing Supabase Connection

You can test your Supabase connection using the built-in test tool:

1. Run the app
2. Go to **Profile** tab → **Settings**
3. Scroll to **Developer Tools** (orange icon)
4. Tap **"Test Supabase Connection"**
5. Tap **"Test Connection"** button

The test will verify:
- ✅ Supabase client initialization
- ✅ URL configuration
- ✅ API key configuration
- ✅ Auth service connection
- ✅ Database connection

