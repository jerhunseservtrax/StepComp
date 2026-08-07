#!/usr/bin/env python3
"""Regression check: create-challenge must invite selected friends via RPC.

Live RLS blocks creator force-enroll of other users into challenge_members
(42501). CreateChallenge previously inserted those rows and swallowed errors,
so selected friends were never notified. The client must call
send_challenge_invites after the creator is enrolled.
"""

from __future__ import annotations

import json
import re
import sys
import urllib.error
import urllib.request
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHALLENGE_SERVICE = ROOT / "StepComp" / "Services" / "ChallengeService.swift"

BASE = "https://cwrirmowykxajumjokjj.supabase.co"
ANON = "sb_publishable_sfIAdMwGWCg81LZo_HuNVA_BnMXHA-A"


def http(
    method: str,
    path: str,
    token: str | None = None,
    body: dict | None = None,
    prefer: str | None = None,
):
    headers = {
        "apikey": ANON,
        "Content-Type": "application/json",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if prefer:
        headers["Prefer"] = prefer
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.status, resp.read().decode()
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()


def signup(tag: str):
    email = f"create-invite-reg-{tag}-{uuid.uuid4().hex[:8]}@example.com"
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
    source = CHALLENGE_SERVICE.read_text(encoding="utf-8")

    start = source.find("private func createChallengeInSupabase")
    end = source.find("private func generateInviteCode", start)
    if start < 0 or end < 0:
        failures.append("Could not locate createChallengeInSupabase in ChallengeService.swift")
        return failures

    body = source[start:end]
    if "send_challenge_invites" not in body:
        failures.append(
            "createChallengeInSupabase must call send_challenge_invites after creator enrollment"
        )

    # Detect the old anti-pattern: loop participantIds and addChallengeMember for others.
    if re.search(
        r"for participantId in challenge\.participantIds.*?addChallengeMember\(",
        body,
        flags=re.S,
    ):
        failures.append(
            "createChallengeInSupabase still force-enrolls participants via addChallengeMember; "
            "use send_challenge_invites instead"
        )

    return failures


def check_live() -> list[str]:
    failures: list[str] = []
    try:
        ta, ua = signup("a")
        tb, ub = signup("b")
    except Exception as exc:  # noqa: BLE001 - probe environment
        return [f"live signup unavailable: {exc}"]

    # Current live still allows force-accept friendships (tracked separately in PR #58).
    http(
        "POST",
        "/rest/v1/friendships",
        token=ta,
        body={"requester_id": ua, "addressee_id": ub, "status": "accepted"},
        prefer="return=representation",
    )

    now = datetime.now(timezone.utc)
    code, raw = http(
        "POST",
        "/rest/v1/challenges",
        token=ta,
        body={
            "name": "create-invite-regression",
            "start_date": (now - timedelta(hours=1)).isoformat(),
            "end_date": (now + timedelta(days=3)).isoformat(),
            "created_by": ua,
            "is_public": False,
            "category": "friends",
        },
        prefer="return=representation",
    )
    if code not in (200, 201) or not raw.strip():
        return [f"challenge create failed: {code} {raw[:200]}"]
    challenge_id = json.loads(raw)[0]["id"]

    code, raw = http(
        "POST",
        "/rest/v1/challenge_members",
        token=ta,
        body={"challenge_id": challenge_id, "user_id": ub},
        prefer="return=representation",
    )
    if code != 403 and "42501" not in raw:
        failures.append(
            f"expected creator force-enroll of friend to be denied, got {code} {raw[:180]}"
        )

    code, raw = http(
        "POST",
        "/rest/v1/challenge_members",
        token=ta,
        body={"challenge_id": challenge_id, "user_id": ua},
        prefer="return=representation",
    )
    if code not in (200, 201):
        failures.append(f"creator self-enroll failed: {code} {raw[:180]}")
        return failures

    code, raw = http(
        "POST",
        "/rest/v1/rpc/send_challenge_invites",
        token=ta,
        body={"p_challenge_id": challenge_id, "p_friend_ids": [ub]},
    )
    if code != 200 or raw.strip() not in {"1", '"1"'}:
        # RPC returns bare integer JSON
        try:
            count = json.loads(raw)
        except json.JSONDecodeError:
            count = None
        if code != 200 or count != 1:
            failures.append(
                f"send_challenge_invites should create 1 invite, got {code} {raw[:180]}"
            )

    code, raw = http(
        "GET",
        f"/rest/v1/challenge_invites?challenge_id=eq.{challenge_id}&invitee_id=eq.{ub}&select=id,status",
        token=tb,
    )
    if code != 200:
        failures.append(f"invitee could not read challenge_invites: {code} {raw[:180]}")
    else:
        rows = json.loads(raw)
        if not rows or rows[0].get("status") != "pending":
            failures.append(f"expected pending invite for friend, got {raw[:180]}")

    return failures


def main() -> int:
    static_failures = check_static()
    print("=== static ===")
    if static_failures:
        for item in static_failures:
            print(f"FAIL: {item}")
    else:
        print("PASS")

    print("=== live ===")
    try:
        live_failures = check_live()
    except Exception as exc:  # noqa: BLE001
        live_failures = [f"live probe crashed: {exc}"]
    if live_failures:
        for item in live_failures:
            print(f"FAIL: {item}")
    else:
        print("PASS")

    if static_failures:
        print("\nRESULT: FAIL (static)")
        return 1
    if live_failures:
        print("\nRESULT: FAIL (live)")
        return 2
    print("\nRESULT: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
