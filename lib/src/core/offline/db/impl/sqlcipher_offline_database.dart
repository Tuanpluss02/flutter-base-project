import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:base/src/core/error/app_failure.dart';
import 'package:base/src/core/offline/db/backup_exclusion.dart';
import 'package:base/src/core/offline/db/database_key_manager.dart';
import 'package:base/src/core/offline/db/impl/sqlcipher_connection.dart';
import 'package:base/src/core/offline/db/migrations.dart';
import 'package:base/src/core/offline/db/offline_database.dart';
import 'package:base/src/core/offline/db/tables.dart';
import 'package:base/src/core/offline/policy/offline_config.dart';
import 'package:base/src/core/offline/scope/data_scope_store.dart';
import 'package:base/src/core/result/result.dart';
import 'package:base/src/core/scope/data_scope.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// SQLCipher-backed [OfflineDatabase].
///
/// The database is only opened when [OfflineConfig.enabled] is true. Any
/// failure while loading the key, opening, migrating or excluding the file
/// from backups is returned as [AppFailure.localPersistence] and never falls
/// back to plaintext storage.
final class SqlcipherOfflineDatabase implements OfflineDatabase {
  SqlcipherOfflineDatabase(
    this._keyManager,
    this._backupExclusion,
    this._scopeStore, {
    this.config = const OfflineConfig(),
    Future<Directory> Function()? directoryProvider,
    OfflineDatabaseOpener? opener,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory,
       _opener = opener ?? openSqlcipherConnection;

  /// File name used inside the application support directory.
  static const databaseFileName = 'base_offline.db';

  final DatabaseKeyManager _keyManager;
  final BackupExclusion _backupExclusion;
  final DataScopeStore _scopeStore;
  final OfflineConfig config;
  final Future<Directory> Function() _directoryProvider;
  final OfflineDatabaseOpener _opener;
  OfflineDatabaseConnection? _database;
  Uint8List? _activeKey;
  String? _path;
  Future<Result<void>>? _opening;
  Future<Result<void>>? _rekeying;

  /// Opens or creates the encrypted database for [scope].
  @override
  Future<Result<void>> open(DataScope scope) async {
    final inFlight = _opening;
    if (inFlight != null) {
      final result = await inFlight;
      if (result is Ok<void> && _scopeStore.scope == scope) return result;
      return result is Ok<void>
          ? const Result.err(AppFailure.localPersistence())
          : result;
    }
    final future = _open(scope);
    _opening = future;
    try {
      return await future;
    } finally {
      _opening = null;
    }
  }

  Future<Result<void>> _open(DataScope scope) async {
    if (!config.enabled || !_isValidScope(scope)) {
      return const Result.err(AppFailure.localPersistence());
    }
    if (_database != null) {
      return _scopeStore.scope == scope
          ? const Result.ok(null)
          : const Result.err(AppFailure.localPersistence());
    }
    try {
      final directory = await _directoryProvider();
      await directory.create(recursive: true);
      final path = '${directory.path}/$databaseFileName';
      _path = path;
      final directoryExclusion = await _backupExclusion.excludeFromBackup(
        directory.path,
      );
      if (directoryExclusion is Err<void>) {
        return Result.err(directoryExclusion.failure);
      }
      final exists = await File(path).exists();
      if (!exists) {
        final keyResult = await _keyManager.loadOrCreate();
        if (keyResult is Err<Uint8List>) return Result.err(keyResult.failure);
        final key = (keyResult as Ok<Uint8List>).data;
        await _keyManager.clearPending();
        final connection = await _openWithKey(path, key);
        return await _finishOpen(connection, key, scope, path);
      }
      final candidatesResult = await _keyManager.loadCandidates();
      if (candidatesResult is Err<DatabaseKeyCandidates>) {
        return Result.err(candidatesResult.failure);
      }
      final candidates = (candidatesResult as Ok<DatabaseKeyCandidates>).data;
      if (candidates.isEmpty) {
        return const Result.err(AppFailure.localPersistence());
      }
      OfflineDatabaseConnection? connection;
      Uint8List? usedKey;
      if (candidates.primary != null) {
        try {
          connection = await _openWithKey(path, candidates.primary!);
          usedKey = candidates.primary;
        } catch (_) {
          connection = null;
        }
      }
      if (connection == null && candidates.pending != null) {
        try {
          connection = await _openWithKey(path, candidates.pending!);
          usedKey = candidates.pending;
        } catch (_) {
          connection = null;
        }
      }
      if (connection == null || usedKey == null) {
        return const Result.err(AppFailure.localPersistence());
      }
      final finished = await _finishOpen(connection, usedKey, scope, path);
      if (finished is Err<void>) return finished;
      if (identical(usedKey, candidates.primary)) {
        if (candidates.pending != null) await _keyManager.clearPending();
      } else {
        await _keyManager.promote(usedKey);
      }
      return const Result.ok(null);
    } catch (_) {
      return const Result.err(AppFailure.localPersistence());
    }
  }

  Future<OfflineDatabaseConnection> _openWithKey(String path, Uint8List key) =>
      _opener(
        path: path,
        password: base64Encode(key),
        version: offlineSchemaVersion,
        onCreate: createOfflineSchema,
        onUpgrade: upgradeOfflineSchema,
      );

  Future<Result<void>> _finishOpen(
    OfflineDatabaseConnection connection,
    Uint8List key,
    DataScope scope,
    String path,
  ) async {
    _database = connection;
    _activeKey = key;
    try {
      final fileExclusion = await _backupExclusion.excludeFromBackup(path);
      if (fileExclusion is Err<void>) {
        await close();
        return Result.err(fileExclusion.failure);
      }
      _scopeStore.setScope(scope);
      return const Result.ok(null);
    } catch (_) {
      await close();
      return const Result.err(AppFailure.localPersistence());
    }
  }

  /// Closes the connection and releases the active scope.
  @override
  Future<Result<void>> close() async {
    final database = _database;
    _database = null;
    _activeKey = null;
    _scopeStore.setScope(null);
    if (database == null) return const Result.ok(null);
    try {
      await database.close();
      return const Result.ok(null);
    } catch (_) {
      return const Result.err(AppFailure.localPersistence());
    }
  }

  /// Reads rows from a scoped table.
  @override
  Future<Result<List<Map<String, Object?>>>> query(OfflineQuery query) async {
    final database = _database;
    if (database == null || query.scope != _scopeStore.scope) {
      return const Result.err(AppFailure.localPersistence());
    }
    final epoch = _scopeStore.epoch;
    try {
      final rows = await _select(database, query);
      if (!_scopeStore.isCurrent(query.scope, epoch)) {
        return const Result.err(AppFailure.localPersistence());
      }
      return Result.ok(rows);
    } catch (_) {
      return const Result.err(AppFailure.localPersistence());
    }
  }

  /// Runs [action] inside one transaction scoped to the current [DataScope].
  @override
  Future<Result<void>> transaction(
    Future<void> Function(OfflineTransaction tx) action,
  ) async {
    final database = _database;
    final scope = _scopeStore.scope;
    if (database == null || scope == null) {
      return const Result.err(AppFailure.localPersistence());
    }
    final epoch = _scopeStore.epoch;
    try {
      await database.transaction((nativeTx) async {
        await action(_ScopedTransaction(nativeTx, scope));
        if (!_scopeStore.isCurrent(scope, epoch)) {
          throw StateError('Offline scope changed during transaction');
        }
      });
      return const Result.ok(null);
    } catch (_) {
      return const Result.err(AppFailure.localPersistence());
    }
  }

  /// Deletes local data and the encryption keys after the caller has decided
  /// that a full re-sync is acceptable. The next open creates a fresh key.
  @override
  Future<Result<void>> resetForResync() async {
    final path = _path;
    if (path == null) return const Result.err(AppFailure.localPersistence());
    final closeResult = await close();
    if (closeResult is Err<void>) return closeResult;
    try {
      for (final suffix in const ['-wal', '-shm', '-journal']) {
        final file = File('$path$suffix');
        if (await file.exists()) await file.delete();
      }
      final main = File(path);
      if (await main.exists()) await main.delete();
    } catch (_) {
      return const Result.err(AppFailure.localPersistence());
    }
    final cleared = await _keyManager.clear();
    if (cleared is Err<void>) return cleared;
    _path = null;
    return const Result.ok(null);
  }

  /// Rotates the database key with `PRAGMA rekey` and persists the new key.
  @override
  Future<Result<void>> rekey() async {
    final inFlight = _rekeying;
    if (inFlight != null) return inFlight;
    final future = _rekey();
    _rekeying = future;
    try {
      return await future;
    } finally {
      _rekeying = null;
    }
  }

  Future<Result<void>> _rekey() async {
    final database = _database;
    final oldKey = _activeKey;
    if (database == null || oldKey == null) {
      return const Result.err(AppFailure.localPersistence());
    }
    final nextKey = _keyManager.generate();
    final staged = await _keyManager.stage(nextKey);
    if (staged is Err<void>) return staged;
    try {
      await database.execute("PRAGMA rekey = '${base64Encode(nextKey)}'");
    } catch (_) {
      await _keyManager.clearPending();
      return const Result.err(AppFailure.localPersistence());
    }
    _activeKey = nextKey;
    await _keyManager.promote(nextKey);
    return const Result.ok(null);
  }

  bool _isValidScope(DataScope scope) {
    final accountId = scope.accountId;
    final tenantId = scope.tenantId;
    return accountId.isNotEmpty &&
        accountId == accountId.trim() &&
        (tenantId == null ||
            (tenantId.isNotEmpty && tenantId == tenantId.trim()));
  }
}

/// Default SQLCipher opener. The password is always the Base64-encoded key.
Future<OfflineDatabaseConnection> openSqlcipherConnection({
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
}) async {
  final key = base64Decode(password);
  if (key.length != databaseKeyLength) {
    throw ArgumentError.value(key.length, 'password', 'Invalid key length');
  }
  final safePassword = base64Encode(key);
  final database = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: version,
      onConfigure: (db) async {
        final cipher = await db.rawQuery('PRAGMA cipher_version');
        if (cipher.isEmpty || cipher.first.values.firstOrNull == null) {
          throw StateError('SQLCipher is unavailable');
        }
        await db.execute("PRAGMA key = '$safePassword'");
        await db.rawQuery('SELECT count(*) FROM sqlite_master');
      },
      onCreate: (db, _) => onCreate(SqlcipherConnection(db)),
      onUpgrade: (db, oldVersion, newVersion) =>
          onUpgrade(SqlcipherConnection(db), oldVersion, newVersion),
      onDowngrade: (db, oldVersion, newVersion) =>
          throw StateError('Offline schema downgrade is unsupported'),
    ),
  );
  return SqlcipherConnection(database);
}

