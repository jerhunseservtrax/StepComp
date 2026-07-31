#!/usr/bin/env python3
"""Regression check for friendship force-accept + non-friend invites.

Expects FIX_FRIENDSHIP_FORCE_ACCEPT_AND_INVITE_FRIENDS_ONLY.sql to be deployed.

Usage:
  SUPABASE_URL=https://xxx.supabase.co \\
  SUPABASE_ANON_KEY=sb_publishable_... \\
  python3 scripts/friendship_invite_idor_regression_check.py

Creates two temporary users + one challenge, asserts:
  - INSERT friendships with status='accepted' is rejected
  - INSERT friendships with status='pending' succeeds
  - requester cannot PATCH pending -> accepted
  - addressee can PATCH pending -> accepted
  - send_challenge_invites to a non-friend returns 0
  - direct challenge_invites INSERT for a non-friend is rejected
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
        with urllib.request.urlopen(request, timeout=30) as resp:
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
    token = payload.get("access_token")
    user = payload.get("user") or {}
    uid = user.get("id")
    if not token:
        code, raw = req(
            "POST",
            "/auth/v1/token?grant_type=password",
            ANON,
            {"email": email, "password": password},
        )
        if code != 200:
            raise RuntimeError(f"login failed {code}: {raw}")
        payload = json.loads(raw)
        token = payload["access_token"]
        uid = payload["user"]["id"]
    return token, uid


def main() -> int:
    stamp = int(time.time())
    password = "ProbeTest!23456"
    tok_a, uid_a = signup(f"friend_idor_{stamp}_a@example.com", password)
    tok_b, uid_b = signup(f"friend_idor_{stamp}_b@example.com", password)

    for tok, uid, name in ((tok_a, uid_a, "fa"), (tok_b, uid_b, "fb")):
        req(
            "POST",
            "/rest/v1/profiles",
            tok,
            {
                "id": uid,
                "username": f"{name}{uid[:8]}",
                "display_name": name,
                "daily_step_goal": 10000,
                "public_profile": True,
            },
            prefer="resolution=merge-duplicates,return=minimal",
        )

    failures: list[str] = []

    code, raw = req(
        "POST",
        "/rest/v1/friendships",
        tok_a,
        {
            "requester_id": uid_a,
            "addressee_id": uid_b,
            "status": "accepted",
        },
        prefer="return=representation",
    )
    if code in (200, 201):
        failures.append(f"force-accept INSERT succeeded: {code} {raw}")
        # cleanup if unexpectedly created
        try:
            fid = json.loads(raw)[0]["id"]
            req("DELETE", f"/rest/v1/friendships?id=eq.{fid}", tok_a)
            req("DELETE", f"/rest/v1/friendships?id=eq.{fid}", tok_b)
        except Exception:
            pass
    else:
        print(f"OK force-accept INSERT rejected ({code})")

    code, raw = req(
        "POST",
        "/rest/v1/friendships",
        tok_a,
        {
            "requester_id": uid_a,
            "addressee_id": uid_b,
            "status": "pending",
        },
        prefer="return=representation",
    )
    if code not in (200, 201):
        failures.append(f"pending INSERT failed: {code} {raw}")
        friendship_id = None
    else:
        friendship_id = json.loads(raw)[0]["id"]
        print("OK pending INSERT allowed")

    if friendship_id:
        code, raw = req(
            "PATCH",
            f"/rest/v1/friendships?id=eq.{friendship_id}",
            tok_a,
            {"status": "accepted"},
            prefer="return=representation",
        )
        rows = []
        try:
            rows = json.loads(raw) if raw else []
        except json.JSONDecodeError:
            rows = ["non-json"]
        if rows:
            failures.append(f"requester self-accept unexpectedly updated rows: {code} {raw}")
        else:
            print(f"OK requester self-accept blocked ({code})")

        code, raw = req(
            "PATCH",
            f"/rest/v1/friendships?id=eq.{friendship_id}",
            tok_b,
            {"status": "accepted"},
            prefer="return=representation",
        )
        try:
            rows = json.loads(raw) if raw else []
        except json.JSONDecodeError:
            rows = []
        if code not in (200, 201) or not rows or rows[0].get("status") != "accepted":
            failures.append(f"addressee accept failed: {code} {raw}")
        else:
            print("OK addressee accept allowed")

        # Remove friendship so invite non-friend checks are meaningful
        req("DELETE", f"/rest/v1/friendships?id=eq.{friendship_id}", tok_a)
        req("DELETE", f"/rest/v1/friendships?id=eq.{friendship_id}", tok_b)

    now = datetime.now(timezone.utc)
    code, raw = req(
        "POST",
        "/rest/v1/challenges",
        tok_a,
        {
            "name": "FRIEND_IDOR_PROBE_DELETE_ME",
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
        failures.append(f"create challenge failed: {code} {raw}")
        challenge_id = None
    else:
        challenge_id = json.loads(raw)[0]["id"]
        req(
            "POST",
            "/rest/v1/challenge_members",
            tok_a,
            {"challenge_id": challenge_id, "user_id": uid_a},
            prefer="return=minimal",
        )

    if challenge_id:
        # Direct INSERT first so a successful RPC cannot mask the result with 409 uniqueness.
        code, raw = req(
            "POST",
            "/rest/v1/challenge_invites",
            tok_a,
            {
                "challenge_id": challenge_id,
                "inviter_id": uid_a,
                "invitee_id": uid_b,
                "status": "pending",
            },
            prefer="return=representation",
        )
        if code in (200, 201):
            failures.append(f"non-friend challenge_invites INSERT succeeded: {code} {raw}")
            try:
                invite_id = json.loads(raw)[0]["id"]
                req("DELETE", f"/rest/v1/challenge_invites?id=eq.{invite_id}", tok_a)
            except Exception:
                pass
        elif code == 409:
            failures.append(
                f"non-friend challenge_invites INSERT hit uniqueness conflict instead of RLS reject: {raw}"
            )
            req("DELETE", f"/rest/v1/challenge_invites?challenge_id=eq.{challenge_id}", tok_a)
        else:
            print(f"OK non-friend challenge_invites INSERT rejected ({code})")

        req("DELETE", f"/rest/v1/challenge_invites?challenge_id=eq.{challenge_id}", tok_a)

        code, raw = req(
            "POST",
            "/rest/v1/rpc/send_challenge_invites",
            tok_a,
            {"p_challenge_id": challenge_id, "p_friend_ids": [uid_b]},
        )
        if code != 200 or str(raw).strip() not in ("0", "0.0"):
            failures.append(f"non-friend send_challenge_invites expected 0, got {code} {raw}")
        else:
            print("OK non-friend send_challenge_invites returns 0")

        req("DELETE", f"/rest/v1/challenge_invites?challenge_id=eq.{challenge_id}", tok_a)
        req("DELETE", f"/rest/v1/challenge_members?challenge_id=eq.{challenge_id}", tok_a)
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
            print(f"  - {item}")
        return 1

    print("friendship-invite-idor: ok")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}")
        raise SystemExit(2)
