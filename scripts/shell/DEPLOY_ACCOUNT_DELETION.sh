#!/bin/bash

# ============================================================================
# DEPLOY ACCOUNT DELETION FUNCTION
# ============================================================================
# This script deploys the delete_user_account() RPC function to Supabase
# Run this before deploying the app update with the deletion UI
# ============================================================================

echo "🚀 Deploying Account Deletion Function to Supabase..."
echo ""

# Check if SQL file exists
if [ ! -f "DELETE_ACCOUNT_FUNCTION.sql" ]; then
    echo "❌ Error: DELETE_ACCOUNT_FUNCTION.sql not found"
    echo "Make sure you're running this from the project root"
    exit 1
fi

# Execute the SQL file
./EXECUTE_SQL_NOW.sh DELETE_ACCOUNT_FUNCTION.sql

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Verify function in Supabase Dashboard:"
echo "   Database → Functions → delete_user_account"
echo ""
echo "2. Test with a test account:"
echo "   - Create test account with sample data"
echo "   - Use delete account feature"
echo "   - Verify all data removed"
echo ""
echo "3. Check logs in Supabase:"
echo "   Logs & Analytics → Database Logs"
echo "   Look for: '🗑️ Starting account deletion'"
echo ""
echo "4. Deploy app to TestFlight"
echo ""
echo "⚠️  IMPORTANT: Test thoroughly before production!"

