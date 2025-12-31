# 🚀 StepComp Waitlist Setup Guide

## Overview

A complete waitlist system for collecting early interest in your app before App Store launch.

---

## ✅ **What's Included**

1. **Database Table** - Stores waitlist emails securely
2. **Landing Page** - Beautiful HTML page matching app's design
3. **Automatic Count** - Shows "X people waiting" in real-time
4. **Spam Prevention** - Email validation, unique constraint, IP tracking
5. **Privacy Protection** - Row Level Security, emails not publicly readable

---

## 🗄️ **Database Setup**

### **Step 1: Create Waitlist Table**

**Run in Supabase Dashboard → SQL Editor:**

```bash
# Or use the migration file
cat supabase/migrations/create_waitlist_table.sql
```

**What it creates:**
- ✅ `waitlist` table with email, referral source, IP, timestamp
- ✅ Email validation constraint
- ✅ Unique constraint (no duplicate emails)
- ✅ RLS policies (anyone can INSERT, only admins can SELECT)
- ✅ `get_waitlist_count()` function for displaying count

**Table Structure:**
```sql
CREATE TABLE public.waitlist (
    id UUID PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    referral_source TEXT,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    notified_at TIMESTAMPTZ
);
```

---

## 🌐 **Landing Page Setup**

### **Step 2: Configure Supabase Credentials**

**Edit `waitlist.html` lines 100-102:**

```javascript
// Replace these with your actual Supabase credentials
const SUPABASE_URL = 'https://cwrirmowykxajumjokjj.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY_HERE';
```

**Where to find these:**
1. Go to Supabase Dashboard
2. Settings → API
3. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon public** key → `SUPABASE_ANON_KEY`

---

### **Step 3: Deploy the Landing Page**

**Option A: Netlify (Easiest - Free)**

1. Create account at https://netlify.com
2. Drag & drop `waitlist.html` to deploy
3. Get URL: `https://stepcomp-waitlist.netlify.app`
4. Share this link!

**Option B: Vercel (Free)**

1. Create account at https://vercel.com
2. Create new project
3. Upload `waitlist.html`
4. Deploy
5. Get URL: `https://stepcomp-waitlist.vercel.app`

**Option C: GitHub Pages (Free)**

1. Create repo: `stepcomp-waitlist`
2. Upload `waitlist.html` (rename to `index.html`)
3. Enable GitHub Pages in settings
4. Get URL: `https://yourusername.github.io/stepcomp-waitlist`

**Option D: Supabase Hosting (Coming Soon)**

Supabase will support static hosting - stay tuned!

---

## 🎨 **Design Features**

### **Matches Your App's UI:**

**Colors:**
- Primary Yellow: `#F9F506` (exact match to app)
- Background: `#FDFDFD` (light, clean)
- Surface: `#F4F4F5` (cards, inputs)
- Text: Black with gray accents

**Font:**
- Manrope (same as app)
- Bold, modern headings
- Clean, readable body text

**Components:**
- Email input with icon
- Glowing yellow button (matches app)
- Real-time waitlist count
- Success/error messages
- Social proof avatars
- Feature cards (Trophy, Health, Group icons)

---

## 🔐 **Security Features**

### **1. Email Validation**
- Client-side: HTML5 required + type="email"
- Server-side: PostgreSQL regex constraint
- Prevents invalid emails

### **2. Duplicate Prevention**
- `UNIQUE` constraint on email column
- Friendly message: "You're already on the waitlist!"
- No duplicate sign-ups

### **3. Spam Prevention**
- Stores IP address
- Stores user agent
- Can add rate limiting later
- Tracks referral source

### **4. Privacy Protection**
- RLS: Only service role can read emails
- Public can only INSERT (join waitlist)
- Emails not exposed via API
- Can only view in Supabase Dashboard

### **5. No Passwords Needed**
- Simple email collection
- No user accounts
- No authentication
- Just notify when ready

---

## 📊 **Admin Features**

### **View All Waitlist Emails**

**In Supabase Dashboard → Table Editor:**
1. Select `waitlist` table
2. See all emails, timestamps, referral sources
3. Export to CSV for email marketing

**Or via SQL:**
```sql
SELECT 
    email,
    referral_source,
    created_at,
    notified_at
FROM public.waitlist
ORDER BY created_at DESC;
```

