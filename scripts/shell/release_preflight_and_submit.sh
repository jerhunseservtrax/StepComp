#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/shell/release_preflight_and_submit.sh --mode <dry-run|confirm> --app-id <APP_ID> --version <VERSION> --build-id <BUILD_ID> --metadata-dir <DIR> [--skip-preflight]

Required:
  --mode          dry-run or confirm
  --app-id        App Store Connect app id
  --version       Marketing version (e.g. 1.2.3)
  --build-id      App Store Connect build id for this version
  --metadata-dir  Metadata directory path (e.g. ./metadata/version/1.2.3)

Optional:
  --skip-preflight  Skip manual preflight confirmation prompt
EOF
}

MODE=""
APP_ID=""
VERSION=""
BUILD_ID=""
METADATA_DIR=""
SKIP_PREFLIGHT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --app-id)
      APP_ID="${2:-}"
      shift 2
      ;;
    --version)
      VERSION="${2:-}"
      shift 2
      ;;
    --build-id)
      BUILD_ID="${2:-}"
      shift 2
      ;;
    --metadata-dir)
      METADATA_DIR="${2:-}"
      shift 2
      ;;
    --skip-preflight)
      SKIP_PREFLIGHT=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$MODE" || -z "$APP_ID" || -z "$VERSION" || -z "$BUILD_ID" || -z "$METADATA_DIR" ]]; then
  echo "Missing required arguments."
  usage
  exit 1
fi

if [[ "$MODE" != "dry-run" && "$MODE" != "confirm" ]]; then
  echo "--mode must be one of: dry-run, confirm"
  exit 1
fi

if ! command -v asc >/dev/null 2>&1; then
  echo "asc CLI not found. Install with: brew install rudrankriyam/tap/asc"
  exit 1
fi

if [[ ! -d "$METADATA_DIR" ]]; then
  echo "Metadata directory not found: $METADATA_DIR"
  exit 1
fi

echo "StepComp release gate"
echo "  mode: $MODE"
echo "  app-id: $APP_ID"
echo "  version: $VERSION"
echo "  build-id: $BUILD_ID"
echo "  metadata-dir: $METADATA_DIR"
echo ""

if [[ "$SKIP_PREFLIGHT" -eq 0 ]]; then
  echo "Preflight confirmation required before continuing."
  echo "Confirm each item is complete:"
  echo "  1) No unresolved rejection-severity findings"
  echo "  2) Warnings are triaged (fix or explicit acceptance)"
  echo "  3) Privacy manifest, entitlements, and legal checks are complete"
  read -r -p "Type 'preflight-passed' to continue: " PRECHECK
  if [[ "$PRECHECK" != "preflight-passed" ]]; then
    echo "Preflight gate failed or not confirmed. Aborting."
    exit 1
  fi
fi

echo ""
echo "Running ASC validation sequence..."
asc auth status --validate
asc metadata pull --app "$APP_ID" --version "$VERSION" --dir "./metadata"
asc release run --app "$APP_ID" --version "$VERSION" --build "$BUILD_ID" --metadata-dir "$METADATA_DIR" --dry-run
asc validate --app "$APP_ID" --version "$VERSION"
asc review doctor --app "$APP_ID"

if [[ "$MODE" == "confirm" ]]; then
  echo ""
  read -r -p "All checks passed. Submit now? Type 'submit-now' to continue: " SUBMIT_CONFIRM
  if [[ "$SUBMIT_CONFIRM" != "submit-now" ]]; then
    echo "Submission cancelled."
    exit 1
  fi

  asc release run --app "$APP_ID" --version "$VERSION" --build "$BUILD_ID" --metadata-dir "$METADATA_DIR" --confirm
  asc status --app "$APP_ID" --watch
else
  echo ""
  echo "Dry-run mode complete. No submission performed."
fi

