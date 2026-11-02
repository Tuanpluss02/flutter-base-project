import 'package:pristie/src/core/offline/db/offline_database.dart';
import 'package:pristie/src/core/offline/db/tables.dart';

/// Current offline schema version.
const offlineSchemaVersion = 2;

/// Creates the current offline schema from scratch.
Future<void> createOfflineSchema(OfflineDatabaseExecutor db) async {
  await db.execute(
    'CREATE TABLE $offlineItemsTable ('
    'id TEXT NOT NULL, account_id TEXT NOT NULL, tenant_id TEXT NOT NULL, '
    'data_json TEXT NOT NULL, version TEXT, deleted_at INTEGER, '
    'updated_at INTEGER NOT NULL, pending_overlay_json TEXT, '
    'PRIMARY KEY(account_id, tenant_id, id))',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS offline_items_scope_updated ON '
    '$offlineItemsTable(account_id, tenant_id, updated_at)',
  );
  await db.execute(
    'CREATE TABLE $offlineOutboxTable ('
    'id TEXT NOT NULL, account_id TEXT NOT NULL, tenant_id TEXT NOT NULL, '
    'data_scope_epoch INTEGER NOT NULL, entity_key TEXT NOT NULL, '
    'operation TEXT NOT NULL, payload_version INTEGER NOT NULL, '
    'payload_json TEXT NOT NULL, base_version TEXT, sequence INTEGER NOT NULL, '
    'state TEXT NOT NULL, attempt_count INTEGER NOT NULL DEFAULT 0, '
    'next_attempt_at INTEGER, lease_owner TEXT, lease_expires_at INTEGER, '
    'idempotency_key TEXT NOT NULL, created_at INTEGER NOT NULL, '
    'PRIMARY KEY(account_id, tenant_id, id))',
  );
  await db.execute(
    'CREATE UNIQUE INDEX IF NOT EXISTS offline_outbox_sequence ON '
    '$offlineOutboxTable(account_id, tenant_id, sequence)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS offline_outbox_claim ON '
    '$offlineOutboxTable(account_id, tenant_id, state, sequence)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS offline_outbox_entity ON '
    '$offlineOutboxTable(account_id, tenant_id, entity_key, sequence)',
  );
  await db.execute(
    'CREATE TABLE $offlineConflictsTable ('
    'id TEXT NOT NULL, account_id TEXT NOT NULL, tenant_id TEXT NOT NULL, '
    'operation_id TEXT NOT NULL, local_json TEXT NOT NULL, '
    'remote_json TEXT NOT NULL, base_version TEXT, server_version TEXT, '
    'created_at INTEGER NOT NULL, PRIMARY KEY(account_id, tenant_id, id))',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS offline_conflicts_operation ON '
    '$offlineConflictsTable(account_id, tenant_id, operation_id)',
  );
  await db.execute(
    'CREATE TABLE $offlineSyncStateTable ('
    'dataset TEXT NOT NULL, account_id TEXT NOT NULL, tenant_id TEXT NOT NULL, '
    'cursor TEXT, last_synced_at INTEGER, min_supported_cursor TEXT, '
    'resync_required INTEGER NOT NULL DEFAULT 0, '
    'PRIMARY KEY(account_id, tenant_id, dataset))',
  );
  await db.execute(
    'CREATE TABLE $offlineMetaTable ('
    'key TEXT PRIMARY KEY, value TEXT NOT NULL)',
  );
}

/// Applies non-destructive schema upgrades. Unknown or older versions fail
/// instead of silently resetting local data.
Future<void> upgradeOfflineSchema(
  OfflineDatabaseExecutor db,
  int oldVersion,
  int newVersion,
) async {
  if (newVersion != offlineSchemaVersion ||
      oldVersion > newVersion ||
      oldVersion < 1) {
    throw StateError('Unsupported offline schema version');
  }
  if (oldVersion == newVersion) return;
  if (oldVersion != 1) {
    throw StateError('Unsupported offline schema upgrade path');
  }
  await db.execute(
    'ALTER TABLE $offlineItemsTable '
    'ADD COLUMN pending_overlay_json TEXT',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS offline_items_scope_updated ON '
    '$offlineItemsTable(account_id, tenant_id, updated_at)',
  );
  await db.execute(
    'CREATE UNIQUE INDEX IF NOT EXISTS offline_outbox_sequence ON '
    '$offlineOutboxTable(account_id, tenant_id, sequence)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS offline_outbox_claim ON '
    '$offlineOutboxTable(account_id, tenant_id, state, sequence)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS offline_outbox_entity ON '
    '$offlineOutboxTable(account_id, tenant_id, entity_key, sequence)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS offline_conflicts_operation ON '
    '$offlineConflictsTable(account_id, tenant_id, operation_id)',
  );
}
