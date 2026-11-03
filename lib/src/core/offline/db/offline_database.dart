import 'package:base/src/core/result/result.dart';
import 'package:base/src/core/scope/data_scope.dart';

/// Local persistence contract exposed to the rest of the application.
///
/// Implementations must never leak the underlying SQLite/SQLCipher package
/// and must never fall back to an unencrypted database.
abstract interface class OfflineDatabase {
  /// Opens the encrypted database for [scope].
  Future<Result<void>> open(DataScope scope);

  /// Closes the database and clears the active data scope.
  Future<Result<void>> close();

  /// Reads rows from a scoped table.
  Future<Result<List<Map<String, Object?>>>> query(OfflineQuery query);

  /// Runs [action] inside one database transaction.
  Future<Result<void>> transaction(
    Future<void> Function(OfflineTransaction tx) action,
  );

  /// Deletes local data and rotates to a fresh key after a controlled decision
  /// to re-sync from the server.
  Future<Result<void>> resetForResync();

  /// Rotates the database encryption key.
  Future<Result<void>> rekey();
}

/// A query that is always bound to one [DataScope].
final class OfflineQuery {
  const OfflineQuery({
    required this.table,
    required this.scope,
    this.whereSql,
    this.whereArgs = const [],
    this.orderBy,
    this.limit,
  });

  /// Scoped table name.
  final String table;

  /// Scope that must match the currently opened scope.
  final DataScope scope;

  /// Optional additional predicate. The scope predicate is always prepended.
  final String? whereSql;

  /// Arguments for [whereSql].
  final List<Object?> whereArgs;

  /// Optional SQL ordering clause.
  final String? orderBy;

  /// Optional row limit.
  final int? limit;
}

/// Transaction-bound operations. Scope columns are managed by the database.
abstract interface class OfflineTransaction {
  /// Inserts [values] into [table] using the active scope.
  Future<void> insert(String table, Map<String, Object?> values);

  /// Updates rows in [table] using the active scope.
  Future<void> update(
    String table,
    Map<String, Object?> values, {
    required String whereSql,
    required List<Object?> whereArgs,
  });

  /// Selects rows from [table] using [query].
  Future<List<Map<String, Object?>>> select(OfflineQuery query);
}

/// Narrow executor contract used by schema code so migrations stay testable
/// without depending on a concrete database package.
abstract interface class OfflineDatabaseExecutor {
  /// Executes a single SQL statement.
  Future<void> execute(String sql, [List<Object?>? arguments]);

  /// Inserts [values] into [table].
  Future<int> insert(String table, Map<String, Object?> values);

  /// Updates rows matching [where] in [table].
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    required String where,
    required List<Object?> whereArgs,
  });

  /// Queries [table] with an optional predicate, ordering and limit.
  Future<List<Map<String, Object?>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  });
}

/// Open database connection with transaction and lifecycle support.
abstract interface class OfflineDatabaseConnection
    implements OfflineDatabaseExecutor {
  /// Runs [action] inside one transaction.
  Future<T> transaction<T>(
    Future<T> Function(OfflineDatabaseExecutor tx) action,
  );

  /// Closes the native connection.
  Future<void> close();
}

/// Opens a native encrypted database and wires schema callbacks.
typedef OfflineDatabaseOpener = Future<OfflineDatabaseConnection> Function({
  required String path,
  required String password,
  required int version,
  required Future<void> Function(OfflineDatabaseExecutor db) onCreate,
  required Future<void> Function(
    OfflineDatabaseExecutor db,
    int oldVersion,
    int newVersion,
  )
  onUpgrade,
});
