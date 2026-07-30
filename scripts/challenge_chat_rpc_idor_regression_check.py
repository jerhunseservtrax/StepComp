#!/usr/bin/env python3
"""Regression check for challenge chat / snapshot RPC authorization.

Expects FIX_CHALLENGE_CHAT_SYSTEM_MESSAGE_AND_SNAPSHOT_IDOR.sql to be deployed.

Usage:
  SUPABASE_URL=https://xxx.supabase.co \\
  SUPABASE_ANON_KEY=sb_publishable_... \\
  python3 scripts/challenge_chat_rpc_idor_regression_check.py

Creates two temporary users + one private challenge, asserts:
  - non-member create_system_message is rejected
  - non-member get_challenge_unread_count returns 0
  - non-member snapshot_challenge_results returns [] / unauthorized
  - member create_system_message succeeds
Then cleans up probe rows.
"""

from __future__ import annotations

import json
import os
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
    import re

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


def main() -> int:
    stamp = int(time.time())
    password = "ProbeTest!23456"
    tok_a, uid_a = signup(f"chat_idor_{stamp}_a@example.com", password)
    tok_b, uid_b = signup(f"chat_idor_{stamp}_b@example.com", password)

    for tok, uid, name in ((tok_a, uid_a, "chatA"), (tok_b, uid_b, "chatB")):
        req(
            "POST",
            "/rest/v1/profiles",
            tok,
            {
                "id": uid,
                "username": f"{name}{uid[:8]}",
                "display_name": name,
                "daily_step_goal": 10000,
            },
            prefer="resolution=merge-duplicates,return=minimal",
        )

    now = datetime.now(timezone.utc)
    code, raw = req(
        "POST",
        "/rest/v1/challenges",
        tok_a,
        {
            "name": "CHAT_IDOR_PROBE_DELETE_ME",
            "description": "regression probe",
            "is_public": False,
            "created_by": uid_a,
            "start_date": now.isoformat().replace("+00:00", "Z"),
            "end_date": (now + timedelta(days=3)).isoformat().replace("+00:00", "Z"),
            "category": "friends",
        },
        prefer="return=representation",
    )
    if code not in (200, 201):
        raise RuntimeError(f"create challenge failed {code}: {raw}")
    challenge_id = json.loads(raw)[0]["id"]

    req(
        "POST",
        "/rest/v1/challenge_members",
        tok_a,
        {"challenge_id": challenge_id, "user_id": uid_a},
        prefer="return=minimal",
    )
    req(
        "POST",
        "/rest/v1/challenge_messages",
        tok_a,
        {
            "challenge_id": challenge_id,
            "user_id": uid_a,
            "content": "member message",
            "message_type": "text",
        },
        prefer="return=minimal",
    )

    failures: list[str] = []

    code, raw = req(
        "POST",
        "/rest/v1/rpc/create_system_message",
        tok_b,
        {"p_challenge_id": challenge_id, "p_content": "FORGED_SHOULD_FAIL"},
    )
    if code == 200:
        failures.append(f"non-member create_system_message succeeded: {raw}")
    else:
        print(f"OK non-member create_system_message rejected ({code})")

    code, raw = req(
        "POST",
        "/rest/v1/rpc/get_challenge_unread_count",
        tok_b,
        {"p_challenge_id": challenge_id},
    )
    if code != 200 or raw.strip() not in ("0", "0.0"):
        failures.append(f"non-member unread expected 0, got {code} {raw}")
    else:
        print("OK non-member unread count is 0")

    code, raw = req(
        "POST",
        "/rest/v1/rpc/snapshot_challenge_results",
        tok_b,
        {"p_challenge_id": challenge_id},
    )
    if code == 200 and raw.strip() not in ("[]", "null"):
        failures.append(f"non-member snapshot leaked data: {raw}")
    elif code >= 500:
        failures.append(f"non-member snapshot server error: {code} {raw}")
    else:
        print(f"OK non-member snapshot blocked/empty ({code})")

    code, raw = req(
        "POST",
        "/rest/v1/rpc/create_system_message",
        tok_a,
        {"p_challenge_id": challenge_id, "p_content": "legitimate system notice"},
    )
    if code != 200:
        failures.append(f"member create_system_message failed: {code} {raw}")
    else:
        print("OK member create_system_message allowed")

    # Cleanup best-effort
    req("DELETE", f"/rest/v1/challenge_messages?challenge_id=eq.{challenge_id}", tok_a)
    req("DELETE", f"/rest/v1/challenge_members?challenge_id=eq.{challenge_id}", tok_a)
    req("DELETE", f"/rest/v1/challenge_members?challenge_id=eq.{challenge_id}", tok_b)
    req("DELETE", f"/rest/v1/challenges?id=eq.{challenge_id}", tok_a)
    for tok, uid in ((tok_a, uid_a), (tok_b, uid_b)):
        req(
            "PATCH",
            f"/rest/v1/profiles?id=eq.{uid}",
            tok,
            {"display_name": "DELETED_PROBE", "username": f"del_{uid[:8]}"},
        )

    if failures:
        print("FAIL:")
        for item in failures:
            print(" -", item)
        return 1

    print("PASS: challenge chat/snapshot RPC authorization regression checks")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # pragma: no cover
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(2)
