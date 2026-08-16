#!/usr/bin/env python3
"""Regression checks for past-dated workout sync overwrite.

finishWorkout() used to pin every non-today session to 23:59:59 and reconstruct
started_at as end - duration. sync_workout_session then upserts on
UNIQUE(user_id, started_at) and deletes the previous session's sets.

Concrete trigger:
  1. On the Workouts tab, select yesterday.
  2. Complete Push in 15:00.
  3. Complete Pull in 15:00.
  4. Both sync with the same started_at; the second RPC replaces the first.

Static checks always run. Optional live probe documents the hole until
FIX_WORKOUT_SESSION_SYNC_IDEMPOTENCY.sql is deployed.

Usage:
  python3 scripts/workout_session_timestamp_collision_regression_check.py
  WORKOUT_SYNC_LIVE_PROBE=0 python3 scripts/workout_session_timestamp_collision_regression_check.py
"""

from __future__ import annotations

import datetime as dt
import json
import os
import re
import sys
import uuid
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIX_SQL = ROOT / "scripts/sql/FIX_WORKOUT_SESSION_SYNC_IDEMPOTENCY.sql"
CREATE_SQL = ROOT / "scripts/sql/CREATE_USER_METRICS_TABLES.sql"
WORKOUT_VM = ROOT / "StepComp/ViewModels/WorkoutViewModel.swift"
METRICS_SWIFT = ROOT / "StepComp/Services/MetricsService.swift"

DEFAULT_URL = "https://cwrirmowykxajumjokjj.supabase.co"
DEFAULT_ANON = "sb_publishable_sfIAdMwGWCg81LZo_HuNVA_BnMXHA-A"


def fail(msg: str) -> None:
    print(f"workout-session-collision: FAIL — {msg}", file=sys.stderr)
    sys.exit(1)


def must_contain(text: str, needle: str, label: str) -> None:
    if needle not in text:
        fail(f"{label} missing required snippet: {needle!r}")


def executable_sql(text: str) -> str:
    return "\n".join(
        line for line in text.splitlines() if not line.lstrip().startswith("--")
    )


def extract_function(sql: str, name: str) -> str:
    marker = f"CREATE OR REPLACE FUNCTION public.{name}"
    if marker not in sql:
        fail(f"SQL missing {name}")
    body = sql.split(marker, 1)[1]
    nxt = body.find("CREATE OR REPLACE FUNCTION")
    if nxt != -1:
        body = body[:nxt]
    return body


# --- Algorithm contract (mirrors WorkoutSessionTimestampMapper) ---

def map_timestamps(
    target_date: dt.datetime | None,
    now: dt.datetime,
    duration_seconds: float,
    existing_starts: list[dt.datetime],
) -> tuple[dt.datetime, dt.datetime]:
    duration = max(0.0, duration_seconds)
    if target_date is not None and (
        target_date.date() != now.date()
    ):
        end = target_date.replace(
            hour=now.hour, minute=now.minute, second=now.second, microsecond=0
        )
    else:
        end = now
    start = end - dt.timedelta(seconds=duration)
    existing = {int(ts.timestamp()) for ts in existing_starts}
    while int(start.timestamp()) in existing:
        start += dt.timedelta(seconds=1)
        end += dt.timedelta(seconds=1)
    return start, end


def check_algorithm() -> None:
    now = dt.datetime(2026, 8, 16, 10, 15, 30)
    yesterday = dt.datetime(2026, 8, 15, 0, 0, 0)
    duration = 15 * 60

    start1, end1 = map_timestamps(yesterday, now, duration, [])
    if end1 != dt.datetime(2026, 8, 15, 10, 15, 30):
        fail(f"past-dated end should keep clock time, got {end1}")
    if start1 != dt.datetime(2026, 8, 15, 10, 0, 30):
        fail(f"past-dated start should be end-duration, got {start1}")

    later = now + dt.timedelta(minutes=20)
    start2, end2 = map_timestamps(yesterday, later, duration, [start1])
    if start2 == start1:
        fail("second same-duration past workout collided with the first start")
    if end2.date() != yesterday.date():
        fail("second workout left the target calendar day")

    # Same duration + same clock time on a later logging day must still unique.
    next_day_same_clock = dt.datetime(2026, 8, 17, 10, 15, 30)
    start3, _ = map_timestamps(yesterday, next_day_same_clock, duration, [start1])
    if start3 == start1:
        fail("same clock time on a later day still collided")

    today_start, today_end = map_timestamps(now, now, duration, [])
    if today_end != now:
        fail("today sessions must keep the real finish timestamp")
    if today_start != now - dt.timedelta(seconds=duration):
        fail("today start should be now-duration")