Future<List<Map<String, Object?>>> _select(
  OfflineDatabaseExecutor db,
  OfflineQuery query,
) async {
  _validateQuery(query);
  if (!scopedOfflineTables.contains(query.table)) {
    throw ArgumentError.value(query.table, 'table');
  }
  final where =
      'account_id = ? AND tenant_id = ?'
      '${query.whereSql == null ? '' : ' AND (${query.whereSql})'}';
  final rows = await db.query(
    query.table,
    where: where,
    whereArgs: [
      query.scope.accountId,
      query.scope.tenantId ?? '',
      ...query.whereArgs,
    ],
    orderBy: query.orderBy,
    limit: query.limit,
  );
  return rows.map((row) => Map<String, Object?>.from(row)).toList();
}

void _validateQuery(OfflineQuery query) {
  final limit = query.limit;
  if (limit != null && limit <= 0) {
    throw ArgumentError.value(limit, 'limit');
  }
  final whereSql = query.whereSql;
  if (whereSql != null) {
    final normalized = whereSql.toUpperCase();
    for (final keyword in const [
      'OR',
      'UNION',
      'EXCEPT',
      'INTERSECT',
      'PRAGMA',
      'ATTACH',
      'DETACH',
    ]) {
      if (RegExp('\\b$keyword\\b').hasMatch(normalized)) {
        throw ArgumentError.value(whereSql, 'whereSql');
      }
    }
    for (final marker in const [';', '--', '/*', '*/']) {
      if (whereSql.contains(marker)) {
        throw ArgumentError.value(whereSql, 'whereSql');
      }
    }
  }
  final orderBy = query.orderBy;
  if (orderBy != null) {
    final pattern = RegExp(
      r'^[A-Za-z_][A-Za-z0-9_]*(\s+(ASC|DESC))?'
      r'(,\s*[A-Za-z_][A-Za-z0-9_]*(\s+(ASC|DESC))?)*$',
      caseSensitive: false,
    );
    if (!pattern.hasMatch(orderBy.trim())) {
      throw ArgumentError.value(orderBy, 'orderBy');
    }
  }
}

