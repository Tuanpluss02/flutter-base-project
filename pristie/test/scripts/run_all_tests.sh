#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Running All CI Bash Script Tests"
echo "=========================================="

FAILED=0

run_test() {
  local script="$1"
  echo ""
  if bash "$script"; then
    echo ">> $script PASSED"
  else
    echo ">> $script FAILED" >&2
    FAILED=1
  fi
}

run_test "test_check_config.sh"
run_test "test_check_boundaries.sh"
run_test "test_check_secrets.sh"

echo ""
echo "=========================================="
if [ "$FAILED" -eq 0 ]; then
  echo "All CI Bash Script Tests PASSED successfully!"
  echo "=========================================="
  exit 0
else
  echo "Some CI Bash Script Tests FAILED!" >&2
  echo "=========================================="
  exit 1
fi
