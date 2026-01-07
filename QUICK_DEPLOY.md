# 🚀 Quick Deploy Checklist

## ⚡ 3-Step Deployment

### 1️⃣ Set Up Supabase (5 minutes)
```bash
1. Go to https://app.supabase.com
2. Open your project → Settings → API
3. Copy "Project URL" and "anon public key"
4. Go to SQL Editor
5. Paste contents of SETUP_WAITLIST_DATABASE.sql
6. Click "Run"
```

### 2️⃣ Update waitlist.html (2 minutes)
```javascript
// Lines 179-180 in waitlist.html
const SUPABASE_URL = 'https://YOUR-PROJECT.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOi...'; // Your actual key
```

### 3️⃣ Deploy to Netlify (3 minutes)
```bash
Option A - Drag & Drop:
1. Go to https://app.netlify.com
2. Click "Add site" → "Deploy manually"
3. Drag waitlist.html and netlify.toml
4. Done! 🎉

Option B - GitHub (recommended):
1. Push code to GitHub
2. Go to https://app.netlify.com
3. Click "Add site" → "Import from Git"
4. Select your repo
5. Deploy!
```

---

## ✅ Test Your Deployment

1. Visit your Netlify URL
2. Enter email → Click "Get Early Access"
3. Check Supabase → Table Editor → waitlist
4. Confirm email is there! 🎉

---

## 📁 Files Created

- ✅ `netlify.toml` - Netlify config
- ✅ `NETLIFY_DEPLOYMENT_GUIDE.md` - Full guide
- ✅ `SETUP_WAITLIST_DATABASE.sql` - Database setup
- ✅ `QUICK_DEPLOY.md` - This file

---

## 🔧 Supabase Credentials Location

**In Supabase Dashboard:**
- Settings → API → Project URL
- Settings → API → Project API keys → anon public

**Update in:**
- `waitlist.html` lines 179-180

---

## 🎯 After Deployment

**Custom Domain (Optional):**
- Netlify: Site settings → Domain management
- Add your domain (e.g., stepcomp.app)

**Share Your Waitlist:**
- Twitter/X, Instagram, Facebook
- Reddit (r/fitness, r/apps)
- Product Hunt (when ready)

**Monitor Signups:**
- Supabase → Table Editor → waitlist
- Export to CSV for email campaigns

---

## 🆘 Quick Troubleshooting

**"Invalid API key"**
→ Check you copied anon key (not service key)

**"Relation waitlist does not exist"**
→ Run SETUP_WAITLIST_DATABASE.sql in Supabase

**"0 people waiting" not changing**
→ Grant execute: `GRANT EXECUTE ON FUNCTION get_waitlist_count() TO anon;`

**Form not submitting**
→ Open DevTools (F12) → Console for errors

---

## 💡 Pro Tip

**Auto-deploy on Git push:**
1. Connect Netlify to your GitHub repo
2. Every push = automatic deployment
3. No manual uploads needed!

---

## 🎉 You're Ready!

Total time: **~10 minutes**
Result: **Live waitlist collecting emails! 🚀**

**Need detailed help?** Check `NETLIFY_DEPLOYMENT_GUIDE.md`

