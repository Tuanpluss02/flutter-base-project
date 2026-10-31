#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRISTIE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

validate_config_file() {
  local file="$1"
  local expected_env="${2:-}"

  if [ ! -f "$file" ]; then
    echo "ERROR: Config file not found: $file" >&2
    return 1
  fi

  # 1. Exact keys check
  if ! jq -e 'keys == ["API_BASE_URL","APP_ENV","APP_NAME","CONNECT_TIMEOUT_MS","ENABLE_LOGGING","RECEIVE_TIMEOUT_MS","SEND_TIMEOUT_MS"]' "$file" >/dev/null; then
    echo "ERROR: Invalid keys in $file. Keys must exactly match [API_BASE_URL, APP_ENV, APP_NAME, CONNECT_TIMEOUT_MS, ENABLE_LOGGING, RECEIVE_TIMEOUT_MS, SEND_TIMEOUT_MS]" >&2
    return 1
  fi

  # 2. APP_ENV check
  local file_env
  file_env="$(jq -r '.APP_ENV' "$file")"
  if [ "$file_env" != "dev" ] && [ "$file_env" != "stg" ] && [ "$file_env" != "prod" ]; then
    echo "ERROR: Invalid APP_ENV '$file_env' in $file. Must be dev, stg, or prod." >&2
    return 1
  fi

  if [ -n "$expected_env" ]; then
    if ! jq -e --arg env "$expected_env" '.APP_ENV == $env' "$file" >/dev/null; then
      echo "ERROR: APP_ENV in $file is '$file_env', expected '$expected_env'" >&2
      return 1
    fi
  fi

  # 3. HTTPS check
  if ! jq -e '.API_BASE_URL | startswith("https://")' "$file" >/dev/null; then
    echo "ERROR: API_BASE_URL in $file must start with https://" >&2
    return 1
  fi

  # 4. Timeouts check (> 0)
  if ! jq -e '(.CONNECT_TIMEOUT_MS > 0) and (.RECEIVE_TIMEOUT_MS > 0) and (.SEND_TIMEOUT_MS > 0)' "$file" >/dev/null; then
    echo "ERROR: CONNECT_TIMEOUT_MS, RECEIVE_TIMEOUT_MS, and SEND_TIMEOUT_MS in $file must all be greater than 0" >&2
    return 1
  fi

  # 5. Prod logging check: prod must have ENABLE_LOGGING == false
  if [ "$file_env" = "prod" ]; then
    if ! jq -e '.ENABLE_LOGGING == false' "$file" >/dev/null; then
      echo "ERROR: ENABLE_LOGGING must be false in prod environment ($file)" >&2
      return 1
    fi
  fi

  return 0
}

run_fixtures() {
  local fixtures_dir="$1"
  local failures=0

  echo "Validating configuration fixtures in: $fixtures_dir"

  # Positive fixture: dev_valid.json should pass
  local valid_fixture="$fixtures_dir/dev_valid.json"
  if [ -f "$valid_fixture" ]; then
    if validate_config_file "$valid_fixture" "dev" >/dev/null 2>&1; then
      echo "  [PASS] dev_valid.json correctly passed validation."
    else
      echo "  [FAIL] dev_valid.json failed validation unexpectedly!" >&2
      failures=$((failures + 1))
    fi
  else
    echo "  [ERROR] dev_valid.json not found in $fixtures_dir" >&2
    failures=$((failures + 1))
  fi

  # Negative fixtures: each should fail validation
  local negative_fixtures=(
    "prod_logging_on.json:prod"
    "http_url.json:dev"
    "missing_key.json:dev"
    "extra_key.json:dev"
  )

  for item in "${negative_fixtures[@]}"; do
    local fix_file="${item%%:*}"
    local fix_env="${item##*:}"
    local path="$fixtures_dir/$fix_file"

    if [ -f "$path" ]; then
      if validate_config_file "$path" "$fix_env" >/dev/null 2>&1; then
        echo "  [FAIL] $fix_file unexpectedly passed validation! (Expected failure)" >&2
        failures=$((failures + 1))
      else
        echo "  [PASS] $fix_file correctly rejected as expected."
      fi
    else
      echo "  [ERROR] $fix_file not found in $fixtures_dir" >&2
      failures=$((failures + 1))
    fi
  done

  if [ "$failures" -gt 0 ]; then
    echo "Fixture validation FAILED with $failures issue(s)." >&2
    return 1
  fi

  echo "All configuration fixtures verified successfully."
  return 0
}

# Mode 1: --fixtures
if [ "${1:-}" = "--fixtures" ]; then
  shift
  user_dir="${1:-test/fixtures/config}"
  if [ -d "$user_dir" ]; then
    fixtures_dir="$(cd "$user_dir" && pwd)"
  elif [ -d "$PRISTIE_DIR/$user_dir" ]; then
    fixtures_dir="$(cd "$PRISTIE_DIR/$user_dir" && pwd)"
  else
    fixtures_dir="$user_dir"
  fi
  run_fixtures "$fixtures_dir"
  exit $?
fi

# Mode 2: direct file validation (argument is provided and is not an existing directory)
if [ -n "${1:-}" ] && [ ! -d "$1" ]; then
  validate_config_file "$1" "${2:-}"
  exit $?
fi

# Mode 3: validate standard config files in config directory
CONFIG_DIR="config"
if [ ! -d "$CONFIG_DIR" ] && [ -d "$PRISTIE_DIR/config" ]; then
  CONFIG_DIR="$PRISTIE_DIR/config"
fi

if [ -n "${1:-}" ] && [ -d "$1" ]; then
  CONFIG_DIR="$1"
fi

echo "Validating environment configuration files in: $CONFIG_DIR"
failed=0

validate_config_file "$CONFIG_DIR/env_dev.json" "dev" || failed=1
validate_config_file "$CONFIG_DIR/env_stg.json" "stg" || failed=1
validate_config_file "$CONFIG_DIR/env_prod.json" "prod" || failed=1

if [ "$failed" -ne 0 ]; then
  echo "ERROR: Environment configuration validation failed!" >&2
  exit 1
fi

echo "All environment configuration files are valid."
exit 0
