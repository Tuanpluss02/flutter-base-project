# Offline Database Spike Harness (Task 8a)

This directory contains standalone spike fixtures and verification tests evaluating candidate encrypted local database solutions for Pristie Phase 2 Offline-First architecture under Flutter `3.47.8` / Dart `3.13.7`.

## Evaluated Candidates

1. **Candidate 1: `drift` (2.35.3) + `sqlcipher_flutter_libs` / `sqlite3` (3.8.0 with `sqlite3mc` build hooks)**
2. **Candidate 2: `sqflite_sqlcipher` (3.4.1) (+ `path_provider` 2.1.6)**

## Evaluation Criteria

- Encrypted database creation, data persistence, close, and reopen.
- Wrong encryption key failure verification (typed `SqliteException` / `DatabaseException` with code `26` `SQLITE_NOTADB`).
- Key rotation via `PRAGMA rekey` or `PRAGMA hexrekey`.
- Binary header validation (asserting no plaintext `SQLite format 3` header).
- Platform build verification on iOS (`--no-codesign --simulator`) and Android (`assembleDebug`).
- Analyzer and toolchain compatibility with Dart `3.13.7` and `flutter_lints 6.0.0`.

## How to Run the Spike

From repo root:
```bash
./pristie/tool/offline_spike/run_spike.sh
```

Or from this directory:
```bash
fvm dart run bin/run_spike.dart
fvm flutter test test/offline_spike_test.dart
```

## Summary of Findings

- `sqlcipher_flutter_libs` is discontinued (`0.7.0+eol`) and replaced by Dart Native Assets / build hooks in `package:sqlite3` 3.x.
- Drift's native encryption path requires Dart Native Assets build hooks (`hooks: user_defines: sqlite3: source: sqlite3mc`), which bundles `SQLite3MultipleCiphers`. If misconfigured or if hooks fail, it can silently fall back to unencrypted standard SQLite.
- `sqflite_sqlcipher` delegates directly to official Zetetic SQLCipher binaries on Android (`net.zetetic:sqlcipher-android`) and iOS (`SQLCipher 4.10.0` pod). It requires no build hooks, no C toolchain orchestration, and introduces zero code generation dependencies or analyzer constraint conflicts.
- For complete rationale, security requirements, key lifecycle, and backup exclusion policies, refer to [ADR 0001](../../../docs/adr/0001-offline-database.md).
