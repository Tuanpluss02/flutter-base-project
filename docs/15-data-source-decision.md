# 15 — Local vs Remote: Decision Rules

Use this document whenever a task reads or writes data. The agent MUST record the outcome in the feature's `FEATURE.md` ("Data decision record"). Not covered by any rule here → `BLOCKED` (`AGENTS.md` §4). Never decide by convenience.

**Golden rule:** the UI/Bloc **never** reads from the network. "Remote" means the *sync layer* talks to Directus and writes into the DB; the UI still reads the DB. The only exceptions are the explicit `RemoteOnly` cases in §2.

## 1. The six questions (answer in order, stop at the first "yes" that gives a result)

| # | Question | If yes → |
|---|---|---|
| 1 | Is it an **irreversible or money/identity action**, or must the value be **exact at this instant** (payment, deposit, booking confirmation, availability check, OTP, eKYC, password change)? | `OnlineOnly` (remote). Offline: disable the action with a clear message. Read §4 (freshness guard) for the screens leading to it. |
| 2 | Is the result **computed by the server** and not derivable from stored rows (price quote, mortgage rules, recommendations, server-side search ranking)? | `RemoteQuery` (§2): call remote, do **not** persist as source of truth; in-memory cache with short TTL allowed. Offline: unavailable state, or local approximation only if `FEATURE.md` explicitly defines it. |
| 3 | Is it a **write** that makes sense offline and is safe to apply later (favorite, saved search, draft, profile edit, inquiry draft)? | `OutboxWrite` (local-first + outbox, doc 02 §8). |
| 4 | Is it **read data** from a collection within the mirror threshold (≤ 5,000 rows and ≤ ~5 MB)? | `CacheOnly` + `mirror`: read local, delta-sync in background. Filtering/sorting/search are local SQL. |
| 5 | Is it **read data** from a larger collection or needing server-side filtering? | `CacheOnly` + `queryScoped`: read local cache for the `queryKey`; fetch when the query is new or stale (§3). |
| 6 | None of the above | `BLOCKED`. |

## 2. Resulting data sources

| Source | UI reads from | Network used by | Offline behavior |
|---|---|---|---|
| `CacheOnly / mirror` | DB stream | SyncCoordinator (delta) | Fully works |
| `CacheOnly / queryScoped` | DB stream (rows of that `queryKey`) | SyncCoordinator (per query) | Last cached results; unseen query → offline empty state |
| `OutboxWrite` | DB stream | Outbox processor | Writes accepted locally, badge shows pending |
| `RemoteQuery` | Use case → repository `Future<Result<T>>` (not a DB stream) | Repository directly (via Retrofit in `guard()`) | Unavailable state with Retry |
| `OnlineOnly` | Use case → repository `Future<Result<T>>` | Repository directly | Action disabled, message shown |

`RemoteQuery` and `OnlineOnly` repositories still follow all other rules (Result, mappers, no DTO leaks, tests). Their results MUST NOT be written into synced entity tables. Sensitive results are never persisted.

## 3. Situations that cause mistakes (mandatory behavior)

| Situation | Rule |
|---|---|
| **Detail opened by id and the row is not in the DB** (deep link, push, shared link) | `watchById` reads DB. If missing: trigger `fetchById` through the sync layer (fetch → upsert → DB stream emits). UI: loading until row appears or `Failure`; offline → "not available offline" state. Never render the network response directly. |
| **Local DB empty on first launch, online** | Show skeleton, trigger refresh, render when rows arrive. Never bypass the DB with a direct fetch "just for the first screen". |
| **Local DB empty, offline** | Offline/empty state with Retry. No infinite spinner. |
| **Local data exists but is stale** | Show it immediately with stale indicator; refresh in background (doc 02 §7). Do not block. |
| **Search/filter on a `mirror` collection** | Local SQL only. No remote search call. |
| **Search on a `queryScoped` collection** | Debounce → compute `queryKey` → show cached rows for it → fetch → upsert → stream updates. |
| **Pagination** | `mirror`: paginate the local query. `queryScoped`: read `LIMIT n` from DB, `fetchNextPage()` appends via sync. |
| **User-owned data after login on a new device** | Initial sync (requires auth), UI shows skeleton until first page lands; then normal local-first. |
| **Data needed by a write but not local** (e.g. parent entity) | Writes needing server-only data are `OnlineOnly`. Never fabricate missing data locally. |
| **Realtime event arrives** | Trigger sync of that collection. Never update UI from the event directly. |
| **Feature spans both** (list is `CacheOnly`, "book now" is `OnlineOnly`) | Split into two repositories/policies inside the feature; document both in `FEATURE.md`. |

## 4. Freshness guard (local-first must not mislead at decision time)

Before an irreversible action that depends on a mutable fact (price, availability, status) the flow MUST:
1. Re-fetch that entity from remote (`RemoteQuery`, ignoring cache).
2. Compare with the displayed values. If changed → show the new values and require explicit user confirmation.
3. Submit with the values the user confirmed; server remains authoritative and may still reject.

Provide this as a reusable `FreshnessGuard` use case in the feature; do not copy-paste ad hoc checks.

## 5. Real-estate defaults (override only via `FEATURE.md` + reviewer approval)

| Data | Policy |
|---|---|
| Projects, listings, units, amenities, districts, agents, banners, news | `CacheOnly` (mirror if within threshold) |
| Listing price/availability **at booking/deposit time** | `RemoteQuery` freshness guard (§4) |
| Favorites, saved searches, recently-viewed | `OutboxWrite` (`clientWins`) |
| Inquiry / viewing-request draft | `OutboxWrite` (draft local; final submit policy defined in `FEATURE.md`) |
| Profile (non-sensitive fields) | `OutboxWrite` (`fieldMerge`) |
| Mortgage/loan calculator using server rules, price quotes | `RemoteQuery` |
| Login, OTP, password, session | `OnlineOnly` |
| Payment, deposit, booking confirmation, eKYC, contract signing | `OnlineOnly`, nothing sensitive persisted |
| Media upload | `OnlineOnly` unless justified |
| Notifications inbox | `CacheOnly` (mirror, user-scoped) |

## 6. Forbidden

- Bloc/widget/use case calling Retrofit, Dio, or a remote data source directly for `CacheOnly`/`OutboxWrite` data.
- "Remote fallback if local is empty" that bypasses the DB.
- Persisting `RemoteQuery`/`OnlineOnly` results in synced tables.
- Making an `OnlineOnly` action work offline by queuing it.
- Querying the server for filters/search on a `mirror` collection.
- Deciding policy per screen: policy is per **entity/operation**, declared once in `FEATURE.md`.

## 7. Data decision record (copy into `FEATURE.md`)

For each entity/operation: answers to the six questions (one line each), resulting source from §2, TTL/scope, offline behavior, freshness guard needed (yes/no). Reviewers reject a feature without it.
