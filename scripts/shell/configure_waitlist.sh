#!/bin/bash

# Configure waitlist.html with your Supabase credentials
# This script helps you quickly set up the waitlist page

echo "🚀 StepComp Waitlist Configuration"
echo ""
echo "You'll need your Supabase Project URL and Anon Key"
echo "Find them at: https://app.supabase.com/project/cwrirmowykxajumjokjj/settings/api"
echo ""

read -p "Enter your Supabase URL (e.g., https://xxx.supabase.co): " SUPABASE_URL
read -p "Enter your Supabase Anon Key: " SUPABASE_ANON_KEY

# Update the HTML file
sed -i.bak "s|const SUPABASE_URL = 'YOUR_SUPABASE_URL';|const SUPABASE_URL = '$SUPABASE_URL';|g" waitlist.html
sed -i.bak "s|const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';|const SUPABASE_ANON_KEY = '$SUPABASE_ANON_KEY';|g" waitlist.html

echo ""
echo "✅ Configuration updated in waitlist.html!"
echo ""
echo "📋 Next Steps:"
echo "1. Run the SQL migration in Supabase Dashboard"
echo "   → Copy supabase/migrations/create_waitlist_table.sql"
echo "   → Paste in SQL Editor and run"
echo ""
echo "2. Deploy waitlist.html to:"
echo "   → Netlify: https://netlify.com (drag & drop)"
echo "   → Vercel: https://vercel.com"
echo "   → GitHub Pages"
echo ""
echo "3. Share your waitlist link and start collecting emails!"
echo ""
echo "📚 See WAITLIST_SETUP.md for complete instructions"

