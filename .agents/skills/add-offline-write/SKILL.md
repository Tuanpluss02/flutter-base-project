---
name: add-offline-write
description: Add an offline-capable write flow (OutboxWrite) with optimistic local persistence, outbox coalescing, and conflict resolution.
---

# Skill: Add Offline Write (`OutboxWrite`)

Read first: `docs/02-offline-first-and-sync.md` §4, §8–9, `docs/05-networking-and-directus.md`, `docs/06-database-drift.md`, ADR-0004 & ADR-0014 in `docs/14-decisions.md`.

## Steps

1. **Declare Policy in `FEATURE.md`:**
   - Set policy to `OutboxWrite` and choose `ConflictPolicy` (`serverWins`, `clientWins`, `lastWriteWins`, `fieldMerge`, or `askUser`), plus the Data Decision Record (`docs/15` §7).
2. **Table Columns (`docs/02` §4, `docs/06` §2):**
   - Mix in both `SyncedTableMixin` and `OutboxTableMixin` (`class <Plural> extends Table with SyncedTableMixin, OutboxTableMixin`), which adds:
     - `syncStatus` (`synced | pending | failed | conflict` via `SyncRowStatusConverter` explicit `wireValue`)
     - `localUpdatedAt` (DATETIME)
     - `baseServerUpdatedAt` (TEXT nullable — holds `server_updated_at` the edit was based on)
   - Client-created entities MUST generate a UUID v4 via the injected UUID generator as primary key.
3. **Atomic Local Write + Outbox Enqueue (`docs/02` §8):**
   - In a **single Drift transaction** (through the core outbox API from T-042; never insert into `outbox_operations` with your own SQL):
     1. Upsert/update the entity row with `syncStatus = SyncRowStatus.pending` and updated `localUpdatedAt` (from the injected `Clock`). On the **first** local edit of a synced row, copy its current `serverUpdatedAt` into `baseServerUpdatedAt`; keep it unchanged on further edits.
     2. Enqueue/coalesce the operation in `outbox_operations` with `payload` = minimal patch (changed fields only), `base_server_updated_at` = the row's `baseServerUpdatedAt` (null for creates), and `depends_on` = parent outbox op ID when creating/updating a child under an offline-created parent. Coalescing: `create + update → create`, `update + update → merged update`, `create + delete → drop both`, `update + delete → delete`.
   - After commit, call `SyncCoordinator.requestFlush()` (non-blocking, fire-and-forget). The coordinator debounces flushes by 500 ms, so do not add your own debounce or call it inside the transaction.
4. **Conflict Detection & Resolution (`docs/02` §9, ADR-0004):**
   - Use the core `ConflictDetector` (Option B by default: pre-flight `GET /items/<c>/<id>?fields=id,date_updated` comparing `date_updated` against `base_server_updated_at` before `PATCH`, or Option A `409` from server hook) and apply the declared `ConflictPolicy`.
5. **Protect Pending Local Edits During Delta Sync (`docs/02` §6, §9):**
   - Ensure `applyPage` skips overwriting local fields of rows that have a pending outbox operation for that `id`.
6. **UI States (`docs/02` §7, `docs/08` §5):**
   - Render `AppPendingBadge(syncStatus)` and provide Retry/Discard actions on `failed` or `conflict` rows.
7. **Tests (`docs/09` §7):**
   - Cover sync scenarios 9–17 (atomic write+enqueue, coalescing, FIFO per entity + `depends_on` ordering, retry/backoff, 401 refresh, conflict detection B + policy outcome, delta non-overwrite).
