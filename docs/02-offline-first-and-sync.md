# 02 — Offline-First and Sync

This is the most important document. Every data-touching task MUST follow it.

## 1. Principles

1. **The local DB is the single source of truth for the UI.** Widgets/Blocs observe `Stream`s from repositories that read Drift. They never render a network response directly.
2. **The network never blocks the UI.** Screens render from local data immediately; refresh happens in the background.
3. **Writes that must work offline go local first** (and are queued in the outbox). Everything else is online-only and says so.
4. **Server is authoritative** unless a feature explicitly declares another conflict policy.
5. **Every sync operation is idempotent and resumable.** Killing the app at any instruction must not corrupt state.
6. **Be honest in the UI:** show staleness, pending state, and failures; never silently drop user data.

## 2. Data policy per feature (declared in `FEATURE.md`)

| Policy | Meaning | Examples (real-estate app) |
|---|---|---|
| `CacheOnly` | Read-only mirror/cache of server data. Server wins always. | projects, listings, amenities, banners, agents, news |
| `OutboxWrite` | User can create/update/delete offline; changes are queued and synced. | favorites, saved searches, draft inquiry/viewing request, profile edits |
| `OnlineOnly` | Requires network; UI is blocked/disabled with a clear message offline. | payment, eKYC, deposit/booking confirmation, login, OTP |

Default for a new feature: `CacheOnly`. Choosing `OutboxWrite` requires a conflict policy (§9). Never make payment/eKYC/booking-confirmation offline-capable.

## 3. Sync scope: mirror vs query-scoped

| Scope | Use when | Behavior |
|---|---|---|
| `mirror` | Collection ≤ **5,000 rows** and ≤ ~5 MB of payload | Delta-sync the **whole** collection into the DB. Filtering/sorting/searching happen locally in SQL. Works fully offline. |
| `queryScoped` | Larger collections or server-side-only filtering | Cache result pages per `queryKey` (hash of filters+sort). Offline shows last cached results for that exact query; unseen queries show an offline empty-state. |

Choose in `FEATURE.md`; revisit when a collection grows past the threshold. Luxury-listing catalogs are expected to be `mirror`.

## 4. Local schema conventions (summary; details in doc 06)

Every **synced entity table** has:

| Column | Type | Meaning |
|---|---|---|
| `id` | TEXT PK | Server id (UUID). Client-created rows use client UUID v4 which becomes the server PK. |
| `server_updated_at` | TEXT (ISO-8601 UTC, ms precision) | Directus `date_updated` (fallback `date_created`) as received. Used as cursor. |
| `is_deleted` | BOOL default false | Tombstone (soft delete). Filtered out by all UI queries. |
| `synced_at` | DATETIME | When this row was last written by sync. |

`OutboxWrite` entity tables additionally have:

| Column | Type | Meaning |
|---|---|---|
| `sync_status` | TEXT enum `synced \| pending \| failed \| conflict` | Row-level state for UI badges |
| `local_updated_at` | DATETIME | Last local edit |
| `base_server_updated_at` | TEXT NULL | `server_updated_at` the edit was based on (conflict detection) |

Core tables (owned by `core/sync`):

```
sync_state(
  collection TEXT,            -- e.g. 'listings'
  query_key  TEXT,            -- '' for mirror scope
  cursor     TEXT NULL,       -- max server_updated_at processed (raw server string)
  last_synced_at DATETIME NULL,
  last_attempt_at DATETIME NULL,
  last_error TEXT NULL,
  has_more   BOOL DEFAULT false,   -- queryScoped pagination
  schema_version INT,         -- bump to force full resync
  PRIMARY KEY (collection, query_key)
)

outbox_operations(
  id TEXT PK,                 -- uuid, also used as idempotency key
  entity_type TEXT, entity_id TEXT,
  op TEXT,                    -- create | update | delete | custom
  payload TEXT,               -- JSON of the minimal change (patch), not the whole row
  base_server_updated_at TEXT NULL,
  status TEXT,                -- pending | in_flight | failed | conflict | done
  attempt_count INT DEFAULT 0, next_attempt_at DATETIME NULL, last_error TEXT NULL,
  depends_on TEXT NULL,       -- another outbox id that must complete first
  created_at DATETIME, updated_at DATETIME
)
INDEX (status, next_attempt_at); INDEX (entity_type, entity_id);

sync_quarantine(
  collection TEXT, entity_id TEXT, server_updated_at TEXT, error TEXT, created_at DATETIME,
  PRIMARY KEY (collection, entity_id)
)  -- rows the delta runner could not map (poison rows); retried on full resync / schemaVersion bump / app upgrade

query_results(
  collection TEXT,            -- owning collection, e.g. 'listings'
  query_key  TEXT,            -- hash of filters+sort (same key as sync_state.query_key)
  entity_id  TEXT,            -- id in the feature's entity table
  position   INT,             -- server order within this query
  PRIMARY KEY (collection, query_key, entity_id)
)
INDEX (collection, query_key, position);
-- queryScoped only. The entity rows themselves live in the feature table; this table only stores membership + order.
-- Pruned per doc 06 §6 (not referenced for > 90 days). has_more lives in sync_state.
```

