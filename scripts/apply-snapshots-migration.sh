#!/bin/bash

# Challenge Snapshots Migration Helper
# This script helps you apply the migration to Supabase

echo "================================================"
echo "Challenge Snapshots Migration"
echo "================================================"
echo ""
echo "OPTION 1: Using Supabase Dashboard (Recommended)"
echo "----------------------------------------------"
echo "1. Go to: https://supabase.com/dashboard"
echo "2. Select your project"
echo "3. Navigate to: SQL Editor"
echo "4. Click 'New Query'"
echo "5. Copy and paste the contents of:"
echo "   scripts/sql/CREATE_CHALLENGE_SNAPSHOTS.sql"
echo "6. Click 'Run' or press Cmd+Enter"
echo ""
echo "OPTION 2: Using psql (if you have direct database access)"
echo "----------------------------------------------"
echo "psql <your-connection-string> -f scripts/sql/CREATE_CHALLENGE_SNAPSHOTS.sql"
echo ""
echo "OPTION 3: View the SQL file now"
echo "----------------------------------------------"

read -p "Would you like to view the SQL file? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    cat scripts/sql/CREATE_CHALLENGE_SNAPSHOTS.sql
fi

echo ""
echo "================================================"
echo "After running the migration in Supabase:"
echo "================================================"
echo "1. Clean build your app (Cmd+Shift+K in Xcode)"
echo "2. Run the app"
echo "3. Go to Archive tab"
echo "4. Open any archived challenge"
echo "5. The app will automatically create snapshots"
echo "================================================"
