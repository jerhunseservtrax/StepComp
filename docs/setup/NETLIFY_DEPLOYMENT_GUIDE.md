# 🚀 Deploy StepComp Waitlist to Netlify

## 📋 Prerequisites

Before deploying, you need:
- ✅ Supabase project URL and anon key
- ✅ GitHub account (for connecting to Netlify)
- ✅ Netlify account (free tier works great!)

---

## 🔧 Step 1: Configure Supabase Credentials

### Get Your Supabase Credentials:

1. **Go to your Supabase project** (https://app.supabase.com)
2. **Click on "Settings"** (gear icon in sidebar)
3. **Go to "API"** section
4. **Copy these two values**:
   - **Project URL** (e.g., `https://abcdefgh.supabase.co`)
   - **anon/public key** (long string starting with `eyJ...`)

### Update waitlist.html:

Open `waitlist.html` and find lines 179-180:

```javascript
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
```

**Replace with your actual values**:

```javascript
const SUPABASE_URL = 'https://YOUR-PROJECT-ID.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'; // Your actual key
```

---

## 🗄️ Step 2: Set Up Supabase Database

Run this SQL in your Supabase SQL Editor:

```sql
-- Create waitlist table
CREATE TABLE IF NOT EXISTS public.waitlist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    referral_source TEXT,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;

-- Allow public to insert (join waitlist)
CREATE POLICY "Anyone can join waitlist"
ON public.waitlist
FOR INSERT
TO public
WITH CHECK (true);

-- Create function to get waitlist count
CREATE OR REPLACE FUNCTION get_waitlist_count()
RETURNS INTEGER
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT COUNT(*)::INTEGER FROM public.waitlist;
$$;

-- Grant execute permission to anon users
GRANT EXECUTE ON FUNCTION get_waitlist_count() TO anon;
```

---

## 🌐 Step 3: Deploy to Netlify

### Method 1: Deploy via Netlify UI (Easiest)

1. **Go to** https://app.netlify.com
2. **Click "Add new site" → "Import an existing project"**
3. **Connect to GitHub** and select your `StepComp` repository
4. **Configure build settings**:
   - **Base directory**: Leave empty (or root `/`)
   - **Build command**: Leave empty (static HTML)
   - **Publish directory**: `.` (current directory)
5. **Click "Deploy site"**

Netlify will automatically detect the `netlify.toml` file and use those settings!

### Method 2: Deploy via Drag & Drop (Fastest)

1. **Go to** https://app.netlify.com
2. **Click "Add new site" → "Deploy manually"**
3. **Drag and drop** these files into the drop zone:
   - `waitlist.html`
   - `netlify.toml`
4. **Done!** Your site will be live in seconds.

### Method 3: Deploy via Netlify CLI

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Login to Netlify
netlify login

# Deploy from StepComp directory
cd /Users/jefferyerhunse/GitRepos/StepComp
netlify deploy --prod

# When prompted:
# - Create a new site? Yes
# - Publish directory: . (current directory)
```

---

## 🎨 Step 4: Configure Custom Domain (Optional)

### Option A: Use Netlify Subdomain (Free)

1. Go to **Site settings → Domain management**
2. Click **"Options" → "Edit site name"**
3. Change to: `stepcomp` or `stepcomp-waitlist`
4. Your URL will be: `https://stepcomp.netlify.app`

### Option B: Use Custom Domain

1. Buy domain (e.g., `stepcomp.app` from Namecheap, GoDaddy, etc.)
2. In Netlify: **Domain settings → Add custom domain**
3. Follow Netlify's DNS configuration instructions
4. Wait for DNS propagation (5-30 minutes)

---

## ✅ Step 5: Test Your Deployment

1. **Visit your Netlify URL**
2. **Enter an email** in the form
3. **Click "Get Early Access"**
4. **Check Supabase** → Go to "Table Editor" → `waitlist` table
5. **Confirm** the email was added! 🎉

### Test Checklist:
- [ ] Page loads correctly
- [ ] "X people waiting" count displays
- [ ] Form submits successfully
- [ ] Success message appears
- [ ] Email appears in Supabase `waitlist` table
- [ ] Duplicate email shows "already on waitlist" message
- [ ] Mobile responsive design works

---

## 🔐 Security Best Practices

### Supabase RLS (Row Level Security):
✅ **Already configured** in the SQL above
- Public can only INSERT (join waitlist)
- No one can read/update/delete entries (admin only via Supabase dashboard)

### Environment Variables (Advanced):
If you want to hide Supabase credentials from the HTML file:

1. **In Netlify**: Site settings → Environment variables
2. **Add variables**:
   - `SUPABASE_URL` = your project URL
   - `SUPABASE_ANON_KEY` = your anon key
3. **Create `index.html`** (instead of hardcoding in waitlist.html):

```javascript
// Replace lines 179-180 with:
const SUPABASE_URL = '[[SUPABASE_URL]]';
const SUPABASE_ANON_KEY = '[[SUPABASE_ANON_KEY]]';
```

4. **Add to `netlify.toml`**:

```toml
[build.processing]
  skip_processing = false

[[plugins]]
  package = "@netlify/plugin-sitemap"
```

**Note**: For a simple waitlist, hardcoding the **anon key** is fine—it's meant to be public and RLS protects your data.

---

## 📊 Step 6: Monitor Your Waitlist

### View Signups in Supabase:

1. Go to **Supabase → Table Editor**
2. Select **`waitlist`** table
3. See all emails, signup times, and referral sources

### Export to CSV:

1. In Supabase Table Editor
2. Click **"Export"** → "CSV"
3. Use for email campaigns (Mailchimp, ConvertKit, etc.)

### Get Real-Time Count:

Run this in Supabase SQL Editor:

```sql
SELECT get_waitlist_count();
```

---

## 🎯 Next Steps After Deployment

### 1. Share Your Waitlist:
- 📱 Twitter/X: "Join the waitlist for StepComp - step tracking meets competition! https://stepcomp.netlify.app"
- 📘 Facebook, Instagram, LinkedIn
- 💬 Discord, Reddit communities (r/fitness, r/apps)
- 🎥 TikTok/YouTube Shorts

### 2. Set Up Analytics (Optional):

**Add Google Analytics** to `waitlist.html` (before `</head>`):

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

**Or use Netlify Analytics** (paid but privacy-friendly):
- Site settings → Analytics → Enable

### 3. Email Automation (Future):

When ready to launch, use:
- **Mailchimp** - Free for <500 contacts
- **ConvertKit** - Great for creators
- **Resend** - Developer-friendly API
- **Supabase Edge Functions** - Custom emails

---

## 🚨 Troubleshooting

### "Supabase error: Invalid API key"
- ✅ Check you copied the **anon key** (not service key)
- ✅ Check for typos in `waitlist.html`
- ✅ Make sure there are no extra spaces

### "Supabase error: relation 'waitlist' does not exist"
- ✅ Run the SQL in Step 2 in your Supabase SQL Editor
- ✅ Check you're in the correct Supabase project

### "0 people waiting" not updating
- ✅ Check `get_waitlist_count()` function exists
- ✅ Run SQL grant command: `GRANT EXECUTE ON FUNCTION get_waitlist_count() TO anon;`
- ✅ Refresh the page

### Duplicate email not showing "already on waitlist"
- ✅ Check the `UNIQUE` constraint on email column
- ✅ Try adding email again via Supabase directly to test

### Form not submitting
- ✅ Open browser DevTools (F12) → Console
- ✅ Look for JavaScript errors
- ✅ Check Network tab for failed requests

---

## 📁 Project Structure

```
StepComp/
├── waitlist.html       # Your waitlist page
├── netlify.toml        # Netlify configuration (created)
└── README.md           # This file
```

---

## 🎉 Success!

Your waitlist is now live! 🚀

**Your Netlify URL**: `https://your-site-name.netlify.app`

### Share Your Success:
1. ✅ Waitlist deployed
2. ✅ Supabase connected
3. ✅ Emails collecting
4. ✅ Ready to promote!

**Next**: Start driving traffic and building your community! 💪

---

## 💡 Pro Tips

1. **Auto-deploy on push**: Netlify automatically redeploys when you push to GitHub
2. **Preview deployments**: Every pull request gets a unique preview URL
3. **Rollback**: Easily rollback to previous deployments in Netlify dashboard
4. **Custom 404**: Add `404.html` to handle not-found pages
5. **Forms (alternative)**: Use Netlify Forms instead of Supabase (easier but less flexible)

---

## 📞 Need Help?

- **Netlify Docs**: https://docs.netlify.com
- **Supabase Docs**: https://supabase.com/docs
- **Netlify Support**: support@netlify.com
- **Supabase Discord**: https://discord.supabase.com

---

**Happy launching! 🚀 Let's get those signups!** 📈

