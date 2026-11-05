---
name: db-migration
description: Evolve the Drift SQLite schema safely with version bump, schema snapshot, step-by-step migration, and SchemaVerifier tests.
---

# Skill: Database Migration

Read first: `docs/06-database-drift.md` §4, §7, ADR-0005 & ADR-0013 in `docs/14-decisions.md`.

Applies to **every** table or column addition/change after T-030 (there is no unversioned phase).

## Rules

1. **Never edit an already-released migration or schema snapshot.**
2. **Increment `schemaVersion`** in `lib/core/database/app_database.dart`.
3. **Export Schema Snapshot (source, committed):**
   - Run `dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/` and commit the new `drift_schemas/drift_schema_v<N>.json`.
4. **Regenerate derived code into `generated/` (git-ignored, never hand-edited):**
   - Run `make gen`. It produces, in order: `lib/generated/core/database/schema_versions.g.dart` (`drift_dev schema steps`), `test/generated/migrations/` (`drift_dev schema generate`), then `build_runner` output under `lib/generated/**`.
   - Never `git add` these files (A13 fails).
5. **Write Migration Logic (`migration` in `AppDatabase`, using the `stepByStep` helper imported from `package:<app>/generated/core/database/schema_versions.g.dart`):**
   - **User-owned / `OutboxWrite` tables** (`outbox_operations`, any table with `sync_status != synced`): MUST be migrated in-place preserving all rows.
   - **`CacheOnly` tables**: may be altered in-place, or dropped-and-recreated **only if** the corresponding `sync_state` row (and its `query_results` rows for `queryScoped`) is reset in the same transaction to force a full resync.
6. **Write Migration Tests (`test/core/database/migrations_test.dart`):**
   - Use `SchemaVerifier` with the generated helpers in `test/generated/migrations/` to test `v(N-1) → vN` and the full chain from `v1 → vN`.
   - Seed `outbox_operations` and pending `OutboxWrite` rows before migrating and assert 100% data preservation after migration.
7. **Verify on a clean state:** `git clean -fdX lib/generated test/generated && make gen && make check`.
