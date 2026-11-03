import 'dart:io';

import 'package:base/src/core/offline/db/offline_database.dart';

/// In-memory table used by the fake SQL engine.
final class FakeTable {
  FakeTable(this.columns);

  final Set<String> columns;
  final List<Map<String, Object?>> rows = <Map<String, Object?>>[];
}

/// In-memory state for one fake database file.
final class FakeDatabaseStore {
  FakeDatabaseStore({required this.password, required this.schemaVersion});

  String password;
  int schemaVersion;
  final Map<String, FakeTable> tables = <String, FakeTable>{};
}

/// Fake encrypted-database opener used by unit tests.
///
/// It emulates the fail-closed behaviour that matters to the offline layer:
/// wrong keys and corrupted files throw, rekey changes the accepted password,
/// migrations run without destroying rows and closing/reopening keeps data.
final class FakeOfflineDatabaseOpener {
  final Map<String, FakeDatabaseStore> stores = <String, FakeDatabaseStore>{};
  final Set<String> corruptedPaths = <String>{};
  int openAttempts = 0;
  int createCount = 0;
  int upgradeCount = 0;
  String? lastPassword;

  /// Seeds an existing database file with [schemaVersion].
  FakeDatabaseStore seed({
    required String path,
    required String password,
    required int schemaVersion,
  }) {
    final store = FakeDatabaseStore(
      password: password,
      schemaVersion: schemaVersion,
    );
    stores[path] = store;
    return store;
  }

  /// Opens a fake database file, running create/upgrade callbacks as sqflite
  /// would.
  Future<OfflineDatabaseConnection> call({
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
    openAttempts++;
    lastPassword = password;
    if (corruptedPaths.contains(path)) {
      throw const FormatException('database disk image is malformed (code 11)');
    }
    final fileExists = await File(path).exists();
    if (!fileExists) stores.remove(path);
    final existing = stores[path];
    final store =
        existing ?? FakeDatabaseStore(password: password, schemaVersion: 0);
    final connection = FakeOfflineConnection(store);
    if (existing == null) {
      createCount++;
      await onCreate(connection);
      store.schemaVersion = version;
      stores[path] = store;
    } else if (existing.password != password) {
      throw const FormatException('file is not a database (code 26)');
    } else if (existing.schemaVersion > version) {
      throw StateError('Offline schema downgrade is unsupported');
    } else if (existing.schemaVersion < version) {
      upgradeCount++;
      await onUpgrade(connection, existing.schemaVersion, version);
      existing.schemaVersion = version;
    }
    await File(path).writeAsBytes(const [0, 1, 2, 3]);
    return connection;
  }
}

/// Fake connection backed by [FakeDatabaseStore].
final class FakeOfflineConnection implements OfflineDatabaseConnection {
  FakeOfflineConnection(this.store);

