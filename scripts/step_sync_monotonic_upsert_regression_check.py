#!/usr/bin/env python3
"""Regression checks for sync_daily_steps monotonic (GREATEST) upsert fix.

Static checks always run. Optional live probe (default on) documents the open
hole until FIX_SYNC_DAILY_STEPS_MONOTONIC_UPSERT.sql is deployed; after deploy
the live probe should pass.

Usage:
  python3 scripts/step_sync_monotonic_upsert_regression_check.py
  STEP_SYNC_LIVE_PROBE=0 python3 scripts/step_sync_monotonic_upsert_regression_check.py
"""

from __future__ import annotations

import json
import os
import re
import sys
import uuid
import urllib.error
import urllib.request
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIX_SQL = ROOT / "scripts/sql/FIX_SYNC_DAILY_STEPS_MONOTONIC_UPSERT.sql"
V2_SQL = ROOT / "scripts/sql/IMPLEMENT_SECURITY_OVERHAUL_V2_SAFE.sql"
V1_SQL = ROOT / "scripts/sql/IMPLEMENT_SECURITY_OVERHAUL.sql"

DEFAULT_URL = "https://cwrirmowykxajumjokjj.supabase.co"
# Publishable anon key already present in StepComp/Services/SupabaseClient.swift
DEFAULT_ANON = "sb_publishable_sfIAdMwGWCg81LZo_HuNVA_BnMXHA-A"


def fail(msg: str) -> None:
    print(f"step-sync-monotonic-upsert: FAIL — {msg}", file=sys.stderr)
    sys.exit(1)


def must_contain(text: str, needle: str, label: str) -> None:
    if needle not in text:
        fail(f"{label} missing required snippet: {needle!r}")


def executable_sql(text: str) -> str:
    return "\n".join(
        line for line in text.splitlines() if not line.lstrip().startswith("--")
    )


def check_static() -> None:
    for path in (FIX_SQL, V2_SQL, V1_SQL):
        if not path.exists():
            fail(f"missing file {path.relative_to(ROOT)}")

    fix_sql = FIX_SQL.read_text()
    v2_sql = V2_SQL.read_text()
    v1_sql = V1_SQL.read_text()
    fix_exec = executable_sql(fix_sql)

    must_contain(fix_sql, "CREATE OR REPLACE FUNCTION public.sync_daily_steps", "FIX SQL")
    must_contain(fix_exec, "GREATEST(daily_steps.steps, EXCLUDED.steps)", "FIX SQL")
    must_contain(fix_exec, "last_synced_at", "FIX SQL")
    must_contain(fix_exec, "v_accepted_steps", "FIX SQL")
    must_contain(fix_exec, "last_synced_at = NOW()", "FIX SQL")

    # Live deploy script must not write absent daily_steps columns.
    # Response JSON may still include an is_suspicious *flag* (v_is_suspicious).
    insert_block = fix_exec.split("INSERT INTO public.daily_steps", 1)[-1].split(
        "ON CONFLICT (user_id, day)", 1
    )[0]
    conflict_block = fix_exec.split("ON CONFLICT (user_id, day)", 1)[-1].split(
        "UPDATE public.profiles", 1
    )[0]
    if re.search(r"\bis_suspicious\b", insert_block) or re.search(
        r"\bis_suspicious\b", conflict_block
    ):
        fail("FIX SQL must not INSERT/UPDATE daily_steps.is_suspicious (column not live)")
    if "updated_at" in conflict_block:
        fail("FIX SQL conflict update must not set daily_steps.updated_at")

    # Stale last-write-wins assignment must be gone from canonical sources.
    for label, text in (("V2 SQL", v2_sql), ("V1 SQL", v1_sql), ("FIX SQL", fix_sql)):
        exec_text = executable_sql(text)
        if re.search(r"steps\s*=\s*p_steps\b", exec_text):
            fail(f"{label} still has last-write-wins steps = p_steps")
        must_contain(exec_text, "GREATEST(daily_steps.steps, EXCLUDED.steps)", label)

    print("step-sync-monotonic-upsert: static ok")