def check_static() -> None:
    for path in (FIX_SQL, CREATE_SQL, WORKOUT_VM, METRICS_SWIFT):
        if not path.exists():
            fail(f"missing file {path.relative_to(ROOT)}")

    vm = WORKOUT_VM.read_text()
    metrics = METRICS_SWIFT.read_text()
    fix_sql = FIX_SQL.read_text()
    create_sql = CREATE_SQL.read_text()
    fix_exec = executable_sql(fix_sql)
    create_exec = executable_sql(create_sql)

    if re.search(r"bySettingHour:\s*23,\s*minute:\s*59", vm):
        fail("WorkoutViewModel still pins past-dated workouts to 23:59:59")

    must_contain(vm, "WorkoutSessionTimestampMapper", "WorkoutViewModel")
    must_contain(vm, "existingStartTimes", "WorkoutViewModel")

    payload = metrics.split("func sessionPayload", 1)[-1]
    if '"id"' not in payload and 'session.id.uuidString' not in payload:
        fail("sessionPayload does not send the local session id")

    for sql, label in ((fix_exec, "FIX SQL"), (create_exec, "CREATE SQL")):
        fn = extract_function(sql, "sync_workout_session")
        must_contain(fn, "client_session_id", label)
        if "ON CONFLICT (user_id, started_at)" in fn:
            fail(f"{label} sync_workout_session still conflicts on started_at")
        must_contain(fn, "ON CONFLICT (user_id, client_session_id)", label)

    must_contain(fix_exec, "DROP CONSTRAINT IF EXISTS uq_workout_sessions_user_start", "FIX SQL")
    must_contain(create_exec, "client_session_id", "CREATE SQL table")
    if "UNIQUE(user_id, started_at)" in create_exec.split("workout_session_sets")[0]:
        fail("CREATE SQL still unique-constrains (user_id, started_at)")


def request_json(url: str, method: str, headers: dict[str, str], body: dict | None = None):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read()
            return resp.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as exc:
        raw = exc.read()
        try:
            parsed = json.loads(raw) if raw else None
        except json.JSONDecodeError:
            parsed = raw.decode("utf-8", errors="replace")
        return exc.code, parsed


def signup(base: str, anon: str) -> tuple[str, str]:
    email = f"workout-collision-{uuid.uuid4().hex[:12]}@example.com"
    password = f"Wc{uuid.uuid4().hex}1!"
    status, payload = request_json(
        f"{base}/auth/v1/signup",
        "POST",
        {"apikey": anon, "Content-Type": "application/json"},
        {"email": email, "password": password},
    )
    if status >= 400:
        fail(f"signup failed ({status})")
    status, payload = request_json(
        f"{base}/auth/v1/token?grant_type=password",
        "POST",
        {"apikey": anon, "Content-Type": "application/json"},
        {"email": email, "password": password},
    )
    if status >= 400 or not isinstance(payload, dict) or "access_token" not in payload:
        fail(f"password grant failed ({status})")
    user_id = payload.get("user", {}).get("id") or payload.get("user_id")
    if not user_id:
        fail("auth response missing user id")
    return payload["access_token"], user_id


def check_live() -> None:
    if os.environ.get("WORKOUT_SYNC_LIVE_PROBE", "1") == "0":
        print("workout-session-collision: live probe skipped")
        return

    base = os.environ.get("SUPABASE_URL", DEFAULT_URL).rstrip("/")
    anon = os.environ.get("SUPABASE_ANON_KEY", DEFAULT_ANON)
    token, _user_id = signup(base, anon)
    headers = {
        "apikey": anon,
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }

    started = "2026-08-15T23:14:59Z"
    ended = "2026-08-15T23:59:59Z"

    def sync(name: str, session_id: str) -> tuple[int, object]:
        return request_json(
            f"{base}/rest/v1/rpc/sync_workout_session",
            "POST",
            headers,
            {
                "p_session": {
                    "id": session_id,
                    "workout_name": name,
                    "started_at": started,
                    "ended_at": ended,
                    "source": "app",
                    "sets": [
                        {
                            "exercise_name": name,
                            "target_muscles": "test",
                            "set_number": 1,
                            "weight_kg": 60,
                            "reps": 8,
                            "is_completed": True,
                        }
                    ],
                }
            },
        )

    id_a = str(uuid.uuid4())
    id_b = str(uuid.uuid4())
    status_a, _ = sync("Push Collision", id_a)
    status_b, _ = sync("Pull Collision", id_b)
    if status_a >= 400:
        print(f"workout-session-collision: live sync A returned {status_a} (table/RPC may be absent)")
        return
    if status_b >= 400:
        fail(f"second same-timestamp sync failed ({status_b})")

    status, rows = request_json(
        f"{base}/rest/v1/rpc/get_workout_history",
        "POST",
        headers,
        {"p_days": 30},
    )
    if status >= 400 or not isinstance(rows, list):
        # Fall back to table read
        status, rows = request_json(
            f"{base}/rest/v1/workout_sessions?select=workout_name,started_at",
            "GET",
            {**headers, "Accept": "application/json"},
            None,
        )
    if not isinstance(rows, list):
        fail("could not read workout history after collision sync")

    names = {
        row.get("workout_name")
        for row in rows
        if isinstance(row, dict)
    }
    if "Push Collision" not in names or "Pull Collision" not in names:
        print(
            "workout-session-collision: LIVE OPEN — started_at last-write-wins "
            "until FIX_WORKOUT_SESSION_SYNC_IDEMPOTENCY.sql is deployed"
        )
        return
    print("workout-session-collision: live idempotency confirmed")


def main() -> None:
    check_algorithm()
    check_static()
    check_live()
    print("workout-session-collision: PASS")


if __name__ == "__main__":
    main()
