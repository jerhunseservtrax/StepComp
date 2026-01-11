# How to Add Supabase Swift Package to Xcode

## Step-by-Step Instructions

### Step 1: Open Your Project in Xcode

1. Open `StepComp.xcodeproj` in Xcode

### Step 2: Add Package Dependency

1. In Xcode, go to **File → Add Package Dependencies...**
   - Or use shortcut: **⌘ + Shift + Control + P**

2. In the search field, enter:
   ```
   https://github.com/supabase-community/supabase-swift.git
   ```
   - **Important**: Use `supabase-community` URL for Xcode projects (per official Supabase docs)

3. Click **Add Package**

4. Select **Up to Next Major Version** with version **2.0.0** or later

5. Click **Add Package**

### Step 3: Add to Target

1. In the "Add Package Products" dialog:
   - Make sure **StepComp** target is selected
   - Check the box next to **Supabase** (the main package)
   - Click **Add Package**

### Step 4: Verify Installation

1. In Xcode's Project Navigator, you should see:
   - **Package Dependencies** section
   - **supabase-swift** listed

2. Build your project (**⌘ + B**)
   - Should build successfully without errors

### Step 5: Verify in Code

The code should now compile with Supabase. Check:

1. Open `StepComp/Services/SupabaseClient.swift`
2. The `#if canImport(Supabase)` block should now be active
3. The `supabase` client should be initialized

## Troubleshooting

### Package Not Found

If you see "Unable to find module dependency: 'Supabase'":

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Reset Package Caches**: File → Packages → Reset Package Caches
3. **Rebuild**: Product → Build (⌘B)

### Build Errors

If you see build errors after adding the package:

1. Make sure you selected the correct target (StepComp)
2. Check that the package version is compatible (2.0.0+)
3. Try removing and re-adding the package

### Verify Package is Added

To verify the package is correctly added:

1. Select your project in Project Navigator
2. Select the **StepComp** target
3. Go to **General** tab
4. Scroll to **Frameworks, Libraries, and Embedded Content**
5. You should see **Supabase** listed

## Alternative: Manual Package.swift

If you prefer using Swift Package Manager directly, you can also add it to a `Package.swift` file, but for Xcode projects, the GUI method above is recommended.

## Next Steps

After adding the package:

1. ✅ Run the Supabase connection test (Settings → Developer Tools)
2. ✅ Create database tables (run `SUPABASE_DATABASE_SETUP.sql`)
3. ✅ Set `useSupabase = true` in `AuthService.swift`
4. ✅ Test authentication flow

## Package Information

- **Repository**: https://github.com/supabase/supabase-swift
- **Documentation**: https://github.com/supabase/supabase-swift
- **Version**: 2.0.0+ (recommended)

