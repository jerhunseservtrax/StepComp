# 🚀 Netlify Deployment Folder

This folder contains **ONLY** the 2 files you need to deploy to Netlify!

---

## 📁 Files in This Folder:

1. ✅ **`waitlist.html`** - Your waitlist page (configured with Supabase)
2. ✅ **`netlify.toml`** - Netlify configuration

---

## 🎯 HOW TO DEPLOY (2 minutes):

### Step 1: Go to Netlify
Visit: **https://app.netlify.com**

### Step 2: Start Deployment
Click: **"Add new site"** → **"Deploy manually"**

### Step 3: Drag This Entire Folder
**Drag the `netlify-deploy` folder** (or just the 2 files inside) into the Netlify drop zone.

### Step 4: Wait 30 seconds
Netlify will process and deploy your site...

### Step 5: YOU'RE LIVE! 🎉
Click the URL to visit your waitlist!

---

## ⚠️ BEFORE DEPLOYING:

Make sure you've completed:
- [x] ✅ Supabase credentials configured (already done!)
- [ ] ⬜ Database setup in Supabase (run `SETUP_WAITLIST_DATABASE.sql`)

**If you haven't set up the database yet**, go back to the main folder and:
1. Open `SETUP_WAITLIST_DATABASE.sql`
2. Copy all the SQL
3. Paste in Supabase SQL Editor: https://app.supabase.com/project/cwrirmowykxajumjokjj/sql
4. Click "Run"

---

## 🧪 After Deployment - Test:

1. Visit your Netlify URL
2. Enter your email
3. Click "Get Early Access"
4. Check Supabase → Table Editor → `waitlist` table
5. Confirm your email is there! ✅

---

## 💡 Pro Tip:

After deploying, change your site name:
- Netlify → Site settings → Change site name
- Set to: `stepcomp` or `stepcomp-waitlist`
- New URL: `https://stepcomp.netlify.app`

---

## 🎉 That's it!

Just drag this folder to Netlify and you're done!

**Questions?** Check the main deployment guides in the parent folder:
- `READY_TO_DEPLOY.md`
- `NETLIFY_DEPLOYMENT_GUIDE.md`

---

**Let's get those signups! 🚀📧**