### **Get Waitlist Count**
```sql
SELECT public.get_waitlist_count();
```

### **Mark Users as Notified**
```sql
UPDATE public.waitlist
SET notified_at = NOW()
WHERE notified_at IS NULL;
```

### **Export for Email Campaign**
```sql
-- Get all emails that haven't been notified yet
SELECT email
FROM public.waitlist
WHERE notified_at IS NULL
ORDER BY created_at ASC;
```

---

## 🧪 **Testing**

### **Test Email Submission:**

1. Open `waitlist.html` in browser
2. Enter email: `test@example.com`
3. Click "Get Early Access"
4. Should see: "🎉 You're on the list!"
5. Counter should increment
6. Try same email again
7. Should see: "You're already on the waitlist!"

### **Test in Supabase Dashboard:**

1. Go to Table Editor → `waitlist`
2. Should see new row with your test email
3. Check `created_at` timestamp
4. Check `ip_address` and `user_agent` populated

---

## 📧 **When App is Ready to Launch**

### **Step 1: Export Emails**
```sql
COPY (
    SELECT email 
    FROM public.waitlist 
    WHERE notified_at IS NULL
) TO STDOUT WITH CSV HEADER;
```

### **Step 2: Send Launch Email**

**Subject:** "🎉 StepComp is LIVE on the App Store!"

**Body:**
```
Hi there!

You signed up for early access to StepComp, and we're excited 
to announce it's now available on the App Store!

Download here: [APP_STORE_LINK]

Features you'll love:
• Challenge friends to daily step competitions
• Automatic Apple Health sync
• Real-time leaderboards
• Fun social features

Thanks for your patience!
The StepComp Team
```

### **Step 3: Mark as Notified**
```sql
UPDATE public.waitlist
SET notified_at = NOW()
WHERE notified_at IS NULL;
```

---

## 🎯 **Customization Options**

### **Change Hero Text:**
Edit line 61 in `waitlist.html`:
```html
<h1>
    Walk more.<br/>
    <span>Your custom text.</span>
</h1>
```

### **Change Feature Cards:**
Edit lines 141-175 - add/remove/modify features

### **Add More Fields:**
Update table schema and form:
```sql
ALTER TABLE public.waitlist
ADD COLUMN phone TEXT;
```

Then update HTML form to collect phone numbers.

---

## 📊 **Analytics Ideas**

### **Track Referral Sources:**
```sql
SELECT 
    referral_source,
    COUNT(*) as signups
FROM public.waitlist
GROUP BY referral_source
ORDER BY signups DESC;
```

### **Signups Over Time:**
```sql
SELECT 
    DATE(created_at) as date,
    COUNT(*) as signups
FROM public.waitlist
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

---

## 🚀 **Quick Start (5 Minutes)**

1. ✅ Run `create_waitlist_table.sql` in Supabase
2. ✅ Update `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `waitlist.html`
3. ✅ Deploy to Netlify/Vercel
4. ✅ Share the link!
5. ✅ Watch emails roll in

---

## 📱 **Share Links**

**Twitter/X:**
```
🚶‍♂️ Turn your walks into competitions! 

Join the StepComp waitlist for early access when we launch on iOS.

[YOUR_WAITLIST_URL]
```

**Instagram Bio:**
```
Step tracker that makes walking fun 🏆
Early access: [link in bio]
```

**Reddit:**
```
r/fitness - "I'm building a step competition app for iOS. 
Join the waitlist if interested!"
```

---

## ✅ **Summary**

**What You Get:**
- ✅ Beautiful landing page matching your app
- ✅ Supabase database integration
- ✅ Real-time waitlist counter
- ✅ Spam protection
- ✅ Privacy-compliant
- ✅ Export-ready for launch

**What You Need:**
- ⚠️ Update Supabase credentials in HTML
- ⚠️ Deploy to hosting platform
- ⚠️ Share the link!

**Time to Set Up:** 5 minutes
**Cost:** $0 (using free tiers)

---

## 🎉 **Ready to Collect Emails!**

Once configured, you'll have a professional waitlist system that:
- Looks great on mobile and desktop
- Matches your app's branding perfectly
- Securely stores emails in Supabase
- Shows real-time signup count
- Prevents spam and duplicates

**Share your waitlist link and start building hype!** 🚀

