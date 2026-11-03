import 'dart:convert';
import 'dart:io';

import 'package:base/src/core/offline/db/impl/sqlcipher_offline_database.dart';
import 'package:base/src/core/offline/db/offline_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late String path;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('base_sqlcipher_');
    path = '${directory.path}/encrypted.db';
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  Future<OfflineDatabaseConnection> open(int keyByte) =>
      openSqlcipherConnection(
        path: path,
        password: base64Encode(List<int>.filled(32, keyByte)),
        version: 1,
        onCreate: (db) => db.execute('CREATE TABLE records (value TEXT)'),
        onUpgrade: (db, oldVersion, newVersion) async {},
      );

  test('encrypts on disk and rejects the wrong key', () async {
    final database = await open(1);
    await database.insert('records', {'value': 'private-value'});
    await database.close();

    final header = await File(path).openRead(0, 16).first;
    expect(header, isNot('SQLite format 3\u0000'.codeUnits));
    await expectLater(open(2), throwsA(isA<Exception>()));

    final reopened = await open(1);
    expect(await reopened.query('records'), [
      {'value': 'private-value'},
    ]);
    await reopened.close();
  });

  test('rekeys the encrypted file', () async {
    final database = await open(1);
    await database.insert('records', {'value': 'private-value'});
    await database.execute(
      "PRAGMA rekey = '${base64Encode(List<int>.filled(32, 2))}'",
    );
    await database.close();

    await expectLater(open(1), throwsA(isA<Exception>()));
    final reopened = await open(2);
    expect(await reopened.query('records'), [
      {'value': 'private-value'},
    ]);
    await reopened.close();
  });
}
