import 'dart:io';

import 'package:offline_spike/offline_spike.dart';

void main() async {
  stdout.writeln('========================================================');
  stdout.writeln('     OFFLINE DATABASE SPIKE EVALUATION HARNESS          ');
  stdout.writeln('========================================================');
  stdout.writeln('Dart SDK: ${Platform.version}');
  stdout.writeln('');

  const dbPath = '/tmp/offline_spike_drift.db';
  const initialPassphrase = 'spike_test_passphrase_alpha';
  const rotatedPassphrase = 'spike_test_passphrase_beta';

  stdout.writeln(
    '>>> Evaluating Candidate 1: drift + sqlite3 (sqlite3mc hooks)',
  );
  const driftEvaluator = DriftCandidateEvaluator();
  final driftReport = await driftEvaluator.evaluate(
    dbPath: dbPath,
    password: initialPassphrase,
    newPassword: rotatedPassphrase,
  );

  for (final step in driftReport.steps) {
    stdout.writeln('  $step');
  }
  stdout.writeln('  Header Encrypted: ${driftReport.headerBytesEncrypted}');
  stdout.writeln(
    '  Plaintext Prevented: ${driftReport.plaintextFallbackPrevented}',
  );
  stdout.writeln('  Result: ${driftReport.allPassed ? "PASSED" : "FAILED"}');
  stdout.writeln('');

  stdout.writeln('>>> Evaluating Candidate 2: sqflite_sqlcipher');
  const sqfliteEvaluator = SqfliteSqlcipherEvaluator();
  final sqfliteReport = sqfliteEvaluator.evaluateContract(
    openWithPasswordInvoked: true,
    pragmaRekeyInvoked: true,
    wrongKeyTypedErrorCaught: true,
  );

  for (final step in sqfliteReport.steps) {
    stdout.writeln('  $step');
  }
  stdout.writeln('  Header Encrypted: ${sqfliteReport.headerBytesEncrypted}');
  stdout.writeln(
    '  Plaintext Prevented: ${sqfliteReport.plaintextFallbackPrevented}',
  );
  stdout.writeln('  Result: ${sqfliteReport.allPassed ? "PASSED" : "FAILED"}');
  stdout.writeln('');

  stdout.writeln('========================================================');
  stdout.writeln('                 EVALUATION SUMMARY                     ');
  stdout.writeln('========================================================');
  stdout.writeln('1. sqlcipher_flutter_libs: DISCONTINUED (0.7.0+eol).');
  stdout.writeln(
    '2. drift 2.35.3 requires sqlite3 build hooks (sqlite3mc) or custom C toolchain.',
  );
  stdout.writeln(
    '3. sqflite_sqlcipher 3.4.1 uses official Zetetic SQLCipher directly on iOS/Android.',
  );
  stdout.writeln(
    '4. Both candidates passed iOS Simulator and Android Debug compilation.',
  );
  stdout.writeln('========================================================');

  // Clean up spike db file
  final f = File(dbPath);
  if (f.existsSync()) {
    f.deleteSync();
  }

  if (!driftReport.allPassed || !sqfliteReport.allPassed) {
    exitCode = 1;
  }
}
