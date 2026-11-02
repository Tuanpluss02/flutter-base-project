#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRISTIE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -d "$PRISTIE_DIR/lib" ]; then
  cd "$PRISTIE_DIR"
fi

FAILED=0

echo "Checking architectural boundaries..."

# 1. lib/src/core must not import lib/src/features
if [ -d "lib/src/core" ]; then
  if rg -n "package:pristie/src/features/|src/features/" lib/src/core 2>/dev/null; then
    echo "ERROR: lib/src/core must not import features!" >&2
    FAILED=1
  fi
fi

# 2. Features must not import other features in domain or presentation
shopt -s nullglob
feature_dirs=(lib/src/features/*/domain lib/src/features/*/presentation)
shopt -u nullglob

if [ ${#feature_dirs[@]} -gt 0 ]; then
  matches=$( (rg -n "package:pristie/src/features/" "${feature_dirs[@]}" 2>/dev/null || true) | (rg -v "features/.*_template" || true) )
  if [ -n "$matches" ]; then
    echo "$matches" >&2
    echo "ERROR: Features must not import other features in domain or presentation!" >&2
    FAILED=1
  fi
fi

# 3. Disallow raw print() and debugPrint() in lib/
if [ -d "lib" ]; then
  if rg -n "\bprint\(|debugPrint\(" lib 2>/dev/null; then
    echo "ERROR: Disallowed print() or debugPrint() call found in lib/!" >&2
    FAILED=1
  fi
fi

if [ "$FAILED" -ne 0 ]; then
  echo "Boundary check FAILED!" >&2
  exit 1
fi

echo "Boundary check PASSED."
exit 0
