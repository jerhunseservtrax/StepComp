#!/usr/bin/env python3
"""Static regression checks for critical auth/session correctness paths.

These checks are intentionally lightweight so they can run on Linux where the
Swift/Xcode toolchain is unavailable in Cursor Cloud.
"""

from pathlib import Path
import plistlib
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]


def read_text(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def project_url_scheme_sets() -> list[set[str]]:
    project = read_text("StepComp.xcodeproj/project.pbxproj")
    values = re.findall(r"INFOPLIST_KEY_CFBundleURLTypes = \"(.*?)\";", project)
    scheme_sets: list[set[str]] = []
    for raw_value in values:
        value = raw_value.replace(r"\n", "\n").replace(r"\"", '"')
        match = re.search(r"CFBundleURLSchemes\s*=\s*\((.*?)\);", value, re.DOTALL)
        if not match:
            continue
        schemes = {
            scheme.strip().strip('"').strip("'")
            for scheme in match.group(1).splitlines()
            if scheme.strip() and scheme.strip() != ","
        }
        scheme_sets.append({scheme.rstrip(",") for scheme in schemes if scheme.rstrip(",")})
    return scheme_sets


class CriticalAuthRegressionTests(unittest.TestCase):
    def test_password_reset_redirect_scheme_is_registered(self) -> None:
        info_plist = plistlib.loads((ROOT / "StepComp/Info.plist").read_bytes())
        registered_schemes = {
            scheme
            for url_type in info_plist.get("CFBundleURLTypes", [])
            for scheme in url_type.get("CFBundleURLSchemes", [])
        }

        forgot_password = read_text("StepComp/Screens/Onboarding/ForgotPasswordSheet.swift")
        match = re.search(r'URL\(string:\s*"([^"]+://reset-password)"\)', forgot_password)
        self.assertIsNotNone(match, "Password reset redirect URL not found")
        redirect_scheme = match.group(1).split(":", 1)[0]

        self.assertIn(
            redirect_scheme,
            registered_schemes,
            "Password reset emails must use a URL scheme registered in Info.plist",
        )
        xcode_scheme_sets = project_url_scheme_sets()
        self.assertGreaterEqual(
            len(xcode_scheme_sets),
            2,
            "Expected Debug and Release Xcode URL type build settings",
        )
        for schemes in xcode_scheme_sets:
            self.assertIn(
                redirect_scheme,
                schemes,
                "Password reset scheme must be present in every Xcode URL type build setting",
            )

    def test_cached_user_does_not_mark_session_authenticated(self) -> None:
        auth_service = read_text("StepComp/Services/AuthService.swift")
        handler_match = re.search(
            r"private func handleAuthStateChange\(event: AuthChangeEvent, session: Session\?\) async \{"
            r"([\s\S]*?)"
            r"\n    private func applyAuthenticatedSession",
            auth_service,
        )
        self.assertIsNotNone(handler_match, "Auth state handler not found")
        unsafe_cached_auth = re.compile(
            r"if let cachedUser = loadCachedUser\(\) \{[^{}]*"
            r"currentUser = cachedUser[^{}]*"
            r"isAuthenticated = true",
            re.DOTALL,
        )

        self.assertIsNone(
            unsafe_cached_auth.search(handler_match.group(1)),
            "A startup cached profile must not be treated as an authenticated Supabase session",
        )

    def test_active_workout_only_clears_on_explicit_sign_out(self) -> None:
        auth_service = read_text("StepComp/Services/AuthService.swift")

        self.assertIn(
            "clearActiveWorkoutState:",
            auth_service,
            "Signed-out cleanup must explicitly control whether workout drafts are cleared",
        )
        self.assertRegex(
            auth_service,
            r"func signOut\(\) async throws \{[\s\S]*clearActiveWorkoutStateOnNextSignOut = true",
            "User-initiated sign-out must request workout cleanup",
        )
        self.assertRegex(
            auth_service,
            r"forceLogout\(\) async \{[\s\S]*applySignedOutState\([^)]*clearActiveWorkoutState: false",
            "Forced auth logout must preserve active workout drafts to avoid data loss",
        )

    def test_legacy_cached_user_migration_and_sign_out_cleanup(self) -> None:
        auth_service = read_text("StepComp/Services/AuthService.swift")
        load_cached_match = re.search(
            r"private func loadCachedUser\(\) -> User\? \{([\s\S]*?)\n    \}",
            auth_service,
        )
        self.assertIsNotNone(load_cached_match, "loadCachedUser() not found")
        load_cached_body = load_cached_match.group(1)

        self.assertIn(
            "UserDefaults.standard.data(forKey: userDefaultsKey)",
            load_cached_body,
            "Legacy UserDefaults cached user must be read for one-time migration",
        )
        self.assertIn(
            "KeychainStore.save(encoded, account: keychainUserAccount)",
            load_cached_body,
            "Legacy cached user must be migrated into Keychain",
        )
        self.assertIn(
            "UserDefaults.standard.removeObject(forKey: userDefaultsKey)",
            load_cached_body,
            "Legacy UserDefaults cached user must be removed after migration",
        )

        signed_out_match = re.search(
            r"private func applySignedOutState\([\s\S]*?\) \{([\s\S]*?)\n    \}",
            auth_service,
        )
        self.assertIsNotNone(signed_out_match, "applySignedOutState() not found")
        self.assertIn(
            "UserDefaults.standard.removeObject(forKey: userDefaultsKey)",
            signed_out_match.group(1),
            "Explicit cached auth deletion must remove legacy UserDefaults cache too",
        )


if __name__ == "__main__":
    unittest.main()
