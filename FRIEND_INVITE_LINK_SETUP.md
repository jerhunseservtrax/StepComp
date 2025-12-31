# 🔗 Friend Invite Link Setup Guide

## Overview

Friend invite links allow users to share a link that:
1. **Opens the app** if installed (deep link)
2. **Redirects to App Store** if app not installed (universal link fallback)

---

## 🎯 How It Works

### User Flow:
```
User clicks "Share Invite Link"
         ↓
App generates token via RPC (create_friend_invite)
         ↓
Creates deep link: je.stepcomp://friend-invite?token=ABC123
         ↓
User shares link via Messages, Email, etc.
         ↓
Recipient clicks link
         ↓
    ┌─────────────┴─────────────┐
    │                           │
App Installed              App NOT Installed
    │                           │
    ↓                           ↓
Opens app                 Opens App Store
InviteAcceptView          (or web page with download link)
    ↓
Consumes token via RPC
    ↓
Friend request created
```

---

## ✅ Current Implementation Status

### ✅ Already Implemented:
1. **Database Schema** - `friend_invites` table exists
2. **RPC Functions** - `create_friend_invite()` and `consume_friend_invite()`
3. **Deep Link Routing** - `DeepLinkRouter` handles `je.stepcomp://friend-invite?token=...`
4. **UI Components** - `InviteAcceptView` displays invite
5. **Service Layer** - `FriendsService` has `createInviteRPC()` and `consumeInviteRPC()`
6. **ViewModel** - `FriendsViewModel` has `createInviteLink()` method
7. **Share Sheet** - Native iOS share functionality in `FriendsView`

### ⚠️ Needs Configuration:
1. **Universal Links** - For App Store fallback
2. **Associated Domains** - Xcode entitlement
3. **Apple App Site Association** - Server-side JSON file

---

## 🔧 Setup Instructions

### Step 1: Configure URL Scheme (Already Done ✅)

**File:** `Info.plist`

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>je.stepcomp</string>
        </array>
        <key>CFBundleURLName</key>
        <string>je.stepcomp</string>
    </dict>
</array>
```

**Test:**
```bash
# Open this URL on device/simulator
xcrun simctl openurl booted "je.stepcomp://friend-invite?token=test123"
```

---

### Step 2: Add Universal Links (For App Store Fallback)

#### 2.1 Add Associated Domains Entitlement

**In Xcode:**
1. Select your target → **Signing & Capabilities**
2. Click **+ Capability**
3. Add **Associated Domains**
4. Add domain: `applinks:stepcomp.app` (replace with your domain)

**Or manually in** `StepComp.entitlements`:
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:stepcomp.app</string>
    <string>applinks:www.stepcomp.app</string>
</array>
```

#### 2.2 Create Apple App Site Association File

**Host this file at:** `https://stepcomp.app/.well-known/apple-app-site-association`

**File content:**
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.je.stepcomp",
        "paths": [
          "/friend-invite/*",
          "/invite/*"
        ]
      }
    ]
  }
}
```

**Replace:**
- `TEAM_ID` - Your Apple Developer Team ID (found in Xcode → Signing & Capabilities)
- `je.stepcomp` - Your app's bundle identifier

**Requirements:**
- Must be served over **HTTPS**
- Must be at **root** of domain: `/.well-known/apple-app-site-association`
- **No** `.json` extension
- Content-Type: `application/json`
- Must be accessible **without** authentication

#### 2.3 Update Deep Link Router

**File:** `StepComp/Utilities/DeepLinkRouter.swift`

```swift
func handle(url: URL) {
    // Handle both custom scheme and universal links
    let scheme = url.scheme ?? ""
    let host = url.host ?? ""
    
    // Custom scheme: je.stepcomp://friend-invite?token=ABC
    if scheme == "je.stepcomp" && host == "friend-invite" {
        if let token = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "token" })?.value {
            pendingInviteToken = token
        }
    }
    
    // Universal link: https://stepcomp.app/friend-invite/ABC123
    if scheme == "https" && (host == "stepcomp.app" || host == "www.stepcomp.app") {
        let pathComponents = url.pathComponents
        if pathComponents.count >= 3 && pathComponents[1] == "friend-invite" {
            let token = pathComponents[2]
            pendingInviteToken = token
        }
    }
}
```

---

### Step 3: Create Web Fallback Page (Optional but Recommended)

**Host at:** `https://stepcomp.app/friend-invite/[TOKEN]`

**Example:** `invite.html`
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>StepComp Friend Invite</title>
    <script>
        // Try to open app first
        const token = window.location.pathname.split('/').pop();
        const appUrl = `je.stepcomp://friend-invite?token=${token}`;
        
        // Attempt to open app
        window.location = appUrl;
        
        // If app doesn't open, redirect to App Store after 2 seconds
        setTimeout(() => {
            window.location = 'https://apps.apple.com/app/stepcomp/YOUR_APP_ID';
        }, 2000);
    </script>
</head>
<body>
    <h1>Opening StepComp...</h1>
    <p>If the app doesn't open, <a href="https://apps.apple.com/app/stepcomp/YOUR_APP_ID">download it here</a>.</p>
