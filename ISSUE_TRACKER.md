# FitComp Issue Tracker

> High-impact issues investigated or resolved by automation.
> Last updated: 2026-05-31

---

## Resolved

### 2026-05-31 - Auth deep-link callback breakage
- **Severity:** Critical
- **Impact:** Password reset links could fail to open the app because they used an unregistered URL scheme. Google Sign-In could complete in the browser but fail to establish an app session because the callback was not processed by Supabase in the web-auth completion path.
- **Root Cause:** Auth redirects were split across hard-coded URL strings and app-level URL handling, while `ASWebAuthenticationSession` delivers callbacks directly to its completion handler.
- **Resolution:** Password reset redirects now use the registered `fitcomp://reset-password` URL, custom-scheme routing rejects unregistered schemes, and Google OAuth callbacks are handed to Supabase before session lookup.
- **Validation:** Added DeepLinkRouter regression coverage for unregistered custom schemes and the configured password-reset redirect URL. iOS XCTest execution is unavailable on this Linux runner (`xcodebuild` and `swift` are not installed).
