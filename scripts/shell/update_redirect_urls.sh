#!/bin/bash

# Update Supabase Auth Redirect URLs via Management API
# This script updates redirect URLs for password reset to use the app's registered URL schemes.

PROJECT_REF="cwrirmowykxajumjokjj"

echo "📝 Updating Supabase Auth Redirect URLs..."
echo ""
echo "You'll need your Supabase access token (from https://app.supabase.com/account/tokens)"
echo ""
read -p "Enter your Supabase access token: " ACCESS_TOKEN

# Update auth configuration
curl -X PATCH "https://api.supabase.com/v1/projects/${PROJECT_REF}/config/auth" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "SITE_URL": "fitcomp://",
    "ADDITIONAL_REDIRECT_URLS": "fitcomp://reset-password,fitcomp://friend-invite,je.fitcomp://reset-password,je.fitcomp://friend-invite,je.stepcomp://reset-password,je.stepcomp://friend-invite"
  }'

echo ""
echo ""
echo "✅ Done! Wait 1-2 minutes for changes to propagate."
echo ""
echo "To verify:"
echo "1. Request a password reset in your app"
echo "2. Check the email link - it should start with fitcomp://"
echo ""

