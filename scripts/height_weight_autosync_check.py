#!/usr/bin/env python3
"""Regression check: HealthKit must not persist 175/68 UI defaults.

ProfileViewModel treated stored 175 cm / 68 kg as "unset" and then wrote
HealthKit height together with the @Published default weight (68) to
profiles. That corrupted real 175/68 users and new users who only had
height in HealthKit (fake 68 kg stuck in the cloud, later weight sync
blocked because height was no longer the sentinel).
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POLICY = ROOT / "StepComp" / "Services" / "HeightWeightAutoSyncPolicy.swift"
PROFILE_VM = ROOT / "StepComp" / "ViewModels" / "ProfileViewModel.swift"
AUTH = ROOT / "StepComp" / "Services" / "AuthService.swift"


def is_missing_stored_measurement(stored: int) -> bool:
    """Only missing/zero storage counts as unset. 175 and 68 are valid."""
    return stored <= 0


def should_auto_load(stored_height: int, stored_weight: int) -> bool:
    return is_missing_stored_measurement(stored_height) or is_missing_stored_measurement(
        stored_weight
    )


def profile_write_payload(loaded_height: int | None, loaded_weight: int | None):
    height = loaded_height if loaded_height is not None and loaded_height > 0 else None
    weight = loaded_weight if loaded_weight is not None and loaded_weight > 0 else None
    return height, weight


def merged_profile_values(
    incoming_height: int | None,
    incoming_weight: int | None,
    existing_height: int | None,
    existing_weight: int | None,
):
    return (
        incoming_height if incoming_height is not None else existing_height,
        incoming_weight if incoming_weight is not None else existing_weight,
    )


def test_policy_matrix() -> None:
    cases = [
        (0, True, "missing"),
        (-1, True, "negative"),
        (175, False, "real height sentinel"),
        (68, False, "real weight sentinel"),
        (182, False, "custom height"),
        (90, False, "custom weight"),
    ]
    for stored, expect_missing, label in cases:
        got = is_missing_stored_measurement(stored)
        if got != expect_missing:
            raise AssertionError(f"{label} stored={stored}: missing={got}, expected {expect_missing}")

    if should_auto_load(175, 68):
        raise AssertionError("175/68 must not trigger HealthKit auto-sync")
    if not should_auto_load(0, 0):
        raise AssertionError("0/0 must trigger HealthKit auto-sync")
    if not should_auto_load(182, 0):
        raise AssertionError("height set / weight missing must still allow weight sync")
    if should_auto_load(182, 90):
        raise AssertionError("both fields set must not auto-sync")

    height, weight = profile_write_payload(182, None)
    if height != 182 or weight is not None:
        raise AssertionError(
            f"height-only HealthKit load must write height=182 weight=None, got {height}/{weight}"
        )

    merged_h, merged_w = merged_profile_values(182, None, 170, 81)
    if merged_h != 182 or merged_w != 81:
        raise AssertionError(
            f"partial update must preserve existing weight, got {merged_h}/{merged_w}"
        )


def _require_contains(text: str, needle: str, label: str) -> None:
    if needle not in text:
        raise AssertionError(f"{label} must contain {needle!r}")


def test_source_rejects_sentinel_guard() -> None:
    if not POLICY.exists():
        raise AssertionError("HeightWeightAutoSyncPolicy.swift is missing")

    policy = POLICY.read_text()
    profile = PROFILE_VM.read_text()
    auth = AUTH.read_text()

    _require_contains(policy, "isMissingStoredMeasurement", "autosync policy")
    _require_contains(policy, "shouldAutoLoad", "autosync policy")
    _require_contains(policy, "profileWritePayload", "autosync policy")
    _require_contains(policy, "mergedProfileValues", "autosync policy")

    if re.search(r"currentHeight == 0 \|\| currentHeight == 175", profile):
        raise AssertionError(
            "ProfileViewModel still treats 175 cm as an unset sentinel"
        )
    if re.search(r"currentWeight == 0 \|\| currentWeight == 68", profile):
        raise AssertionError(
            "ProfileViewModel still treats 68 kg as an unset sentinel"
        )

    _require_contains(
        profile,
        "HeightWeightAutoSyncPolicy.shouldAutoLoad",
        "ProfileViewModel",
    )
    _require_contains(
        profile,
        "HeightWeightAutoSyncPolicy.profileWritePayload",
        "ProfileViewModel",
    )

    load_fn = re.search(
        r"private func loadHeightWeightFromHealthKit\(.*?\n    \}\n",
        profile,
        flags=re.S,
    )
    if not load_fn:
        raise AssertionError("Could not find loadHeightWeightFromHealthKit")
    body = load_fn.group(0)
    if re.search(r"updateUserHeightWeight\(height:\s*heightInt,\s*weight:\s*weight\)", body):
        raise AssertionError(
            "height-only HealthKit load still persists @Published default weight"
        )
    if "profileWritePayload" not in body:
        raise AssertionError(
            "loadHeightWeightFromHealthKit must persist only fields loaded from HealthKit"
        )

    _require_contains(
        auth,
        "HeightWeightAutoSyncPolicy.mergedProfileValues",
        "AuthService.updateUserHeightWeight",
    )


def main() -> int:
    test_policy_matrix()
    test_source_rejects_sentinel_guard()
    print("height_weight_autosync_check: all assertions passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
