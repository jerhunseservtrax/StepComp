# FitComp Fix Tracker

> Log of all bugs encountered and fixes implemented to prevent recurrence.
> Last updated: 2026-03-22 (v2)

---

## Table of Contents

- [Critical Fixes](#critical-fixes)
- [Authentication & Session](#authentication--session)
- [Database & Supabase RLS](#database--supabase-rls)
- [UI/UX Bugs](#uiux-bugs)
- [Build & Compilation](#build--compilation)
- [Data Integrity](#data-integrity)
- [Challenges](#challenges)
- [Chat System](#chat-system)
- [Settings](#settings)
- [Notifications](#notifications)
- [SQL & Database Scripts](#sql--database-scripts)
- [Live Activities & Lifecycle](#live-activities--lifecycle)
- [Auth & Session Recovery](#auth--session-recovery)
- [Deep Linking](#deep-linking)

---

## Critical Fixes

### 1. Workout State Data Loss After Long Sessions
- **Commit:** `6b21b36`
- **Symptom:** Users lost in-progress workout data (sets/reps) after long sessions or app suspension. Widget continued tracking while app lost in-memory state.
- **Root Cause:** Workout state was only held in memory — any app lifecycle event (suspension, termination) wiped it.
- **Fix:** Added `ActiveWorkoutDraft` model with Codable persistence. Draft saved on every mutation, restored on launch/lifecycle transitions, cleared on finish/cancel/auth invalidation.
- **Files:** `WorkoutViewModel.swift`, `RootView.swift`, `AuthService.swift`
- **Prevention:** Any new in-progress state that users would lose work on must be persisted to disk, not just held in memory.

---

### 2. Number Pad Input Bug (Typing 5 Shows 4)
- **Commit:** `2f162e5`
- **Symptom:** During workout set entry, typing 5 showed 4, typing 1 showed 0.
- **Root Cause:** System keyboard with TextField caused a feedback loop. Unit conversions (lbs/kg) happened on every keystroke, and rounding errors accumulated.
- **Fix:** Built custom `WorkoutNumberPad` component (0-9, decimal, backspace, Done). Direct string manipulation with unit conversion only at commit time.
- **Files:** `ActiveWorkoutView.swift` + 30 other files
- **Prevention:** Never apply unit conversions on every keystroke. Convert only on commit/save.

---

### 3. Session Persistence Across Force Quit
- **Commit:** `d1f326b`
- **Symptom:** Users logged out on force quit; login page shown on reopen.
- **Root Cause:** Multiple `AuthService` instances (RootView, SessionViewModel, StepCompApp each created one). State was not shared. On nil `.initialSession`, `isAuthenticated` was set to false, clearing onboarding flag.
- **Fix:** Converted AuthService to singleton pattern (`AuthService.shared`). Session persists in Keychain with explicit accessibility setting.
- **Files:** `AuthService.swift`, `RootView.swift`, `StepCompApp.swift`, `ProfileSettingsView.swift`, `ProfileView.swift`
- **Prevention:** Services with auth state must be singletons. Never create multiple instances of state-holding services.

---

### 4. Critical Deadlock on Sign Out
- **Commit:** `94d60b0`
- **Symptom:** App froze completely on sign out, stuck in `pthread_kill`.
- **Root Cause:** `await MainActor.run` called from within a `@MainActor` context in `SessionViewModel.signOut()`. The main actor was waiting for itself — a circular wait.
- **Fix:** Removed `MainActor.run` wrapper (class was already `@MainActor`). Removed conflicting `dismiss()` from SettingsView.
- **Files:** `SessionViewModel.swift`, `SettingsView.swift`
- **Prevention:** Never use `await MainActor.run` inside code that's already on `@MainActor`. Check actor isolation before wrapping.

---

### 5. App Crash During Sign Out (Retain Cycle)
- **Commit:** `e2c8fb1`
- **Symptom:** "DashboardViewModel deallocated with non-zero retain count 2" — memory corruption and crash.
- **Root Cause:** `deinit` called `stopAutoRefresh()` which was `nonisolated` and created a `Task` capturing `self`, incrementing retain count during deallocation.
- **Fix:** Moved timer cleanup directly into deinit (synchronous, no Task creation). Applied same fix to ProfileViewModel.
- **Files:** `DashboardViewModel.swift`, `ProfileViewModel.swift`
- **Prevention:** Never create Tasks or capture `self` in `deinit`. Deinit cleanup must be synchronous.

---

### 6. App Crash on Sign-Out View Transition
- **Commit:** `096e282`
- **Symptom:** Crash during sign-out transition from MainTabView to OnboardingFlowView.
- **Root Cause:** `@StateObject` for SessionViewModel caused double ownership conflict during view transition.
- **Fix:** Changed to `@ObservedObject`. Wrapped state updates in `MainActor.run`. Added `.id()` modifier for clean view recreation.
- **Files:** `RootView.swift`, `MainTabView.swift`, `SessionViewModel.swift`
- **Prevention:** Use `@ObservedObject` for shared view models during view transitions. Use `.id()` to force clean recreation.

---

## Authentication & Session

### 7. Apple Sign In Profile Creation Failure
- **Commit:** `fda99a6`
- **Symptom:** Apple Sign In users couldn't create challenges due to incomplete profile.
- **Root Cause:** Missing `displayName`, `email`, `totalSteps`, `dailyStepGoal` fields. Username could collide with other users.
- **Fix:** Use full UUID for username. Populate all required fields. Verify profile exists before proceeding.
- **Files:** `AuthService.swift`, `CreateChallengeViewModel.swift`
- **Prevention:** All auth providers must create complete profiles with all required fields populated.

### 8. Missing Auth Session on Challenge Load
- **Commit:** `992b491`
- **Symptom:** "Auth session missing" error on app launch.
- **Root Cause:** ChallengeService tried to load challenges before authentication completed.
- **Fix:** Added session check; skip loading if not authenticated.
- **Files:** `ChallengeService.swift`, `ChallengesViewModel.swift`
- **Prevention:** All services that require auth must check session before making requests.

---

## Database & Supabase RLS

### 9. Infinite Recursion in RLS Policies
- **Commits:** `dbd6730`, `77a6696`, `39f8ee7`
- **Symptom:** Database queries hanging or failing with recursion errors.
- **Root Cause:** `challenges` SELECT policy referenced `challenge_members`, which referenced back to `challenges` — circular dependency.
- **Fix:** Created helper function to break circular reference. Replaced `EXISTS` with simple `IN` subquery.
- **Files:** SQL scripts, RLS policies
- **Prevention:** Never create RLS policies that reference tables with policies referencing back. Use helper functions or simple subqueries.

### 10. Waitlist 401 Unauthorized
- **Commits:** `b5a0cc9`, `a1a0e98`, `d41ca23`, `814e879`, `f7abe47`
- **Symptom:** Email submission to waitlist returned 401, then 42501 RLS violation.
- **Root Cause:** Multiple issues: `anon` role lacked INSERT grant; sequence permissions missing; RLS policy used `TO public` instead of `TO anon`; `.select()` after INSERT triggered SELECT policy.
- **Fix:** Grant INSERT to anon; grant sequence usage; recreate policy with `TO anon, authenticated`; remove `.select()` from insert.
- **Prevention:** For public-facing tables: grant to `anon` explicitly, test as unauthenticated user, avoid `.select()` after insert if SELECT policy is restrictive.

### 11. Profiles Table Schema Mismatch
- **Commit:** `dbd6730`
- **Symptom:** Compilation errors and query failures.
- **Root Cause:** `profiles` table used `user_id` instead of `id` as expected by the app.
- **Fix:** SQL migration to rename column. Fixed all references in code.
- **Prevention:** Establish schema conventions early. App model field names should match DB column names.

### 12. PostgreSQL inet Type Error
- **Commit:** `f85b681`
- **Symptom:** Step sync failed with type error.
- **Root Cause:** `p_ip` parameter set to string `'unknown'`, invalid for PostgreSQL `inet` type.
- **Fix:** Changed to `nil` (NULL).
- **Prevention:** Use proper types for PostgreSQL columns. When value is unknown, use NULL not placeholder strings.

---

## UI/UX Bugs

### 13. Height/Weight Off-by-One Error
- **Commit:** `e6fcb89`
- **Symptom:** User enters 5'11", saves, reload shows 5'10". User enters 170 lbs, shows 169 lbs.
- **Root Cause:** Truncation (`Int()`) instead of rounding in unit conversions. `Int(71 * 2.54) = 180`, then `180 / 2.54 = 70.866` → `Int(70.866 % 12) = 10`.
- **Fix:** Added `.rounded()` to all 4 conversion functions (cmToImperial, imperialToCm, kgToLbs, lbsToKg).
- **Files:** `ProfileSettingsView.swift`
- **Prevention:** Always use `.rounded()` before truncating to Int in unit conversions.

### 14. Tab Bar Selector Wrong Color
- **Commit:** `85fa20b`
- **Symptom:** Tab bar selector was yellow in dark mode (should be coral).
- **Root Cause:** `.tint(StepCompColors.primary)` modifier overriding `UITabBarAppearance`.
- **Fix:** Removed redundant `.tint()` modifier.
- **Files:** `MainTabView.swift`
- **Prevention:** Don't mix SwiftUI `.tint()` with UIKit appearance API for tab bars.

### 15. Goal Celebration Triggered on Manual Tap
- **Commit:** `b1da929`
- **Symptom:** Goal celebration fired when user tapped the card, not just on actual goal achievement.
- **Root Cause:** Manual trigger attached to card tap gesture.
- **Fix:** Removed manual trigger. Celebration only fires automatically when goal is first reached. Improved goal line visibility (3px, dashed, step badge).
- **Files:** `DailyGoalCard.swift`
- **Prevention:** Achievement celebrations should only trigger from data state changes, never from user gestures.

### 16. Settings Tab Showing Wrong View
- **Commit:** `0614543`
- **Symptom:** Settings tab showed ProfileView instead of SettingsView.
- **Fix:** Changed tab destination to correct view.
- **Files:** `MainTabView.swift`

### 17. Dark Mode Toggle Disconnected
- **Commit:** `ed72a66`
- **Symptom:** Dark mode toggle in Settings had no effect.
- **Root Cause:** Toggle was not connected to ThemeManager.
- **Fix:** Connected `@EnvironmentObject themeManager`; added `onChange` handler.
- **Files:** `SettingsView.swift`

### 18. Public Profile Toggle Always OFF
- **Commit:** `720e306`
- **Symptom:** Toggle always showed OFF regardless of actual state.
- **Root Cause:** Checking `currentUser != nil` (always true) instead of `currentUser?.publicProfile`.
- **Fix:** Fixed binding; added `publicProfile` field to User model; mapped from DB.
- **Files:** `User.swift`, `SettingsView.swift`, `AuthService.swift`

### 19. Streak Calculation Wrong
- **Commit:** `6049305`
- **Symptom:** Settings showed 0-day streak even when user hit daily goal multiple days.
- **Root Cause:** Checked `steps > 0` instead of `steps >= dailyGoal`. Only fetched 7 days of data.
- **Fix:** Check against daily goal from UserDefaults. Fetch 30 days of data.
- **Files:** `SettingsView.swift`

### 20. Sign In Screen Confusing for Existing Users
- **Commit:** `e9dfd4a`
- **Symptom:** UI implied only new accounts could be created, confusing existing Apple users.
- **Fix:** Updated heading and description text to cover both new and returning users.
- **Files:** `SignInView.swift`

---

## Build & Compilation

### 21. Xcode Cloud Export Error 70
- **Commit:** `86d62c7`
- **Symptom:** Export failed for all distribution types.
- **Root Cause:** `health-records` entitlement requires special Apple approval. `ENABLE_APP_SANDBOX` and `ENABLE_USER_SELECTED_FILES` are macOS-only.
- **Fix:** Removed problematic entitlements. Disabled sandbox. Added associated domains. Fixed Info.plist.
- **Files:** `project.pbxproj`, `StepComp.entitlements`, `Info.plist`
- **Prevention:** Don't add entitlements without verifying platform compatibility and Apple approval requirements.

### 22. iOS Compilation Errors (Text Concatenation, Non-Codable Types)
- **Commit:** `8cffb0f`
- **Symptom:** Multiple compilation failures.
- **Root Cause:** `StepSyncService` used `[String: Any]` (not Codable). UIKit import inside function. `Text + Text` deprecated in iOS 26.
- **Fix:** Added Codable struct for Edge Function payload. Moved UIKit import to file scope. Replaced `Text + Text` with `HStack(spacing: 0)`.
- **Files:** `StepSyncService.swift`, `SignInView.swift`, `WelcomeView.swift`
- **Prevention:** All Supabase payloads must be Codable structs. Avoid `Text` concatenation.

### 23. SettingsView Type-Check Timeout
- **Commits:** `543f09a`, `cd216d2`, `61d95d1`
- **Symptom:** Swift compiler timed out type-checking SettingsView body.
- **Root Cause:** Too many chained `onChange` modifiers and complex expressions in a single body.
- **Fix:** Broke body into computed properties. Split into 3 sub-ViewModifiers (ThemePreferenceModifier, NotificationPreferencesModifier, UnitSystemPreferenceModifier).
- **Files:** `SettingsView.swift`
- **Prevention:** Break large SwiftUI views into sub-views/modifiers. Don't chain more than 3-4 onChange modifiers.

### 24. Smart Quotes in Source Code
- **Commit:** `22bb6e1`
- **Symptom:** Compilation error in LegalAndSupportViews.
- **Root Cause:** Smart quotes (curly quotes) instead of regular quotes. Duplicate `BulletPoint` struct.
- **Fix:** Replaced smart quotes. Removed duplicate struct.
- **Files:** `LegalAndSupportViews.swift`
- **Prevention:** Ensure editor/AI tools don't insert smart quotes in Swift source.

### 25. Duplicate AppIcon Assets
- **Commit:** `515a5bf`
- **Symptom:** AppIcon conflict during build.
- **Root Cause:** Duplicate `Assets 2.xcassets` folder.
- **Fix:** Deleted duplicate assets folder.
- **Prevention:** Don't duplicate asset catalogs. Use a single `Assets.xcassets`.

### 26. QuickSelectButton Naming Conflict
- **Commit:** `f57de01`
- **Symptom:** Compilation error due to ambiguous type reference.
- **Root Cause:** Two different `QuickSelectButton` components in different files with different signatures.
- **Fix:** Renamed one to `DurationQuickSelectButton`.
- **Prevention:** Use descriptive, unique names for reusable components. Prefix with context.

### 27. Duplicate Function/Variable Declarations
- **Commits:** `61e3295`, `cc1ae7c`, `5380f73`
- **Symptom:** Compilation errors from redeclarations.
- **Root Cause:** `createInviteLink()` declared twice; `calendar`/`now` variables declared twice; PrivacyToggleView defined in two files.
- **Fix:** Removed duplicates in each case.
- **Prevention:** Search for existing declarations before adding new ones.

---

## Data Integrity

### 28. Rest Timer Drifts in Background
- **Documented in:** `.cursor/rules/bug-fixes.md`
- **Symptom:** Rest timer showed wrong remaining time after app returned from background.
- **Root Cause:** Timer used in-process ticks only, no lifecycle reconciliation.
- **Fix:** Use wall-clock target end date. Reconcile on foreground return.
- **Prevention:** All timers must use wall-clock dates, not in-process tick counting.

### 29. Workout Widget Persists After End/Cancel
- **Documented in:** `.cursor/rules/bug-fixes.md`
- **Symptom:** Stale Live Activities persisted on lock screen after workout ended.
- **Root Cause:** `WorkoutLiveActivityManager.end()` only ended in-memory `currentActivity`, not all system activities.
- **Fix:** End all system activities, not just the in-memory reference.
- **Prevention:** Always iterate all system activities when cleaning up Live Activities.

### 30. Leave Challenge Not Deleting from DB
- **Commit:** `7177bcf`
- **Symptom:** User left challenge but was still shown as member.
- **Root Cause:** `leaveChallenge()` only removed from local cache, not from `challenge_members` table.
- **Fix:** Added proper Supabase DELETE call.
- **Files:** `GroupViewModel.swift`
- **Prevention:** All "remove" actions must include both local cache removal AND database deletion.

---

## Challenges

### 31. Challenges Not Appearing After Creation
- **Commit:** `54f3ccf`
- **Symptom:** Newly created challenges didn't appear on Home or Active tab.
- **Root Cause:** Only loaded challenges from `challenge_members` table, not `created_by`. Timing issue where member entry didn't exist yet.
- **Fix:** Load challenges created by user plus joined challenges. Added 0.5s delay before refresh.
- **Files:** `HomeDashboardView.swift`, `ChallengesViewModel.swift`

### 32. Multiple Challenge Creation Failure
- **Commit:** `33b7593`
- **Symptom:** Creating a second challenge failed or reused old data.
- **Root Cause:** `@StateObject` persisted across sheet presentations. 6-char invite code collisions.
- **Fix:** Added `onDisappear` reset. Increased invite code to 8 chars. Added retry logic (3 attempts).
- **Files:** `CreateChallengeView.swift`, `CreateChallengeViewModel.swift`

### 33. Creator's Own Challenges Hidden in Discover
- **Commit:** `559ebb8`
- **Symptom:** Creator's own public challenges didn't appear in Discover tab.
- **Root Cause:** Filter excluded `challenge.creatorId != userId`.
- **Fix:** Removed creator exclusion. Only exclude already-joined challenges.

### 34. Challenge Deletion Only Local
- **Commit:** `6083d94`
- **Symptom:** Deleted challenge reappeared on refresh.
- **Root Cause:** Only removed from local cache, not database.
- **Fix:** Added proper Supabase DELETE call.
- **Files:** `ChallengeService.swift`

### 35. Edge Function 404 on Step Sync
- **Commit:** `c5b5ddf`
- **Symptom:** Step sync failed with 404.
- **Fix:** Added RPC fallback when Edge Function is unavailable.
- **Files:** `StepSyncService.swift`

---

## Chat System

### 36. Chat Messages Not Displaying Correctly
- **Commits:** `6fb2f88`, `5abcfe0`, `b50f117`, `7c68752`, `3cc9b07`, `ffb734e`
- **Symptom:** Various — circular references, realtime failures, wrong names shown, messages not appearing.
- **Root Causes:** Circular reference in init (`supabase = supabase`); realtime API issues; FK join syntax; missing message parameters; sent messages showing user IDs.
- **Fixes:** Simplified deinit; simplified realtime subscription; used `profiles(username, display_name, avatar_url)` join syntax; added missing parameters with ISO8601DateFormatter; reload messages after send.
- **Files:** `ChallengeChatViewModel.swift`, `ChallengeMessage.swift`
- **Prevention:** After sending a message, always reload from server to get fully-populated data. Use simplified FK join syntax for Supabase.

### 37. Duplicate send_challenge_message Functions
- **Commit:** `3d12218`
- **Symptom:** ERROR 42725 — multiple overloads causing ambiguity.
- **Fix:** Drop all existing overloads before creating new function.
- **Prevention:** Always drop existing DB functions before recreating to avoid overload ambiguity.

---

## Settings

### 38. All Static Settings Made Functional
- **Commit:** `e8fbd52`
- **Symptom:** 8 of 23 settings were broken or non-functional (logout, delete account, notifications, unit system, HealthKit, Apple Watch).
- **Root Cause:** Closures not wired; no UserDefaults persistence; HealthKit not connected.
- **Fix:** Fixed closure wiring. Added UserDefaults persistence for notifications and unit system. Connected HealthKit authorization.
- **Files:** `SettingsView.swift`
- **Prevention:** Every settings toggle must be connected to actual state management. Test all settings after adding them.

### 39. HealthKit Method Names Wrong
- **Commit:** `eae3efb`
- **Symptom:** Compilation error in Edit Height/Weight sheet.
- **Root Cause:** Called `getMostRecentHeight()`/`getMostRecentWeight()` — actual methods are `getHeight()`/`getWeight()`.
- **Prevention:** Always verify method names by reading the service file before calling.

---

## Notifications

### 40. Push Notifications Missing App Icon
- **Commit:** `d68f3ec`
- **Symptom:** Push notifications displayed without app icon.
- **Root Cause:** App not registered for remote notifications (APNs).
- **Fix:** Created AppDelegate with APNs registration. Added `aps-environment` entitlement.
- **Files:** `AppDelegate.swift`, `StepCompApp.swift`, `StepComp.entitlements`, `NotificationManager.swift`
- **Prevention:** APNs registration is required for proper notification display, even for local notifications.

### 41. Rest Timer No Notification Outside App
- **Documented in:** `.cursor/rules/bug-fixes.md`
- **Symptom:** Rest timer completion not notified when app is backgrounded.
- **Root Cause:** Only had in-app visual/haptic/sound alerts. No local notification scheduled.
- **Fix:** Schedule local notification for timer completion.
- **Prevention:** Any timer that matters to the user must schedule a local notification for background/lock screen delivery.

---

## SQL & Database Scripts

### 42. PostgreSQL Syntax Errors in Scripts
- **Commits:** `74efdae`, `50a970e`
- **Symptom:** Scripts failed to execute.
- **Root Cause:** `RAISE NOTICE` outside DO block. `CREATE POLICY IF NOT EXISTS` not valid PostgreSQL. `PRINT` statements not PostgreSQL.
- **Fix:** Wrapped in anonymous DO blocks. Used `DROP POLICY IF EXISTS` then `CREATE POLICY`. Replaced `PRINT` with `RAISE NOTICE`.
- **Prevention:** PostgreSQL does not support `CREATE POLICY IF NOT EXISTS` or `PRINT`. Always use `DROP IF EXISTS` + `CREATE`. Wrap procedural code in `DO $$ BEGIN ... END $$`.

### 43. Daily Steps Index Creation Failure
- **Commit:** `8bdb710`
- **Symptom:** Partial index creation failed during table creation.
- **Fix:** Split table creation and index creation into separate SQL statements.
- **Prevention:** Separate DDL operations (CREATE TABLE and CREATE INDEX) into distinct statements.

---

## Deprecation Fixes

### 44. Supabase API Deprecations
- **Commit:** `a042514`
- **Symptom:** Deprecation warnings for storage upload and realtime subscribe.
- **Fix:** Updated to new API signatures. Used `subscribeWithError()` instead of `subscribe()`.
- **Prevention:** Check Supabase changelog when updating SDK versions. Use non-deprecated APIs.

### 45. LinearGradient.stops Error
- **Commit:** `515a5bf`
- **Symptom:** Compilation error with gradient stops.
- **Fix:** Added `glowColor()` helper function.
- **Files:** `ChallengeChatViewModel.swift`

---

## Live Activities & Lifecycle

### 46. Live Activity Orphaned After App Relaunch
- **Status:** Fixed (uncommitted)
- **Symptom:** Stale Live Activity persisted on lock screen after app was force-quit and relaunched during a workout.
- **Root Cause:** `WorkoutLiveActivityManager` only tracked the in-memory `currentActivity` reference, which was lost on relaunch. System activities continued running with no manager reference.
- **Fix:** Added `adoptExistingActivityIfNeeded()` to scan for and re-adopt running system activities on launch.
- **Files:** `WorkoutLiveActivityManager.swift`
- **Prevention:** On launch, always scan for existing system activities and adopt them before creating new ones.

---

## Auth & Session Recovery

### 47. Auth State Inconsistency on App Relaunch
- **Status:** Fixed (uncommitted)
- **Symptom:** Intermittent auth state mismatch — user appeared logged out despite valid Keychain session.
- **Root Cause:** No periodic auth state recovery. If the auth listener missed an event or was set up after the initial session check, state could become stale.
- **Fix:** Added `triggerAuthRecoveryCheckIfNeeded()` in `RootView` with debouncing (`lastAuthRecoveryCheckAt`). Auth state is re-verified on foreground transitions.
- **Files:** `RootView.swift`, `AuthService.swift`
- **Prevention:** Auth-dependent apps should verify session state on every foreground transition, not just on initial launch.

### 48. Duplicate Metrics Sync on Launch
- **Status:** Fixed (uncommitted)
- **Symptom:** Metrics sync fired multiple times on app launch, causing redundant network calls and potential race conditions.
- **Root Cause:** Multiple code paths (app init, auth listener, foreground transition) all triggered metrics sync independently.
- **Fix:** Added `hasTriggeredMetricsStartupSync` flag to ensure sync only fires once per launch. Guard checks both authentication state and session readiness before syncing.
- **Files:** `RootView.swift`
- **Prevention:** Use a flag to deduplicate startup operations that can be triggered from multiple lifecycle events.

---

## Data Integrity (continued)

### 49. Empty Exercise Left After Deleting All Sets
- **Status:** Fixed (uncommitted)
- **Symptom:** Deleting the last set of an exercise left an empty exercise entry with zero sets in the workout.
- **Root Cause:** `removeSet()` only removed the set but didn't check if the exercise had any remaining sets.
- **Fix:** After removing a set, check if the exercise has zero sets remaining and remove the entire exercise if so.
- **Files:** `WorkoutViewModel.swift`
- **Prevention:** When removing child items from a collection, always check if the parent should also be removed.

### 50. Timer UI Update Race Condition
- **Status:** Fixed (uncommitted)
- **Symptom:** Occasional UI glitches with workout timer display (flicker, stale values).
- **Root Cause:** Timer callback could fire on a background thread, updating `@Published` properties without `@MainActor` isolation.
- **Fix:** Wrapped timer callback body in `Task { @MainActor in ... }` to ensure UI updates happen on the main actor.
- **Files:** `WorkoutViewModel.swift`
- **Prevention:** All timer/callback closures that update `@Published` properties must be explicitly dispatched to `@MainActor`.

---

## Deep Linking

### 51. Invalid Invite Token Processing
- **Status:** Fixed (uncommitted)
- **Symptom:** Malformed or empty invite tokens in deep links could trigger unnecessary network requests or errors.
- **Root Cause:** No validation on invite token format before processing the deep link.
- **Fix:** Added `isValidInviteToken()` that validates token length (8-128 chars) and character set (alphanumeric, `-`, `_`) before routing.
- **Files:** `DeepLinkRouter.swift`
- **Prevention:** Always validate deep link parameters at the routing layer before passing to services.

---

## Profile & Settings

### 52. ProfileSettings Height/Weight Ignored Unit System
- **Status:** Fixed (uncommitted)
- **Symptom:** Profile settings always displayed and saved height/weight as imperial, even when user had selected metric.
- **Root Cause:** Init hardcoded `cmToImperial` / `kgToLbs` conversion regardless of `UnitPreferenceManager.unitSystem`.
- **Fix:** Check `unitManager.unitSystem` in init; show raw cm/kg for metric, convert for imperial. Use `unitManager.heightComponents(fromCm:)` and `unitManager.weightFromStorage()` for proper round-trip.
- **Files:** `ProfileSettingsView.swift`
- **Prevention:** All unit-dependent displays must consult `UnitPreferenceManager.shared.unitSystem` before converting.

### 53. DailyGoalCard Progress Capped at 100%
- **Status:** Fixed (uncommitted)
- **Symptom:** Progress percentage showed max 100% even when user exceeded daily step goal.
- **Root Cause:** `progress` computed property used `min(…, 1.0)`, capping at 100%.
- **Fix:** Renamed to `rawProgress` and removed the `min()` cap so percentage can exceed 100%. Removed unused rainbow gradient code.
- **Files:** `DailyGoalCard.swift`
- **Prevention:** Percentage display should reflect actual value. Only cap the visual ring, not the number.

### 54. getNextWorkout Skipped One-Time Workouts
- **Status:** Fixed (uncommitted)
- **Symptom:** One-time scheduled workouts never appeared in the "Upcoming Workout" card on the home dashboard.
- **Root Cause:** `getWorkoutsForDay()` only checked `assignedDays` (recurring), ignoring `oneTimeDate`. `getNextWorkout()` started searching from tomorrow instead of today.
- **Fix:** Added `getWorkoutsForDate()` that checks both `oneTimeDate` and `assignedDays`. Changed `getNextWorkout()` to start from day 0 (today).
- **Files:** `WorkoutViewModel.swift`
- **Prevention:** When workouts can be both recurring and one-time, all query methods must check both scheduling modes.

### 55. Settings Distance Display Hardcoded to Miles
- **Status:** Fixed (uncommitted)
- **Symptom:** Settings profile section always displayed distance in miles regardless of unit preference.
- **Root Cause:** `formattedDistance` was hardcoded: `String(format: "%.1f mi", totalDistanceMiles)`.
- **Fix:** Convert to km, then use `unitPreferenceManager.formatDistance()` and `.distanceUnit` for display.
- **Files:** `SettingsView.swift`
- **Prevention:** All distance displays must go through `UnitPreferenceManager` formatting helpers.

---

## Service Initialization

### 56. Multiple Service Instances Causing State Desync
- **Status:** Fixed (uncommitted)
- **Symptom:** HealthKit and Challenge data could become stale or inconsistent across different views.
- **Root Cause:** `RootView` created new `HealthKitService()` and `ChallengeService()` instances instead of using shared singletons. `DashboardViewModel` init required service injection, creating additional instances.
- **Fix:** Changed to `HealthKitService.shared` and `ChallengeService.shared` in `RootView`. Simplified `DashboardViewModel` init to use lazy service injection.
- **Files:** `RootView.swift`, `DashboardViewModel.swift`, `HealthKitService.swift`
- **Prevention:** State-holding services must always use singleton pattern. Never create ad-hoc instances in view init.

---

## Quick Reference: Common Patterns That Cause Bugs

| Pattern | Risk | What To Do Instead |
|---------|------|---------------------|
| Multiple instances of state-holding services | State desync, auth loss | Use singleton pattern |
| `await MainActor.run` inside `@MainActor` | Deadlock | Remove the wrapper |
| Creating Tasks in `deinit` | Retain cycle crash | Keep deinit synchronous |
| `@StateObject` for shared ViewModels during transitions | Crash on view swap | Use `@ObservedObject` |
| `Int()` truncation in unit conversions | Off-by-one errors | Use `.rounded()` first |
| In-process timer ticks | Timer drift in background | Use wall-clock target dates |
| Local-only delete/leave operations | Data reappears on refresh | Always delete from DB too |
| `[String: Any]` for Supabase payloads | Non-Codable crash | Use Codable structs |
| Unit conversion on every keystroke | Input feedback loop | Convert only on commit |
| `CREATE POLICY IF NOT EXISTS` | PostgreSQL syntax error | `DROP IF EXISTS` + `CREATE` |
| Chaining 5+ `onChange` modifiers | Type-check timeout | Split into sub-ViewModifiers |
| Timer callbacks without `@MainActor` | UI race conditions | Wrap in `Task { @MainActor in }` |
| No validation on deep link params | Bad network requests | Validate format before routing |
| Multiple startup sync triggers | Redundant network calls | Use a one-shot flag to deduplicate |
| Not adopting existing Live Activities | Orphaned system activities | Scan and adopt on launch |
| Hardcoded unit display (miles, lbs) | Wrong values for metric users | Always use `UnitPreferenceManager` formatters |
| Capping progress at 100% in display | Misleading achievement info | Cap the visual ring, not the number |
| Only checking recurring workout days | One-time workouts invisible | Query both `assignedDays` and `oneTimeDate` |
