# StepComp TestFlight Submission Guide

This guide defines the required release flow for StepComp uploads.

For full App Store preflight + `asc` release orchestration, use:
- `docs/setup/APP_STORE_PREFLIGHT_ASC_RUNBOOK.md`

## Release Inputs (Required)

Before any archive or upload:
- `APP_ID` (App Store Connect app ID)
- `VERSION` (marketing version)
- `BUILD_NUMBER` (CFBundleVersion / current project version)
- `BUILD_ID` (App Store Connect build identifier for submission)
- `METADATA_DIR` (metadata path used by `asc`, for example `./metadata/version/<VERSION>`)

## Mandatory Pre-Submission Gate

Do not upload until all of the following are true:
- [ ] No unresolved preflight rejection-level findings
- [ ] `Info.plist` privacy strings and export compliance are valid
- [ ] Entitlements align with enabled app capabilities
- [ ] `PrivacyInfo.xcprivacy` is included in the StepComp app target
- [ ] Legal copy does not contain placeholder links

## Build And Export

### Xcode UI
1. Select `Any iOS Device (arm64)`.
2. Run `Product -> Archive`.
3. Validate in Organizer.
4. Upload in Organizer.

### CLI (Preferred For Repeatability)
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

`exportOptions.plist` is configured for:
- `method = app-store`
- `destination = upload`
- `signingStyle = automatic`
- `teamID = 8HSMVL4J99`

## App Store Connect Validation

Run this sequence before release submission:
```bash
asc auth status --validate
asc metadata pull --app "<APP_ID>" --version "<VERSION>" --dir "./metadata"
asc release run --app "<APP_ID>" --version "<VERSION>" --build "<BUILD_ID>" --metadata-dir "<METADATA_DIR>" --dry-run
asc validate --app "<APP_ID>" --version "<VERSION>"
asc review doctor --app "<APP_ID>"
```

Or run the helper script:
```bash
scripts/shell/release_preflight_and_submit.sh \
  --mode dry-run \
  --app-id "<APP_ID>" \
  --version "<VERSION>" \
  --build-id "<BUILD_ID>" \
  --metadata-dir "<METADATA_DIR>"
```

Submit only after all checks pass:
```bash
asc release run --app "<APP_ID>" --version "<VERSION>" --build "<BUILD_ID>" --metadata-dir "<METADATA_DIR>" --confirm
asc status --app "<APP_ID>" --watch
```

## Post-Upload Checklist

- [ ] Build reaches Processed state in TestFlight
- [ ] Internal test notes are added
- [ ] External review notes are added (if external testing is used)
- [ ] Crash and feedback monitoring started in App Store Connect

## Common Failure Recovery

- Invalid bundle/version: confirm `VERSION` and `BUILD_NUMBER` are incremented correctly.
- Invalid signature/profile: re-check Team and signing config.
- Missing compliance/purpose strings: verify `StepComp/Info.plist`.
- Capability mismatch: verify `StepComp/StepComp.entitlements` and Apple portal capability state.

