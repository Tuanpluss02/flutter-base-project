# 06 — Local Database (Drift)

## 1. Setup

- `core/database/app_database.dart` declares `@DriftDatabase(tables: [...], daos: [...])`. The table/DAO lists are a **merge hotspot**: add entries alphabetically, one per line.
- Tables live in their feature: `features/<f>/data/local/tables/<name>_table.dart`; DAOs in `.../daos/<name>_dao.dart` (`@DriftAccessor`). Core tables (`sync_state`, `outbox_operations`, `sync_quarantine`, `query_results`) live in `core/database/tables/`.
- Open the DB in a **background isolate** (`NativeDatabase.createInBackground`). Run on app start inside `bootstrap()`; expose via DI as a singleton.
- `build.yaml` options: `store_date_time_values_as_text: true` (**ms precision, UTC ISO-8601**), `sql.dialect: sqlite`, modular code generation off unless the table count justifies it (ADR), and `build_extensions` redirecting all `.g.dart` output into `lib/generated/{{}}.g.dart` (ADR-0005).
- `beforeOpen`: `PRAGMA foreign_keys = ON`, `PRAGMA journal_mode = WAL`, `PRAGMA busy_timeout = 5000`.

## 2. Table conventions

- Class name: plural noun (`Listings`); `@DataClassName('ListingRow')`; table name `listings` (snake_case plural).
- Primary key: `TEXT id` (server/client UUID). No autoincrement ids for synced entities. Drift does **not** infer a PK from a column named `id`: every table MUST override `Set<Column> get primaryKey => {id};` (otherwise SQLite uses `rowid` and `insertAllOnConflictUpdate` will insert duplicates instead of upserting).
- Mandatory columns per doc 02 §4 (`server_updated_at`, `is_deleted`, `synced_at`; plus `sync_status`, `local_updated_at`, `base_server_updated_at` for `OutboxWrite`) are shared via table mixins in `lib/core/database/tables/sync_table_mixins.dart`:
  - `mixin SyncedTableMixin on Table` (`id`, `serverUpdatedAt`, `isDeleted`, `syncedAt`, `primaryKey => {id}`).
  - `mixin OutboxTableMixin on Table` (`syncStatus` via `text().map(const SyncRowStatusConverter())()`, `localUpdatedAt`, `baseServerUpdatedAt`) — applied together as `with SyncedTableMixin, OutboxTableMixin` (both `on Table`; never `mixin Outbox on Synced`).
  - Table mixins provide only these common columns + PK: each feature table still explicitly declares `@DataClassName`, `@TableIndex`, `tableName`, foreign keys, `search_text`, and feature columns.
