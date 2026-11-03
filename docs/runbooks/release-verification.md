# Release Verification Runbook

This runbook outlines the checks for a production release candidate built from the Flutter base.

---

## Prerequisites

1. Ensure the workspace is clean and on the target release branch (`integration/flutter-core-base` or `main`).
2. Verify toolchain compliance as documented in [docs/toolchain.md](../toolchain.md).
3. Ensure no local uncommitted changes exist:
   ```bash
   git status
   ```

---

## 1. Local CI Verification Gate

Run the local full verification script from the repository root:

```bash
bash scripts/ci_local.sh
```

**Passing Criteria:**
- Step 1: Flutter toolchain pin matches `3.47.8`.
- Step 2: `flutter pub get --enforce-lockfile` passes with zero dependency discrepancies.
- Step 3: `build_runner` generates cleanly with zero workspace diff.
- Step 4: `dart format` reports zero unformatted files.
- Step 5: `flutter analyze` reports zero errors, warnings, or infos (`--fatal-infos --fatal-warnings`).
- Step 6: `slang analyze --full --exit-if-changed` passes with zero missing/unused keys.
- Step 7: All test suites pass (239+ tests).
- Step 8: `check_config.sh` validates all `.env` files with exact keys and prod `ENABLE_LOGGING=false`.
- Step 9: `check_boundaries.sh` confirms architectural layer isolation.
- Step 10: `check_secrets.sh` (Gitleaks) confirms zero secrets committed.

---

## 2. Release Build Execution

Build production release binaries using `--dart-define-from-file=config/env_prod.env`:

The base does not include distribution signing credentials. These builds verify the release configuration; configure signing outside Git before distributing an Android AAB or iOS app.

### 2.1 Android AppBundle (AAB)

```bash
fvm flutter build appbundle --release --flavor prod --dart-define-from-file=config/env_prod.env
```
- **Output:** `build/app/outputs/bundle/prodRelease/app-prod-release.aab`

### 2.2 iOS Release Build

```bash
fvm flutter build ios --release --no-codesign --flavor prod --dart-define-from-file=config/env_prod.env
```
- **Output:** `build/ios/iphoneos/Runner.app`

---

## 3. Artifact Security Inspection

Verify that release artifacts contain no hardcoded secrets or insecure configurations:

### 3.1 Android AAB Inspection

1. Extract the generated AAB using `unzip` to a temporary directory:
   ```bash
   mkdir -p /tmp/base-aab-check
   unzip -q build/app/outputs/bundle/prodRelease/app-prod-release.aab -d /tmp/base-aab-check
   ```
2. Scan extracted files for credentials/secrets with Gitleaks:
   ```bash
   gitleaks dir /tmp/base-aab-check --redact --exit-code 1
   ```
3. Verify merged manifest properties:
   - `android:allowBackup="false"`
   - `android:fullBackupContent="false"`
   - `android:usesCleartextTraffic="false"`
   - `android:networkSecurityConfig` active
4. Clean up temporary directory:
   ```bash
   rm -r /tmp/base-aab-check
   ```

### 3.2 iOS Runner.app Inspection

1. Inspect `Info.plist` inside `build/ios/iphoneos/Runner.app/Info.plist`:
   ```bash
   plutil -p build/ios/iphoneos/Runner.app/Info.plist | grep -i arbitrary
   ```
   *Expected:* No output (ATS default active, `NSAllowsArbitraryLoads` is NOT present).
2. Verify `UIFileSharingEnabled`:
   ```bash
   plutil -p build/ios/iphoneos/Runner.app/Info.plist | grep -i UIFileSharingEnabled
   ```
   *Expected:* `"UIFileSharingEnabled" => 0` (or `false`).
3. Scan `Runner.app` directory with Gitleaks:
   ```bash
   gitleaks dir build/ios/iphoneos/Runner.app --redact --exit-code 1
   ```

---

## 4. Release Checklist & Sign-Off

Record all verification logs and build hashes into the release verification report before signing and distributing the artifacts.
