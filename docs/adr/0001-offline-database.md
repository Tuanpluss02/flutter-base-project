# ADR 0001: Offline Encrypted Local Database Selection

## Amendment — 2026-11-03

Flutter 3.47.8 warns that `sqflite_sqlcipher` does not support Swift Package
Manager and that this will become an error. The original decision below records
the 2026-10-31 evaluation; the current implementation uses
`sqflite_common_ffi: 2.4.5` with `sqlite3: 3.8.0` and the `sqlcipher` native
asset build hook on Android and iOS. The existing `OfflineDatabase` contract,
schema, and key lifecycle remain in place. The opener checks `cipher_version`
before setting the key or creating schema, so a build using ordinary SQLite
fails closed instead of writing plaintext. A real FFI test verifies ciphertext
on disk, wrong-key rejection, and rekey. Existing on-device databases created
with SQLCipher 4 must be checked with the new library during release validation.

- **Status:** Accepted
- **Date:** 2026-10-31
- **Deciders:** Mobile Core Team, Security Reviewer
- **Consulted:** Flutter Core Base Rev6 Specs (`offline-first.md`, `security-privacy.md`, `01-scope-toolchain-architecture.md`, `04-storage-and-shared-ui.md`)
- **Task:** Task 8a (Offline spike — dependency + encryption ADR gate)

---

## 1. Context and Problem Statement

Phase 2 of Pristie introduces an offline-first data synchronization engine (`lib/src/core/offline/`). To protect local business records, user drafts, and sync outbox queues on mobile devices, data persisted on disk must be encrypted at rest using authenticated, hardware-backed key material.

The core base specifications mandate strict security gates (G1–G10 in `security-privacy.md §9`):
1. **Fail-Closed At-Rest Encryption (G3):** The database must be encrypted with 256-bit AES/SQLCipher. Plaintext fallback is strictly prohibited.
2. **Key Lifecycle (G4):** The encryption key must be generated on-device (32 bytes secure random), stored in OS Keystore/Keychain via `SecureStorage` (key `db_key_v1`), never hardcoded, never logged, and never persisted inside the database itself. Key rotation (`PRAGMA rekey`) must be supported.
3. **Key Loss Recovery (G5):** An unrecoverable key, corrupted database, or incorrect password must produce a typed failure (`AppFailure.localPersistence()`). The application must provide a controlled reset/re-sync recovery path without entering a crash loop or falling back to plaintext.
4. **Backup Exclusion (G7):** The local database and encryption keys must be explicitly excluded from OS cloud and device backups (Android Auto-Backup / Google Drive, iOS iCloud / iTunes backups).
5. **Toolchain & Analyzer Compatibility (G10):** The package must solve cleanly under Flutter `3.47.8` / Dart `3.13.7`, with `analyzer: ">=13.3.0 <14.0.0"` and `flutter_lints: 6.0.0`, without creating conflicts with `freezed: 4.0.1` or `auto_route_generator: 10.6.0`.

---

## 2. Candidates Evaluated

A dedicated evaluation harness was executed in `tool/offline_spike/` to evaluate two primary candidate stacks outside the core app codebase:

### Candidate 1: `drift` (2.35.3) + `sqlcipher_flutter_libs` / `sqlite3` (3.8.0 with `sqlite3mc` hooks)
- **Architecture:** High-level Dart ORM / query builder (`drift`) backed by `sqlite3` FFI.
- **Encryption Delivery:**
  - `sqlcipher_flutter_libs` was the historic approach, but as of late 2025/2026, version `0.7.0+eol` is marked discontinued/EOL by maintainer Simon Binder (`"Not used anymore, update to version 3.x of package:sqlite3 instead"`).
  - Modern `drift >= 2.32.0` and `package:sqlite3 >= 3.x` rely on Dart Native Assets build hooks (`hooks: user_defines: sqlite3: source: sqlite3mc`), bundling `SQLite3MultipleCiphers` via dynamic C hooks.

### Candidate 2: `sqflite_sqlcipher` (3.4.1) (+ `path_provider` 2.1.6)
- **Architecture:** Mature Flutter platform plugin delegating to official Zetetic SQLCipher native binaries (`net.zetetic:sqlcipher-android` on Android, `SQLCipher 4.10.0` CocoaPods pod on iOS/macOS).
- **Encryption Delivery:** Native method channels pass the password directly to `net.zetetic.database.sqlcipher.SQLiteDatabase` / `FMDB/SQLCipher`. Native platform bindings manage page-level cryptographic transformations.

---

## 3. Spike Evaluation Results

Both candidates were subjected to 5 empirical verification tests:

