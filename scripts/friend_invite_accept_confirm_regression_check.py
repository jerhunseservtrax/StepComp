#!/usr/bin/env python3
"""Regression check: friend invite accept must confirm before consuming.

InviteAcceptView previously called consume_friend_invite in `.task` on appear.
That burns one-time invite tokens under whichever account is currently signed in
(shared-device / wrong-account), and the intended recipient then gets
"Invite already used".
"""

from __future__ import annotations

import json
import re
import sys
import urllib.error
import urllib.request
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ACCEPT_VIEW = ROOT / "StepComp" / "Screens" / "Friends" / "InviteAcceptView.swift"

BASE = "https://cwrirmowykxajumjokjj.supabase.co"
ANON = "sb_publishable_sfIAdMwGWCg81LZo_HuNVA_BnMXHA-A"


def http(method: str, path: str, token: str | None = None, body: dict | None = None):
    headers = {
        "apikey": ANON,
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token or ANON}",
    }
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.status, resp.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()


def signup(tag: str) -> tuple[str, str]:
    email = f"invite-confirm-reg-{tag}-{uuid.uuid4().hex[:8]}@example.com"
    password = f"Probe!{uuid.uuid4().hex[:12]}Aa1"
    http("POST", "/auth/v1/signup", body={"email": email, "password": password})
    code, raw = http(
        "POST",
        "/auth/v1/token?grant_type=password",
        body={"email": email, "password": password},
    )
    if code != 200:
        raise RuntimeError(f"signup/login failed for {tag}: {code} {raw[:200]}")
    payload = json.loads(raw)
    return payload["access_token"], payload["user"]["id"]


def check_static() -> list[str]:
    failures: list[str] = []
    source = ACCEPT_VIEW.read_text(encoding="utf-8")

    # Must not auto-consume on view appearance.
    if re.search(r"\.task\s*\{[^}]*consume\s*\(", source, re.DOTALL):
        failures.append(
            "InviteAcceptView must not call consume(...) inside .task on appear"
        )

    # Appearance task / onAppear must not invoke the RPC either.
    if re.search(
        r"\.(task|onAppear)\s*\{[^}]*consumeInviteRPC\s*\(",
        source,
        re.DOTALL,
    ):
        failures.append(
            "InviteAcceptView must not call consumeInviteRPC from .task/.onAppear"
        )

    # Explicit user confirmation path required.
    if "confirmAndConsume" not in source and "acceptInvite" not in source:
        failures.append(
            "InviteAcceptView must expose an explicit confirm/accept action "
            "(confirmAndConsume or acceptInvite) before consuming"
        )

    if "Send Friend Request" not in source and "Accept Invite" not in source:
        failures.append(
            "InviteAcceptView must present a confirm CTA "
            "('Send Friend Request' or 'Accept Invite') before consuming"
        )

    # consumeInviteRPC should still exist on the service side via FriendsService,
    # but the view model consume helper must be gated.
    if "func consume(token:" in source and "confirmAndConsume" not in source and "acceptInvite" not in source:
        # consume may remain as private helper, but only if confirm path exists
        # (already checked above). Keep this as documentation of intent.
        pass

    return failures


def check_live() -> list[str]:
    """Prove one-time token burn still exists server-side (documents the hazard)."""
    failures: list[str] = []
    try:
        tok_a, _uid_a = signup("a")
        tok_b, _uid_b = signup("b")
        tok_c, _uid_c = signup("c")
    except Exception as exc:  # noqa: BLE001
        return [f"Live signup failed: {exc}"]

    code, raw = http(
        "POST",
        "/rest/v1/rpc/create_friend_invite",
        tok_a,
        {"expires_in_hours": 24},
    )
    if code != 200:
        return [f"create_friend_invite failed: {code} {raw[:200]}"]

    invite = json.loads(raw)
    token = invite[0]["token"] if isinstance(invite, list) else invite["token"]

    code, raw = http(
        "POST",
        "/rest/v1/rpc/consume_friend_invite",
        tok_b,
        {"invite_token": token},
    )
    if code != 200:
        failures.append(f"Unexpected: wrong-account consume failed: {code} {raw[:200]}")
        return failures

    code, raw = http(
        "POST",
        "/rest/v1/rpc/consume_friend_invite",
        tok_c,
        {"invite_token": token},
    )
    if code == 200:
        failures.append(
            "Expected second consume to fail after first use; token was reusable"
        )
    elif "already used" not in raw.lower() and "P0001" not in raw:
        failures.append(
            f"Expected 'Invite already used' on second consume; got {code} {raw[:200]}"
        )

    return failures


def main() -> int:
    static_failures = check_static()
    live_failures = check_live()

    if static_failures:
        print("STATIC FAIL")
        for item in static_failures:
            print(f"  - {item}")
    else:
        print("STATIC PASS")

    if live_failures:
        print("LIVE FAIL")
        for item in live_failures:
            print(f"  - {item}")
    else:
        print("LIVE PASS (one-time burn hazard still present server-side; client must confirm first)")

    if static_failures or live_failures:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
