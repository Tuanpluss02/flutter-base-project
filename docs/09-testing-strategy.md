# 09 — Testing Strategy

## 1. Pyramid and tools

| Level | What | Tools |
|---|---|---|
| Unit | mappers, entities, use cases, repositories, Blocs, interceptors, sync engine, outbox | `flutter_test`, `bloc_test`, `mocktail`, in-memory Drift, `http_mock_adapter`, `clock` |
| Widget | pages/views with fake Blocs, design-system components | `flutter_test` (`pumpWidget`), fake Blocs |
| Golden | design-system components, key screens (light/dark, text scale 1.0/1.5) | `matchesGoldenFile` with fixed fonts; goldens committed, one reference platform (CI Linux) |
| Integration | critical flows on emulator with fake backend | `integration_test`, DI `test` environment with a local fake Directus server (or `http_mock_adapter`) |
| Sync scenarios | offline/online/conflict matrix (§7) | in-memory DB + fake remote + fake connectivity + fake clock |

Prefer **hand-written fakes** (fake repositories/remote data sources) over mocks for anything stream- or state-based. Use `mocktail` for simple interaction verification.

## 2. Layout and naming

- `test/` mirrors `lib/` one-to-one: `lib/features/listing/data/mappers/listing_mapper.dart` → `test/features/listing/data/mappers/listing_mapper_test.dart`.
- Shared helpers in `test/support/`: `builders/` (test data builders, e.g. `aListing(...)`), `fakes/` (FakeRemote, FakeConnectivity, FakeClock, FakeSecureStorage), `createTestDb()`, `pumpApp()`.
- Structure each test as Arrange / Act / Assert; test names read as sentences (`'keeps cached items when refresh fails'`).
- No real network, no real time (`Clock`), no `sleep`/`Future.delayed` in tests (use `fakeAsync`/`pumpAndSettle` appropriately), no test order dependence, no shared mutable state between tests.

## 3. Required tests per change (matrix)

| Change | Required |
|---|---|
| New/changed mapper | unit: every field, nulls, unknown enum, UTC dates |
| New repository / method | unit: success, each failure kind, stream emissions; never hits real Dio/DB (DB is in-memory) |
| New use case | unit with a fake repository: delegation, **each business rule**, error propagation (`Err` passes through unchanged), stream behavior for `Watch…`; a pure pass-through still gets one delegation test |
| New DAO query | DAO test + query-plan test if list/hot path |
| New Bloc / event | `bloc_test` per §9 of doc 04, real use cases over a fake repository |
| New page/view | widget test: loading, empty, data, stale/offline, error-with-data; semantic labels |
| New design-system component | golden + widget test |
| New sync spec | delta runner test: first sync, incremental, tombstone, resume after failure, overlap dedupe |
| New outbox entity | outbox tests: enqueue+coalesce, retry/backoff, each error class, conflict policy |
| Table/column change | migration test (§4 doc 06) |
| New endpoint | contract test with fixture; error-mapping test |
| Bug fix | regression test that fails before the fix |

## 4. Coverage gates (enforced by `make coverage`)

Computed on non-generated files (exclude `**/generated/**`, `*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `*.config.dart`, `main_*.dart`).

| Scope | Minimum line coverage |
|---|---|
| `domain/**` | 90% |
| `data/**` (mappers, repos, DAOs, sync specs) | 85% |
| `presentation/bloc/**` | 90% |
| `core/sync/**`, `core/network/**`, `core/error/**` | 90% |
| `presentation/pages|widgets/**` | 60% |
| Overall | 80% |

Thresholds only go **up**. Lowering one requires an ADR. Coverage is a floor, not a goal: tests must assert behavior.

## 5. Determinism rules

Inject `Clock`, `Random` (seeded), UUID generator, connectivity, and secure storage. Any `Timer`/debounce is driven by `fakeAsync`. Goldens use bundled fonts and fixed device size/pixel ratio. Flaky test = P1 bug: fix or delete within 24 h, never `retry` or skip silently.

## 6. Integration tests (critical flows, nightly + before release)

1. Cold start offline with warm DB → home renders from cache.
2. Login → initial sync → browse listings → open detail.
3. Favorite offline → app killed → relaunch online → favorite synced.
4. Token expiry during sync → refresh → continue.
5. Logout clears user data, keeps public cache.
6. App upgrade with DB migration (install previous schema snapshot, upgrade).

## 7. Sync scenario matrix (must exist as automated tests)

1. First sync populates DB; second sync with no changes causes no row updates and no UI emission.
2. Incremental sync applies only changed rows; cursor advances only after commit.
3. Crash/failure mid-sync resumes from last committed page; no duplicates.
4. Overlap window re-delivers rows idempotently.
5. Tombstone (soft delete) hides row; id-reconcile removes orphan.
6. Forced resync on `schemaVersion` change.
7. Refresh failure keeps cached data and sets `isStale/lastError`.
8. Single-flight: 10 concurrent `requestSync` → one network run (+ at most one follow-up).
9. Outbox: offline write persists entity + op atomically; UI reflects it immediately.
10. Outbox coalescing (create+update, update+update, create+delete).
11. Outbox ordering per entity and parallelism across entities; `depends_on` respected.
12. Retry/backoff schedule and max attempts → `failed`; 5xx/timeouts retried; 400 duplicate-create resolved.
13. 401 during flush → single refresh → success; refresh failure pauses outbox, keeps ops.
14. Each `ConflictPolicy` produces the expected final row and user-visible outcome.
15. Incoming delta does not overwrite fields with a pending local op.
16. `in_flight` recovery after simulated crash.
17. Logout/account switch clears user-scoped tables, `sync_state`, outbox.
18. Connectivity flap (online→offline→online) triggers exactly one flush.
19. One unmappable row is quarantined and skipped; the rest of the page applies; cursor advances; row retried after forced resync.
20. ≥ 20% (and ≥ 5) unmappable rows in a page → `ContractMismatchFailure`, cursor not advanced, cached data kept, collection marked `contractBroken`.
21. Timeout on a sync page halves page size (200→100→50, min 25); three successful runs restore it.
22. Circuit breaker opens after 5 background failures in 60 s, backs off, closes on probe success; user-initiated actions bypass it.
23. Maintenance (503 + `Retry-After`) pauses sync/outbox without consuming outbox attempts; resumes after probe.
24. HTML (captive-portal) response to a JSON call becomes `NetworkFailure(unexpectedContent)`, not `ParsingFailure`.
