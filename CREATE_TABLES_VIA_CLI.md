# Creating Tables via Supabase CLI

## 🔐 Authentication Required

To use the Supabase CLI to create tables, you need to authenticate first.

### Option 1: Login via Browser (Recommended)

```bash
cd /Users/jefferyerhunse/GitRepos/StepComp
supabase login
```

This will:
1. Open your browser
2. Ask you to authenticate with Supabase
3. Store your access token locally

### Option 2: Use Access Token

If you have a Supabase access token:

```bash
export SUPABASE_ACCESS_TOKEN="your-access-token"
```

Get your access token from: https://app.supabase.com/account/tokens

---

## 📋 Steps to Create Tables

### Step 1: Login
```bash
supabase login
```

### Step 2: Link Project
```bash
supabase link --project-ref cwrirmowykxajumjokjj
```

You'll need your database password (found in Supabase Dashboard → Settings → Database → Database Password)

### Step 3: Execute SQL Script
```bash
supabase db execute --file SUPABASE_DATABASE_SETUP.sql
```

Or execute directly:
```bash
supabase db execute < SUPABASE_DATABASE_SETUP.sql
```

---

## 🎯 Alternative: Use Supabase Dashboard (Easier)

If CLI authentication is complex, you can use the Supabase Dashboard:

1. Go to: https://app.supabase.com/project/cwrirmowykxajumjokjj
2. Click **SQL Editor** in left sidebar
3. Click **New Query**
4. Copy entire contents of `SUPABASE_DATABASE_SETUP.sql`
5. Paste into editor
6. Click **Run** (or press ⌘ + Enter)

This is often faster and doesn't require CLI setup!

---

## 🔍 Verify Tables Were Created

After running the script, verify in Supabase Dashboard:

1. Go to **Table Editor**
2. You should see:
   - ✅ `profiles`
   - ✅ `challenges`
   - ✅ `challenge_members`
   - ✅ `friends`

---

## ⚠️ Note

The CLI method requires:
- Supabase account login
- Database password
- Proper authentication

The Dashboard method is simpler and doesn't require CLI setup!

