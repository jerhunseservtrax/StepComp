# Adding Supabase Swift Package to Xcode Project

## ⚠️ Important Note

Your project is an **Xcode project** (`.xcodeproj`), not a Swift Package Manager project. You **cannot** use `Package.swift` directly. Instead, you must add the package through Xcode's GUI.

---

## ✅ Correct Method: Add via Xcode GUI

### Step-by-Step Instructions

1. **Open Your Project**
   - Open `StepComp.xcodeproj` in Xcode

2. **Add Package Dependency**
   - In Xcode menu: **File → Add Package Dependencies...**
   - Or use shortcut: **⌘ + Shift + Control + P**

3. **Enter Package URL**
   - In the search field, paste:
   ```
   https://github.com/supabase-community/supabase-swift.git
   ```
   - **Note**: Use `supabase-community` URL for Xcode projects (as per official docs)
   - Click **Add Package**

4. **Select Version**
   - Choose **Up to Next Major Version**
   - Set version to **2.0.0** or later
   - Click **Add Package**

5. **Add to Target**
   - In the "Add Package Products" dialog:
     - ✅ Check **StepComp** target
     - ✅ Select **Supabase** product (the main package)
     - Click **Add Package**

6. **Verify Installation**
   - In Project Navigator, you should see:
     - **Package Dependencies** section
     - **supabase-swift** listed
   - Build the project (**⌘ + B**) to verify

---

## 📦 What Gets Added

When you add the Supabase package, Xcode will:

1. **Download the package** from GitHub
2. **Resolve dependencies** automatically
3. **Link to your target** (StepComp)
4. **Make it available** in your code via `import Supabase`

---

## 🔍 Verify It's Working

After adding the package, check:

1. **Project Navigator**
   - Look for **Package Dependencies** section
   - You should see `supabase-swift`

2. **Build Settings**
   - Select **StepComp** target
   - Go to **General** tab
   - Scroll to **Frameworks, Libraries, and Embedded Content**
   - You should see **Supabase** listed

3. **Code Compilation**
   - Open `StepComp/Services/SupabaseClient.swift`
   - The `#if canImport(Supabase)` block should now compile
   - No errors about missing module

4. **Test Connection**
   - Run the app
   - Go to **Settings → Developer Tools**
   - Tap **"Test Supabase Connection"**
   - Should show "Supabase client initialized" ✅

---

## ❌ Why Package.swift Won't Work

If you tried to create a `Package.swift` file:

- ❌ Xcode projects don't use `Package.swift`
- ❌ That file is for Swift Package Manager projects only
- ❌ Your project structure is `.xcodeproj`, not a Package
- ✅ You must use Xcode's GUI method instead

---

## 🛠️ Alternative: Convert to Swift Package (Not Recommended)

If you really want to use `Package.swift`, you would need to:

1. Convert your Xcode project to a Swift Package
2. Restructure your entire project
3. Lose Xcode project features (storyboards, etc.)

**This is NOT recommended** - just use Xcode's GUI method!

---

## 📋 Quick Checklist

- [ ] Opened Xcode project
- [ ] File → Add Package Dependencies...
- [ ] Entered: `https://github.com/supabase/supabase-swift.git`
- [ ] Selected version 2.0.0+
- [ ] Added to StepComp target
- [ ] Selected Supabase product
- [ ] Built project successfully (⌘ + B)
- [ ] Verified in Package Dependencies
- [ ] Tested connection in app

---

## 🐛 Troubleshooting

### "Unable to find module dependency"

**Solution:**
1. Product → Clean Build Folder (⇧⌘K)
2. File → Packages → Reset Package Caches
3. File → Packages → Resolve Package Versions
4. Product → Build (⌘B)

### Package Not Showing in Project

**Solution:**
1. Check Project Navigator → Package Dependencies
2. If missing, re-add via File → Add Package Dependencies...
3. Make sure StepComp target is selected

### Build Errors After Adding

**Solution:**
1. Verify target is selected correctly
2. Check that Supabase product is added
3. Clean build folder and rebuild

---

## 📚 Next Steps After Adding Package

1. ✅ **Package added** (you're here)
2. ⏭️ **Create database tables** (run `SUPABASE_DATABASE_SETUP.sql`)
3. ⏭️ **Enable Supabase** (`useSupabase = true` in AuthService.swift)
4. ⏭️ **Test connection** (Settings → Developer Tools)

---

## 💡 Pro Tip

After adding the package, you can verify it's working by:

```swift
// In any Swift file, try:
import Supabase

// If this compiles without errors, the package is added correctly!
```

---

## 📖 Reference

- **Supabase Swift SDK**: https://github.com/supabase/supabase-swift
- **Xcode Package Docs**: https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app

