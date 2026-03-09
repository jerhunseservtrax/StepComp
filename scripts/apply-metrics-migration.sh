#!/bin/bash

# User Metrics Tables Migration Helper
# Creates workout_sessions, workout_session_sets, and weight_log tables
# plus RPC functions for syncing and querying historical metrics.

echo "================================================"
echo "User Metrics Tables Migration"
echo "================================================"
echo ""
echo "OPTION 1: Using Supabase Dashboard (Recommended)"
echo "----------------------------------------------"
echo "1. Go to: https://supabase.com/dashboard"
echo "2. Select your project"
echo "3. Navigate to: SQL Editor"
echo "4. Click 'New Query'"
echo "5. Copy and paste the contents of:"
echo "   scripts/sql/CREATE_USER_METRICS_TABLES.sql"
echo "6. Click 'Run' or press Cmd+Enter"
echo ""
echo "OPTION 2: Using psql (if you have direct database access)"
echo "----------------------------------------------"
echo "psql <your-connection-string> -f scripts/sql/CREATE_USER_METRICS_TABLES.sql"
echo ""
echo "OPTION 3: View the SQL file now"
echo "----------------------------------------------"

read -p "Would you like to view the SQL file? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    cat scripts/sql/CREATE_USER_METRICS_TABLES.sql
fi

echo ""
echo "================================================"
echo "After running the migration in Supabase:"
echo "================================================"
echo "1. Clean build your app (Cmd+Shift+K in Xcode)"
echo "2. Run the app"
echo "3. Existing local data will auto-sync on launch"
echo ""
echo "New tables created:"
echo "  - workout_sessions   (completed workout headers)"
echo "  - workout_session_sets (exercise sets per session)"
echo "  - weight_log         (body weight entries)"
echo ""
echo "New RPC functions:"
echo "  - sync_workout_session(p_session JSONB)"
echo "  - sync_weight_entry(p_date, p_weight_kg, p_source)"
echo "  - get_user_metrics_summary(p_days)"
echo "  - get_exercise_history(p_exercise_name, p_days)"
echo "  - get_weight_history(p_days)"
echo "  - get_workout_history(p_days)"
echo "================================================"
