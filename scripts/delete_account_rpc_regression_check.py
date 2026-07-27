#!/usr/bin/env python3
"""Static regression checks for delete_user_account live-schema fix."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIX_SQL = ROOT / "scripts/sql/FIX_DELETE_USER_ACCOUNT_LIVE_SCHEMA.sql"
CANONICAL_SQL = ROOT / "scripts/sql/DELETE_ACCOUNT_FUNCTION.sql"
LEGACY_SQL_MARKERS = ROOT / "scripts/sql"
SETTINGS_VIEW = ROOT / "StepComp/Screens/Settings/SettingsView.swift"
SETTINGS_MODIFIERS = ROOT / "StepComp/Screens/Settings/SettingsViewModifiers.swift"


def fail(msg: str) -> None:
    print(f"delete-account-rpc: FAIL — {msg}", file=sys.stderr)
    sys.exit(1)


def must_contain(text: str, needle: str, label: str) -> None:
    if needle not in text:
        fail(f"{label} missing required snippet: {needle!r}")


def must_not_contain(text: str, needle: str, label: str) -> None:
    if needle in text:
        fail(f"{label} still contains stale snippet: {needle!r}")


def main() -> None:
    for path in (FIX_SQL, CANONICAL_SQL, SETTINGS_VIEW, SETTINGS_MODIFIERS):
        if not path.exists():
            fail(f"missing file {path.relative_to(ROOT)}")

    fix_sql = FIX_SQL.read_text()
    canonical_sql = CANONICAL_SQL.read_text()
    settings = SETTINGS_VIEW.read_text()
    modifiers = SETTINGS_MODIFIERS.read_text()

    for label, sql in (("FIX SQL", fix_sql), ("canonical SQL", canonical_sql)):
        must_contain(sql, "CREATE OR REPLACE FUNCTION public.delete_user_account()", label)
        must_contain(sql, "requester_id = v_user_id OR addressee_id = v_user_id", label)
        must_contain(sql, "DELETE FROM public.notifications", label)
        must_contain(sql, "DELETE FROM public.challenges", label)
        must_contain(sql, "DELETE FROM auth.users", label)
        must_contain(sql, "GRANT EXECUTE ON FUNCTION public.delete_user_account()", label)
        must_not_contain(sql, "WHERE user_id = v_user_id OR friend_id = v_user_id", label)
        must_not_contain(sql, "\\i ", label)

        if not re.search(
            r"SET\s+search_path\s*=\s*public\s*,\s*auth",
            sql,
            flags=re.IGNORECASE,
        ):
            fail(f"{label} must pin search_path to public, auth")

    # Settings must call the RPC and surface failures (not silent TODO).
    must_contain(settings, '.rpc("delete_user_account")', "SettingsView")
    must_contain(settings, "deleteAccountErrorMessage", "SettingsView")
    must_contain(modifiers, "showingDeleteAccountError", "SettingsViewModifiers")
    must_contain(modifiers, "Account Deletion Failed", "SettingsViewModifiers")

    # Guard against reintroducing the legacy friendships columns in other delete scripts.
    stale_hits = []
    for path in LEGACY_SQL_MARKERS.glob("*DELETE*ACCOUNT*.sql"):
        text = path.read_text()
        if "friend_id = v_user_id" in text or "OR friend_id =" in text:
            stale_hits.append(str(path.relative_to(ROOT)))
    if stale_hits:
        fail(f"stale friendships columns remain in: {', '.join(stale_hits)}")

    print("delete-account-rpc: ok")


if __name__ == "__main__":
    main()
