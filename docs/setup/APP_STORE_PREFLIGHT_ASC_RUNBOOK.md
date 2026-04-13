# StepComp App Store Preflight and ASC Runbook

## Purpose

This runbook standardizes StepComp release execution with:
- App Store preflight checks as a mandatory quality gate
- `asc` validation and submission as the final operational gate

## Required Inputs

Set these values for each release:
- `APP_ID`: App Store Connect app ID
- `VERSION`: marketing version (for example `1.2.0`)
- `BUILD_NUMBER`: app build number (`CFBundleVersion`)
- `BUILD_ID`: App Store Connect build ID tied to `VERSION`
- `METADATA_DIR`: metadata directory (for example `./metadata/version/1.2.0`)

## Repository Files Used In This Flow

- `exportOptions.plist`
- `StepComp/Info.plist`
- `StepComp/StepComp.entitlements`
- `StepComp/PrivacyInfo.xcprivacy`
- `docs/setup/TESTFLIGHT_SUBMISSION_GUIDE.md`
- `FIX_TRACKER.md`

## Phase 1: Baseline Release Readiness

Complete this checklist first:
- [ ] `Info.plist` privacy usage descriptions are complete and accurate
- [ ] `ITSAppUsesNonExemptEncryption` value is correct for your release
- [ ] Entitlements match features and portal capabilities
- [ ] `PrivacyInfo.xcprivacy` has StepComp target membership in Xcode
- [ ] Onboarding and legal copy do not contain placeholder URLs/text
- [ ] Version and build number are set and incremented correctly

## Phase 2: Mandatory Preflight Gate

Run the preflight skill workflow against code and metadata.

### Scope
- Metadata correctness (name/subtitle/description/keywords/legal URLs)
- Privacy and data disclosure consistency
- Entitlement-to-feature consistency
- Health and fitness guideline checks
- Screenshot and app behavior consistency checks

### Pass Criteria (Go/No-Go)
- No unresolved rejection-severity findings
- All warnings explicitly triaged as either:
  - fixed, or
  - accepted with documented rationale

If the gate fails, do not continue to build/export or submission.

## Phase 3: Build And Export Artifact

Build archive and export with project configuration:

```bash
xcodebuild -project StepComp.xcodeproj \
  -scheme StepComp \
  -sdk iphoneos \
  -configuration Release \
  archive -archivePath ./build/StepComp.xcarchive

xcodebuild -exportArchive \
  -archivePath ./build/StepComp.xcarchive \
  -exportOptionsPlist exportOptions.plist \
  -exportPath ./build
```

Expected artifact hand-off:
- `./build/StepComp.xcarchive`
- exported IPA in `./build`

Map these to App Store submission metadata:
- archive/build output -> `BUILD_ID`
- metadata files -> `METADATA_DIR`

## Phase 4: ASC Validation And Submission Sequence

Run in this order:

```bash
asc auth status --validate
asc metadata pull --app "<APP_ID>" --version "<VERSION>" --dir "./metadata"
asc release run --app "<APP_ID>" --version "<VERSION>" --build "<BUILD_ID>" --metadata-dir "<METADATA_DIR>" --dry-run
asc validate --app "<APP_ID>" --version "<VERSION>"
asc review doctor --app "<APP_ID>"
```

Submit only when all above commands pass:

```bash
asc release run --app "<APP_ID>" --version "<VERSION>" --build "<BUILD_ID>" --metadata-dir "<METADATA_DIR>" --confirm
asc status --app "<APP_ID>" --watch
```

### One-command helper script

Use the repository script to execute the same gate flow:

```bash
# Dry-run gate (no submission)
scripts/shell/release_preflight_and_submit.sh \
  --mode dry-run \
  --app-id "<APP_ID>" \
  --version "<VERSION>" \
  --build-id "<BUILD_ID>" \
  --metadata-dir "<METADATA_DIR>"

# Full submit flow
scripts/shell/release_preflight_and_submit.sh \
  --mode confirm \
  --app-id "<APP_ID>" \
  --version "<VERSION>" \
  --build-id "<BUILD_ID>" \
  --metadata-dir "<METADATA_DIR>"
```

## Phase 5: Operational Ownership

Assign these owners for each release:
- Engineering owner: preflight pass and build/export integrity
- Release owner: `asc` dry-run, validation, submit
- QA owner: TestFlight smoke coverage and test notes

## Final Go/No-Go Checklist

- [ ] Preflight gate passed
- [ ] Build/archive/export completed
- [ ] `asc release ... --dry-run` passed
- [ ] `asc validate` passed
- [ ] `asc review doctor` shows no blockers
- [ ] Ownership checklist completed

## Post-Release Logging Requirement

After each release attempt, add an entry to `FIX_TRACKER.md` under the Release Pipeline section:
- release version/build
- gate failures encountered
- root cause
- fix applied
- prevention note for future releases
