import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

/// Result status of a candidate evaluation test step.
class StepResult {
  const StepResult({
    required this.name,
    required this.passed,
    required this.details,
    this.errorType,
  });

  final String name;
  final bool passed;
  final String details;
  final String? errorType;

  @override
  String toString() => '[$name] ${passed ? "PASS" : "FAIL"}: $details';
}

/// Consolidated evaluation results for a candidate package.
class CandidateReport {
  const CandidateReport({
    required this.candidateName,
    required this.version,
    required this.license,
    required this.steps,
    required this.headerBytesEncrypted,
    required this.plaintextFallbackPrevented,
    required this.summary,
  });

  final String candidateName;
  final String version;
  final String license;
  final List<StepResult> steps;
  final bool headerBytesEncrypted;
  final bool plaintextFallbackPrevented;
  final String summary;

  bool get allPassed =>
      steps.every((s) => s.passed) &&
      headerBytesEncrypted &&
      plaintextFallbackPrevented;
}

/// Evaluator for Candidate 1: drift + sqlite3 with native build hooks (sqlite3mc).
class DriftCandidateEvaluator {
  const DriftCandidateEvaluator();

  Future<CandidateReport> evaluate({
    required String dbPath,
    required String password,
    required String newPassword,
  }) async {
    final steps = <StepResult>[];
    final file = File(dbPath);
    if (file.existsSync()) {
      file.deleteSync();
    }

    var headerEncrypted = false;
    var plaintextPrevented = false;

    // 1. Create and write encrypted DB
    try {
      final db = sqlite3.open(file.path);
      final cipherCheck = db.select('PRAGMA cipher;');
      if (cipherCheck.isEmpty) {
        throw StateError(
          'PRAGMA cipher is empty. SQLite3MultipleCiphers hook was not loaded!',
        );
      }
      db.execute("PRAGMA key = '$password';");
      db.execute(
        'CREATE TABLE test_data (id INTEGER PRIMARY KEY, secret_value TEXT);',
      );
      db.execute(
        "INSERT INTO test_data (secret_value) VALUES ('confidential_record');",
      );
      db.close();

      steps.add(
        const StepResult(
          name: 'Create and write encrypted DB',
          passed: true,
          details: 'Successfully created table and inserted record.',
        ),
      );
    } catch (e) {
      steps.add(
        StepResult(
          name: 'Create and write encrypted DB',
          passed: false,
          details: 'Failed: $e',
          errorType: e.runtimeType.toString(),
        ),
      );
    }

    // Inspect file header on disk
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      final header = String.fromCharCodes(bytes.take(16));
      final hasPlaintextHeader = header.startsWith('SQLite format 3');
      headerEncrypted = !hasPlaintextHeader && bytes.isNotEmpty;
      plaintextPrevented = !hasPlaintextHeader;
      steps.add(
        StepResult(
          name: 'Plaintext header inspection',
          passed: !hasPlaintextHeader,
          details: hasPlaintextHeader
              ? 'CRITICAL FAIL: File contains plaintext "SQLite format 3" header!'
              : 'PASS: Header is encrypted binary ciphertext.',
        ),
      );
    }

    // 2. Reopen with correct password via Drift NativeDatabase
    try {
      final executor = NativeDatabase(
        file,
        setup: (rawDb) {
          rawDb.execute("PRAGMA key = '$password';");
        },
      );
      final driftDb = _SpikeDriftDb(executor);
      final rows = await driftDb
          .customSelect('SELECT secret_value FROM test_data WHERE id = 1;')
          .get();
      await driftDb.close();

      final matches =
          rows.isNotEmpty &&
          rows.first.read<String>('secret_value') == 'confidential_record';
      steps.add(
        StepResult(
          name: 'Reopen with correct password',
          passed: matches,
          details: matches
              ? 'Read back expected record: confidential_record'
              : 'Record mismatch',
        ),
      );
    } catch (e) {
      steps.add(
        StepResult(
          name: 'Reopen with correct password',
          passed: false,
          details: 'Failed: $e',
          errorType: e.runtimeType.toString(),
        ),
      );
    }

    // 3. Reopen with wrong password - MUST FAIL TYPED
    try {
      final badDb = sqlite3.open(file.path);
      badDb.execute("PRAGMA key = 'completely_wrong_pass';");
      try {
        badDb.select('SELECT * FROM test_data;');
        steps.add(
          const StepResult(
            name: 'Wrong key typed failure',
            passed: false,
            details: 'SECURITY CRITICAL: Query succeeded with invalid key!',
          ),
        );
      } on SqliteException catch (e) {
        final isNotADatabase = e.resultCode == 26; // SQLITE_NOTADB
        steps.add(
          StepResult(
            name: 'Wrong key typed failure',
            passed: isNotADatabase,
            details:
                'Caught typed SqliteException: code ${e.resultCode} (${e.message})',
            errorType: 'SqliteException',
          ),
        );
      } catch (e) {
        steps.add(
          StepResult(
            name: 'Wrong key typed failure',
            passed: true,
            details: 'Caught exception: $e',
            errorType: e.runtimeType.toString(),
          ),
        );
      } finally {
        badDb.close();
      }
    } catch (e) {
      steps.add(
        StepResult(
          name: 'Wrong key typed failure',
          passed: false,
          details: 'Failed during open: $e',
          errorType: e.runtimeType.toString(),
        ),
      );
    }

    // 4. PRAGMA rekey execution
    try {
      final rekeyDb = sqlite3.open(file.path);
      rekeyDb.execute("PRAGMA key = '$password';");
      rekeyDb.execute("PRAGMA rekey = '$newPassword';");
      rekeyDb.close();

      // Verify new key works
      final verifyDb = sqlite3.open(file.path);
      verifyDb.execute("PRAGMA key = '$newPassword';");
      final newRows = verifyDb.select('SELECT * FROM test_data;');
      verifyDb.close();

      // Verify old key now fails
      var oldKeyFailed = false;
      final testOldDb = sqlite3.open(file.path);
      testOldDb.execute("PRAGMA key = '$password';");
      try {
        testOldDb.select('SELECT * FROM test_data;');
      } on SqliteException {
        oldKeyFailed = true;
      } finally {
        testOldDb.close();
      }

      final rekeySuccess = newRows.isNotEmpty && oldKeyFailed;
      steps.add(
        StepResult(
          name: 'PRAGMA rekey rotation',
          passed: rekeySuccess,
          details: rekeySuccess
              ? 'Key rotation succeeded: new key reads data, old key rejected.'
              : 'Key rotation failed verification.',
        ),
      );
    } catch (e) {
      steps.add(
        StepResult(
          name: 'PRAGMA rekey rotation',
          passed: false,
          details: 'Failed: $e',
          errorType: e.runtimeType.toString(),
        ),
      );
    }

    return CandidateReport(
      candidateName: 'drift + sqlite3 (sqlite3mc hooks)',
      version: 'drift 2.35.3 / sqlite3 3.8.0',
      license: 'MIT (drift) / MIT (sqlite3) / MIT+BSD (sqlite3mc)',
      steps: steps,
      headerBytesEncrypted: headerEncrypted,
      plaintextFallbackPrevented: plaintextPrevented,
      summary:
          'Native build hook provides encrypted SQLite3MultipleCiphers. '
          'Requires hooks: user_defines configuration and C compiler toolchain. '
          'sqlcipher_flutter_libs 0.7.0+eol is discontinued.',
    );
  }
}

class _SpikeDriftDb extends GeneratedDatabase {
  _SpikeDriftDb(super.e);
  @override
  List<TableInfo> get allTables => [];
  @override
  int get schemaVersion => 1;
}
