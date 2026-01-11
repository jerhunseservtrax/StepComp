# Correct Supabase Swift Installation for Xcode

## ✅ Official Installation Method

According to the [official Supabase Swift documentation](https://supabase.com/docs/reference/swift/introduction), for **Xcode projects**, you should use:

### Package URL for Xcode:
```
https://github.com/supabase-community/supabase-swift.git
```

**Note**: This is different from Swift Package Manager projects which use:
```
https://github.com/supabase/supabase-swift.git
```

---

## 📋 Step-by-Step Installation

### 1. Open Your Xcode Project
- Open `StepComp.xcodeproj` in Xcode

### 2. Add Package Dependency
- **File → Add Package Dependencies...**
- Or shortcut: **⌘ + Shift + Control + P**

### 3. Enter the Correct URL
- Paste: `https://github.com/supabase-community/supabase-swift.git`
- Click **Add Package**

### 4. Select Version
- Choose **Up to Next Major Version**
- Set to **2.0.0** or later
- Click **Add Package**

### 5. Add to Target
- Select **StepComp** target
- Check **Supabase** product
- Click **Add Package**

---

## 🔍 Why Two Different URLs?

### For Swift Package Manager Projects:
- URL: `https://github.com/supabase/supabase-swift.git`
- Used in `Package.swift` files
- For pure Swift Package projects

### For Xcode Projects:
- URL: `https://github.com/supabase-community/supabase-swift.git`
- Used via Xcode GUI
- For `.xcodeproj` projects (like yours)

---

## ✅ Verify Installation

After adding the package:

1. **Check Project Navigator**
   - Look for **Package Dependencies**
   - Should see `supabase-swift`

2. **Build Project**
   - Press **⌘ + B**
   - Should build successfully

3. **Test Import**
   ```swift
   import Supabase
   // Should compile without errors
   ```

4. **Check Your SupabaseClient.swift**
   - The `#if canImport(Supabase)` block should now be active
   - `supabase` client should initialize

---

## 🎯 Your Current Configuration

Your `SupabaseClient.swift` is already set up correctly:

```swift
let supabase: SupabaseClient = {
    guard let url = URL(string: SupabaseConfig.supabaseURL) else {
        fatalError("Invalid Supabase URL")
    }
    
    return SupabaseClient(
        supabaseURL: url,
        supabaseKey: SupabaseConfig.supabaseAnonKey
    )
}()
```

This matches the official initialization pattern:
```swift
let client = SupabaseClient(
    supabaseURL: URL(string: "https://xyzcompany.supabase.co")!,
    supabaseKey: "public-anon-key"
)
```

---

## 📚 Official Documentation Reference

- **Installation Guide**: https://supabase.com/docs/reference/swift/introduction
- **GitHub Repository**: https://github.com/supabase-community/supabase-swift
- **Swift Package**: https://github.com/supabase/supabase-swift (for SPM projects)

---

## ⚠️ Important Notes

1. **Use `supabase-community` URL** for Xcode projects
2. **Version 2.0.0+** is recommended
3. **Add to StepComp target** (not just the project)
4. **Select Supabase product** (not individual sub-packages unless needed)

---

## 🚀 Next Steps After Installation

1. ✅ **Package added** (using correct URL)
2. ⏭️ **Create database tables** (`SUPABASE_DATABASE_SETUP.sql`)
3. ⏭️ **Enable Supabase** (`useSupabase = true`)
4. ⏭️ **Test connection** (Settings → Developer Tools)

---

## 🐛 Troubleshooting

### If package doesn't resolve:
- Make sure you're using `supabase-community` URL
- Check internet connection
- Try: File → Packages → Reset Package Caches

### If build fails:
- Clean build folder: **⇧⌘K**
- Rebuild: **⌘B**
- Verify target is selected correctly

---

## 💡 Pro Tip

The Supabase Swift SDK supports:
- ✅ **Database** - Postgres queries
- ✅ **Auth** - User authentication
- ✅ **Realtime** - Live updates
- ✅ **Storage** - File uploads
- ✅ **Functions** - Edge functions

You can add individual packages if you don't need everything, but for StepComp, the full `Supabase` package is recommended.

