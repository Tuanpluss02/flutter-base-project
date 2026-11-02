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

  awk -v expected_env="$expected_env" '
    function trim(value) {
      sub(/^[ \t\r]+/, "", value)
      sub(/[ \t\r]+$/, "", value)
      return value
    }

    function unquote(value, first, last, single_quote) {
      first = substr(value, 1, 1)
      last = substr(value, length(value), 1)
      if (first == "\"" && last == "\"") {
        return substr(value, 2, length(value) - 2)
      }
      single_quote = sprintf("%c", 39)
      if (first == single_quote && last == single_quote) {
        return substr(value, 2, length(value) - 2)
      }
      if (first == "`" && last == "`") {
        return substr(value, 2, length(value) - 2)
      }
      return value
    }

    function fail(message) {
      print "ERROR: " message > "/dev/stderr"
      failed = 1
      exit 1
    }

    BEGIN {
      expected_count = split("APP_ENV API_BASE_URL APP_NAME ENABLE_LOGGING CONNECT_TIMEOUT_MS RECEIVE_TIMEOUT_MS SEND_TIMEOUT_MS", expected_keys, " ")
      for (i = 1; i <= expected_count; i++) {
        allowed[expected_keys[i]] = 1
      }
    }

    {
      line = trim($0)
      if (line == "" || substr(line, 1, 1) == "#") next

      separator = index(line, "=")
      if (separator == 0) {
        fail("invalid property line in " FILENAME ": " line)
      }

      key = trim(substr(line, 1, separator - 1))
      value = trim(substr(line, separator + 1))

      if (key !~ /^[A-Za-z_][A-Za-z0-9_]*$/) {
        fail("invalid key in " FILENAME ": " key)
      }
      if (key in seen) {
        fail("duplicate key in " FILENAME ": " key)
      }
      if (!(key in allowed)) {
        fail("unexpected key in " FILENAME ": " key)
      }

      seen[key] = unquote(value)
    }

    END {
      if (failed) exit 1

      for (i = 1; i <= expected_count; i++) {
        key = expected_keys[i]
        if (!(key in seen)) {
          fail("missing key in " FILENAME ": " key)
        }
      }

      if (expected_env != "" && seen["APP_ENV"] != expected_env) {
        fail("APP_ENV in " FILENAME " is \"" seen["APP_ENV"] "\", expected \"" expected_env "\"")
      }
      if (seen["APP_ENV"] != "dev" && seen["APP_ENV"] != "stg" && seen["APP_ENV"] != "prod") {
        fail("APP_ENV in " FILENAME " must be dev, stg, or prod")
      }
      if (seen["API_BASE_URL"] !~ /^https:\/\/[^[:space:]]+$/) {
        fail("API_BASE_URL in " FILENAME " must start with https:// and contain no spaces")
      }
      if (trim(seen["APP_NAME"]) == "") {
        fail("APP_NAME in " FILENAME " is required")
      }
      if (seen["ENABLE_LOGGING"] != "true" && seen["ENABLE_LOGGING"] != "false") {
        fail("ENABLE_LOGGING in " FILENAME " must be true or false")
      }
      if (seen["APP_ENV"] == "prod" && seen["ENABLE_LOGGING"] != "false") {
        fail("ENABLE_LOGGING must be false in prod (" FILENAME ")")
      }

      timeout_keys_count = split("CONNECT_TIMEOUT_MS RECEIVE_TIMEOUT_MS SEND_TIMEOUT_MS", timeout_keys, " ")
      for (i = 1; i <= timeout_keys_count; i++) {
        key = timeout_keys[i]
        if (seen[key] !~ /^[0-9]+$/ || seen[key] + 0 <= 0) {
          fail(key " in " FILENAME " must be a positive integer")
        }
      }
    }
  ' "$file"
}

run_fixtures() {
  local fixtures_dir="$1"
  local failures=0

  echo "Validating configuration fixtures in: $fixtures_dir"

  local valid_fixture="$fixtures_dir/dev_valid.env"
  if [ -f "$valid_fixture" ]; then
    if validate_config_file "$valid_fixture" "dev" >/dev/null 2>&1; then
      echo "  [PASS] dev_valid.env correctly passed validation."
    else
      echo "  [FAIL] dev_valid.env failed validation unexpectedly!" >&2
      failures=$((failures + 1))
    fi
  else
    echo "  [ERROR] dev_valid.env not found in $fixtures_dir" >&2
    failures=$((failures + 1))
  fi

  local negative_fixtures=(
    "prod_logging_on.env:prod"
    "http_url.env:dev"
    "missing_key.env:dev"
    "extra_key.env:dev"
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

if [ -n "${1:-}" ] && [ ! -d "$1" ]; then
  validate_config_file "$1" "${2:-}"
  exit $?
fi

CONFIG_DIR="config"
if [ ! -d "$CONFIG_DIR" ] && [ -d "$PRISTIE_DIR/config" ]; then
  CONFIG_DIR="$PRISTIE_DIR/config"
fi

if [ -n "${1:-}" ] && [ -d "$1" ]; then
  CONFIG_DIR="$1"
fi

echo "Validating environment configuration files in: $CONFIG_DIR"
failed=0

validate_config_file "$CONFIG_DIR/env_dev.env" "dev" || failed=1
validate_config_file "$CONFIG_DIR/env_stg.env" "stg" || failed=1
validate_config_file "$CONFIG_DIR/env_prod.env" "prod" || failed=1

if [ "$failed" -ne 0 ]; then
  echo "ERROR: Environment configuration validation failed!" >&2
  exit 1
fi

echo "All environment configuration files are valid."
exit 0