def http_json(
    method: str,
    url: str,
    *,
    anon: str,
    token: str | None = None,
    body: dict | None = None,
) -> tuple[int, object]:
    headers = {
        "apikey": anon,
        "Authorization": f"Bearer {token or anon}",
        "Content-Type": "application/json",
    }
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read().decode()
            return resp.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try:
            payload = json.loads(raw) if raw else None
        except json.JSONDecodeError:
            payload = raw
        return e.code, payload


def check_live() -> None:
    base = os.environ.get("SUPABASE_URL", DEFAULT_URL).rstrip("/")
    anon = os.environ.get("SUPABASE_ANON_KEY", DEFAULT_ANON)
    email = f"monotonic-probe-{uuid.uuid4().hex[:12]}@example.com"
    password = f"Probe-{uuid.uuid4().hex}!Aa1"

    status, auth = http_json(
        "POST",
        f"{base}/auth/v1/signup",
        anon=anon,
        body={"email": email, "password": password},
    )
    if status != 200 or not isinstance(auth, dict) or not auth.get("access_token"):
        fail(f"live signup failed: {status} {auth!r}")

    token = auth["access_token"]
    today = date.today().isoformat()

    status, high = http_json(
        "POST",
        f"{base}/rest/v1/rpc/sync_daily_steps",
        anon=anon,
        token=token,
        body={
            "p_day": today,
            "p_steps": 12000,
            "p_source": "regression",
            "p_device_id": "monotonic-check",
            "p_user_agent": "regression",
        },
    )
    if status != 200:
        fail(f"high sync failed: {status} {high!r}")

    status, low = http_json(
        "POST",
        f"{base}/rest/v1/rpc/sync_daily_steps",
        anon=anon,
        token=token,
        body={
            "p_day": today,
            "p_steps": 3000,
            "p_source": "regression",
            "p_device_id": "monotonic-check",
            "p_user_agent": "regression",
        },
    )
    if status != 200:
        fail(f"low sync failed: {status} {low!r}")

    status, rows = http_json(
        "GET",
        f"{base}/rest/v1/daily_steps?select=steps&day=eq.{today}",
        anon=anon,
        token=token,
    )
    if status != 200 or not isinstance(rows, list) or not rows:
        fail(f"daily_steps read failed: {status} {rows!r}")

    stored = rows[0].get("steps")
    accepted = None
    if isinstance(low, dict):
        accepted = low.get("accepted_steps")

    if stored != 12000 or accepted != 12000:
        fail(
            "live still last-write-wins "
            f"(stored={stored}, accepted_steps={accepted}); "
            "deploy scripts/sql/FIX_SYNC_DAILY_STEPS_MONOTONIC_UPSERT.sql"
        )

    # Ascending sync must still advance
    status, mid = http_json(
        "POST",
        f"{base}/rest/v1/rpc/sync_daily_steps",
        anon=anon,
        token=token,
        body={
            "p_day": today,
            "p_steps": 15000,
            "p_source": "regression",
            "p_device_id": "monotonic-check",
            "p_user_agent": "regression",
        },
    )
    if status != 200:
        fail(f"ascending sync failed: {status} {mid!r}")

    status, rows = http_json(
        "GET",
        f"{base}/rest/v1/daily_steps?select=steps&day=eq.{today}",
        anon=anon,
        token=token,
    )
    if status != 200 or not isinstance(rows, list) or rows[0].get("steps") != 15000:
        fail(f"ascending sync did not advance stored steps: {rows!r}")

    print("step-sync-monotonic-upsert: live ok")


def main() -> None:
    check_static()
    live = os.environ.get("STEP_SYNC_LIVE_PROBE", "1") != "0"
    if live:
        check_live()
    else:
        print("step-sync-monotonic-upsert: live probe skipped")
    print("step-sync-monotonic-upsert: ok")


if __name__ == "__main__":
    main()
