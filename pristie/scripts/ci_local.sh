#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRISTIE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -d "$PRISTIE_DIR" ]; then
  cd "$PRISTIE_DIR"
fi

echo "=== 1. Checking Flutter toolchain pin ==="
fvm flutter --version --machine | jq -e '.frameworkVersion == "3.47.8"'

echo "=== 2. Enforcing dependency lockfile ==="
fvm flutter pub get --enforce-lockfile

echo "=== 3. Code generation and clean workspace check ==="
fvm dart run build_runner build -d
git diff --exit-code
test -z "$(git ls-files --others --exclude-standard)"

echo "=== 4. Code formatting check ==="
fvm dart format --output=none --set-exit-if-changed .

echo "=== 5. Static analysis ==="
fvm flutter analyze --fatal-infos --fatal-warnings

echo "=== 6. Slang translation analysis ==="
fvm dart run slang analyze --full --exit-if-changed

echo "=== 7. Flutter tests ==="
fvm flutter test

echo "=== 8. Configuration check ==="
scripts/check_config.sh

echo "=== 9. Architecture boundary check ==="
scripts/check_boundaries.sh

echo "=== 10. Secret scan ==="
scripts/check_secrets.sh

echo "=== All CI verification gates PASSED ==="