## 5. Read flow (stale-while-revalidate)

```
Page opens → Bloc subscribes repo.watchX()  ─► Drift stream ─► UI (instant, from DB)
                  └─► repo.refresh()  (fire-and-forget, single-flight) ─► SyncCoordinator
                                                                   │ fetch delta
                                                                   ▼ upsert in one transaction
                                                             Drift emits ─► UI updates (per §7 policy)
```

Rules:

- `watchX()` returns data from DB only. `refresh()` returns `Result<SyncOutcome>` and never throws.
- **Refresh triggers** (all go through `SyncCoordinator.requestSync(collection, reason)`): first subscription if `now - last_synced_at > ttl`; app resume; connectivity regained; manual pull-to-refresh (`force: true`, bypass TTL); realtime event for that collection; push data message for that collection (T-046); after a successful outbox flush touching that collection. `SyncReason` values: `start | ttl | resume | connectivity | manual | realtime | push | outboxFlush | forcedResync`.
- **Single-flight:** concurrent requests for the same `(collection, queryKey)` share one in-flight future. Requests arriving during a run trigger exactly one follow-up run.
- **Default TTLs** (override in `FEATURE.md`): hot catalog 5 min; reference data (amenities, districts) 24 h; user data 1 min.
- First launch with empty DB and no network: show the empty/offline state (not an infinite spinner).
- On refresh failure with existing data: **keep data**, expose `lastError` + `isStale`; never clear the table.

## 6. Delta sync algorithm (mirror scope)

Inputs: `SyncSpec` for the collection. Cursor = max `server_updated_at` already applied.

1. Mark attempt in `sync_state`.
2. Fetch pages: `filter[date_updated][_gte]=<cursor minus overlap>`, `sort=date_updated,id`, `limit=200`, `offset` paging inside this run. **Overlap = 2 seconds** (clock/transaction skew safety). If cursor is null → full fetch.
3. For each page, in **one DB transaction**: upsert rows (idempotent by `id`), apply tombstones, quarantine rows whose mapping fails (doc 07 §10), **skip rows with a pending outbox op for that id** (local intent wins until the op resolves, see §9), then advance `cursor` to the max `server_updated_at` in the page **only after the transaction commits**.
4. Stop when a page returns fewer than `limit` rows. Update `last_synced_at`, clear `last_error`.
5. On any error: keep the cursor from the last committed page, store `last_error`, return `Err(failure)`. The next run resumes.

**Deletions** (pick in this order, record choice in `FEATURE.md`):
1. *Soft delete on the server* (`status`/`deleted_at` field exposed in the delta; client sets `is_deleted`). **Preferred; request from backend.**
2. *Reconcile by ids* for small collections: periodically (daily or on full refresh) fetch `fields=id` for the whole collection and remove local ids that no longer exist.
3. If neither is available: full refresh (`cursor=null`) with replace-all in a transaction on TTL expiry.

**Forced full resync** when: `sync_state.schema_version` ≠ the spec's `schemaVersion`; DB migration says so; the server reports an invalid cursor; user switches account/environment.

**Query-scoped scope:** same loop, but the filter/sort come from the `queryKey`, the results are stored in `query_results(collection, query_key, entity_id, position)` (schema in §4) with `has_more`, and the UI paginates by reading `LIMIT n` from the DB while `fetchNextPage()` appends.

## 7. UI update policy (how fresh data reaches the screen)

The DB stream updates the UI automatically, but presentation MUST apply these rules so the UI doesn't jump:

