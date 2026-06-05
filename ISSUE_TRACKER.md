# FitComp Issue Tracker

> Critical issues discovered by automated bug-finding runs and their resolution status.

## 2026-06-05 - Critical Bug Investigation

### Chat history truncated after pagination + realtime
- **Severity:** Critical user-facing breakage
- **Status:** Fixed
- **Trigger:** Open a challenge chat with more than 40 messages, load older messages, then send or receive a realtime message.
- **Impact:** Older loaded messages disappeared from the chat UI, making history appear lost.
- **Fix:** Reconcile latest-page refreshes with already loaded older pages in `ChallengeChatViewModel`.

### Offline metrics cache leaked across account switches
- **Severity:** Critical privacy issue
- **Status:** Fixed
- **Trigger:** User A loads metrics/leaderboard data on a shared device, signs out, User B signs in, then a network failure causes disk fallback.
- **Impact:** User B could see User A's cached metrics or leaderboard data.
- **Fix:** Scope offline cache keys by user id and clear offline caches on sign-out/account changes.
