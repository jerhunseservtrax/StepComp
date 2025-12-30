# How to Generate Apple Client Secret for Supabase

## Quick Reference

Supabase needs a **Client Secret** (JWT token) for Apple Sign In OAuth, not the raw private key file.

## What You Need

1. **Team ID** - From Apple Developer Portal → Membership
2. **Key ID** - From the Sign in with Apple key you created
3. **Services ID** (optional) - If using web OAuth, or use your bundle ID
4. **Private Key** - The .p8 file you downloaded

## Method 1: Using Node.js Script (Recommended)

1. Install dependencies:
```bash
npm install jsonwebtoken
```

2. Create a file `generate-secret.js`:
```javascript
const jwt = require('jsonwebtoken');
const fs = require('fs');

// Replace these with your values
const teamId = 'YOUR_TEAM_ID'; // e.g., 'ABC123DEF4'
const keyId = 'YOUR_KEY_ID'; // e.g., 'XYZ987ABC6'
const clientId = 'JE.StepComp'; // Your bundle ID or Services ID
const privateKeyPath = './AuthKey_XYZ987ABC6.p8'; // Path to your .p8 file

// Read the private key
const privateKey = fs.readFileSync(privateKeyPath);

// Generate the JWT token (client secret)
const token = jwt.sign(
  {
    iss: teamId,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 86400 * 180, // Valid for 6 months
    aud: 'https://appleid.apple.com',
    sub: clientId
  },
  privateKey,
  {
    algorithm: 'ES256',
    keyid: keyId
  }
);

console.log('Client Secret (JWT):');
console.log(token);
console.log('\n⚠️  This secret expires in 6 months. Save it securely!');
```

3. Run the script:
```bash
node generate-secret.js
```

4. Copy the output JWT token to Supabase's "Secret Key" field

## Method 2: Using Python

1. Install PyJWT:
```bash
pip install PyJWT cryptography
```

2. Create a file `generate_secret.py`:
```python
import jwt
import time
from datetime import datetime, timedelta

# Replace these with your values
TEAM_ID = 'YOUR_TEAM_ID'
KEY_ID = 'YOUR_KEY_ID'
CLIENT_ID = 'JE.StepComp'  # Your bundle ID
PRIVATE_KEY_PATH = './AuthKey_XYZ987ABC6.p8'

# Read the private key
with open(PRIVATE_KEY_PATH, 'r') as f:
    private_key = f.read()

# Generate the JWT token
now = int(time.time())
token = jwt.encode(
    {
        'iss': TEAM_ID,
        'iat': now,
        'exp': now + (180 * 24 * 60 * 60),  # 6 months
        'aud': 'https://appleid.apple.com',
        'sub': CLIENT_ID
    },
    private_key,
    algorithm='ES256',
    headers={'kid': KEY_ID}
)

print('Client Secret (JWT):')
print(token)
print('\n⚠️  This secret expires in 6 months. Save it securely!')
```

3. Run the script:
```bash
python generate_secret.py
```

## Method 3: Online JWT Generator

⚠️ **Security Warning**: Only use trusted tools and don't share your private key

1. Go to a JWT generator that supports ES256 (e.g., jwt.io with proper setup)
2. Use these settings:
   - **Algorithm**: ES256
   - **Header**: `{"alg":"ES256","kid":"YOUR_KEY_ID"}`
   - **Payload**: 
     ```json
     {
       "iss": "YOUR_TEAM_ID",
       "iat": CURRENT_TIMESTAMP,
       "exp": CURRENT_TIMESTAMP + 15552000,
       "aud": "https://appleid.apple.com",
       "sub": "JE.StepComp"
     }
     ```
   - **Private Key**: Contents of your .p8 file

## For Native iOS Apps

For native iOS apps using Sign in with Apple, you can use your **bundle ID** as the Client ID:
- **Client IDs in Supabase**: `JE.StepComp`
- **Client Secret**: Still needed (generated JWT token)

## Important Notes

1. **Expiration**: Client secrets expire every 6 months
2. **Regeneration**: You'll need to regenerate and update in Supabase before expiration
3. **Security**: Keep your private key (.p8 file) secure and never commit it to git
4. **Multiple Apps**: You can use the same key for multiple apps, just change the `sub` (client ID) in the JWT

## Quick Test

After generating and adding the secret to Supabase:
1. Try signing in with Apple in your app
2. Check Xcode console for success messages
3. Verify user appears in Supabase → Authentication → Users

