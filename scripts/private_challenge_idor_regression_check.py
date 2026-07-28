#!/usr/bin/env python3
"""Static regression checks for private challenge membership/leaderboard IDOR fix."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIX_SQL = ROOT / "scripts/sql/FIX_PRIVATE_CHALLENGE_MEMBERSHIP_AND_LEADERBOARD_IDOR.sql"
V2_SQL = ROOT / "scripts/sql/IMPLEMENT_SECURITY_OVERHAUL_V2_SAFE.sql"
CHALLENGE_SERVICE = ROOT / "StepComp/Services/ChallengeService.swift"


def fail(msg: str) -> None:
    print(f"private-challenge-idor: FAIL — {msg}", file=sys.stderr)
    sys.exit(1)


def must_contain(text: str, needle: str, label: str) -> None:
    if needle not in text:
        fail(f"{label} missing required snippet: {needle!r}")


def must_not_contain(text: str, needle: str, label: str) -> None:
    if needle in text:
        fail(f"{label} still contains stale snippet: {needle!r}")


def main() -> None:
    for path in (FIX_SQL, V2_SQL, CHALLENGE_SERVICE):
        if not path.exists():
            fail(f"missing file {path.relative_to(ROOT)}")

    fix_sql = FIX_SQL.read_text()
    v2_sql = V2_SQL.read_text()
    challenge_service = CHALLENGE_SERVICE.read_text()

    # Membership INSERT must require self + (public | creator | pending invite).
    must_contain(fix_sql, "Insert own membership when allowed", "FIX SQL")
    must_contain(fix_sql, "user_id = auth.uid()", "FIX SQL")
    must_contain(fix_sql, "c.is_public = TRUE", "FIX SQL")
    must_contain(fix_sql, "c.created_by = auth.uid()", "FIX SQL")
    must_contain(fix_sql, "challenge_invites", "FIX SQL")
    must_contain(fix_sql, "ci.status = 'pending'", "FIX SQL")
    must_contain(fix_sql, 'DROP POLICY IF EXISTS "Creators can add members"', "FIX SQL")
    must_not_contain(
        fix_sql,
        'CREATE POLICY "Creators can add members"',
        "FIX SQL",
    )
    must_not_contain(
        fix_sql,
        'CREATE POLICY "Insert own membership"\n  ON challenge_members FOR INSERT\n  WITH CHECK (user_id = auth.uid());',
        "FIX SQL",
    )

    # Leaderboard RPCs must gate on access_check and avoid is_suspicious dependency.
    for fn in (
        "get_challenge_leaderboard(p_challenge_id UUID)",
        "get_challenge_leaderboard_today(p_challenge_id UUID)",
    ):
        must_contain(fix_sql, fn, "FIX SQL")

    if fix_sql.count("WITH access_check AS") < 2:
        fail("FIX SQL must define access_check for all-time and today leaderboards")

    must_contain(fix_sql, "AND EXISTS (SELECT 1 FROM access_check)", "FIX SQL")
    # Executable SQL must not filter on is_suspicious (column is not live).
    executable_sql = "\n".join(
        line for line in fix_sql.splitlines() if not line.lstrip().startswith("--")
    )
    if "is_suspicious" in executable_sql:
        fail("FIX SQL executable body must not reference is_suspicious")

    # Canonical V2 overhaul must not reintroduce open private self-join / force-enroll.
    must_contain(v2_sql, "Insert own membership when allowed", "V2 SQL")
    must_contain(v2_sql, "challenge_invites", "V2 SQL")
    must_not_contain(v2_sql, 'CREATE POLICY "Creators can add members"', "V2 SQL")
    if re.search(
        r'CREATE POLICY "Insert own membership"\s+ON challenge_members FOR INSERT\s+WITH CHECK \(user_id = auth\.uid\(\)\);',
        v2_sql,
    ):
        fail("V2 SQL still has unrestricted Insert own membership policy")

    # Client defense-in-depth before direct membership insert.
    must_contain(
        challenge_service,
        "remoteChallenge.isPublic || remoteChallenge.createdBy == userId",
        "ChallengeService",
    )
    must_contain(challenge_service, "accept_challenge_invite", "ChallengeService")

    print("private-challenge-idor: ok")


if __name__ == "__main__":
    main()
