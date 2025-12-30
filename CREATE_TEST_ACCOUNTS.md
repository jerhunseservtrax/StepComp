# Create Test Accounts for Friends Feature

This guide will help you create 5 test accounts in Supabase that you can use to test the add friend feature.

## Test Accounts

The following 5 test accounts will be created:

1. **Sarah Chen**
   - Email: `sarah.test@stepcomp.app`
   - Username: `@sarahchen`
   - Password: `TestPassword123!`

2. **Mike Johnson**
   - Email: `mike.test@stepcomp.app`
   - Username: `@mikejohnson`
   - Password: `TestPassword123!`

3. **Emma Wilson**
   - Email: `emma.test@stepcomp.app`
   - Username: `@emmawilson`
   - Password: `TestPassword123!`

4. **Alex Rivera**
   - Email: `alex.test@stepcomp.app`
   - Username: `@alexrivera`
   - Password: `TestPassword123!`

5. **Jordan Taylor**
   - Email: `jordan.test@stepcomp.app`
   - Username: `@jordantaylor`
   - Password: `TestPassword123!`

## Method 1: Using Bash Script (Easiest - No Python Required)

### Prerequisites

1. Get your Supabase service role key:
   - Go to Supabase Dashboard > **Settings > API**
   - Copy your **service_role key** (⚠️ Keep this secret!)

### Steps

1. Set the service role key:
   ```bash
   export SUPABASE_SERVICE_ROLE_KEY='your-service-role-key'
   ```

2. Run the script:
   ```bash
   ./create_test_accounts.sh
   ```

The script will create all 5 test accounts automatically.

## Method 2: Using Python Script (Recommended)

### Prerequisites

1. Install Python 3.7+
2. Install the Supabase Python client:
   ```bash
   pip install supabase
   ```

### Steps

1. Get your Supabase credentials:
   - Go to your Supabase Dashboard
   - Navigate to **Settings > API**
   - Copy your **Project URL** and **service_role key** (⚠️ Keep this secret!)

2. Set environment variables:
   ```bash
   export SUPABASE_URL="https://your-project-id.supabase.co"
   export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"
   ```

3. Run the script:
   ```bash
   python3 CREATE_TEST_ACCOUNTS.py
   ```

The script will:
- Create auth users in Supabase
- Create profiles for each user
- Handle existing users gracefully (updates profiles if users already exist)

## Method 3: Using Supabase Dashboard (Manual)

### Steps

1. **Create Auth Users:**
   - Go to Supabase Dashboard > **Authentication > Users**
   - Click **"Add User"** for each test account
   - Use the email and password from the list above
   - **Important:** Copy the User ID for each user

2. **Create Profiles:**
   - Go to Supabase Dashboard > **SQL Editor**
   - Open `CREATE_TEST_ACCOUNTS.sql`
   - Replace the placeholder UUIDs (`00000000-0000-0000-0000-000000000001`, etc.) with the actual User IDs from step 1
   - Run the SQL script

## Method 4: Using Supabase CLI

If you have the Supabase CLI set up:

1. Create a migration file:
   ```bash
   supabase migration new create_test_accounts
   ```

2. Copy the SQL from `CREATE_TEST_ACCOUNTS.sql` into the migration file

3. Update the UUIDs with actual user IDs (you'll need to create users first via Dashboard or API)

4. Apply the migration:
   ```bash
   supabase db push
   ```

## Verifying Test Accounts

After creating the accounts, verify they exist:

1. **Check Auth Users:**
   - Go to Supabase Dashboard > **Authentication > Users**
   - You should see all 5 test accounts

2. **Check Profiles:**
   - Go to Supabase Dashboard > **Table Editor > profiles**
   - You should see profiles for all 5 users with usernames, names, and avatars

## Using Test Accounts in the App

1. **Sign In:**
   - Use any of the test account emails and password `TestPassword123!`
   - The accounts are pre-configured with profiles

2. **Add Friends:**
   - Search for usernames like `@sarahchen`, `@mikejohnson`, etc.
   - Send friend requests
   - Accept friend requests from other test accounts

## Notes

- All test accounts use the same password: `TestPassword123!`
- Email confirmation is automatically enabled (for Python script method)
- Profiles include realistic avatars, heights, and weights
- You can modify the test account data in `CREATE_TEST_ACCOUNTS.py` if needed

## Troubleshooting

### "User already exists" error
- This is normal if you run the script multiple times
- The script will update existing profiles

### "Permission denied" error
- Make sure you're using the **service_role** key, not the **anon** key
- The service_role key has admin privileges needed to create users

### "Profile already exists" error
- The script uses `ON CONFLICT` handling, so this shouldn't be an issue
- If it occurs, check that the user_id matches the auth user ID

