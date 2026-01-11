# Supabase CLI Guide

## ✅ Installation Complete

The Supabase CLI has been successfully installed via Homebrew.

**Version:** 2.67.1  
**Location:** `/opt/homebrew/Cellar/supabase/2.67.1`

## 🚀 What You Can Do with Supabase CLI

### 1. Link to Your Supabase Project

```bash
cd /Users/jefferyerhunse/GitRepos/StepComp
supabase link --project-ref cwrirmowykxajumjokjj
```

This connects your local project to your Supabase project.

### 2. Run Database Migrations Locally

Instead of running SQL in the Supabase Dashboard, you can:

```bash
# Create a new migration
supabase migration new create_profiles_table

# Apply migrations
supabase db push
```

### 3. Generate TypeScript Types

```bash
# Generate types from your database schema
supabase gen types typescript --local > types/database.types.ts
```

### 4. Start Local Development

```bash
# Start local Supabase instance (Docker required)
supabase start
```

This gives you a local Supabase instance for development.

### 5. Run SQL Scripts

```bash
# Run SQL file against your project
supabase db execute --file SUPABASE_DATABASE_SETUP.sql
```

## 📋 Quick Commands

### Initialize Supabase in Your Project

```bash
cd /Users/jefferyerhunse/GitRepos/StepComp
supabase init
```

### Link to Your Project

```bash
supabase link --project-ref cwrirmowykxajumjokjj
```

You'll need your database password (found in Supabase Dashboard → Settings → Database).

### Create Database Tables

```bash
# Option 1: Run SQL file directly
supabase db execute --file SUPABASE_DATABASE_SETUP.sql

# Option 2: Create migration and apply
supabase migration new setup_tables
# Edit the migration file, then:
supabase db push
```

### Check Status

```bash
supabase status
```

### View Logs

```bash
supabase logs
```

## 🔧 Common Workflows

### Setting Up Database Tables

1. **Link to project:**
   ```bash
   supabase link --project-ref cwrirmowykxajumjokjj
   ```

2. **Run SQL setup script:**
   ```bash
   supabase db execute --file SUPABASE_DATABASE_SETUP.sql
   ```

3. **Verify tables were created:**
   ```bash
   supabase db diff
   ```

### Creating a New Migration

1. **Create migration:**
   ```bash
   supabase migration new add_user_preferences
   ```

2. **Edit the migration file** in `supabase/migrations/`

3. **Apply migration:**
   ```bash
   supabase db push
   ```

### Local Development

1. **Start local Supabase:**
   ```bash
   supabase start
   ```

2. **Reset local database:**
   ```bash
   supabase db reset
   ```

3. **Stop local Supabase:**
   ```bash
   supabase stop
   ```

## 📚 Useful Commands

```bash
# Get help
supabase --help

# Check CLI version
supabase --version

# List all commands
supabase help

# Database commands
supabase db --help

# Auth commands
supabase auth --help

# Storage commands
supabase storage --help
```

## 🎯 Next Steps

Now that you have the CLI installed:

1. **Link your project:**
   ```bash
   cd /Users/jefferyerhunse/GitRepos/StepComp
   supabase link --project-ref cwrirmowykxajumjokjj
   ```

2. **Run the database setup:**
   ```bash
   supabase db execute --file SUPABASE_DATABASE_SETUP.sql
   ```

3. **Verify everything works:**
   - Check Supabase Dashboard → Table Editor
   - Run the connection test in your app

## 📖 Documentation

- **Official Docs**: https://supabase.com/docs/reference/cli
- **GitHub**: https://github.com/supabase/cli

## ⚠️ Note

The CLI requires:
- Docker (for local development)
- Your Supabase project reference ID: `cwrirmowykxajumjokjj`
- Database password (from Supabase Dashboard → Settings → Database)

