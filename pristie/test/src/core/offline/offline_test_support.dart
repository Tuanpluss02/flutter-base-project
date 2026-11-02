import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/core/offline/db/offline_database.dart';
import 'package:pristie/src/core/offline/db/tables.dart';
import 'package:pristie/src/core/result/result.dart';
import 'package:pristie/src/core/scope/data_scope.dart';

Future<void> insertItem(
  OfflineDatabase database,
  String id, {
  String data = '{"value":1}',
  Map<String, Object?> extra = const <String, Object?>{},
}) async {
  final result = await database.transaction((tx) async {
    await tx.insert(offlineItemsTable, <String, Object?>{
      'id': id,
      'data_json': data,
      'version': '1',
      'deleted_at': null,
      'updated_at': 1000,
      ...extra,
    });
  });
  expectOk(result);
}

Future<List<Map<String, Object?>>> readItems(
  OfflineDatabase database,
  DataScope scope,
) async {
  final result = await database.query(
    OfflineQuery(table: offlineItemsTable, scope: scope),
  );
  expectOk(result);
  return (result as Ok<List<Map<String, Object?>>>).data;
}

void expectOk<T>(Result<T> result) {
  expect(result, isA<Ok<T>>(), reason: 'Expected success, got $result');
}

void expectLocalPersistence<T>(Result<T> result) {
  expect(result, isA<Err<T>>(), reason: 'Expected typed failure, got $result');
  final failure = (result as Err<T>).failure;
  expect(failure, const AppFailure.localPersistence());
}
