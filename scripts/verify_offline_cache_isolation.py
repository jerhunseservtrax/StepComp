#!/usr/bin/env python3
"""Static regression checks for user-scoped offline cache usage."""

from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]


def read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text()


def require(condition: bool, message: str) -> None:
    if not condition:
        print(f"FAIL: {message}")
        sys.exit(1)


def main() -> None:
    swift_sources = "\n".join(path.read_text() for path in (ROOT / "StepComp").rglob("*.swift"))
    unscoped_patterns = [
        r'OfflineCacheService\.fetchWithFallback\(key:\s*"',
        r'OfflineCacheService\.fetchArrayWithFallback\(key:\s*"',
        r'OfflineCacheService\.save\([^)\n]*key:\s*"',
        r'OfflineCacheService\.load\([^)\n]*key:\s*"',
    ]
    for pattern in unscoped_patterns:
        require(
            re.search(pattern, swift_sources) is None,
            f"found unscoped offline cache call matching {pattern}",
        )

    offline_cache = read("StepComp/Services/OfflineCacheService.swift")
    require("userId.lowercased()" in offline_cache, "userScopedKey must normalize user IDs")

    metrics = read("StepComp/Services/MetricsService.swift")
    for key in ("metrics_summary_\\(days)", "weight_history_\\(days)", "workout_history_\\(days)"):
        require(
            f'userScopedOfflineCacheKey("{key}")' in metrics,
            f"MetricsService cache key {key} must be user-scoped",
        )

    challenge = read("StepComp/Services/ChallengeService.swift")
    require(
        'userScopedOfflineCacheKey("leaderboard_\\(challengeId)")' in challenge,
        "ChallengeService leaderboard cache must be user-scoped",
    )
    require("func clearRuntimeCache()" in challenge, "ChallengeService must expose runtime cache cleanup")

    auth = read("StepComp/Services/AuthService.swift")
    require("OfflineCacheService.clearAll()" in auth, "AuthService must clear offline cache on auth cleanup")
    require("ChallengeService.shared.clearRuntimeCache()" in auth, "AuthService must clear challenge runtime cache")
    require("userId.lowercased()" in auth, "AuthService account-switch comparison must normalize user IDs")

    print("offline-cache-isolation: ok")


if __name__ == "__main__":
    main()
