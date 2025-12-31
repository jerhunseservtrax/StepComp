#!/bin/bash

# ============================================
# Waitlist Preview & Setup Helper
# ============================================

echo "🚀 StepComp Waitlist Helper"
echo "=========================="
echo ""

# Check if waitlist.html exists
if [ -f "waitlist.html" ]; then
    echo "✅ Found waitlist.html"
    echo ""
    echo "Opening in browser..."
    open waitlist.html
    echo ""
    echo "📋 The page should now be open in your browser!"
    echo ""
    echo "⚠️  Note: The form won't work until you:"
    echo "   1. Create the waitlist table in Supabase"
    echo "   2. Update SUPABASE_URL and SUPABASE_ANON_KEY in waitlist.html"
    echo ""
else
    echo "❌ waitlist.html not found in current directory"
    echo "   Current directory: $(pwd)"
    echo ""
    echo "Please navigate to the project root directory."
    exit 1
fi

echo "📖 For setup instructions, see: WAITLIST_QUICK_START.md"
echo ""