</body>
</html>
```

---

### Step 4: Update Share Link Generation

**File:** `StepComp/ViewModels/FriendsViewModel.swift` (Already Updated ✅)

```swift
func createInviteLink() async -> URL? {
    do {
        let result = try await service.createInviteRPC(expiresInHours: 168)
        
        // Option 1: Custom scheme (works if app installed)
        let customScheme = "je.stepcomp://friend-invite?token=\(result.token)"
        
        // Option 2: Universal link (fallback to web/App Store)
        // let universalLink = "https://stepcomp.app/friend-invite/\(result.token)"
        
        return URL(string: customScheme)
    } catch {
        errorMessage = "Failed to create invite link"
        return nil
    }
}
```

**For production, use universal link:**
```swift
let universalLink = "https://stepcomp.app/friend-invite/\(result.token)"
return URL(string: universalLink)
```

---

## 🧪 Testing

### Test 1: Custom Scheme (App Installed)
```bash
# On simulator
xcrun simctl openurl booted "je.stepcomp://friend-invite?token=test123"

# On device via Safari
# Navigate to: je.stepcomp://friend-invite?token=test123
```

**Expected:** App opens, shows `InviteAcceptView`

### Test 2: Universal Link (App Installed)
```bash
# On simulator
xcrun simctl openurl booted "https://stepcomp.app/friend-invite/test123"
```

**Expected:** App opens (if associated domains configured)

### Test 3: Universal Link (App NOT Installed)
1. Delete app from device
2. Open link in Safari: `https://stepcomp.app/friend-invite/test123`

**Expected:** Redirects to App Store or web page

### Test 4: Share Sheet
1. Open Friends tab
2. Tap "Invite Link" section
3. Tap "Share Invite"
4. Share via Messages
5. Recipient taps link

**Expected:** Opens app or App Store

---

## 📊 Database Flow

### Create Invite:
```sql
-- RPC: create_friend_invite(expires_in_hours => 168)
INSERT INTO friend_invites (inviter_id, token, expires_at)
VALUES (auth.uid(), 'ABC123...', NOW() + INTERVAL '168 hours')
RETURNING token, expires_at;
```

### Consume Invite:
```sql
-- RPC: consume_friend_invite(invite_token => 'ABC123...')
-- 1. Validate token
SELECT * FROM friend_invites WHERE token = 'ABC123...';

-- 2. Create friendship
INSERT INTO friendships (requester_id, addressee_id, status)
VALUES (inviter_id, auth.uid(), 'pending');

-- 3. Mark invite as used
UPDATE friend_invites SET used_at = NOW() WHERE token = 'ABC123...';

-- 4. Return inviter info
RETURNING friendship_id, inviter_id, inviter_username, ...;
```

---

## 🔒 Security

### Token Properties:
- ✅ **Random** - 16 bytes, base64url encoded
- ✅ **Unique** - Database constraint
- ✅ **Expirable** - Default 7 days (168 hours)
- ✅ **Single-use** - Marked as `used_at` after consumption
- ✅ **User-scoped** - RLS policies enforce `auth.uid()`

### Validation:
```sql
-- Token must exist
-- Token must not be expired
-- Token must not be used
-- Cannot invite yourself
```

---

## 🎨 UI Components

### 1. Share Button (Friends Tab)
**File:** `StepComp/Screens/Friends/FriendsView.swift`

```swift
Section {
    PrivateDiscoveryCard(onShareInvite: {
        Task {
            if let url = await vm.createInviteLink() {
                share(url: url)
            }
        }
    })
} header: {
    Text("Invite Link")
}
```

### 2. Invite Accept Screen
**File:** `StepComp/Screens/Friends/InviteAcceptView.swift`

Shows:
- Inviter's avatar
- Inviter's name
- "Friend request sent" confirmation
- Error handling for invalid/expired tokens

---

## 🚀 Deployment Checklist

- [ ] Configure Associated Domains in Xcode
- [ ] Upload `apple-app-site-association` file to server
- [ ] Verify file is accessible via HTTPS
- [ ] Test custom scheme on device
- [ ] Test universal link on device
- [ ] Test App Store fallback (delete app first)
- [ ] Update share link to use universal link (not custom scheme)
- [ ] Test with real users
- [ ] Monitor invite usage in database

---

## 📱 User Experience

### Sending Invite:
1. Open Friends tab
2. Scroll to "Invite Link" section
3. Tap "Share Invite"
4. Choose share method (Messages, Email, etc.)
5. Send to friend

### Receiving Invite:
1. Tap link in message
2. **If app installed:** Opens app → Friend request sent
3. **If app NOT installed:** Opens App Store → Download app → Open link again

---

## 🐛 Troubleshooting

### Link doesn't open app:
- Verify URL scheme in `Info.plist`
- Check `DeepLinkRouter` is handling URL
- Test with `xcrun simctl openurl`

### Universal link opens Safari instead of app:
- Verify Associated Domains entitlement
- Check `apple-app-site-association` file is accessible
- Ensure Team ID and Bundle ID match
- Try deleting and reinstalling app

### "Invalid invite token" error:
- Token may be expired (check `expires_at`)
- Token may be already used (check `used_at`)
- Token may not exist in database

---

## ✅ Summary

**Current Status:** ✅ Fully functional with custom scheme
**Next Step:** Configure universal links for App Store fallback
**Priority:** Medium (custom scheme works for testing, universal links needed for production)

**What works now:**
- ✅ Generate invite link
- ✅ Share via native share sheet
- ✅ Open app with link (if installed)
- ✅ Accept friend request
- ✅ Token validation & expiration

**What needs setup:**
- ⚠️ Universal links (for App Store fallback)
- ⚠️ Web hosting for fallback page
- ⚠️ App Store listing (for final redirect)