- Timestamps: `dateTime()` (stored as text UTC). The raw server cursor string is kept in `server_updated_at` (TEXT) and in `sync_state.cursor`; never round-trip it through local-time `DateTime`.
- Enums: `TypeConverter<MyEnum, String>` using explicit `wireValue` (never Drift's `textEnum`, which relies on `.name`).
- JSON/complex columns: `TypeConverter` with `freezed`/`json_serializable` models; do not store JSON for fields you filter/sort on — promote them to real columns.
- **Index** every column used in `WHERE`/`ORDER BY` of list queries (e.g. `price`, `district_id`, `status`, `server_updated_at`, `(is_deleted, status)`); declare with `@TableIndex`.
- **Local text search (Vietnamese diacritic-insensitive):** for `mirror` tables with local search (e.g. `listings`), persist a normalized `search_text` column (lowercase + stripped Vietnamese diacritics, computed in the DTO→Row mapper) and query against the normalized search term, or configure an FTS5 virtual table with `tokenize='unicode61 remove_diacritics 2'`.
- Foreign keys declared with `references(...)` + `onDelete` explicitly chosen.
- Money/area: store as integer minor units / integer or decimal-as-text with a converter; never `double` for money.

## 3. DAO rules

- DAOs expose `Stream<List<Row>> watchX(filter)`, `Stream<Row?> watchById(id)`, and write methods used only by repositories/sync specs.
- All list queries filter `is_deleted = false` by default (use a shared query extension on `SimpleSelectStatement` for `SyncedTableMixin` tables, not a generic DAO base class or methods inside the table mixin).
- Batch writes: use the top-level helper `upsertChunked(db, table, rows, chunkSize: 500)` in `lib/core/database/` wrapping `batch((b) => b.insertAllOnConflictUpdate(table, chunk))` inside a `transaction`.
- Streams for lists use `LIMIT`/pagination; never `watch()` an unbounded table over a large result set.
- DAOs know nothing about DTOs or entities; mappers live in `data/mappers`.

## 4. Migrations

- `schemaVersion` is a single integer in `AppDatabase`. Every schema change increments it.
- Use `drift_dev schema dump` to store a snapshot per version in `drift_schemas/` (**committed**: snapshots are source, not generated code). Everything derived from the snapshots is generated into `generated/` folders and git-ignored (ADR-0005, ADR-0013), and `make gen` regenerates it:
  - `dart run drift_dev schema steps drift_schemas/ lib/generated/core/database/schema_versions.g.dart` → step-by-step migration helpers used by `AppDatabase.migration`.
  - `dart run drift_dev schema generate drift_schemas/ test/generated/migrations/` → `SchemaVerifier` helpers for migration tests.
- **Adding a table or column is always a schema change** (rule 13): bump `schemaVersion`, dump the snapshot, add a step, add a test. There is no "unversioned" phase after T-030.
- **Never edit a released migration or snapshot.** Add a new step.
- **Migration tests** (`SchemaVerifier`) for every version jump N→N+1 and the full chain from the oldest supported version; assert data preservation for user-owned tables (outbox, pending entity rows, session-bound data).
- **Cache tables may be rebuilt**: for `CacheOnly` tables a migration MAY drop-and-recreate and reset the matching `sync_state` row (forcing a full resync) — only if the table holds no unsynced user data. `outbox_operations` and any `OutboxWrite` table with `sync_status != synced` rows MUST be migrated in place.
- A destructive reset of the whole DB is forbidden in production builds.
- Migrations must be idempotent-safe (wrapped in a transaction by Drift) and fast (< 1 s typical); heavy data transforms are chunked.

## 5. Encryption (ADR-0003, default: enabled)

- SQLCipher via `sqlcipher_flutter_libs` (**do not** add `sqlite3_flutter_libs` at the same time — both bundle native SQLite binaries and will collide on Android/iOS); DB key = 256-bit random generated on first run, stored in `flutter_secure_storage` (`first_unlock_this_device` on iOS; Android Keystore-backed). Pass `PRAGMA key = "x'...'"` inside the `setup` callback of `NativeDatabase.createInBackground`. Never derive the key from user input; never log it.
- Opening with a wrong/missing key (e.g. restored backup on a new device): delete the DB file and start fresh, then full resync; pending outbox ops are lost → this is why backups of the DB are disabled (doc 11).
- Encryption must be switchable through config for tests (plain in-memory DB in tests).

## 6. Performance guidance

- Target: list queries < 16 ms on a mid-range device for ≤ 5k rows with indexes.
- Avoid `SELECT *` joins in streams that emit often; select needed columns for list cards (`ListingSummaryRow`) and fetch full rows for detail.
- Use `EXPLAIN QUERY PLAN` in tests for the hottest queries; assert an index is used (no `SCAN` on large tables).
- Keep write transactions short; do not do network or heavy mapping inside a transaction.
- Provide a `DatabaseMaintenance` task: periodic `PRAGMA optimize`, prune `done` outbox rows (none kept), prune cache rows not referenced for > 90 days **only** for `queryScoped` caches; `VACUUM` only on explicit user/maintenance action.

## 7. Testing

- Use `NativeDatabase.memory()` (or `DatabaseConnection` with executor in-memory) via a test helper `createTestDb()` in `test/support/`.
- DAO tests: CRUD, filters, ordering, tombstone exclusion, stream emissions (`expectLater(dao.watch..., emitsInOrder([...]))`).
- Migration tests per §4 (they import the generated `test/generated/migrations/schema*.dart`; run `make gen` first). Query-plan tests for hot queries per §6.
