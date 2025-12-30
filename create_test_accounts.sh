#!/bin/bash
# Quick script to create test accounts using Supabase CLI or curl

set -e

SUPABASE_URL="${SUPABASE_URL:-https://cwrirmowykxajumjokjj.supabase.co}"
SUPABASE_SERVICE_KEY="${SUPABASE_SERVICE_ROLE_KEY}"

if [ -z "$SUPABASE_SERVICE_KEY" ]; then
    echo "❌ Error: SUPABASE_SERVICE_ROLE_KEY not set"
    echo ""
    echo "Please set your Supabase service role key:"
    echo "  export SUPABASE_SERVICE_ROLE_KEY='your-service-role-key'"
    echo ""
    echo "You can find this in: Supabase Dashboard > Settings > API > service_role key"
    exit 1
fi

echo "🚀 Creating test accounts in Supabase..."
echo "   URL: $SUPABASE_URL"
echo ""

# Test accounts data
declare -a ACCOUNTS=(
    "sarah.test@stepcomp.app:TestPassword123!:sarahchen:Sarah:Chen:https://i.pravatar.cc/150?img=1:165:60"
    "mike.test@stepcomp.app:TestPassword123!:mikejohnson:Mike:Johnson:https://i.pravatar.cc/150?img=5:180:75"
    "emma.test@stepcomp.app:TestPassword123!:emmawilson:Emma:Wilson:https://i.pravatar.cc/150?img=9:170:65"
    "alex.test@stepcomp.app:TestPassword123!:alexrivera:Alex:Rivera:https://i.pravatar.cc/150?img=12:175:70"
    "jordan.test@stepcomp.app:TestPassword123!:jordantaylor:Jordan:Taylor:https://i.pravatar.cc/150?img=15:172:68"
)

for account_data in "${ACCOUNTS[@]}"; do
    IFS=':' read -r email password username first_name last_name avatar height weight <<< "$account_data"
    
    echo "📝 Creating account: $email"
    
    # Create auth user
    response=$(curl -s -X POST "$SUPABASE_URL/auth/v1/admin/users" \
        -H "apikey: $SUPABASE_SERVICE_KEY" \
        -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$email\",
            \"password\": \"$password\",
            \"email_confirm\": true
        }")
    
    user_id=$(echo "$response" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
    
    if [ -z "$user_id" ]; then
        # User might already exist, try to get existing user
        echo "   ⚠️  User might already exist, checking..."
        response=$(curl -s -X GET "$SUPABASE_URL/auth/v1/admin/users?email=$email" \
            -H "apikey: $SUPABASE_SERVICE_KEY" \
            -H "Authorization: Bearer $SUPABASE_SERVICE_KEY")
        user_id=$(echo "$response" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
    fi
    
    if [ -z "$user_id" ]; then
        echo "   ❌ Failed to create or find user"
        continue
    fi
    
    echo "   ✅ User ID: $user_id"
    
    # Create/update profile
    profile_response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/profiles" \
        -H "apikey: $SUPABASE_SERVICE_KEY" \
        -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
        -H "Content-Type: application/json" \
        -H "Prefer: resolution=merge-duplicates" \
        -d "{
            \"user_id\": \"$user_id\",
            \"username\": \"$username\",
            \"first_name\": \"$first_name\",
            \"last_name\": \"$last_name\",
            \"avatar\": \"$avatar\",
            \"is_premium\": false,
            \"height\": $height,
            \"weight\": $weight
        }")
    
    echo "   ✅ Profile created/updated: $first_name $last_name"
    echo ""
done

echo "✅ Complete! Test accounts created."
echo ""
echo "📋 Test Account Credentials:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for account_data in "${ACCOUNTS[@]}"; do
    IFS=':' read -r email password username first_name last_name avatar height weight <<< "$account_data"
    echo "Email: $email"
    echo "Password: $password"
    echo "Name: $first_name $last_name"
    echo "Username: @$username"
    echo ""
done

