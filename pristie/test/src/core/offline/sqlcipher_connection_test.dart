import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/core/offline/db/impl/sqlcipher_offline_database.dart';
import 'package:pristie/src/core/offline/db/offline_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.davidmartos96.sqflite_sqlcipher');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('forwards the encryption key as the SQLCipher password', () async {
    Map<String, Object?>? openArguments;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'openDatabase':
          openArguments = Map<String, Object?>.from(
            call.arguments as Map<Object?, Object?>,
          );
          return 1;
        case 'query':
          return <Map<String, Object?>>[
            <String, Object?>{'user_version': 0},
          ];
        case 'execute':
        case 'closeDatabase':
          return null;
      }
      return null;
    });

    final database = await openSqlcipherConnection(
      path: '/tmp/pristie_encrypted.db',
      password: 'base64-encoded-key',
      version: 1,
      onCreate: (OfflineDatabaseExecutor db) async {},
      onUpgrade: (
        OfflineDatabaseExecutor db,
        int oldVersion,
        int newVersion,
      ) async {},
    );

    expect(openArguments, isNotNull);
    expect(openArguments!['path'], '/tmp/pristie_encrypted.db');
    expect(openArguments!['password'], 'base64-encoded-key');
    await database.close();
  });
}