| Situation | Behavior |
|---|---|
| Fetch returns no change | No emission, no rebuild (upsert only when `server_updated_at` differs; Drift dedupes identical emissions). |
| **List/feed**, user at top and not interacting | Apply silently with animated insert/remove (stable `ValueKey(id)`, `SliverAnimatedList`/diff). |
| **List/feed**, user scrolled or interacting | Do **not** insert above the viewport. Show a "N new items ↑" pill; apply on tap. Implemented by `ContentUpdatePolicy` in `shared/`. |
| **Detail screen** | Replace in place (few fields change). Material changes (price, availability) are highlighted briefly. |
| **Form being edited** | **Never overwrite user input.** Keep the draft; resolve at submit via the conflict policy. |
| Refresh in progress with data present | Show a thin progress indicator (app bar), **never** a full-screen skeleton. Skeleton only when there is no local data at all. |
| Data older than TTL×N or offline | Show "Updated 2 h ago" + offline banner. |
| Refresh failed, data present | Keep data; non-blocking snackbar with Retry. |
| Row with `sync_status = pending/failed/conflict` | Small badge/icon; failed rows offer Retry/Discard. |

Blocs expose `lastSyncedAt`, `isRefreshing`, `isStale`, `failure` in state (see doc 04).

## 8. Outbox (writes while offline)

**Write path (all in ONE DB transaction):** apply the change to the entity table (`sync_status = pending`, bump `local_updated_at`, keep `base_server_updated_at`) **and** insert the `outbox_operations` row. Then `SyncCoordinator.requestFlush()` after the transaction commits. The UI is updated optimistically from the DB.

**Operation lifecycle:** `pending → in_flight → done` (row deleted after success) or `→ failed` (permanent) or `→ conflict`. After a crash, any `in_flight` older than 2 min is reset to `pending`.

**Processing rules:**
- FIFO **per entity** (`entity_type + entity_id`); different entities may run in parallel (max 3).
- An op with `depends_on` waits for that op to be `done` (e.g. child created offline under a parent created offline).
- **Coalescing on enqueue:** `create + update → create(merged)`; `update + update → update(merged patch)`; `create + delete → drop both`; `update + delete → delete`.
- **Retry with exponential backoff + jitter:** 1 s, 2 s, 4 s, … capped at 5 min, **max 8 attempts** then `failed`.
- **Error classification:**

| Result | Action |
|---|---|
| network/timeout/5xx | retry (backoff), keep `pending` |
| 429 | retry after `Retry-After` (or backoff) |
| 401 | refresh token (single-flight) then retry once; if refresh fails → pause outbox, route to login, keep ops |
| 403 | `failed` (permanent), surface to user |
| 404 on update/delete | treat as already deleted: mark `done`, tombstone locally |
| 409 / version mismatch | apply conflict policy (§9) |
| 400 duplicate key on **create** | create already succeeded earlier: `GET` the row, store it, mark `done` |
| 400/422 validation | `failed`, store field errors for the UI |

- **Idempotency:** Directus has no native idempotency key. Idempotency comes from the **client-generated UUID primary key** on creates and from deterministic PATCH payloads. The outbox `id` is still sent as `X-Idempotency-Key` (harmless; honored if the backend adds support).
- **Flush triggers:** after local write (`requestFlush()` is debounced 500 ms **inside the coordinator**; callers never debounce), connectivity regained, app resume, app start, successful token refresh, periodic 15 min while foregrounded. Background execution (`workmanager`/BGTask) is **not part of the base** (doc 01 §2); if added later via ADR it is best-effort only: correctness MUST NOT depend on it.
- **Logout/account switch:** if pending ops exist, warn the user; on confirm, delete that user's ops and user-scoped tables.

## 9. Conflict resolution

Each `OutboxWrite` entity declares a `ConflictPolicy` in its `SyncSpec`:

| Policy | Behavior | Use for |
|---|---|---|
| `serverWins` (**default**) | Discard local change, take server row, notify user if the change was meaningful | prices, status, anything authoritative |
| `clientWins` | Re-send the local change on top of the latest server row | user-owned preferences |
| `lastWriteWins` | Compare `local_updated_at` vs `server_updated_at` | low-value user data |
| `fieldMerge` | Merge non-overlapping fields; overlapping fields fall back to `serverWins` | profile, saved searches |
| `askUser` | Mark row `conflict`; present both versions | long free text |

**Detection (ASSUMPTION — Directus has no `If-Match`):** two options, decided in ADR-0004. Default **B** until the backend team ships **A**.
- **A (preferred):** server-side Flow/hook compares the `base_server_updated_at` sent in the request and returns 409.
- **B:** client pre-flight `GET /items/<c>/<id>?fields=id,date_updated` before PATCH; if `date_updated` ≠ `base_server_updated_at` → conflict. Accept the small race window.

