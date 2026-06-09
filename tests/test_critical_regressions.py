import re
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read_source(relative_path: str) -> str:
    return (ROOT / relative_path).read_text()


class CriticalRegressionTests(unittest.TestCase):
    def test_password_reset_redirect_uses_registered_scheme(self):
        info_plist = ET.parse(ROOT / "StepComp/Info.plist").getroot()
        strings = [node.text for node in info_plist.iter("string")]
        registered_schemes = {
            strings[index + 1]
            for index, value in enumerate(strings[:-1])
            if value == "com.je.stepcomp.auth"
        }

        forgot_password = read_source("StepComp/Screens/Onboarding/ForgotPasswordSheet.swift")
        match = re.search(r'URL\(string:\s*"([^"]+://reset-password)"\)', forgot_password)

        self.assertIsNotNone(match, "ForgotPasswordSheet should configure a reset redirect URL")
        redirect_url = match.group(1)
        redirect_scheme = redirect_url.split("://", 1)[0]

        self.assertEqual(redirect_url, "fitcomp://reset-password")
        self.assertIn(redirect_scheme, registered_schemes)

    def test_google_oauth_callback_processes_url_before_reading_session_without_token_logs(self):
        source = read_source("StepComp/Screens/Onboarding/SignInOnboardingView+Auth.swift")
        callback_body = source[source.index("func handleOAuthCallback(url: URL) async") :]

        handle_index = callback_body.find("try await supabase.auth.session(from: url)")
        profile_check_index = callback_body.find("sessionViewModel.checkSession()")

        self.assertNotEqual(handle_index, -1, "OAuth callback must await Supabase session extraction")
        self.assertNotEqual(profile_check_index, -1, "OAuth callback should verify the resulting profile")
        self.assertLess(handle_index, profile_check_index)
        self.assertNotIn("let session = try await supabase.auth.session\n", callback_body)
        self.assertNotIn("supabase.auth.handle(url)", callback_body)
        self.assertNotIn("callbackURL.absoluteString", source)
        self.assertNotIn('print("🔵 OAuth callback received: \\(url)")', source)

    def test_metrics_offline_cache_is_user_scoped_and_cleared_on_sign_out(self):
        metrics_service = read_source("StepComp/Services/MetricsService.swift")
        auth_service = read_source("StepComp/Services/AuthService.swift")

        self.assertIn("currentUserScopedCacheKey", metrics_service)
        self.assertNotIn('key: "metrics_summary_\\(days)"', metrics_service)
        self.assertNotIn('key: "weight_history_\\(days)"', metrics_service)
        self.assertNotIn('key: "workout_history_\\(days)"', metrics_service)
        self.assertIn("OfflineCacheService.clearAll()", auth_service)


if __name__ == "__main__":
    unittest.main()
