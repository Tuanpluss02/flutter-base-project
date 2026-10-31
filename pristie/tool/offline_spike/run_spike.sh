#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== 1. Running Dart Spike Evaluation Binary ==="
fvm dart run bin/run_spike.dart

echo "=== 2. Running Flutter Test Suite ==="
fvm flutter test test/offline_spike_test.dart

echo "=== Offline Spike Tests Succeeded ==="