| Evaluation Criterion | Candidate 1: `drift` + `sqlite3mc` | Candidate 2: `sqflite_sqlcipher` |
|---|---|---|
| **1. Encrypted DB Creation, Write, Read, Reopen** | **PASS** — Created table, inserted record, read back accurately. | **PASS** — Created table, inserted record, read back accurately. |
| **2. Header Ciphertext Validation (No Plaintext)** | **PASS** — Disk inspection confirms binary ciphertext; does **not** contain `SQLite format 3`. | **PASS** — Disk inspection confirms binary ciphertext; does **not** contain `SQLite format 3`. |
| **3. Wrong Key Typed Failure** | **PASS** — Threw typed `SqliteException` (code 26: `SQLITE_NOTADB`). | **PASS** — Threw typed `DatabaseException` / `PlatformException` (code 26: `file is not a database`). |
| **4. PRAGMA rekey Support** | **PASS** — Rekey updated file; new key succeeds, old key rejected with code 26. | **PASS** — `PRAGMA rekey = '...'` succeeds; new key valid, old key rejected. |
| **5. Platform Build Verification** | **PASS**:<br>• iOS Simulator: `✓ Built build/ios/iphonesimulator/Runner.app`<br>• Android Debug: `✓ Built build/app/outputs/flutter-apk/app-debug.apk` | **PASS**:<br>• iOS Simulator: `✓ Built build/ios/iphonesimulator/Runner.app`<br>• Android Debug: `✓ Built build/app/outputs/flutter-apk/app-debug.apk` |
| **Silent Plaintext Fallback Risk** | **HIGH RISK**: If `hooks: user_defines` is missing or fails on host, `sqlite3` silently defaults to plain SQLite and writes unencrypted databases. | **ZERO RISK (FAIL CLOSED)**: If SQLCipher fails to link or password is missing/invalid, open fails immediately. |
| **Analyzer & Codegen Friction** | **HIGH**: Requires `drift_dev` for typed queries; introduces code generation dependency graphs and potential analyzer friction. | **NONE**: No codegen required; zero analyzer conflicts with Freezed 4 or AutoRoute 10. |
| **Maintenance & Ecosystem State** | `sqlcipher_flutter_libs` is EOL (`0.7.0+eol`). Native Assets build hook is evolving. | Mature, battle-tested across thousands of production applications. |

---

## 4. Decision

We select **Candidate 2: `sqflite_sqlcipher` (exact version `3.4.1`)** alongside **`path_provider` (exact version `2.1.6`)** for Pristie Phase 2 Offline-First local database persistence.

### Exact Version Pins to Commit in `pubspec.yaml`:
```yaml
dependencies:
  sqflite_sqlcipher: 3.4.1
  path_provider: 2.1.6
```

---

## 5. Rationale & Trade-offs

### Why `sqflite_sqlcipher` was chosen:
1. **Security & Fail-Closed Guarantee (G3):** `sqflite_sqlcipher` binds directly to official Zetetic SQLCipher binaries at the platform layer. It cannot silently fall back to plaintext SQLite. If an invalid key is provided or cryptographic initialization fails, it throws a typed `DatabaseException`.
2. **Zero Code Generation Friction (G10):** Pristie's toolchain has strict analyzer pinning (`analyzer: ">=13.3.0 <14.0.0"` for `freezed: 4.0.1` and `auto_route_generator: 10.6.0`). Adding `drift_dev` would introduce a second major code generator and increase build times. `sqflite_sqlcipher` requires no code generation.
3. **Alignment with Architectural Abstraction:** In `offline-first.md` and Task 8b, the design specifies an abstracted `OfflineDatabase` interface:
   ```dart
   abstract interface class OfflineDatabase {
     Future<Result<void>> open(DataScope scope);
     Future<Result<void>> close();
     Future<Result<List<Map<String, Object?>>>> query(OfflineQuery query);
     Future<Result<void>> transaction(Future<void> Function(OfflineTransaction tx) action);
   }
   ```
   This interface returns raw row mappings (`List<Map<String, Object?>>`) and deliberately shields the rest of the application from leaking ORM/DAO types. `sqflite_sqlcipher` maps directly onto this contract with lower overhead.
4. **License Compatibility:** `sqflite_sqlcipher` is licensed under BSD-2-Clause. The underlying SQLCipher library is distributed under Zetetic's BSD-style license. Both are commercially permissive and compatible with Pristie.

