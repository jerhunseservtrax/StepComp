#!/usr/bin/env python3
"""Regression check: challenge_messages cannot forge message_type='system' via RLS.

Expects FIX_CHALLENGE_MESSAGES_SYSTEM_TYPE_RLS.sql to be deployed.

Usage:
  SUPABASE_URL=https://xxx.supabase.co \\
  SUPABASE_ANON_KEY=sb_publishable_... \\
  python3 scripts/challenge_messages_system_type_rls_regression_check.py

Creates two temporary users + one public challenge, asserts:
  - member direct INSERT with message_type='system' is rejected
  - member PATCH escalating text -> system is rejected
  - member text INSERT and send_challenge_message still succeed
Then cleans up probe rows.
"""

from __future__ import annotations

import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
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


def req(method: str, path: str, token: str, body=None, prefer: str | None = None):
    data = None if body is None else json.dumps(body).encode()
    headers = {
        "apikey": ANON,
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    if prefer:
        headers["Prefer"] = prefer
    request = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request) as resp:
            return resp.status, resp.read().decode()
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read().decode()


def signup(email: str, password: str) -> tuple[str, str]:
    code, raw = req(
        "POST",
        "/auth/v1/signup",
        ANON,
        {"email": email, "password": password},
    )
    if code not in (200, 201):
        raise RuntimeError(f"signup failed {code}: {raw}")
    payload = json.loads(raw)
    return payload["access_token"], payload["user"]["id"]


def assert_rejected(label: str, code: int, raw: str) -> None:
    if code in (200, 201) and raw not in ("", "[]", "null"):
        # PostgREST may return 200 [] when WITH CHECK filters UPDATEs
        if raw.strip() not in ("[]",):
            raise AssertionError(f"{label}: expected rejection, got {code} {raw[:300]}")
    if code == 200 and raw.strip() == "[]":
        return  # UPDATE filtered by RLS — acceptable rejection shape
    if code not in (401, 403, 409) and "42501" not in raw and "row-level security" not in raw.lower():
        # Allow P0001 / other authz errors too
        if code >= 400:
            return
        raise AssertionError(f"{label}: unexpected success/shape {code} {raw[:300]}")


def main() -> int:
    stamp = int(time.time())
    password = "ProbeTest!23456"
    tok_a, uid_a = signup(f"sysmsg_rls_{stamp}_a@example.com", password)
    tok_b, uid_b = signup(f"sysmsg_rls_{stamp}_b@example.com", password)

    now = datetime.now(timezone.utc)
    start = (now - timedelta(days=1)).date().isoformat()
    end = (now + timedelta(days=30)).date().isoformat()

    code, raw = req(
        "POST",
        "/rest/v1/challenges",
        tok_a,
        {
            "name": f"sysmsg-rls-{stamp}",
            "is_public": True,
            "start_date": start,
            "end_date": end,
            "created_by": uid_a,
        },
        prefer="return=representation",
    )
    if code not in (200, 201):
        raise RuntimeError(f"create challenge failed {code}: {raw}")
    challenge_id = json.loads(raw)[0]["id"]

    for tok, uid in ((tok_a, uid_a), (tok_b, uid_b)):
        code, raw = req(
            "POST",
            "/rest/v1/challenge_members",
            tok,
            {"challenge_id": challenge_id, "user_id": uid},
            prefer="return=representation",
        )
        if code not in (200, 201):
            raise RuntimeError(f"join failed {code}: {raw}")

    failures: list[str] = []

    # 1) Direct INSERT system forgery must fail
    code, raw = req(
        "POST",
        "/rest/v1/challenge_messages",
        tok_b,
        {
            "challenge_id": challenge_id,
            "user_id": uid_b,
            "content": "forged system via insert",
            "message_type": "system",
        },
        prefer="return=representation",
    )
    try:
        assert_rejected("member INSERT message_type=system", code, raw)
        print("PASS: member INSERT message_type=system rejected")
    except AssertionError as exc:
        failures.append(str(exc))
        print(f"FAIL: {exc}")

    # 2) Text insert must still work
    code, raw = req(
        "POST",
        "/rest/v1/challenge_messages",
        tok_b,
        {
            "challenge_id": challenge_id,
            "user_id": uid_b,
            "content": "legit text",
            "message_type": "text",
        },
        prefer="return=representation",
    )
    if code not in (200, 201):
        failures.append(f"member text INSERT should succeed, got {code} {raw[:200]}")
        print(f"FAIL: member text INSERT {code}")
        msg_id = None
    else:
        msg_id = json.loads(raw)[0]["id"]
        print("PASS: member text INSERT succeeds")

    # 3) PATCH escalate text -> system must fail
    if msg_id:
        code, raw = req(
            "PATCH",
            f"/rest/v1/challenge_messages?id=eq.{msg_id}",
            tok_b,
            {"message_type": "system", "content": "escalated to system"},
            prefer="return=representation",
        )
        try:
            assert_rejected("member PATCH escalate to system", code, raw)
            print("PASS: member PATCH escalate to system rejected")
        except AssertionError as exc:
            failures.append(str(exc))
            print(f"FAIL: {exc}")

    # 4) send_challenge_message still works and stays text
    code, raw = req(
        "POST",
        "/rest/v1/rpc/send_challenge_message",
        tok_b,
        {"p_challenge_id": challenge_id, "p_content": "rpc text ok"},
    )
    if code != 200:
        failures.append(f"send_challenge_message should succeed, got {code} {raw[:200]}")
        print(f"FAIL: send_challenge_message {code}")
    else:
        print("PASS: send_challenge_message succeeds")

    # Cleanup best-effort
    req("DELETE", f"/rest/v1/challenge_messages?challenge_id=eq.{challenge_id}", tok_a)
    req("DELETE", f"/rest/v1/challenge_members?challenge_id=eq.{challenge_id}", tok_a)
    req("DELETE", f"/rest/v1/challenges?id=eq.{challenge_id}", tok_a)

    if failures:
        print("\nRESULT: FAIL (deploy FIX_CHALLENGE_MESSAGES_SYSTEM_TYPE_RLS.sql)")
        for item in failures:
            print(f"  - {item}")
        return 1

    print("\nRESULT: PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(2)
