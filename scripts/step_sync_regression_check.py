#!/usr/bin/env python3
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def require(condition: bool, message: str) -> bool:
    if not condition:
        print(f"FAIL: {message}", file=sys.stderr)
        return False
    return True


def main() -> int:
    passed = True

    validator_path = ROOT / "StepComp" / "Services" / "StepSyncResponseValidator.swift"
    passed = require(validator_path.exists(), "Step sync response validator file should exist") and passed
    if validator_path.exists():
        validator = validator_path.read_text()
        passed = require(
            "guard response.success else" in validator,
            "Validator must reject success=false responses",
        ) and passed
        passed = require(
            "reported failure without an error message" in validator,
            "Validator must reject success=false responses even when error is nil",
        ) and passed

    service = (ROOT / "StepComp" / "Services" / "StepSyncService.swift").read_text()
    passed = require(
        "throw StepSyncEdgeFunctionError.sessionRefreshFailed" in service,
        "Step sync must throw when a 401 session refresh fails",
    ) and passed
    passed = require(
        "StepSyncEdgeFunctionResponseValidator.ensureSuccess(retryResponse)" in service,
        "401 retry response must use the same success validation as first attempt",
    ) and passed

    edge_function = (ROOT / "supabase" / "functions" / "sync-steps" / "index.ts").read_text()
    match = re.search(r"const RATE_LIMIT_PER_HOUR = (\d+)", edge_function)
    passed = require(match is not None, "Hourly step sync rate-limit constant should exist") and passed
    if match:
        hourly_limit = int(match.group(1))
        passed = require(
            hourly_limit >= 60,
            f"Hourly step sync rate limit should allow the 60s dashboard auto-refresh cadence (got {hourly_limit})",
        ) and passed

    if passed:
        print("Step sync regression checks passed.")
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
