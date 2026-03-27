# Bug Fix Guardrails

Purpose: keep resolved bugs from being reintroduced.

## Rule 1: Persistent Auth Must Survive Force Quit

Status: fixed on 2026-03-16

Symptoms that must never return:
- User is asked to sign in after force-quit and relaunch.
- User is routed to onboarding/login unless they explicitly chose logout.

Root causes that were fixed:
- `AuthService` handled `.initialSession` with `nil` by immediately clearing auth state.
- Transient `isAuthenticated = false` cleared `hasCompletedOnboarding`.
- Keychain persistence did not explicitly set accessibility.

Required guardrails:
1. In `StepComp/Services/AuthService.swift`, `.initialSession` with `nil` must try cached-user fallback before any signed-out state.
2. In `StepComp/Services/AuthService.swift`, signed-out handling during startup checks must not blindly clear state if cache exists.
3. In `StepComp/ViewModels/SessionViewModel.swift`, onboarding completion flag must only be cleared by explicit user logout flow.
4. In `StepComp/Utilities/KeychainStore.swift`, keychain writes for auth-related cache must keep `kSecAttrAccessibleAfterFirstUnlock`.

Verification checklist for any auth-related change:
- Sign in, force-quit app, relaunch: user remains signed in.
- Restart app offline after prior sign-in: cached user can still open app.
- Explicit logout from settings: user is signed out and onboarding/login path is shown.

## Rule 2: Rest Timer Must Follow Wall Clock

Status: fixed on 2026-03-16

Symptoms that must never return:
- Rest timer pauses/freeze while app is backgrounded.
- On return from background, timer shows stale remaining time.

Root causes that were fixed:
- Timer state was decremented by in-process ticks only.
- No lifecycle reconciliation on foreground/background.

Required guardrails:
1. `StepComp/Services/RestTimerManager.swift` must use a wall-clock target end date as source of truth.
2. Foreground lifecycle handling must recompute remaining time from current wall clock and finish immediately if expired.
3. Adding time during an active timer must update both displayed duration and target end date.

Verification checklist for any timer-related change:
- Start timer, background for 10+ seconds, foreground: remaining time reflects elapsed real time.
- Start short timer, background past expiry, foreground: timer is immediately finished.
- Add time while running: remaining time and total duration both stay consistent.

## Rule 3: Bug-Fix Workflow

For every bug fix:
1. Document: add a short entry to this file (symptom, root cause, guardrails, verification).
2. Protect: add or update logic/tests to lock expected behavior.
3. Verify: run at least one reproduction check for the original bug before marking complete.

## Rule 4: Workout Widget Must Stop On End/Cancel

Status: fixed on 2026-03-16

Symptoms that must never return:
- Lock screen/Dynamic Island workout timer keeps running after workout is canceled or ended.

Root causes that were fixed:
- `WorkoutLiveActivityManager.end()` only ended `currentActivity` stored in memory.
- After app lifecycle transitions, in-memory `currentActivity` could be nil while system still had active workout Live Activity.

Required guardrails:
1. `StepComp/Services/WorkoutLiveActivityManager.swift` must end all `Activity<WorkoutAttributes>.activities`, not just the in-memory reference.
2. `start`/`update` paths must adopt an existing system activity when in-memory reference is missing.
3. End/cancel workout flows in `WorkoutViewModel` must continue to call both `WorkoutLiveActivityManager.end()` and `WorkoutWidgetStore.clear()`.

Verification checklist for any workout activity change:
- Start workout, lock phone, cancel workout in app, lock screen widget disappears immediately.
- Start workout, force-close/reopen app, end workout, lock screen widget disappears.
- Start workout, complete workout, confirm no lingering Live Activity remains.

## Rule 5: Rest Timer Must Notify Outside App

Status: fixed on 2026-03-16

Symptoms that must never return:
- Rest timer ends while app is backgrounded and user gets no popup notification.

Root causes that were fixed:
- `RestTimerManager` had only in-app visual/haptic/sound alerts.
- No local notification was scheduled for timer completion.

Required guardrails:
1. `StepComp/Services/RestTimerManager.swift` must schedule a completion local notification when rest timer starts.
2. Extending timer duration must reschedule completion notification with the new remaining time.
3. Stopping, skipping, or finishing timer must cancel pending rest-timer completion notifications.

Verification checklist for any rest timer changes:
- Start rest timer, leave app, wait for completion time: receive local notification popup.
- Start timer, add time, leave app: notification fires at updated end time.
- Start timer then cancel/skip: no completion notification should fire.
