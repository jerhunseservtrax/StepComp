#!/usr/bin/env python3
"""Regression check: private profiles are not world-readable.

Expects FIX_PRIVATE_PROFILE_SELECT_RLS.sql to be deployed.

Usage:
  SUPABASE_URL=https://xxx.supabase.co \\
  SUPABASE_ANON_KEY=sb_publishable_... \\
  python3 scripts/private_profile_select_rls_regression_check.py

Creates temporary users and asserts:
  - anon cannot read a private profile (email/height/weight hidden)
  - unrelated authenticated user cannot read a private profile
  - self can still read own private profile
  - public profiles remain readable by anon
  - accepted friends can read each other's private profiles
  - client PATCH of is_premium / total_steps is rejected or no-ops
Then cleans up probe friendships where possible.
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


def patch_profile(token: str, uid: str, fields: dict) -> tuple[int, str]:
    return req(
        "PATCH",
        f"/rest/v1/profiles?id=eq.{uid}",
        token,
        fields,
        prefer="return=representation",
    )


def get_profile(token: str, uid: str) -> tuple[int, list]:
    code, raw = req(
        "GET",
        f"/rest/v1/profiles?id=eq.{uid}&select=id,username,email,first_name,last_name,height,weight,public_profile,is_premium,total_steps",
        token,
    )
    if code != 200:
        return code, []
    try:
        rows = json.loads(raw)
    except json.JSONDecodeError:
        return code, []
    return code, rows if isinstance(rows, list) else []


def main() -> int:
    stamp = int(time.time())
    password = "ProbeTest!23456"
    tok_a, uid_a = signup(f"privprof_{stamp}_a@example.com", password)
    tok_b, uid_b = signup(f"privprof_{stamp}_b@example.com", password)
    tok_c, uid_c = signup(f"privprof_{stamp}_c@example.com", password)

    failures: list[str] = []

    # A private with PII; B public; C private stranger
    code, raw = patch_profile(
        tok_a,
        uid_a,
        {
            "username": f"privprof_a_{stamp}",
            "display_name": "PrivateA",
            "public_profile": False,
            "first_name": "Hidden",
            "last_name": "Person",
            "email": f"privprof_{stamp}_a@example.com",
            "height": 181,
            "weight": 79,
        },
    )
    if code not in (200, 201) or not json.loads(raw):
        raise RuntimeError(f"patch A failed {code}: {raw}")

    code, raw = patch_profile(
        tok_b,
        uid_b,
        {
            "username": f"privprof_b_{stamp}",
            "display_name": "PublicB",
            "public_profile": True,
            "first_name": "Open",
            "last_name": "Book",
        },
    )
    if code not in (200, 201) or not json.loads(raw):
        raise RuntimeError(f"patch B failed {code}: {raw}")

    code, raw = patch_profile(
        tok_c,
        uid_c,
        {
            "username": f"privprof_c_{stamp}",
            "display_name": "PrivateC",
            "public_profile": False,
        },
    )
    if code not in (200, 201) or not json.loads(raw):
        raise RuntimeError(f"patch C failed {code}: {raw}")

    # 1) Anon must not read private A
    code, rows = get_profile(ANON, uid_a)
    if code == 200 and rows:
        failures.append(f"anon read private profile: {rows[0]}")
        print("FAIL: anon can read private profile")
    else:
        print("PASS: anon cannot read private profile")

    # 2) Unrelated authenticated C must not read private A
    code, rows = get_profile(tok_c, uid_a)
    if code == 200 and rows:
        failures.append(f"stranger read private profile: {rows[0]}")
        print("FAIL: stranger can read private profile")
    else:
        print("PASS: stranger cannot read private profile")

    # 3) Self can read private A
    code, rows = get_profile(tok_a, uid_a)
    if code != 200 or not rows or rows[0].get("height") != 181:
        failures.append(f"self cannot read own private profile: {code} {rows}")
        print("FAIL: self cannot read own private profile")
    else:
        print("PASS: self can read own private profile")

    # 4) Anon can still read public B
    code, rows = get_profile(ANON, uid_b)
    if code != 200 or not rows or rows[0].get("public_profile") is not True:
        failures.append(f"anon cannot read public profile: {code} {rows}")
        print("FAIL: anon cannot read public profile")
    else:
        print("PASS: anon can read public profile")

    # 5) Accepted friends can read each other's private profiles
    code, raw = req(
        "POST",
        "/rest/v1/friendships",
        tok_a,
        {"requester_id": uid_a, "addressee_id": uid_c, "status": "pending"},
        prefer="return=representation",
    )
    # Pending may already be blocked by PR #58 deploy; fall back to accept path
    if code in (200, 201) and json.loads(raw):
        fid = json.loads(raw)[0]["id"]
        code2, raw2 = req(
            "PATCH",
            f"/rest/v1/friendships?id=eq.{fid}",
            tok_c,
            {"status": "accepted"},
            prefer="return=representation",
        )
        friend_ok = code2 in (200, 201) and bool(json.loads(raw2) if raw2 else [])
    else:
        # If force-accepted insert still works (pre-#58), use it for the friend-read assertion
        code, raw = req(
            "POST",
            "/rest/v1/friendships",
            tok_a,
            {"requester_id": uid_a, "addressee_id": uid_c, "status": "accepted"},
            prefer="return=representation",
        )
        friend_ok = code in (200, 201) and bool(json.loads(raw) if raw else [])

    if not friend_ok:
        print("WARN: could not establish friendship for friend-read check; skipping")
    else:
        code, rows = get_profile(tok_c, uid_a)
        if code != 200 or not rows:
            failures.append(f"friend cannot read private profile: {code} {rows}")
            print("FAIL: friend cannot read private profile")
        else:
            print("PASS: friend can read private profile")

    # 6) Privileged column UPDATE must not stick
    code, raw = patch_profile(tok_a, uid_a, {"is_premium": True, "total_steps": 9999999})
    code2, rows2 = get_profile(tok_a, uid_a)
    premium = rows2[0].get("is_premium") if rows2 else None
    steps = rows2[0].get("total_steps") if rows2 else None
    if premium is True or steps == 9999999:
        failures.append(f"privileged columns still writable: is_premium={premium} total_steps={steps} patch={code} {raw[:200]}")
        print("FAIL: is_premium/total_steps still client-writable")
    else:
        print("PASS: is_premium/total_steps not client-writable")

    # Cleanup friendship rows (best-effort)
    req("DELETE", f"/rest/v1/friendships?or=(requester_id.eq.{uid_a},addressee_id.eq.{uid_a})", tok_a)

    if failures:
        print("\nRESULT: FAIL")
        for item in failures:
            print(" -", item)
        return 1

    print("\nRESULT: PASS")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # pragma: no cover
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(2)
