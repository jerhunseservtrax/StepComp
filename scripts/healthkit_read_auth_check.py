#!/usr/bin/env python3
"""Regression check: HealthKit write status must not gate reads.

Apple's HKHealthStore.authorizationStatus(for:) reports SHARE/WRITE status
only. Users who grant Read for steps but deny Write were treated as
unauthorized, so the home dashboard and step sync returned 0 forever.

HKAuthorizationStatus raw values:
  0 = notDetermined
  1 = sharingDenied
  2 = sharingAuthorized
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SERVICE = ROOT / "StepComp" / "Services" / "HealthKitService.swift"
POLICY = ROOT / "StepComp" / "Services" / "HealthKitAuthorizationPolicy.swift"


def can_attempt_read(write_status_raw: int) -> bool:
    """Reads may succeed after the user has been prompted, even if write was denied."""
    return write_status_raw != 0


def can_attempt_write(write_status_raw: int) -> bool:
    return write_status_raw == 2


def test_policy_matrix() -> None:
    cases = [
        (0, False, False, "notDetermined"),
        (1, True, False, "sharingDenied"),
        (2, True, True, "sharingAuthorized"),
    ]
    for raw, expect_read, expect_write, label in cases:
        read = can_attempt_read(raw)
        write = can_attempt_write(raw)
        if read != expect_read or write != expect_write:
            raise AssertionError(
                f"{label} (raw={raw}): read={read} write={write}, "
                f"expected read={expect_read} write={expect_write}"
            )


def _require_contains(text: str, needle: str, label: str) -> None:
    if needle not in text:
        raise AssertionError(f"{label} must contain {needle!r}")


def test_source_uses_policy() -> None:
    service = SERVICE.read_text()
    policy_path = POLICY if POLICY.exists() else SERVICE
    policy = policy_path.read_text()

    if "isAuthorized = status == .sharingAuthorized" in service:
        raise AssertionError(
            "HealthKitService still treats sharingAuthorized (write) as the read gate"
        )

    _require_contains(policy, "canAttemptRead", "authorization policy")
    _require_contains(policy, "canAttemptWrite", "authorization policy")
    _require_contains(service, "HealthKitAuthorizationPolicy.canAttemptRead", "HealthKitService")
    _require_contains(service, "HealthKitAuthorizationPolicy.canAttemptWrite", "HealthKitService.saveWeight path")

    save_match = re.search(
        r"func saveWeight\(.*?\n    \}\n",
        service,
        flags=re.S,
    )
    if not save_match:
        raise AssertionError("Could not find saveWeight in HealthKitService.swift")
    if "canAttemptWrite" not in save_match.group(0):
        raise AssertionError("saveWeight must require write authorization via canAttemptWrite")


def main() -> int:
    test_policy_matrix()
    test_source_uses_policy()
    print("healthkit_read_auth_check: all assertions passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
