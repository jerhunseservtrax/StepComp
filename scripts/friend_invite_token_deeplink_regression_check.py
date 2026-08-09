#!/usr/bin/env python3
"""Regression check: friend invite deep links must accept live tokens.

Live create_friend_invite uses Postgres encode(gen_random_bytes(16), 'base64url'),
which returns tokens that include '~' padding. DeepLinkRouter.isValidInviteToken
must accept that alphabet or every shared invite link is silently dropped.
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
ROUTER = ROOT / "StepComp" / "Utilities" / "DeepLinkRouter.swift"

BASE = "https://cwrirmowykxajumjokjj.supabase.co"
ANON = "sb_publishable_sfIAdMwGWCg81LZo_HuNVA_BnMXHA-A"

# Mirrors the intended client validator after the fix.
CLIENT_TOKEN_RE = re.compile(r"^[A-Za-z0-9_=~-]+$")


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


def signup() -> str:
    email = f"invite-token-reg-{uuid.uuid4().hex[:10]}@example.com"
    password = f"Probe!{uuid.uuid4().hex[:12]}Aa1"
    http("POST", "/auth/v1/signup", body={"email": email, "password": password})
    code, raw = http(
        "POST",
        "/auth/v1/token?grant_type=password",
        body={"email": email, "password": password},
    )
    if code != 200:
        raise RuntimeError(f"login failed: {code} {raw[:200]}")
    return json.loads(raw)["access_token"]


def extract_pattern_from_source() -> str | None:
    source = ROUTER.read_text(encoding="utf-8")
    match = re.search(
        r'isValidInviteToken\([\s\S]*?let pattern = "([^"]+)"',
        source,
    )
    return match.group(1) if match else None


def client_accepts(token: str, pattern: str) -> bool:
    trimmed = token.strip()
    if not (8 <= len(trimmed) <= 128):
        return False
    return re.search(pattern, trimmed) is not None


def check_static() -> list[str]:
    failures: list[str] = []
    pattern = extract_pattern_from_source()
    if pattern is None:
        failures.append("Could not locate isValidInviteToken pattern in DeepLinkRouter.swift")
        return failures

    # Reject control/special characters that are not base64url.
    if client_accepts("ABC!@#$%^&*", pattern):
        failures.append(f"Validator too permissive for special chars: {pattern}")

    # Must accept live base64url padding forms.
    for sample in (
        "oznuK7XIV6T_wTgNco7qag~~",
        "hm-jMzhmUmbnN4OdGingvA~~",
        "abcdEFGH1234-_",
        "abcdEFGH1234==",
    ):
        if not client_accepts(sample, pattern):
            failures.append(
                f"Validator rejects valid base64url invite token {sample!r} with pattern {pattern}"
            )

    if "~" not in pattern and r"\x7e" not in pattern:
        failures.append(
            "Invite token pattern must allow '~' (live Postgres base64url padding)"
        )

    return failures


def check_live() -> list[str]:
    failures: list[str] = []
    pattern = extract_pattern_from_source()
    if pattern is None:
        return ["Skipping live check; pattern missing"]

    try:
        access = signup()
    except Exception as exc:  # noqa: BLE001 - surface probe errors
        return [f"Live signup failed: {exc}"]

    rejected = 0
    samples: list[str] = []
    for _ in range(5):
        code, raw = http(
            "POST",
            "/rest/v1/rpc/create_friend_invite",
            token=access,
            body={"expires_in_hours": 1},
        )
        if code != 200:
            failures.append(f"create_friend_invite failed: {code} {raw[:200]}")
            return failures
        token = json.loads(raw)[0]["token"]
        samples.append(token)
        if not client_accepts(token, pattern):
            rejected += 1

    if rejected:
        failures.append(
            f"Live invite tokens rejected by client validator: {rejected}/5 "
            f"(examples: {samples[:3]})"
        )
    else:
        print(f"Live OK: accepted {len(samples)} tokens (e.g. {samples[0]})")

    # Keep the intended alphabet documented for reviewers.
    if not all(CLIENT_TOKEN_RE.fullmatch(t) for t in samples):
        failures.append(
            "Live tokens used characters outside documented base64url set A-Za-z0-9_=~-"
        )

    return failures


def main() -> int:
    failures = check_static()
    failures.extend(check_live())
    if failures:
        print("FAIL:")
        for item in failures:
            print(f"  - {item}")
        return 1
    print("PASS: friend invite deep-link token validation accepts live tokens")
    return 0


if __name__ == "__main__":
    sys.exit(main())
