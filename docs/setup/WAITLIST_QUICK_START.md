# 🚀 Waitlist Quick Start Guide

## ✅ **Step 1: Check if Table Already Exists**

### **Option A: Check in Supabase Dashboard**
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Click **"Table Editor"** in left sidebar
4. Look for **`waitlist`** table
5. **If you see it → Skip to Step 2!**
6. **If you don't see it → Continue below**

### **Option B: Check via SQL**
1. Go to Supabase Dashboard → **SQL Editor**
2. Run this query:
```sql
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'waitlist'
);
```
- **Returns `true`** → Table exists! Skip to Step 2
- **Returns `false`** → Table doesn't exist, create it below

---

## 🗄️ **Step 2: Create Waitlist Table (If Needed)**

### **Method 1: Using SQL Editor (Recommended)**

1. **Open Supabase Dashboard**
2. Click **"SQL Editor"** in left sidebar
3. Click **"New Query"**
4. **Copy the entire contents** of `supabase/migrations/create_waitlist_table.sql`
5. **Paste into SQL Editor**
6. Click **"Run"** (or press `Cmd+Enter` / `Ctrl+Enter`)
7. ✅ You should see: **"Success. No rows returned"**

### **Method 2: Using Supabase CLI**

```bash
# If you have Supabase CLI installed
cd /Users/jefferyerhunse/GitRepos/StepComp
supabase db execute --file supabase/migrations/create_waitlist_table.sql
```

### **Verify Table Was Created:**

Run this in SQL Editor:
```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'waitlist'
ORDER BY ordinal_position;
```

**Expected output:**
```
id           | uuid
email        | text
referral_source | text
ip_address   | inet
user_agent   | text
created_at   | timestamp with time zone
notified_at  | timestamp with time zone
```

---

## 👀 **Step 3: Preview Waitlist Page Locally**

### **Method 1: Open in Browser (Easiest)**

1. **Open Finder**
2. Navigate to: `/Users/jefferyerhunse/GitRepos/StepComp`
3. Find `waitlist.html`
4. **Right-click** → **"Open With"** → **"Safari"** (or Chrome/Firefox)
5. ✅ Page opens in browser!

**Note:** The form won't work yet (needs Supabase credentials), but you can see the design!

### **Method 2: Using Terminal**

```bash
# Open in default browser
open waitlist.html

# Or specify browser
open -a "Google Chrome" waitlist.html
open -a "Safari" waitlist.html
```

### **Method 3: Using Python Simple Server (For Full Functionality)**

```bash
# Navigate to project directory
cd /Users/jefferyerhunse/GitRepos/StepComp

# Start local server (Python 3)
python3 -m http.server 8000

# Or if you have Node.js
npx serve .
```

Then open: `http://localhost:8000/waitlist.html`

---

## ⚙️ **Step 4: Configure Supabase Credentials (To Make Form Work)**

### **Find Your Supabase Credentials:**

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Click **"Settings"** (gear icon) → **"API"**
4. Copy these values:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon public** key (long string starting with `eyJ...`)

### **Update waitlist.html:**

1. Open `waitlist.html` in a text editor
2. Find this section (around line 100-102):
```javascript
const SUPABASE_URL = 'YOUR_SUPABASE_URL'; // Replace with your Supabase URL
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY'; // Replace with your Supabase Anon Key
```

3. **Replace with your actual values:**
```javascript
const SUPABASE_URL = 'https://cwrirmowykxajumjokjj.supabase.co'; // Your actual URL
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'; // Your actual key
```

4. **Save the file**

### **Test the Form:**

1. **Refresh the page** in your browser
2. Enter a test email: `test@example.com`
3. Click **"Get Early Access"**
4. ✅ Should see: **"Awesome! You're on the list."**
5. ✅ Counter should increment

---

## 📋 **Quick Checklist**

- [ ] Checked if `waitlist` table exists
- [ ] Created `waitlist` table (if needed)
- [ ] Verified table structure
- [ ] Opened `waitlist.html` in browser
- [ ] Updated Supabase URL in HTML
- [ ] Updated Supabase Anon Key in HTML
- [ ] Tested form submission
- [ ] Verified email appears in Supabase Dashboard

---

## 🎨 **What the Waitlist Page Looks Like**

### **Design Features:**
- ✅ **Yellow accent color** matching your app (`#F9F506`)
- ✅ **Clean white background**
- ✅ **Manrope font** (same as app)
- ✅ **Email input** with icon
- ✅ **Glowing yellow button**
- ✅ **Real-time waitlist counter** (e.g., "42+ people waiting")
- ✅ **Feature cards** (Trophy, Health, Group icons)
- ✅ **Social proof section**
- ✅ **Mobile-responsive** design

### **Sections:**
1. **Hero Section** - "Walk more. Win more."
2. **Email Form** - Input with submit button
3. **Waitlist Counter** - Shows total signups
4. **Feature Cards** - Highlights app features
5. **Social Proof** - Shows community growth

---

## 🐛 **Troubleshooting**

### **"Table already exists" Error:**
- ✅ This is fine! Table already created
- Skip to Step 3

### **"Permission denied" Error:**
- Make sure you're using the **SQL Editor** (not Table Editor)
- You need admin/service role access

### **Form doesn't submit:**
- Check browser console for errors (F12 → Console)
- Verify Supabase URL and Anon Key are correct
- Make sure `waitlist` table exists
- Check that RLS policies are set up correctly

### **Counter shows "0 people waiting":**
- This is normal if no one has signed up yet
- Test by submitting your email
- Counter should update immediately

### **Can't open HTML file:**
- Make sure you're in the correct directory
- Try: `open /Users/jefferyerhunse/GitRepos/StepComp/waitlist.html`
- Or drag file to browser window

---

## 🚀 **Next Steps**

Once everything works:

1. **Deploy the page** to Netlify/Vercel/GitHub Pages
2. **Share the link** on social media
3. **Watch signups roll in** in Supabase Dashboard
4. **Export emails** when ready to launch
5. **Send launch announcement** to waitlist

---

## ✅ **Summary**

**To create table:**
1. Supabase Dashboard → SQL Editor
2. Copy/paste `create_waitlist_table.sql`
3. Click Run

**To preview page:**
1. Open `waitlist.html` in browser
2. Or run: `open waitlist.html`

**To make form work:**
1. Update Supabase URL and Anon Key in HTML
2. Refresh page
3. Test submission

**That's it!** 🎉

