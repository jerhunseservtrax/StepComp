#!/usr/bin/env python3
"""Regression check: step-history + waitlist RPC IDORs are closed.

Expects FIX_STEP_HISTORY_AND_WAITLIST_RPC_IDOR.sql to be deployed for
live assertions to pass. Static checks validate the fix SQL is present.

Usage:
  SUPABASE_URL=https://xxx.supabase.co \\
  SUPABASE_ANON_KEY=sb_publishable_... \\
  python3 scripts/step_history_waitlist_rpc_idor_regression_check.py

Creates temporary users and asserts:
  - Stranger cannot read another user's daily_steps via get_user_step_history
  - Self can still read own step history via the same RPC
  - Direct daily_steps SELECT remains self-scoped
  - Authenticated clients cannot list waitlist emails via
    get_recent_waitlist_signups
"""

from __future__ import annotations

import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path


def load_defaults() -> tuple[str, str]:
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_ANON_KEY")
    if url and key:
        return url.rstrip("/"), key
    swift = Path(__file__).resolve().parents[1] / "StepComp/Services/SupabaseClient.swift"
    text = swift.read_text()
    url = re.search(r'supabaseURL = "([^"]+)"', text).group(1)
    key = re.search(r'supabaseAnonKey = "([^"]+)"', text).group(1)
    return url.rstrip("/"), key


BASE, ANON = load_defaults()
ROOT = Path(__file__).resolve().parents[1]
FIX_SQL = ROOT / "scripts/sql/FIX_STEP_HISTORY_AND_WAITLIST_RPC_IDOR.sql"


def req(method: str, path: str, token: str, body=None):
    data = None if body is None else json.dumps(body).encode()
    headers = {
        "apikey": ANON,
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    request = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request) as resp:
            return resp.status, resp.read().decode()
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read().decode()


def signup(email: str, password: str) -> tuple[str, str]:
    code, raw = req("POST", "/auth/v1/signup", ANON, {"email": email, "password": password})
    if code not in (200, 201):
        raise RuntimeError(f"signup failed {code}: {raw}")
    payload = json.loads(raw)
    return payload["access_token"], payload["user"]["id"]


def static_checks() -> list[str]:
    failures: list[str] = []
    if not FIX_SQL.exists():
        return [f"missing fix SQL: {FIX_SQL}"]
    text = FIX_SQL.read_text()
    required = [
        "get_user_step_history",
        "ds.user_id = auth.uid()",
        "p_user_id IS NULL OR p_user_id = auth.uid()",
        "get_recent_waitlist_signups",
        "auth.role() IS DISTINCT FROM 'service_role'",
        "REVOKE ALL ON FUNCTION public.get_recent_waitlist_signups",
        "GRANT EXECUTE ON FUNCTION public.get_recent_waitlist_signups(INTEGER) TO service_role",
        "FALSE AS is_suspicious",
    ]
    for needle in required:
        if needle not in text:
            failures.append(f"fix SQL missing required fragment: {needle}")
    # Footgun guard: must not SELECT a non-existent column from daily_steps
    if re.search(r"ds\.is_suspicious|daily_steps\.is_suspicious", text):
        failures.append("fix SQL must not read daily_steps.is_suspicious (column absent on live)")
    return failures


def main() -> int:
    failures = static_checks()
    if failures:
        for item in failures:
            print(f"FAIL static: {item}")
        print("STATIC CHECKS FAILED")
        return 1
    print("PASS: static fix SQL contains self-scope + service_role waitlist guards")

    stamp = int(time.time())
    password = "ProbeTest!23456"
    tok_a, uid_a = signup(f"stephist_{stamp}_a@example.com", password)
    tok_b, uid_b = signup(f"stephist_{stamp}_b@example.com", password)
    day = time.strftime("%Y-%m-%d")

    code, raw = req(
        "POST",
        "/rest/v1/rpc/sync_daily_steps",
        tok_a,
        {"p_steps": 4321, "p_day": day, "p_source": "regression"},
    )
    if code != 200:
        raise RuntimeError(f"sync_daily_steps failed {code}: {raw}")
    print("PASS: user A synced daily steps")

    # Direct table SELECT must stay RLS-scoped
    code, raw = req(
        "GET",
        f"/rest/v1/daily_steps?select=user_id,day,steps&user_id=eq.{uid_a}",
        tok_b,
    )
    rows = json.loads(raw) if code == 200 else None
    if code == 200 and rows:
        failures.append(f"direct daily_steps cross-user SELECT leaked: {rows}")
        print("FAIL: stranger can SELECT another user's daily_steps rows")
    else:
        print("PASS: stranger cannot SELECT another user's daily_steps rows")

    # Cross-user RPC must not return victim steps after fix
    code, raw = req(
        "POST",
        "/rest/v1/rpc/get_user_step_history",
        tok_b,
        {"p_user_id": uid_a, "p_start_date": day, "p_end_date": day},
    )
    if code == 200:
        try:
            hist = json.loads(raw)
        except json.JSONDecodeError:
            hist = raw
        if isinstance(hist, list) and any(
            isinstance(row, dict) and row.get("steps") == 4321 for row in hist
        ):
            failures.append("get_user_step_history leaked victim steps to stranger")
            print("FAIL: stranger can read victim step history via RPC (deploy fix SQL)")
        elif isinstance(hist, list) and len(hist) == 0:
            print("PASS: stranger get_user_step_history returns empty")
        else:
            failures.append(f"unexpected cross-user history response {code}: {raw[:200]}")
            print("FAIL: unexpected cross-user history response")
    else:
        # Hard deny is also acceptable
        print(f"PASS: stranger get_user_step_history denied ({code})")

    # Self-read must still work
    code, raw = req(
        "POST",
        "/rest/v1/rpc/get_user_step_history",
        tok_a,
        {"p_user_id": uid_a, "p_start_date": day, "p_end_date": day},
    )
    if code != 200:
        failures.append(f"self history failed {code}: {raw[:200]}")
        print("FAIL: self cannot read own step history")
    else:
        hist = json.loads(raw)
        if not any(isinstance(row, dict) and row.get("steps") == 4321 for row in hist):
            failures.append(f"self history missing synced steps: {raw[:200]}")
            print("FAIL: self history missing synced steps")
        else:
            print("PASS: self can read own step history")

    # Waitlist email listing must not be available to authenticated clients
    code, raw = req(
        "POST",
        "/rest/v1/rpc/get_recent_waitlist_signups",
        tok_b,
        {"limit_count": 1},
    )
    leaked = False
    if code == 200:
        try:
            payload = json.loads(raw)
        except json.JSONDecodeError:
            payload = None
        if isinstance(payload, list) and payload:
            # Do not print waitlist PII into logs.
            leaked = any(isinstance(row, dict) and "email" in row for row in payload)
    if leaked or (code == 200 and isinstance(payload, list) and len(payload) > 0):
        failures.append("get_recent_waitlist_signups still returns rows to authenticated clients")
        print("FAIL: authenticated client can list waitlist signups (deploy fix SQL)")
    else:
        print(f"PASS: authenticated waitlist signup listing blocked ({code})")

    if failures:
        print("\nLIVE CHECKS FAILED (fix SQL likely not deployed yet):")
        for item in failures:
            print(f" - {item}")
        return 1

    print("\nALL CHECKS PASSED")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # noqa: BLE001 - CLI surface
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(2)
