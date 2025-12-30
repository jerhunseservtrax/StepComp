#!/usr/bin/env python3
"""
Create 5 test accounts in Supabase for testing the friends feature.

This script uses the Supabase Management API to create users and their profiles.

Requirements:
    pip install supabase

Usage:
    python3 CREATE_TEST_ACCOUNTS.py
"""

import os
import sys
from supabase import create_client, Client
from supabase.lib.client_options import ClientOptions

# Test account data
TEST_ACCOUNTS = [
    {
        "email": "sarah.test@stepcomp.app",
        "password": "TestPassword123!",
        "username": "sarahchen",
        "first_name": "Sarah",
        "last_name": "Chen",
        "avatar": "https://i.pravatar.cc/150?img=1",
        "height": 165,
        "weight": 60
    },
    {
        "email": "mike.test@stepcomp.app",
        "password": "TestPassword123!",
        "username": "mikejohnson",
        "first_name": "Mike",
        "last_name": "Johnson",
        "avatar": "https://i.pravatar.cc/150?img=5",
        "height": 180,
        "weight": 75
    },
    {
        "email": "emma.test@stepcomp.app",
        "password": "TestPassword123!",
        "username": "emmawilson",
        "first_name": "Emma",
        "last_name": "Wilson",
        "avatar": "https://i.pravatar.cc/150?img=9",
        "height": 170,
        "weight": 65
    },
    {
        "email": "alex.test@stepcomp.app",
        "password": "TestPassword123!",
        "username": "alexrivera",
        "first_name": "Alex",
        "last_name": "Rivera",
        "avatar": "https://i.pravatar.cc/150?img=12",
        "height": 175,
        "weight": 70
    },
    {
        "email": "jordan.test@stepcomp.app",
        "password": "TestPassword123!",
        "username": "jordantaylor",
        "first_name": "Jordan",
        "last_name": "Taylor",
        "avatar": "https://i.pravatar.cc/150?img=15",
        "height": 172,
        "weight": 68
    }
]

def get_supabase_url():
    """Get Supabase URL from environment or config."""
    url = os.getenv("SUPABASE_URL")
    if not url:
        # Default to the URL from SupabaseClient.swift
        url = "https://cwrirmowykxajumjokjj.supabase.co"
        print(f"ℹ️  Using default Supabase URL: {url}")
        print("   (Set SUPABASE_URL environment variable to override)")
    return url

def get_supabase_service_key():
    """Get Supabase service role key (for admin operations)."""
    key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
    if not key:
        print("⚠️  SUPABASE_SERVICE_ROLE_KEY not found in environment")
        print("   Please set SUPABASE_SERVICE_ROLE_KEY environment variable")
        print("   You can find this in: Supabase Dashboard > Settings > API > service_role key")
        sys.exit(1)
    return key

def create_test_accounts():
    """Create test accounts in Supabase."""
    url = get_supabase_url()
    service_key = get_supabase_service_key()
    
    # Create admin client (uses service_role key for admin operations)
    supabase: Client = create_client(url, service_key)
    
    print("🚀 Creating test accounts in Supabase...")
    print(f"   URL: {url}\n")
    
    created_count = 0
    updated_count = 0
    
    for account in TEST_ACCOUNTS:
        try:
            # Check if user already exists
            existing_users = supabase.auth.admin.list_users()
            existing_user = None
            for user in existing_users.users:
                if user.email == account["email"]:
                    existing_user = user
                    break
            
            user_id = None
            
            if existing_user:
                print(f"✅ User already exists: {account['email']}")
                user_id = existing_user.id
            else:
                # Create auth user
                print(f"📝 Creating user: {account['email']}...")
                auth_response = supabase.auth.admin.create_user({
                    "email": account["email"],
                    "password": account["password"],
                    "email_confirm": True  # Auto-confirm email
                })
                user_id = auth_response.user.id
                print(f"   ✅ Auth user created: {user_id}")
            
            # Create or update profile
            profile_data = {
                "id": user_id,  # Use 'id' instead of 'user_id' to match new schema
                "username": account["username"],
                "email": account["email"],
                "first_name": account["first_name"],
                "last_name": account["last_name"],
                "avatar": account["avatar"],
                "is_premium": False,
                "height": account["height"],
                "weight": account["weight"]
            }
            
            # Check if profile exists
            existing_profile = supabase.table("profiles").select("*").eq("id", user_id).execute()
            
            if existing_profile.data:
                # Update existing profile
                supabase.table("profiles").update(profile_data).eq("id", user_id).execute()
                print(f"   ✅ Profile updated: {account['first_name']} {account['last_name']}")
                updated_count += 1
            else:
                # Create new profile
                supabase.table("profiles").insert(profile_data).execute()
                print(f"   ✅ Profile created: {account['first_name']} {account['last_name']}")
                created_count += 1
            
            print()
            
        except Exception as e:
            print(f"   ❌ Error creating account {account['email']}: {str(e)}")
            print()
    
    print("=" * 50)
    print(f"✅ Complete! Created: {created_count}, Updated: {updated_count}")
    print("\n📋 Test Account Credentials:")
    print("-" * 50)
    for account in TEST_ACCOUNTS:
        print(f"Email: {account['email']}")
        print(f"Password: {account['password']}")
        print(f"Name: {account['first_name']} {account['last_name']}")
        print(f"Username: @{account['username']}")
        print()

if __name__ == "__main__":
    try:
        create_test_accounts()
    except KeyboardInterrupt:
        print("\n\n⚠️  Cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        sys.exit(1)

