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

echo "=== Testing check_config.sh ==="

# 1. Standard config check passes
assert_success "Standard config validation passes on dev, stg, prod" scripts/check_config.sh

# 2. Fixture runner passes on test/fixtures/config
assert_success "Fixture runner passes on test/fixtures/config" scripts/check_config.sh --fixtures test/fixtures/config

# 3. Direct single-file validation
assert_success "Direct file validation passes on dev_valid.json" scripts/check_config.sh test/fixtures/config/dev_valid.json dev
assert_failure "Direct file validation fails on prod_logging_on.json" scripts/check_config.sh test/fixtures/config/prod_logging_on.json prod
assert_failure "Direct file validation fails on http_url.json" scripts/check_config.sh test/fixtures/config/http_url.json dev
assert_failure "Direct file validation fails on missing_key.json" scripts/check_config.sh test/fixtures/config/missing_key.json dev
assert_failure "Direct file validation fails on extra_key.json" scripts/check_config.sh test/fixtures/config/extra_key.json dev

# 4. Edge cases
TEMP_CONFIG_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_CONFIG_DIR"' EXIT

# Non-existent file
assert_failure "Direct validation fails on non-existent file" scripts/check_config.sh "$TEMP_CONFIG_DIR/non_existent.json"

# Non-numeric / zero timeout
cat <<'EOF' > "$TEMP_CONFIG_DIR/zero_timeout.json"
{
  "APP_ENV": "dev",
  "API_BASE_URL": "https://api.dev.pristie.example",
  "APP_NAME": "Pristie Dev",
  "ENABLE_LOGGING": true,
  "CONNECT_TIMEOUT_MS": 0,
  "RECEIVE_TIMEOUT_MS": 30000,
  "SEND_TIMEOUT_MS": 30000
}
EOF
assert_failure "Direct validation fails when CONNECT_TIMEOUT_MS is 0" scripts/check_config.sh "$TEMP_CONFIG_DIR/zero_timeout.json" dev

# Invalid APP_ENV
cat <<'EOF' > "$TEMP_CONFIG_DIR/invalid_env.json"
{
  "APP_ENV": "qa",
  "API_BASE_URL": "https://api.dev.pristie.example",
  "APP_NAME": "Pristie Dev",
  "ENABLE_LOGGING": true,
  "CONNECT_TIMEOUT_MS": 15000,
  "RECEIVE_TIMEOUT_MS": 30000,
  "SEND_TIMEOUT_MS": 30000
}
EOF
assert_failure "Direct validation fails when APP_ENV is invalid (qa)" scripts/check_config.sh "$TEMP_CONFIG_DIR/invalid_env.json"

# Directory mode validation with invalid files
mkdir -p "$TEMP_CONFIG_DIR/bad_config"
cp config/env_dev.json "$TEMP_CONFIG_DIR/bad_config/env_dev.json"
cp config/env_stg.json "$TEMP_CONFIG_DIR/bad_config/env_stg.json"
cp test/fixtures/config/prod_logging_on.json "$TEMP_CONFIG_DIR/bad_config/env_prod.json"
assert_failure "Directory mode validation fails when env_prod.json has logging enabled" scripts/check_config.sh "$TEMP_CONFIG_DIR/bad_config"

echo "check_config.sh tests: $PASSED/$TOTAL passed."
if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
exit 0
