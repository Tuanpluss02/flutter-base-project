const offlineItemsTable = 'offline_items';
const offlineOutboxTable = 'offline_outbox';
const offlineConflictsTable = 'offline_conflicts';
const offlineSyncStateTable = 'offline_sync_state';
const offlineMetaTable = 'offline_meta';

/// Tables whose rows are always partitioned by account and tenant scope.
const scopedOfflineTables = {
  offlineItemsTable,
  offlineOutboxTable,
  offlineConflictsTable,
  offlineSyncStateTable,
};

/// Columns owned by the database layer and never writable by callers.
const scopeColumns = {'account_id', 'tenant_id'};

const offlineItemsColumns = {
  'id',
  'account_id',
  'tenant_id',
  'data_json',
  'version',
  'deleted_at',
  'updated_at',
  'pending_overlay_json',
};

const offlineOutboxColumns = {
  'id',
  'account_id',
  'tenant_id',
  'data_scope_epoch',
  'entity_key',
  'operation',
  'payload_version',
  'payload_json',
  'base_version',
  'sequence',
  'state',
  'attempt_count',
  'next_attempt_at',
  'lease_owner',
  'lease_expires_at',
  'idempotency_key',
  'created_at',
};

const offlineConflictsColumns = {
  'id',
  'account_id',
  'tenant_id',
  'operation_id',
  'local_json',
  'remote_json',
  'base_version',
  'server_version',
  'created_at',
};

const offlineSyncStateColumns = {
  'dataset',
  'account_id',
  'tenant_id',
  'cursor',
  'last_synced_at',
  'min_supported_cursor',
  'resync_required',
};

const offlineMetaColumns = {'key', 'value'};

/// Exact column allowlist per table, used to reject unknown or disguised keys.
const offlineTableColumns = {
  offlineItemsTable: offlineItemsColumns,
  offlineOutboxTable: offlineOutboxColumns,
  offlineConflictsTable: offlineConflictsColumns,
  offlineSyncStateTable: offlineSyncStateColumns,
  offlineMetaTable: offlineMetaColumns,
};
