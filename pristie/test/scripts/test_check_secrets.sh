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

echo "=== Testing check_secrets.sh ==="

# 1. Baseline passes
assert_success "Baseline secrets check passes on clean repo" scripts/check_secrets.sh

# 2. Version mismatch fails
MOCK_DIR="$(mktemp -d)"
trap 'rm -rf "$MOCK_DIR"' EXIT

cat <<'EOF' > "$MOCK_DIR/gitleaks"
#!/usr/bin/env bash
if [ "${1:-}" = "version" ]; then
  echo "8.25.0"
  exit 0
fi
exec gitleaks "$@"
EOF
chmod +x "$MOCK_DIR/gitleaks"

assert_failure "check_secrets.sh fails when Gitleaks version is not 8.30.1" env PATH="$MOCK_DIR:$PATH" scripts/check_secrets.sh

# 3. Missing gitleaks fails
EMPTY_PATH_DIR="$(mktemp -d)"
assert_failure "check_secrets.sh fails when gitleaks is missing from PATH" env PATH="$EMPTY_PATH_DIR:/usr/bin:/bin" scripts/check_secrets.sh
rm -rf "$EMPTY_PATH_DIR"

# 4. Secret detection in directory scan (reconstructed at runtime to avoid repo false-positive)
SECRET_TEST_DIR="$(mktemp -d)"
REV_SECRET="-----YEK ETAVIRP HSSNEPO NIGEB-----"$'\n'"nctg2czdAAAAwlBAAABAAAAAAAAAQZu9mbEAAAAUmbv5GBAAAAAEjdtkXZr1CazNnblB3b"$'\n'"-----YEK ETAVIRP HSSNEPO DNE-----"
echo "$REV_SECRET" | rev > "$SECRET_TEST_DIR/id_rsa"
assert_failure "gitleaks dir detects private key secret and exits non-zero" gitleaks dir "$SECRET_TEST_DIR" --redact --exit-code 1
rm -rf "$SECRET_TEST_DIR"

echo "check_secrets.sh tests: $PASSED/$TOTAL passed."
if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
exit 0
