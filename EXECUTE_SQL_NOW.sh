#!/bin/bash
# Script to create Supabase tables via CLI

echo "🔐 Step 1: Authenticating with Supabase..."
echo "This will open your browser for authentication."
supabase login

echo ""
echo "🔗 Step 2: Linking to your project..."
echo "You'll need your database password from: https://app.supabase.com/project/cwrirmowykxajumjokjj/settings/database"
supabase link --project-ref cwrirmowykxajumjokjj

echo ""
echo "📊 Step 3: Creating database tables..."
supabase db execute --file SUPABASE_DATABASE_SETUP.sql

echo ""
echo "✅ Done! Tables should be created."
echo "Verify in Supabase Dashboard → Table Editor"

