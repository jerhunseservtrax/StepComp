#!/usr/bin/env python3
"""
Regression guard: weekly (and daily) challenge leaderboards must read public.daily_steps.

Bug: After Security Overhaul V2, sync_daily_steps no longer denormalizes into
challenge_members.daily_steps / total_steps. Daily/all-time tabs already use
SECURITY DEFINER RPCs over daily_steps, but the Week tab still selected
challenge_members and summed the abandoned JSONB map — so weekly ranks stay 0
for every member after V2 deploy.

Related: get_challenge_leaderboard_today filtered ds.day = CURRENT_DATE (UTC).
With local-day step sync keys, non-UTC users miss today's rows near day boundaries.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHALLENGE_SERVICE = ROOT / "StepComp" / "Services" / "ChallengeService.swift"
WEEKLY_SQL = ROOT / "scripts" / "sql" / "FIX_WEEKLY_LEADERBOARD_FROM_DAILY_STEPS.sql"
V2_SQL = ROOT / "scripts" / "sql" / "IMPLEMENT_SECURITY_OVERHAUL_V2_SAFE.sql"


def assert_true(cond: bool, message: str) -> None:
    if not cond:
        raise AssertionError(message)


def demonstrate_dead_jsonb_read() -> None:
    """Concrete trigger scenario documented for reviewers."""
    # After V2, authentic sync writes only to public.daily_steps.
    # challenge_members.daily_steps remains {} for new syncs.
    member_jsonb = {}
    authentic_daily_steps = {
        "2026-07-20": 8123,
        "2026-07-21": 10440,
        "2026-07-22": 9550,
        "2026-07-23": 12001,
        "2026-07-24": 7800,
        "2026-07-25": 11020,
        "2026-07-26": 6400,
    }
    week_keys = list(authentic_daily_steps.keys())
    jsonb_week_total = sum(member_jsonb.get(day, 0) for day in week_keys)
    real_week_total = sum(authentic_daily_steps[day] for day in week_keys)
    assert_true(jsonb_week_total == 0, "stale JSONB must yield zero weekly steps")
    assert_true(real_week_total > 0, "daily_steps must hold the real weekly total")
    print(
        f"ok: dead-read fixture jsonb_week={jsonb_week_total} "
        f"daily_steps_week={real_week_total}"
    )


def check_v2_removes_denorm() -> None:
    source = V2_SQL.read_text(encoding="utf-8")
    assert_true(
        "challenge_members denormalization removed" in source
        or "REMOVED: challenge_members denormalization" in source,
        "V2 overhaul must document removal of challenge_members denormalization",
    )
    # V2 sync_daily_steps should not UPDATE challenge_members step columns.
    sync_fn = re.search(
        r"CREATE OR REPLACE FUNCTION public\.sync_daily_steps\([\s\S]*?^\$\$;",
        source,
        flags=re.MULTILINE,
    )
    assert_true(sync_fn is not None, "V2 must define sync_daily_steps")
    body = sync_fn.group(0)
    assert_true(
        "UPDATE public.challenge_members" not in body,
        "V2 sync_daily_steps must not update challenge_members",
    )
    print("ok: V2 sync_daily_steps does not denormalize into challenge_members")


def check_weekly_sql_rpc() -> None:
    assert_true(WEEKLY_SQL.exists(), f"missing SQL fix file: {WEEKLY_SQL}")
    source = WEEKLY_SQL.read_text(encoding="utf-8")
    assert_true(
        "get_challenge_leaderboard_week" in source,
        "SQL fix must create get_challenge_leaderboard_week",
    )
    assert_true(
        "FROM public.daily_steps" in source or "JOIN public.daily_steps" in source,
        "weekly RPC must aggregate public.daily_steps",
    )
    assert_true(
        "p_start_date" in source and "p_end_date" in source,
        "weekly RPC must accept an explicit local date range",
    )
    assert_true(
        "p_day" in source and "get_challenge_leaderboard_today" in source,
        "SQL fix must also accept local p_day for today's leaderboard",
    )
    print("ok: weekly/today leaderboard SQL reads daily_steps with local date params")


def check_challenge_service_client() -> None:
    source = CHALLENGE_SERVICE.read_text(encoding="utf-8")

    weekly_fn = re.search(
        r"private func getWeeklyLeaderboardFromSupabase\([\s\S]*?\n    \}",
        source,
    )
    assert_true(weekly_fn is not None, "getWeeklyLeaderboardFromSupabase must exist")
    weekly_body = weekly_fn.group(0)

    assert_true(
        'rpc("get_challenge_leaderboard_week"' in weekly_body
        or 'rpc("get_challenge_leaderboard_week"' in weekly_body.replace(" ", ""),
        "weekly leaderboard must call get_challenge_leaderboard_week RPC",
    )
    assert_true(
        "member.dailySteps" not in weekly_body,
        "weekly leaderboard must not sum challenge_members.dailySteps JSONB",
    )
    assert_true(
        '.from("challenge_members")' not in weekly_body,
        "weekly leaderboard must not select challenge_members for step totals",
    )

    daily_fn = re.search(
        r"private func getDailyLeaderboardFromSupabase\([\s\S]*?\n    \}",
        source,
    )
    assert_true(daily_fn is not None, "getDailyLeaderboardFromSupabase must exist")
    daily_body = daily_fn.group(0)
    assert_true(
        '"p_day"' in daily_body or "p_day" in daily_body,
        "daily leaderboard must pass local p_day to get_challenge_leaderboard_today",
    )
    assert_true(
        "localDayString" in daily_body,
        "daily leaderboard must derive p_day via localDayString",
    )
    assert_true(
        'dateFormat = "yyyy-MM-dd"' in source
        and "formatter.timeZone = calendar.timeZone" in source,
        "localDayString must format yyyy-MM-dd in the calendar time zone",
    )
    print("ok: ChallengeService weekly/daily paths use daily_steps RPCs with local dates")


def main() -> int:
    try:
        demonstrate_dead_jsonb_read()
        check_v2_removes_denorm()
        check_weekly_sql_rpc()
        check_challenge_service_client()
    except AssertionError as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1
    print("weekly-leaderboard: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
