# Fix Xcode Combine Import Errors

## Problem
Xcode is showing false errors about missing Combine imports, even though:
- ✅ All files have `import Combine`
- ✅ Terminal build succeeds (`xcodebuild` works fine)
- ✅ This is an **Xcode indexing issue**, not a code problem

## Solution Steps

### Method 1: Clean Build Folder (Quick Fix)
1. In Xcode: **Product → Clean Build Folder** (⇧⌘K)
2. Wait for indexing to complete (watch the progress bar)
3. Build again: **Product → Build** (⌘B)

### Method 2: Clean DerivedData (More Thorough)
1. **Quit Xcode completely**
2. Run this command in Terminal:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/StepComp-*
   ```
3. **Restart Xcode**
4. Open your project
5. Wait for indexing to complete
6. Build: **Product → Build** (⌘B)

### Method 3: Reset Xcode Index (Nuclear Option)
If Methods 1 & 2 don't work:

1. **Quit Xcode**
2. Delete DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   ```
3. **Restart Xcode**
4. Open project
5. **Product → Clean Build Folder** (⇧⌘K)
6. Build: **Product → Build** (⌘B)

### Method 4: Verify Imports Are Correct
All these files should have `import Combine` at the top:

- ✅ `StepComp/Services/AuthService.swift` - Line 9
- ✅ `StepComp/Services/ChallengeService.swift` - Line 9  
- ✅ `StepComp/ViewModels/GroupViewModel.swift` - Line 10
- ✅ `StepComp/ViewModels/JoinChallengeViewModel.swift` - Line 10
- ✅ `StepComp/ViewModels/LeaderboardViewModel.swift` - Line 10
- ✅ `StepComp/ViewModels/ProfileViewModel.swift` - Line 10
- ✅ `StepComp/ViewModels/SessionViewModel.swift` - Line 9

**They all have the correct imports** - verified via terminal grep.

## Why This Happens

Xcode's SourceKit (the indexing engine) sometimes gets confused about module imports, especially when:
- Files are edited frequently
- Project structure changes
- Xcode is running for a long time
- DerivedData gets corrupted

## Verification

To verify the code is actually correct, run:
```bash
cd /Users/jefferyerhunse/GitRepos/StepComp
xcodebuild -project StepComp.xcodeproj -scheme StepComp -sdk iphonesimulator build
```

If this succeeds (which it does), your code is correct and it's just an Xcode UI issue.

## If Errors Persist

If cleaning doesn't help:
1. Check Xcode version (update if needed)
2. Try opening the project in a new Xcode window
3. Check if there are any `.swiftpm` or build artifacts that need cleaning
4. Restart your Mac (sometimes helps reset Xcode's state)

