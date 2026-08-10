#!/usr/bin/env python3
"""Regression checks for weight bulk-sync order / profiles.weight corruption.

Static checks always run. Optional live probe (default on) documents the open
hole until FIX_SYNC_WEIGHT_ENTRY_LATEST_PROFILE.sql is deployed; after deploy
the live probe should pass.

Usage:
  python3 scripts/weight_sync_order_regression_check.py
  WEIGHT_SYNC_LIVE_PROBE=0 python3 scripts/weight_sync_order_regression_check.py
"""

from __future__ import annotations

import json
import os
import re
import sys
import uuid
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIX_SQL = ROOT / "scripts/sql/FIX_SYNC_WEIGHT_ENTRY_LATEST_PROFILE.sql"
CREATE_SQL = ROOT / "scripts/sql/CREATE_USER_METRICS_TABLES.sql"
METRICS_SWIFT = ROOT / "StepComp/Services/MetricsService.swift"

DEFAULT_URL = "https://cwrirmowykxajumjokjj.supabase.co"
DEFAULT_ANON = "sb_publishable_sfIAdMwGWCg81LZo_HuNVA_BnMXHA-A"


def fail(msg: str) -> None:
    print(f"weight-sync-order: FAIL — {msg}", file=sys.stderr)
    sys.exit(1)


def must_contain(text: str, needle: str, label: str) -> None:
    if needle not in text:
        fail(f"{label} missing required snippet: {needle!r}")


def executable_sql(text: str) -> str:
    return "\n".join(
        line for line in text.splitlines() if not line.lstrip().startswith("--")
    )


def check_static() -> None:
    for path in (FIX_SQL, CREATE_SQL, METRICS_SWIFT):
        if not path.exists():
            fail(f"missing file {path.relative_to(ROOT)}")

    fix_sql = FIX_SQL.read_text()
    create_sql = CREATE_SQL.read_text()
    metrics = METRICS_SWIFT.read_text()
    fix_exec = executable_sql(fix_sql)
    create_exec = executable_sql(create_sql)

    must_contain(fix_sql, "CREATE OR REPLACE FUNCTION public.sync_weight_entry", "FIX SQL")
    must_contain(fix_exec, "recorded_on > p_date", "FIX SQL")
    must_contain(fix_exec, "NOT EXISTS", "FIX SQL")

    # Canonical create script must carry the same profile guard.
    sync_fn = create_exec.split("CREATE OR REPLACE FUNCTION public.sync_weight_entry", 1)[-1]
    sync_fn = sync_fn.split("CREATE OR REPLACE FUNCTION", 1)[0]
    must_contain(sync_fn, "recorded_on > p_date", "CREATE SQL sync_weight_entry")
    must_contain(sync_fn, "NOT EXISTS", "CREATE SQL sync_weight_entry")
    if re.search(
        r"UPDATE public\.profiles\s+SET weight = p_weight_kg::INT\s+WHERE id = v_user_id\s*;",
        sync_fn,
        flags=re.IGNORECASE,
    ):
        fail("CREATE SQL still unconditionally updates profiles.weight")

    # Client bulk catch-up must sort oldest→newest before syncing.
    bulk = metrics.split("func syncAllLocalData()", 1)[-1].split(
        "func fetchMetricsSummary", 1
    )[0]
    if ".sorted { $0.date < $1.date }" not in bulk and ".sorted(by: { $0.date < $1.date })" not in bulk:
        fail("MetricsService.syncAllLocalData must sort unsynced weight entries oldest-first")
    if "localDayKey(for:" not in bulk:
        fail("MetricsService bulk weight payload must use localDayKey")
    must_contain(metrics, "private static func localDayKey(for date: Date)", "MetricsService")

    print("weight-sync-order: static ok")


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
    email = f"weight-order-probe-{uuid.uuid4().hex[:12]}@example.com"
    password = f"Probe-{uuid.uuid4().hex}!Aa1"

    status, auth = http_json(
        "POST",
        f"{base}/auth/v1/signup",
        anon=anon,
        body={"email": email, "password": password},
    )
    if status != 200 or not isinstance(auth, dict) or not auth.get("access_token"):
        # Some projects return sessionless signup; fall back to password grant.
        status, auth = http_json(
            "POST",
            f"{base}/auth/v1/token?grant_type=password",
            anon=anon,
            body={"email": email, "password": password},
        )
        if status != 200 or not isinstance(auth, dict) or not auth.get("access_token"):
            fail(f"live signup/token failed: {status} {auth!r}")

    token = auth["access_token"]
    user = auth.get("user") if isinstance(auth.get("user"), dict) else {}
    user_id = user.get("id")

    status, batch = http_json(
        "POST",
        f"{base}/rest/v1/rpc/sync_weight_entries_batch",
        anon=anon,
        token=token,
        body={"p_entries": []},
    )
    if status not in (404, 200):
        # Unexpected, but not the regression under test.
        print(f"weight-sync-order: note batch rpc status={status} body={batch!r}")

    # Newest-first order (bug trigger): later day then earlier day.
    for day, kg in (("2026-08-09", 82), ("2026-08-01", 80)):
        status, body = http_json(
            "POST",
            f"{base}/rest/v1/rpc/sync_weight_entry",
            anon=anon,
            token=token,
            body={"p_date": day, "p_weight_kg": kg, "p_source": "manual"},
        )
        if status != 200:
            fail(f"sync_weight_entry({day}, {kg}) failed: {status} {body!r}")

    profile_url = f"{base}/rest/v1/profiles?select=weight"
    if user_id:
        profile_url += f"&id=eq.{user_id}"
    status, rows = http_json("GET", profile_url, anon=anon, token=token)
    if status != 200 or not isinstance(rows, list) or not rows:
        fail(f"profiles read failed: {status} {rows!r}")

    profile_weight = rows[0].get("weight")
    if profile_weight != 82:
        fail(
            "live still stamps profiles.weight from older synced day "
            f"(profiles.weight={profile_weight}, expected 82); "
            "deploy scripts/sql/FIX_SYNC_WEIGHT_ENTRY_LATEST_PROFILE.sql"
        )

    print("weight-sync-order: live ok")


def main() -> None:
    check_static()
    if os.environ.get("WEIGHT_SYNC_LIVE_PROBE", "1") != "0":
        check_live()
    else:
        print("weight-sync-order: live probe skipped")
    print("weight-sync-order: ok")


if __name__ == "__main__":
    main()
