import 'package:base/src/core/offline/db/offline_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Adapts one SQLCipher [Database] to the package-neutral executor contract.
final class SqlcipherConnection implements OfflineDatabaseConnection {
  SqlcipherConnection(this._database);

  final Database _database;

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) =>
      _database.execute(sql, arguments);

  @override
  Future<int> insert(String table, Map<String, Object?> values) =>
      _database.insert(table, values);

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    required String where,
    required List<Object?> whereArgs,
  }) => _database.update(table, values, where: where, whereArgs: whereArgs);

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) => _database.query(
    table,
    where: where,
    whereArgs: whereArgs,
    orderBy: orderBy,
    limit: limit,
  );

  @override
  Future<T> transaction<T>(
    Future<T> Function(OfflineDatabaseExecutor tx) action,
  ) =>
      _database.transaction((txn) => action(SqlcipherTransactionExecutor(txn)));

  @override
  Future<void> close() => _database.close();
}

/// Adapts a sqflite [Transaction] to the package-neutral executor contract.
final class SqlcipherTransactionExecutor implements OfflineDatabaseExecutor {
  SqlcipherTransactionExecutor(this._transaction);

  final Transaction _transaction;

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) =>
      _transaction.execute(sql, arguments);

  @override
  Future<int> insert(String table, Map<String, Object?> values) =>
      _transaction.insert(table, values);

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    required String where,
    required List<Object?> whereArgs,
  }) => _transaction.update(table, values, where: where, whereArgs: whereArgs);

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) => _transaction.query(
    table,
    where: where,
    whereArgs: whereArgs,
    orderBy: orderBy,
    limit: limit,
  );
}
