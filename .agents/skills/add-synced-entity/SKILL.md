---
name: add-synced-entity
description: Add a read-only cached entity (CacheOnly mirror or queryScoped) with Drift table, DAO, SyncSpec, and repository streams.
---

# Skill: Add Synced Entity (`CacheOnly`)

Read first: `docs/02-offline-first-and-sync.md`, `docs/05-networking-and-directus.md`, `docs/06-database-drift.md`, `docs/15-data-source-decision.md`.

## Steps

1. **Update `FEATURE.md` Contract (`docs/01` §8, `docs/15` §7):**
   - Record the Data Decision Record (Q1–Q6 answers), Sync Scope (`mirror` ≤ 5k rows & ≤ 5 MB vs `queryScoped`), TTL, deletion strategy (`softDelete | idReconcile | fullRefresh`), Directus collection + fields, and table/indexes.
2. **Drift Table (`lib/features/<feature>/data/local/tables/<plural>_table.dart`):**
   - `@DataClassName('<Name>Row')`
   - Mix in `SyncedTableMixin` (`class <Plural> extends Table with SyncedTableMixin`), which supplies `id` (UUID PK), `serverUpdatedAt` (TEXT, raw server string), `isDeleted` (BOOL default `false`), `syncedAt` (DATETIME), and `primaryKey => {id}` (Drift does **not** infer PK from a column named `id`).
   - Add `@TableIndex` for columns used in `WHERE`/`ORDER BY`. If local text search is required, include a normalized `searchText` column (lowercase + stripped Vietnamese diacritics).
3. **DAO (`lib/features/<feature>/data/local/daos/<name>_dao.dart`):**
   - Expose `Stream<List<<Name>Row>> watch...` filtering `isDeleted.equals(false)` by default (via the shared `SimpleSelectStatement` extension on `SyncedTableMixin`), with `LIMIT`.
   - Expose batch upsert via the core helper `upsertChunked(db, table, rows, chunkSize: 500)` and tombstone methods inside transactions.
   - `queryScoped` only: page queries join the core `query_results` table (`collection, query_key ORDER BY position`); never create a per-feature results table.
4. **Register in `AppDatabase` (`lib/core/database/app_database.dart`):**
   - Add table and DAO alphabetically (merge hotspot). A new table is always a schema change: follow the `db-migration` skill (version bump + snapshot + `make gen` + migration test).
5. **Implement `<Name>SyncSpec` (`lib/features/<feature>/data/sync/<name>_sync_spec.dart`):**
   - Configure `collection`, `schemaVersion`, `ttl`, `scope` (`mirror` vs `queryScoped`), `requiresAuth`, `fetchPage`, and `applyPage` (wrapping per-row DTO→Row mapping to quarantine poison rows per `docs/07` §10).
   - Register alphabetically in `lib/core/sync/sync_registry.dart`.
6. **Implement Repository (`lib/features/<feature>/data/repositories/<name>_repository_impl.dart`):**
   - `watch...` streams from DAO mapped to domain entities; `refresh()` delegates to `SyncCoordinator.requestSync`; `watchSyncStatus()` delegates to `SyncCoordinator.watchStatus`.
7. **Tests:**
   - DAO tests (incl. a re-upsert of the same `id` leaves exactly one row) + `EXPLAIN QUERY PLAN` test for list queries.
   - Sync spec tests covering scenarios 1–7, 19–21 from `docs/09` §7.
