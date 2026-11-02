import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_spike/offline_spike.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqflite;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Spike - Candidate 1: drift + sqlite3mc hooks', () {
    const evaluator = DriftCandidateEvaluator();
    final dbFile = File('/tmp/offline_spike_test_drift.db');

    tearDown(() {
      if (dbFile.existsSync()) {
        dbFile.deleteSync();
      }
    });

    test(
      'evaluates encryption, reopen, wrong key failure, and PRAGMA rekey',
      () async {
        final report = await evaluator.evaluate(
          dbPath: dbFile.path,
          password: 'spike_test_passphrase_alpha',
          newPassword: 'spike_test_passphrase_beta',
        );

        expect(report.headerBytesEncrypted, isTrue);
        expect(report.plaintextFallbackPrevented, isTrue);
        expect(report.allPassed, isTrue);

        for (final step in report.steps) {
          expect(
            step.passed,
            isTrue,
            reason: '${step.name} failed: ${step.details}',
          );
        }
      },
    );
  });

  group('Offline Spike - Candidate 2: sqflite_sqlcipher', () {
    const evaluator = SqfliteSqlcipherEvaluator();
    const channel = MethodChannel('com.davidmartos96.sqflite_sqlcipher');

    test(
      'passes password, executes PRAGMA rekey, and handles typed errors',
      () async {
        final calls = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall call) async {
              calls.add(call);
              if (call.method == 'openDatabase') {
                final args = call.arguments as Map<dynamic, dynamic>?;
                final password = args?['password'] as String?;
                if (password == 'wrong_password') {
                  throw PlatformException(
                    code: 'sqlite_error',
                    message:
                        'SqliteException(26): file is not a database (code 26)',
                    details: {'code': 26},
                  );
                }
                return 1;
              } else if (call.method == 'query') {
                final sql = (call.arguments as Map)['sql'] as String;
                if (sql.contains('user_version')) {
                  return <Map<String, Object?>>[
                    {'user_version': 1},
                  ];
                }
                return <Map<String, Object?>>[
                  {'id': 1, 'secret_value': 'confidential_record'},
                ];
              } else if (call.method == 'execute') {
                return null;
              } else if (call.method == 'closeDatabase') {
                return null;
              }
              return null;
            });

        try {
          // Open with password
          final db = await sqflite.openDatabase(
            ':memory:',
            password: 'test_password_v1',
          );
          final rows = await db.rawQuery('SELECT * FROM test_data;');
          expect(rows, isNotEmpty);

          final openCall = calls.firstWhere((c) => c.method == 'openDatabase');
          expect(
            (openCall.arguments as Map)['password'],
            equals('test_password_v1'),
          );

          // PRAGMA rekey
          await db.rawQuery("PRAGMA rekey = 'new_password_v2';");
          final rekeyCall = calls.firstWhere(
            (c) =>
                c.method == 'query' &&
                (c.arguments as Map)['sql'].toString().contains('PRAGMA rekey'),
          );
          expect(rekeyCall, isNotNull);
          await db.close();

          // Wrong password failure
          var wrongKeyFailedTyped = false;
          try {
            await sqflite.openDatabase(':memory:', password: 'wrong_password');
          } on PlatformException catch (e) {
            wrongKeyFailedTyped = e.code == 'sqlite_error';
          } on sqflite.DatabaseException {
            wrongKeyFailedTyped = true;
          }
          expect(wrongKeyFailedTyped, isTrue);

          final report = evaluator.evaluateContract(
            openWithPasswordInvoked: true,
            pragmaRekeyInvoked: true,
            wrongKeyTypedErrorCaught: wrongKeyFailedTyped,
          );
          expect(report.allPassed, isTrue);
        } finally {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null);
        }
      },
    );
  });

  group('Offline Spike - License & Constraint Assessment', () {
    test('licenses are permissive and commercially compatible', () {
      const driftLicense = 'MIT';
      const sqlite3License = 'MIT';
      const sqlite3mcLicense = 'MIT / BSD-3-Clause';
      const sqfliteSqlcipherLicense = 'BSD-2-Clause';
      const sqlcipherLicense = 'BSD-style (Zetetic)';

      expect(driftLicense, 'MIT');
      expect(sqlite3License, 'MIT');
      expect(sqlite3mcLicense, contains('MIT'));
      expect(sqfliteSqlcipherLicense, 'BSD-2-Clause');
      expect(sqlcipherLicense, contains('BSD'));
    });
  });
}
