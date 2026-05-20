#!/usr/bin/env python3
"""Static regression checks for critical correctness/security fixes.

These checks cover high-severity patterns that are hard to exercise in this
Linux automation environment because the project requires Xcode to build.
"""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def assert_not_contains(path: str, forbidden: str, reason: str) -> None:
    contents = read(path)
    assert forbidden not in contents, f"{path}: {reason}"


def assert_contains(path: str, required: str, reason: str) -> None:
    contents = read(path)
    assert required in contents, f"{path}: {reason}"


def main() -> None:
    assert_not_contains(
        "StepComp/Screens/Onboarding/ForgotPasswordSheet.swift",
        'URL(string: "je.fitcomp://reset-password")',
        "password reset must use the registered fitcomp:// URL scheme",
    )
    assert_contains(
        "StepComp/Screens/Onboarding/ForgotPasswordSheet.swift",
        'URL(string: "fitcomp://reset-password")',
        "password reset redirect should match Info.plist",
    )

    assert_not_contains(
        "StepComp/Screens/Onboarding/SignInOnboardingView+Auth.swift",
        'print("✅ [H7] Callback URL received: \\(callbackURL.absoluteString)")',
        "OAuth callback URLs can contain tokens and must not be logged in release builds",
    )
    assert_not_contains(
        "StepComp/Screens/Onboarding/SignInOnboardingView+Auth.swift",
        'print("🔵 OAuth callback received: \\(url)")',
        "OAuth callback URLs can contain tokens and must not be logged in release builds",
    )

    assert_not_contains(
        "StepComp/Services/SupabaseRequestExecutor.swift",
        'message.contains("token")',
        "generic token substring matching misclassifies invite-token errors as auth failures",
    )

    assert_contains(
        "StepComp/Services/AuthService.swift",
        "OfflineCacheService.clearAll()",
        "sign-out paths must purge sensitive offline cache data",
    )
    assert_not_contains(
        "StepComp/Services/AuthService.swift",
        "OfflineCacheService.clearAll()\n            try await supabase.auth.signOut()",
        "offline cache should clear after confirmed sign-out state, not before signOut can fail",
    )

    assert_not_contains(
        "scripts/shell/update_redirect_urls.sh",
        "je.stepcomp://reset-password",
        "Supabase redirect helper must allow the registered fitcomp:// reset URL",
    )
    assert_contains(
        "scripts/shell/update_redirect_urls.sh",
        "fitcomp://reset-password",
        "Supabase redirect helper must allow the registered fitcomp:// reset URL",
    )

    chat_list = read("StepComp/ViewModels/ChatListViewModel.swift")
    assert ".delete()" not in chat_list or "challenge_members" not in chat_list, (
        "ChatListViewModel must not delete challenge_members while loading chats; "
        "ended challenges are historical data, not orphaned records"
    )

    challenge_service = read("StepComp/Services/ChallengeService.swift")
    assert "Fallback to all-time leaderboard" not in challenge_service, (
        "daily leaderboard fallback must not show all-time cached totals as today's steps"
    )

    assert_contains(
        "StepComp/ViewModels/WorkoutViewModel.swift",
        "guard currentSession == nil else",
        "starting a workout must not overwrite an active in-progress session",
    )


if __name__ == "__main__":
    main()