### Why `drift + sqlcipher_flutter_libs` was rejected:
1. **EOL of `sqlcipher_flutter_libs`:** The package was officially deprecated and marked `0.7.0+eol`.
2. **Silent Plaintext Fallback Danger:** In our spike tests, running `sqlite3` without explicitly configuring build hooks produced an unencrypted database file starting with `SQLite format 3` headers while ignoring `PRAGMA key`. This violates the fail-closed principle.
3. **Native Assets / Build Hook Toolchain Overhead:** Compiling C dependencies via Dart build hooks during CI/CD requires native C compilers and hook orchestration across all build runners, introducing fragility compared to standard CocoaPods and Gradle dependencies.

---

## 6. Key Lifecycle Specification (G4 & G5)

### 6.1 Key Generation and Storage
1. **Key Generation:** A cryptographically secure 256-bit (32 bytes) key is generated using `Random.secure()`:
   ```dart
   final keyBytes = Uint8List(32);
   final secureRandom = Random.secure();
   for (var i = 0; i < 32; i++) {
     keyBytes[i] = secureRandom.nextInt(256);
   }
   ```
2. **Key Storage:** The key is Base64-encoded and stored in `SecureStorage` under the designated key name:
   `db_key_v1`
   - On Android: Backed by Android Keystore and EncryptedSharedPreferences.
   - On iOS: Backed by iOS Keychain with accessibility set to `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
3. **Invariants:**
   - The key is NEVER written to `SharedPreferences` (`LocalStorage`).
   - The key is NEVER committed into source code, test fixtures, or configuration JSON files.
   - The key is NEVER included in logging statements, crash reports, or diagnostic breadcrumbs.

### 6.2 Key Rotation (`PRAGMA rekey`)
When rotating the database key:
1. Generate `newKey` (32 bytes random).
2. Within an active authenticated database session, execute:
   ```sql
   PRAGMA rekey = '<newKeyBase64>';
   ```
3. Upon SQL confirmation, update `SecureStorage` with `db_key_v1 = <newKeyBase64>`.
4. If writing to `SecureStorage` fails, log diagnostic metadata (redacted) and flag for resolution.

### 6.3 Key Loss & Database Corruption Recovery (G5)
If opening the database fails due to an invalid key (`code 26`), missing key in `SecureStorage`, or file corruption:
1. The error maps cleanly to `AppFailure.localPersistence(message: ...)`.
2. The application MUST NOT enter a crash loop.
3. Recovery Flow:
   - Mark the local cache as invalid.
   - Safely delete the corrupted `.db` file and its `-wal` / `-shm` journals.
   - Re-generate a fresh `db_key_v1` in `SecureStorage`.
   - Create a clean encrypted database and trigger a full re-sync from the backend once authenticated.
   - Notify the user with a localized, non-technical warning that cached offline data was reset.

---

## 7. Backup Exclusion Plan (G7)

Both the database files and the encryption keys must be excluded from automated OS backups to prevent extraction from iCloud or Android device backups.

### 7.1 Android Auto-Backup Exclusion
1. **`res/xml/backup_rules.xml`** (Android 12+ / API 31+):
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <data-extraction-rules>
       <cloud-backup>
           <exclude domain="database" path="." />
           <exclude domain="sharedpref" path="." />
       </cloud-backup>
       <device-transfer>
           <exclude domain="database" path="." />
           <exclude domain="sharedpref" path="." />
       </device-transfer>
   </data-extraction-rules>
   ```
2. **`res/xml/data_extraction_rules.xml`** and **`AndroidManifest.xml`**:
   - `android:fullBackupContent="@xml/backup_rules"`
   - `android:dataExtractionRules="@xml/data_extraction_rules"`

### 7.2 iOS Backup Exclusion
1. **Keychain Isolation:** `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` ensures the Keychain entry `db_key_v1` is excluded from iTunes and iCloud backups.
2. **File System Exclusion:** In Task 8b, the database file and directory will be flagged with `NSURLIsExcludedFromBackupKey`:
   ```swift
   var url = URL(fileURLWithPath: databasePath)
   var resourceValues = URLResourceValues()
   resourceValues.isExcludedFromBackup = true
   try url.setResourceValues(resourceValues)
   ```

---

## 8. Residual Risks and Next Steps

1. **Swift Package Manager Warning on iOS:**
   - Flutter 3.47.8 emits a deprecation warning: `The following plugins do not support Swift Package Manager for ios: - sqflite_sqlcipher`.
   - On iOS, CocoaPods handles `SQLCipher 4.10.0` seamlessly. We will monitor upstream `sqflite_sqlcipher` for SPM adoption in future Flutter releases.
2. **Task 8b Hand-off:**
   - Task 8b can immediately proceed with implementing `OfflineDatabase` and `DatabaseKeyManager` using `sqflite_sqlcipher: 3.4.1`.
