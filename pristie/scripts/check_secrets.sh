#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRISTIE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -d "$PRISTIE_DIR" ]; then
  cd "$PRISTIE_DIR"
fi

echo "Checking for secrets with Gitleaks..."

# Check that gitleaks is installed
if ! command -v gitleaks >/dev/null 2>&1; then
  echo "ERROR: gitleaks is not installed or not in PATH." >&2
  exit 1
fi

# Verify Gitleaks version is exactly 8.30.1
GITLEAKS_VERSION="$(gitleaks version 2>&1 | tr -d 'v' | head -n 1 | awk '{print $1}')"
if [ "$GITLEAKS_VERSION" != "8.30.1" ]; then
  echo "ERROR: Required Gitleaks version is 8.30.1, found: $GITLEAKS_VERSION" >&2
  exit 1
fi

echo "Using Gitleaks version: $GITLEAKS_VERSION"

# Run gitleaks dir scan with redaction
echo "Running Gitleaks directory scan..."
gitleaks dir . --redact --exit-code 1

# If git repository / worktree exists, run gitleaks git scan with redaction
if git rev-parse --is-inside-work-tree >/dev/null 2>&1 || [ -e .git ] || [ -e ../.git ]; then
  echo "Running Gitleaks git history scan..."
  gitleaks git . --redact --exit-code 1
fi

echo "Secret check PASSED."
exit 0
