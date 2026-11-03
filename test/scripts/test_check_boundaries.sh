#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRISTIE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PRISTIE_DIR"

TOTAL=0
PASSED=0
FAILED=0

assert_success() {
  local desc="$1"
  shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then
    echo "  [PASS] $desc"
    PASSED=$((PASSED + 1))
  else
    echo "  [FAIL] $desc (expected exit code 0)" >&2
    FAILED=$((FAILED + 1))
  fi
}

assert_failure() {
  local desc="$1"
  shift
  TOTAL=$((TOTAL + 1))
  if "$@" >/dev/null 2>&1; then
    echo "  [FAIL] $desc (expected non-zero exit code, got 0)" >&2
    FAILED=$((FAILED + 1))
  else
    echo "  [PASS] $desc"
    PASSED=$((PASSED + 1))
  fi
}

FIXTURE_DIR="$(mktemp -d)"
mkdir -p "$FIXTURE_DIR/scripts"
cp scripts/check_boundaries.sh "$FIXTURE_DIR/scripts/check_boundaries.sh"
trap 'rm -r "$FIXTURE_DIR"' EXIT

check_fixture_boundaries() {
  (cd "$FIXTURE_DIR" && bash scripts/check_boundaries.sh)
}

echo "=== Testing check_boundaries.sh ==="

# 1. Baseline passes
assert_success "Baseline boundary check passes" scripts/check_boundaries.sh

# 2. Core importing features via package URI
mkdir -p "$FIXTURE_DIR/lib/src/core"
cat <<'EOF' > "$FIXTURE_DIR/lib/src/core/test_violation.dart"
import 'package:base/src/features/home/home.dart';
EOF
assert_failure "Boundary check fails when lib/src/core imports features via package:" check_fixture_boundaries
rm "$FIXTURE_DIR/lib/src/core/test_violation.dart"

# 3. Core importing features via src/features/
cat <<'EOF' > "$FIXTURE_DIR/lib/src/core/test_relative_violation.dart"
import '../src/features/home/home.dart';
EOF
assert_failure "Boundary check fails when lib/src/core imports src/features/" check_fixture_boundaries
rm "$FIXTURE_DIR/lib/src/core/test_relative_violation.dart"

# 4. Feature domain cross-import
mkdir -p "$FIXTURE_DIR/lib/src/features/feature_a/domain"
cat <<'EOF' > "$FIXTURE_DIR/lib/src/features/feature_a/domain/sample.dart"
import 'package:base/src/features/feature_b/domain/other.dart';
EOF
assert_failure "Boundary check fails when feature domain imports another feature" check_fixture_boundaries
rm -r "$FIXTURE_DIR/lib/src/features/feature_a"

# 5. Feature presentation cross-import
mkdir -p "$FIXTURE_DIR/lib/src/features/feature_a/presentation"
cat <<'EOF' > "$FIXTURE_DIR/lib/src/features/feature_a/presentation/sample_page.dart"
import 'package:base/src/features/feature_b/presentation/other_page.dart';
EOF
assert_failure "Boundary check fails when feature presentation imports another feature" check_fixture_boundaries
rm -r "$FIXTURE_DIR/lib/src/features/feature_a"

# 6. Template README is allowed
mkdir -p "$FIXTURE_DIR/lib/src/features/_template"
cat <<'EOF' > "$FIXTURE_DIR/lib/src/features/_template/README.md"
# Template feature
References package:base/src/features/ in doc example.
EOF
assert_success "Boundary check passes with _template/README.md" check_fixture_boundaries
rm -r "$FIXTURE_DIR/lib/src/features/_template"

# 7. Disallowed print() in lib/
cat <<'EOF' > "$FIXTURE_DIR/lib/test_leak_print.dart"
void testPrint() {
  print("disallowed");
}
EOF
assert_failure "Boundary check fails when print() is used in lib/" check_fixture_boundaries
rm "$FIXTURE_DIR/lib/test_leak_print.dart"

# 8. Disallowed debugPrint() in lib/
cat <<'EOF' > "$FIXTURE_DIR/lib/test_leak_debug_print.dart"
void testDebugPrint() {
  debugPrint("disallowed");
}
EOF
assert_failure "Boundary check fails when debugPrint() is used in lib/" check_fixture_boundaries
rm "$FIXTURE_DIR/lib/test_leak_debug_print.dart"

echo "check_boundaries.sh tests: $PASSED/$TOTAL passed."
if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
exit 0
