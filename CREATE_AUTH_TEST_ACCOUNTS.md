# Create Auth Test Accounts

This guide helps you create 5 test accounts in Supabase's `auth.users` table for testing purposes.

## Overview

The script creates 5 test users with:
- Unique UUIDs
- Email addresses (testuser1@stepcomp.test through testuser5@stepcomp.test)
- Usernames (testuser1 through testuser5)
- All using the same password: `TestPassword123!`
- Email confirmed and ready to use
- Corresponding profiles created automatically

## How to Use

### Step 1: Run the SQL Script

1. Go to **Supabase Dashboard** → **SQL Editor**
2. Click **New Query**
3. Copy and paste the contents of `CREATE_AUTH_TEST_ACCOUNTS.sql`
4. Click **Run** (or press Cmd/Ctrl + Enter)

### Step 2: Verify Accounts

After running the script, verify the accounts were created by running the verification query at the bottom of the script, or manually check:

```sql
SELECT 
    u.id,
    u.email,
    u.email_confirmed_at,
    p.username,
    p.display_name
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id OR p.user_id = u.id
WHERE u.email LIKE 'testuser%@stepcomp.test'
ORDER BY u.email;
```

## Test Account Credentials

All accounts use the same password: **TestPassword123!**

| Account | Email | Username | Password |
|---------|-------|----------|----------|
| 1 | testuser1@stepcomp.test | testuser1 | TestPassword123! |
| 2 | testuser2@stepcomp.test | testuser2 | TestPassword123! |
| 3 | testuser3@stepcomp.test | testuser3 | TestPassword123! |
| 4 | testuser4@stepcomp.test | testuser4 | TestPassword123! |
| 5 | testuser5@stepcomp.test | testuser5 | TestPassword123! |

## Account Details

Each account includes:
- ✅ Email confirmed (`email_confirmed_at` set)
- ✅ Account confirmed (`confirmed_at` set)
- ✅ Email provider metadata
- ✅ User metadata (first_name, last_name, username)
- ✅ Profile created in `public.profiles` table
- ✅ Public profile enabled (for friends system)

## Schema Compatibility

The script automatically detects your schema:
- **Newer schema**: Uses `profiles.id` column (from FRIENDS_SYSTEM_MIGRATION.sql)
- **Older schema**: Uses `profiles.user_id` column (from SUPABASE_DATABASE_SETUP_UPDATED.sql)

The script will work with either schema automatically.

## Password Hash

The password hash used is for `TestPassword123!`:
```
$2a$10$6x4YlKtQZJh2uTutCAYad.Ay5iQvaW7wMcGSiJ1P/CroUgAd4q5YO
```

If you need to change the password, generate a new bcrypt hash at:
- https://bcrypt-generator.com/
- Or use PostgreSQL: `SELECT crypt('YourPassword', gen_salt('bf', 10));`

## Troubleshooting

### Error: "duplicate key value violates unique constraint"

This means the accounts already exist. The script uses `ON CONFLICT DO NOTHING` so it's safe to run multiple times. If you want to update existing accounts, modify the script to use `ON CONFLICT DO UPDATE`.

### Error: "column does not exist"

Check your profiles table schema. The script tries to detect the schema automatically, but if you have a custom schema, you may need to adjust the profile insertion section.

### Accounts created but profiles missing

Run the profile creation section manually, or check if the `handle_new_user()` trigger is working correctly.

## Cleanup

To delete these test accounts:

```sql
-- Delete profiles first (due to foreign key constraints)
DELETE FROM public.profiles 
WHERE id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    '33333333-3333-3333-3333-333333333333',
    '44444444-4444-4444-4444-444444444444',
    '55555555-5555-5555-5555-555555555555'
) OR user_id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    '33333333-3333-3333-3333-333333333333',
    '44444444-4444-4444-4444-444444444444',
    '55555555-5555-5555-5555-555555555555'
);

-- Delete auth users
DELETE FROM auth.users 
WHERE id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    '33333333-3333-3333-3333-333333333333',
    '44444444-4444-4444-4444-444444444444',
    '55555555-5555-5555-5555-555555555555'
);
```