final class _ScopedTransaction implements OfflineTransaction {
  _ScopedTransaction(this._db, this._scope);

  final OfflineDatabaseExecutor _db;
  final DataScope _scope;

  @override
  Future<void> insert(String table, Map<String, Object?> values) async {
    _checkTable(table);
    _checkValues(table, values);
    await _db.insert(table, {
      ...values,
      'account_id': _scope.accountId,
      'tenant_id': _scope.tenantId ?? '',
    });
  }

  @override
  Future<void> update(
    String table,
    Map<String, Object?> values, {
    required String whereSql,
    required List<Object?> whereArgs,
  }) async {
    _checkTable(table);
    _checkValues(table, values);
    _validateQuery(
      OfflineQuery(
        table: table,
        scope: _scope,
        whereSql: whereSql,
        whereArgs: whereArgs,
      ),
    );
    if (!scopedOfflineTables.contains(table)) {
      throw ArgumentError.value(table, 'table');
    }
    await _db.update(
      table,
      values,
      where: 'account_id = ? AND tenant_id = ? AND ($whereSql)',
      whereArgs: [_scope.accountId, _scope.tenantId ?? '', ...whereArgs],
    );
  }

  @override
  Future<List<Map<String, Object?>>> select(OfflineQuery query) {
    if (query.scope != _scope) throw StateError('Offline scope mismatch');
    return _select(_db, query);
  }

  void _checkTable(String table) {
    if (!scopedOfflineTables.contains(table)) {
      throw ArgumentError.value(table, 'table');
    }
  }

  void _checkValues(String table, Map<String, Object?> values) {
    final allowed = offlineTableColumns[table];
    if (allowed == null) throw ArgumentError.value(table, 'table');
    for (final key in values.keys) {
      if (!allowed.contains(key)) throw ArgumentError.value(key, 'column');
      if (scopeColumns.contains(key)) {
        throw ArgumentError.value(key, 'column');
      }
    }
  }
}
