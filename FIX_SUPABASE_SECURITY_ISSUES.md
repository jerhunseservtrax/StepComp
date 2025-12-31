# Fix Supabase Security Issues

This guide helps you fix the 9 security warnings shown in Supabase Security Advisor.

## Issues to Fix

1. **8 Function Search Path Mutable warnings** - Functions need `SET search_path` to prevent search path manipulation attacks
2. **1 Leaked Password Protection Disabled warning** - Needs to be enabled in the dashboard

## Solution

### Step 1: Fix Function Search Path Issues

Run the SQL script `FIX_SUPABASE_SECURITY_ISSUES.sql` in your Supabase Dashboard:

1. Go to **Supabase Dashboard** → **SQL Editor**
2. Click **New Query**
3. Copy and paste the contents of `FIX_SUPABASE_SECURITY_ISSUES.sql`
4. Click **Run** (or press Cmd/Ctrl + Enter)

This will update all 8 functions with the `SET search_path = public, pg_catalog;` clause, which prevents search path manipulation attacks.

### Step 2: Enable Leaked Password Protection

The "Leaked Password Protection Disabled" warning cannot be fixed via SQL. You need to enable it in the Supabase Dashboard:

1. Go to **Supabase Dashboard** → **Authentication** → **Settings**
2. Scroll down to the **Password Protection** section
3. Find **"Leaked Password Protection"** toggle
4. **Enable** the toggle
5. Save the changes

This will check user passwords against known data breach databases and prevent users from using compromised passwords.

## Functions Fixed

The following functions have been updated with `SET search_path`:

1. `update_updated_at_column()` - Trigger function for updating timestamps
2. `set_updated_at()` - Trigger function for friendships table
3. `handle_new_user()` - Trigger function for auto-creating profiles
4. `generate_invite_code()` - Generates unique challenge invite codes
5. `get_user_total_steps()` - Gets user's total steps across challenges
6. `get_challenge_leaderboard()` - Gets leaderboard for a challenge
7. `create_friend_invite()` - Creates secure friend invite tokens
8. `consume_friend_invite()` - Consumes friend invite tokens

## Verification

After running the script:

1. Go to **Supabase Dashboard** → **Security Advisor**
2. Click **Refresh** to update the warnings
3. The 8 "Function Search Path Mutable" warnings should be resolved
4. The "Leaked Password Protection Disabled" warning will be resolved after enabling it in Authentication settings

## Security Benefits

- **Search Path Protection**: Prevents attackers from manipulating the search path to execute malicious code
- **Leaked Password Protection**: Prevents users from using passwords that have been compromised in data breaches