  final FakeDatabaseStore store;
  bool _closed = false;

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    _ensureOpen();
    final normalized = sql.trim();
    final create = RegExp(
      r'^CREATE TABLE (\w+)\s*\((.*)\)$',
      dotAll: true,
    ).firstMatch(normalized);
    if (create != null) {
      final columns = <String>{};
      for (final part in _splitTopLevel(create.group(2)!)) {
        final token = part.trim().split(RegExp(r'\s+')).first;
        final keyword = token.toUpperCase();
        if (const {
          'PRIMARY',
          'UNIQUE',
          'FOREIGN',
          'CONSTRAINT',
        }.contains(keyword)) {
          continue;
        }
        if (token.isNotEmpty) columns.add(token);
      }
      store.tables[create.group(1)!] = FakeTable(columns);
      return;
    }
    final alter = RegExp(r'^ALTER TABLE (\w+) ADD COLUMN (\w+)')
        .firstMatch(normalized);
    if (alter != null) {
      final table = store.tables[alter.group(1)!];
      if (table == null) throw StateError('Missing table ${alter.group(1)}');
      table.columns.add(alter.group(2)!);
      for (final row in table.rows) {
        row.putIfAbsent(alter.group(2)!, () => null);
      }
      return;
    }
    if (normalized.startsWith('CREATE INDEX') ||
        normalized.startsWith('CREATE UNIQUE INDEX')) {
      return;
    }
    final rekey = RegExp(r"^PRAGMA rekey = '([^']*)'$").firstMatch(normalized);
    if (rekey != null) {
      store.password = rekey.group(1)!;
      return;
    }
    throw UnsupportedError('Unsupported SQL: $sql');
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values) async {
    _ensureOpen();
    final target = _table(table);
    _checkColumns(target, values);
    final rows = target.rows;
    rows.add(<String, Object?>{...values});
    return rows.length;
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    _ensureOpen();
    final target = _table(table);
    _checkColumns(target, values);
    final rows = target.rows;
    final matches = rows
        .where((row) => _matches(row, where, whereArgs))
        .toList(growable: false);
    for (final row in matches) {
      row.addAll(values);
    }
    return matches.length;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    _ensureOpen();
    var rows = _table(table).rows
        .where((row) => _matches(row, where, whereArgs))
        .toList();
    if (orderBy != null) {
      final parts = orderBy.trim().split(RegExp(r'\s+'));
      final column = parts.first;
      final ascending = parts.length < 2 || parts[1].toUpperCase() != 'DESC';
      rows.sort((left, right) {
        final a = left[column];
        final b = right[column];
        if (a == b) return 0;
        if (a == null) return ascending ? -1 : 1;
        if (b == null) return ascending ? 1 : -1;
        final compared = (a as Comparable<Object?>).compareTo(b);
        return ascending ? compared : -compared;
      });
    }
    if (limit != null) rows = rows.take(limit).toList();
    return rows.map((row) => <String, Object?>{...row}).toList(growable: false);
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(OfflineDatabaseExecutor tx) action,
  ) async {
    _ensureOpen();
    final snapshot = _snapshot();
    try {
      return await action(this);
    } catch (_) {
      _restore(snapshot);
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    _closed = true;
  }

  FakeTable _table(String name) {
    final table = store.tables[name];
    if (table == null) throw StateError('Missing table $name');
    return table;
  }

  void _checkColumns(FakeTable table, Map<String, Object?> values) {
    for (final column in values.keys) {
      if (!table.columns.contains(column)) {
        throw StateError('Unknown column $column');
      }
    }
  }

  void _ensureOpen() {
    if (_closed) throw StateError('Database is closed');
  }

  Map<String, FakeTable> _snapshot() {
    return <String, FakeTable>{
      for (final entry in store.tables.entries)
        entry.key: FakeTable(<String>{...entry.value.columns})
          ..rows.addAll(
            entry.value.rows.map((row) => <String, Object?>{...row}),
          ),
    };
  }

  void _restore(Map<String, FakeTable> snapshot) {
    store.tables
      ..clear()
      ..addAll(snapshot);
  }
}

List<String> _splitTopLevel(String body) {
  var depth = 0;
  final parts = <String>[];
  final buffer = StringBuffer();
  for (final codeUnit in body.codeUnits) {
    final character = String.fromCharCode(codeUnit);
    if (character == '(') depth++;
    if (character == ')') depth--;
    if (character == ',' && depth == 0) {
      parts.add(buffer.toString());
      buffer.clear();
      continue;
    }
    buffer.write(character);
  }
  parts.add(buffer.toString());
  return parts;
}

bool _matches(
  Map<String, Object?> row,
  String? where,
  List<Object?>? whereArgs,
) {
  if (where == null || where.isEmpty) return true;
  final arguments = whereArgs ?? const <Object?>[];
  final comparisons = RegExp(r'(\w+)\s*=\s*\?').allMatches(where).toList();
  if (comparisons.length != arguments.length) {
    throw UnsupportedError('Unsupported WHERE clause: $where');
  }
  for (var index = 0; index < comparisons.length; index++) {
    final column = comparisons[index].group(1)!;
    if (row[column] != arguments[index]) return false;
  }
  return true;
}