While an entity has a pending op, **incoming delta rows for that id do not overwrite local fields**; they update only `server_updated_at` metadata in a side column or are re-applied after the op resolves.

## 10. Connectivity

`ConnectivityService` exposes `Stream<NetworkStatus>` (`online | offline`). `connectivity_plus` only reports link type, so **online = link present AND reachability probe succeeds** (`GET {base}/server/ping`, timeout 3 s, body must be exactly `pong` to defeat captive portals, re-probed on link change and every 30 s while offline). Never gate requests on this flag alone: always attempt the request and classify the failure; the flag drives UI banners and flush triggers.

## 11. Auth interplay

- Sync requires a valid session. Without a session, run **public collections only** (declare `requiresAuth` in the spec).
- Token refresh is single-flight across sync, outbox, and UI requests (doc 05).
- On logout or account switch: stop sync, clear user-scoped tables + `sync_state` + outbox; keep public caches.

## 12. Images and files

DB stores URLs/ids only. Use a disk-cached image loader with a size cap; request Directus asset transforms (`width`, `quality`, `format`) sized for the device. Prefetch only for favorites/last-viewed. Uploads are `OnlineOnly` unless a feature's `FEATURE.md` justifies queued uploads.

## 13. Observability of sync

`AppLogger` MUST emit structured events: `sync.start/ok/fail {collection, reason, rows, durationMs}`, `outbox.enqueue/ok/retry/fail/conflict {entityType, op, attempt}`. Expose a debug screen (dev/staging) showing `sync_state`, outbox rows, last errors, and a "force full resync" button. Report to crash reporter only permanent outbox failures and unexpected exceptions.

## 14. Anti-patterns (reject in review)

- Rendering a Retrofit response directly in UI/Bloc.
- Clearing a table before fetching ("replace all") for mirror collections with a delta available.
- Awaiting network in `bootstrap()` or before navigating.
- Storing server timestamps as `DateTime` seconds (loses ms) or parsing the cursor into local time.
- Advancing the cursor before the transaction commits.
- Optimistic writes without an outbox row (data loss on crash).
- Showing a full-screen spinner when local data exists.
- Silent conflict resolution that discards user-authored text.
- Relying on background tasks for correctness.
- Sync logic inside widgets or Blocs.

## 15. Reference interfaces (*reference*, final signatures decided in T-040…T-044)

```dart
enum SyncScope { mirror, queryScoped }
enum ConflictPolicy { serverWins, clientWins, lastWriteWins, fieldMerge, askUser }

abstract interface class SyncSpec {
  String get collection;            // sync_state key
  int get schemaVersion;            // bump → full resync
  Duration get ttl;
  SyncScope get scope;
  bool get requiresAuth;
  /// Fetch one page from Directus. cursor = raw server string or null.
  Future<RemotePage> fetchPage({required String? cursor, required int offset, required int limit, String queryKey = ''});
  /// Apply a page inside the transaction owned by the runner (upserts + tombstones).
  Future<void> applyPage(RemotePage page);
}

abstract interface class SyncCoordinator {
  Future<Result<SyncOutcome>> requestSync(String collection, {SyncReason reason, bool force = false, String queryKey = ''});
  Future<void> requestFlush();
  Stream<SyncStatus> watchStatus(String collection);   // isRefreshing, lastSyncedAt, lastError
  Stream<OutboxSummary> watchOutbox();                  // pending/failed/conflict counts
}
```

```dart
// Repository (CacheOnly mirror) — reference
final class ListingRepositoryImpl implements ListingRepository {
  ListingRepositoryImpl(this._dao, this._sync);
  final ListingDao _dao;
  final SyncCoordinator _sync;

  @override
  Stream<List<Listing>> watchListings(ListingFilter f) =>
      _dao.watchListings(f).map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Future<Result<void>> refresh({bool force = false}) async =>
      (await _sync.requestSync(ListingSyncSpec.collectionName, force: force)).map((_) {});

  @override
  Stream<SyncStatus> watchSyncStatus() => _sync.watchStatus(ListingSyncSpec.collectionName);
}
```

## 16. Required sync test scenarios

See `docs/09-testing-strategy.md` §7 — a feature touching sync is not done until its scenarios pass.
