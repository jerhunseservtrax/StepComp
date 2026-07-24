#!/usr/bin/env python3
"""
Regression guard: step sync day keys must match HealthKit local calendar days.

Bug: StepSyncService previously sent ISO8601DateFormatter().string(from: Date())
(UTC) as p_day while HealthKit getSteps(for:) uses Calendar.current local day
boundaries. Postgres DATE casts the UTC timestamp, so after UTC midnight in
Americas timezones evening steps are written to the wrong day and later
overwritten by the next local morning sync.
"""

from __future__ import annotations

import re
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STEP_SYNC = ROOT / "StepComp" / "Services" / "StepSyncService.swift"
EDGE = ROOT / "supabase" / "functions" / "sync-steps" / "index.ts"


def assert_true(cond: bool, message: str) -> None:
    if not cond:
        raise AssertionError(message)


def demonstrate_timezone_mismatch() -> None:
    """Concrete trigger: 8pm EDT is already the next UTC calendar day."""
    edt = timezone(timedelta(hours=-4))
    local = datetime(2026, 7, 23, 20, 0, 0, tzinfo=edt)
    utc = local.astimezone(timezone.utc)
    local_day = local.date().isoformat()
    utc_iso = utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    utc_day = utc.date().isoformat()
    assert_true(local_day != utc_day, "fixture should cross the UTC date boundary")
    assert_true(
        utc_iso.startswith(utc_day),
        "ISO8601 UTC string day prefix must equal the UTC calendar day",
    )
    print(f"ok: timezone mismatch fixture local={local_day} utc_iso={utc_iso}")


def check_step_sync_service() -> None:
    source = STEP_SYNC.read_text(encoding="utf-8")

    # Must not key the sync day with a UTC ISO-8601 timestamp.
    bad = re.search(
        r"day:\s*ISO8601DateFormatter\(\)\.string\(from:\s*Date\(\)\)",
        source,
    )
    assert_true(
        bad is None,
        "StepSyncService must not send ISO8601DateFormatter().string(from: Date()) as day",
    )

    assert_true(
        "localDayString" in source,
        "StepSyncService must format sync days via localDayString",
    )
    assert_true(
        'dateFormat = "yyyy-MM-dd"' in source or 'dateFormat = "yyyy-MM-dd"' in source,
        "localDayString must use yyyy-MM-dd",
    )
    assert_true(
        "formatter.timeZone = calendar.timeZone" in source,
        "localDayString must use the calendar time zone (not UTC)",
    )

    # syncTodayStepsToProfile should derive the day from the local helper.
    assert_true(
        re.search(
            r"let day = Self\.localDayString\(for: syncDate\)|"
            r"day:\s*(?:Self\.)?localDayString\(",
            source,
        )
        is not None,
        "syncTodayStepsToProfile must derive day from localDayString(...)",
    )
    print("ok: StepSyncService uses local YYYY-MM-DD day keys")


def check_edge_contract() -> None:
    source = EDGE.read_text(encoding="utf-8")
    assert_true(
        "YYYY-MM-DD" in source,
        "sync-steps Edge Function contract should document YYYY-MM-DD day keys",
    )
    print("ok: Edge Function day contract documents YYYY-MM-DD")


def main() -> int:
    try:
        demonstrate_timezone_mismatch()
        check_step_sync_service()
        check_edge_contract()
    except AssertionError as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1
    print("step-sync-local-day: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
