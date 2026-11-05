# 13 — Base Build Plan (ordered tickets)

Purpose: the agent team builds the base **in this order**. Each ticket is self-contained: read the listed docs, touch only `Owns`, satisfy `Acceptance`, finish with `make check` (once it exists) and the report format from `AGENTS.md` §7.

Conventions: `Dep` = tickets that must be merged first. Tickets with the same Dep set can run **in parallel**. Merge-hotspot rules apply (`AGENTS.md` §6). If a ticket reveals a doc conflict or missing decision → `BLOCKED` report.

```
M0 ─► M1 ─► M2 ─┬─► M4 ─► M5 ─► M6 ─► M7
              └─► M3 ─┘
```

## M0 — Repository foundation

**T-001 Project bootstrap** · Dep: — · Docs: 01, 10 · Owns: repo root, `pubspec.yaml`, `analysis_options.yaml`, `Makefile`, `.fvmrc`, `.gitignore`, `build.yaml`, `android/`, `ios/` flavor config, `lib/main_*.dart`, `lib/app/`
- Create Flutter project (working package name `app`; rename later is a single ticket), FVM pin, 3 flavors (dev/staging/prod) on Android+iOS, `main_<flavor>.dart` → `bootstrap()` stub.
- Resolve **mutually compatible stable** versions of the locked stack (doc 01 §2); commit `pubspec.lock`; record resolved set + forced pins in `docs/14-decisions.md` (ADR-0010).
- `.gitignore` excludes all `generated/` directories (`lib/generated/`, `packages/*/lib/generated/`, `test/generated/`; `drift_schemas/` stays tracked — ADR-0005, ADR-0013). `build.yaml` configures `build_extensions` so all builders (`source_gen|combining_builder`, `freezed`, `auto_route_generator`, `injectable_generator`, `slang`) emit exclusively into `lib/generated/**` (and `packages/*/lib/generated/**`). `Makefile` implements all targets in doc 10 §1 (targets whose tools don't exist yet may be no-ops with a TODO ticket; `make gen` skips the drift schema steps while `drift_schemas/` is empty).
- Firebase wired per flavor (one Firebase project/app per flavor: `google-services.json` per Android flavor, `GoogleService-Info.plist` per iOS scheme, `lib/app/firebase/firebase_options_<flavor>.dart`). Only initialization; Crashlytics behavior is T-011, messaging is T-046.
- Acceptance: `make bootstrap && make check` green on a clean clone; app runs on each flavor showing a placeholder page; flavors have distinct app ids/names.

**T-002 CI + architecture checker + templates** · Dep: T-001 · Docs: 10, 03 · Owns: CI config, `tool/`, `.github/` (or equivalent), `docs/templates/`, `.agents/skills/`
- Implement `tool/arch_check.dart` (rules A1–A17), `tool/coverage_gate.dart`, i18n key check; tests with violating/valid fixtures.
- CI pipeline per doc 10 §4 (PR checks, nightly skeleton, release skeleton), PR template, secret scan, OSV scan.
- Acceptance: a deliberately violating fixture branch fails `make arch` with correct messages; PR pipeline runs `make check` and blocks merge on failure.

## M1 — Core foundation (parallel after T-001)

**T-010 Error model** · Dep: T-001 · Docs: 07 · Owns: `lib/core/error/**`, tests
- `Result`, `Failure` hierarchy, `AppException` hierarchy + `toFailure`, `guard()`. Acceptance: tests per doc 07 §7; ≥ 90% coverage.

**T-011 Logging + crash handling + bootstrap** · Dep: T-001 · Docs: 07, 01 §6 · Owns: `lib/core/logging/**`, `lib/app/bootstrap.dart`
- `AppLogger` + sinks, redactor (with fixture tests), global handlers, `AppBlocObserver`, Crashlytics wiring by flavor. Acceptance: bootstrap order matches doc 01 §6; redaction tests pass; uncaught error test reaches reporter fake.

**T-012 Config/env** · Dep: T-001 · Docs: 01 §7, 05 §7 · Owns: `lib/core/config/**`
- `AppConfig` per flavor via `envied` (obfuscated), no URL/key literals elsewhere. Acceptance: config selected by flavor; test asserts prod has no dev tools enabled.

**T-013 DI skeleton** · Dep: T-001, T-010 · Docs: 08 §2 · Owns: `lib/core/di/**`
- `configureDependencies(env)`, modules for logger, clock, secure storage, shared prefs; `test` environment. Acceptance: container builds in unit test; `getIt` usage restricted per A6.

**T-014 Design system + i18n + theme** · Dep: T-001 · Docs: 08 §3–6 · Owns: `packages/design_system/**`, `lib/i18n/**`
- Tokens, light/dark themes, base components (button, input, card shell, skeleton, banners, empty/error states, offline banner, stale indicator, pending badge, new-items pill), component gallery, goldens, slang setup with `vi` + `en`.
- Acceptance: goldens (light/dark, text scale 1.0/1.5) committed; gallery runs; missing-key CI check works.

**T-015 Router skeleton** · Dep: T-013, T-014 · Docs: 08 §1 · Owns: `lib/core/router/**`, `lib/app/app.dart`
- `AppRouter`, `AuthGuard` (stubbed on `SessionStore` interface), shell/tabs placeholder, deep-link resolver skeleton. Acceptance: navigation tests with a fake session; no `Navigator.push`.

**T-016 Shared Bloc utilities** · Dep: T-001 · Docs: 04 §3, §5 · Owns: `lib/shared/bloc/**`
- `LoadStatus` enum, `debounceRestartable()` transformer + private `Stream.debounce` extension (no new package, doc 04 §5), `SafeEmitterX` (`emit.safe`) and `SafeCubitX` (`safeEmit`). Acceptance: `fakeAsync` tests prove debounce window, restart cancels the previous handler, cancellation on `close()`, and `emit.safe`/`safeEmit` no-op after handler completion/close; ≥ 90% coverage.

## M2 — Network and auth

**T-020 Dio client + interceptors** · Dep: T-010, T-012, T-013 · Docs: 05 §1,5,7,9 · Owns: `lib/core/network/**`
- Dio factory, the 5 interceptors in the mandated order, `CallClass` timeouts (doc 05 §11), request ids, table-driven Directus error-code map (§10), content-type/captive-portal check, `NetworkCircuitBreaker` (§13), `CancelHandle` plumbing (§12), `ConnectivityService` with reachability probe (doc 02 §10).
- Acceptance: interceptor unit tests (single-flight refresh with concurrent 401s, retry matrix, redaction, error table); interceptly absent from prod.

**T-021 Directus helpers** · Dep: T-020 · Docs: 05 §2–3 · Owns: `lib/core/network/directus/**`
- `DirectusQuery` builder, envelopes, DTO base conventions, fixtures. **Verify the contract (§3) against the backend docs/instance; BLOCKED if different.** Acceptance: builder tests produce exact query strings for filters/sort/pagination/delta.

**T-022 Auth feature** · Dep: T-015, T-020, T-021 · Docs: 05 §4, 11 · Owns: `lib/features/auth/**`, `lib/core/security/session/**`
- Login/logout/refresh, `SessionStore` (on top of the `FlutterSecureStorage` instance provided by T-013's DI module), use cases (`LoginUseCase`, `LogoutUseCase`, `RestoreSessionUseCase`, `WatchSessionUseCase`), `SessionBloc`, login page, `FEATURE.md` (`OnlineOnly`). Acceptance: all scenarios in doc 05 §4 tested; tokens never logged; session expiry routes to login.

## M3 — Database (parallel with M2 after T-013)

**T-030 AppDatabase + migrations infra** · Dep: T-013 · Docs: 06 · Owns: `lib/core/database/**`, `drift_schemas/`
- Background-isolate connection, pragmas, converters (`SyncRowStatusConverter`), table mixins (`SyncedTableMixin`, `OutboxTableMixin`), top-level `upsertChunked` helper, schema snapshots (`drift_schemas/`, committed) + generated `SchemaVerifier` helpers (`test/generated/migrations/`, git-ignored, produced by `make gen`, ADR-0013), `createTestDb()`. Acceptance: migration test harness proven with a v1→v2 sample migration (removed or kept as fixture); clean clone → `make bootstrap && make test` regenerates helpers and passes.

**T-031 Sync tables** · Dep: T-030 · Docs: 02 §4, 06 · Owns: `lib/core/database/tables/{sync_state,outbox_operations,sync_quarantine,query_results}*`, their DAOs
- `sync_state`, `outbox_operations`, `sync_quarantine`, `query_results` + DAOs. Acceptance: DAO tests; query-plan tests for the outbox due-ops query and the `query_results` page query (`collection, query_key ORDER BY position`).

**T-032 DB encryption** · Dep: T-030, T-013 · Docs: 06 §5, 11 · Owns: `lib/core/database/connection/**`, `lib/core/security/db_key/**`
- SQLCipher integration, `DbKeyStore` (256-bit key in the T-013 `FlutterSecureStorage` instance), key lifecycle, wrong-key recovery. Acceptance: encrypted file unreadable without key (test), recovery path tested, plain in-memory for tests.

## M4 — Sync engine (needs M2 + M3)

**T-040 SyncCoordinator + registry + triggers** · Dep: T-020, T-031 · Docs: 02 §5, §10–11 · Owns: `lib/core/sync/{coordinator,registry,triggers}/**`
- Single-flight, TTL logic, triggers (start/resume/connectivity/realtime hook), status streams. Acceptance: scenarios 8, 18 and trigger tests.

**T-041 DeltaSyncRunner** · Dep: T-040, T-021 · Docs: 02 §6 · Owns: `lib/core/sync/delta/**`
- Generic runner driven by `SyncSpec`, overlap, transactional page apply, cursor commit rules, tombstones, id-reconcile, forced resync, poison-row quarantine + contract-mismatch detection (doc 07 §10), adaptive page size (doc 05 §11). Acceptance: scenarios 1–7, 19–21.

**T-042 Outbox + conflict policies** · Dep: T-040, T-031 · Docs: 02 §8–9 · Owns: `lib/core/sync/outbox/**`, `lib/core/sync/conflict/**`
- Enqueue+coalesce, processor (per-entity FIFO, parallelism, backoff, error classification, `depends_on`), five conflict policies, detection option B. Acceptance: scenarios 9–17.

**T-043 Realtime bridge** · Dep: T-040, T-022 · Docs: 05 §6 · Owns: `lib/core/realtime/**`
- Centrifuge connection manager → `requestSync`. Acceptance: reconnect/backoff tests; missing events harmless.

**T-044 Sync UX components + debug screen** · Dep: T-040, T-014 · Docs: 02 §7, 08 §5 · Owns: `lib/shared/sync/**`, debug page (dev/staging only)
- cross-cutting use cases (`WatchConnectivityUseCase`, `WatchOutboxSummaryUseCase`, `RequestSyncUseCase`), `SyncStatusBloc`, `ContentUpdatePolicy`, wiring of offline banner/stale/pending widgets, debug screen (sync_state, outbox, force resync). Acceptance: widget tests; debug screen absent in prod build (test).

**T-045 App status (maintenance / force update / contract broken)** · Dep: T-040, T-015, T-020 · Docs: 05 §13, 07 §9 · Owns: `lib/core/network/server_state/**`, `AppStatusBloc`, shell guard hooks
- Cross-cutting use cases, `AppStatusBloc`, maintenance/force-update screens, `ForceUpdateGuard`, `FailurePresenter` in `shared/` (doc 07 §9 matrix). Acceptance: scenarios 22–23; UI states per matrix covered by widget tests.

**T-046 Push notifications infra** · Dep: T-011, T-015, T-022, T-040 · Docs: 05 §3 (checklist 11), 08 §1, 11 · Owns: `lib/core/push/**`
- `firebase_messaging` wrapper behind a `PushService` interface; cross-cutting use cases `RequestPushPermissionUseCase`, `SyncPushTokenUseCase`; token register on login/refresh and unregister on logout (`PushTokenRegistrar` interface, fake in tests); foreground/background/terminated taps → `DeepLinkResolver`; data messages → `SyncCoordinator.requestSync(collection, reason: push)` only (never write UI state). No PII logged.
- **Infra only.** Notification types, copy and the permission-prompt moment are product decisions: no screen calls `RequestPushPermissionUseCase` until product specifies it (record as FOLLOW-UP). If the backend lacks checklist item 11, ship with the fake registrar and report BLOCKED for the real one.
- Acceptance: unit tests for token lifecycle (login, rotation, logout), tap routing for each app state, data message → sync trigger; no push init in tests/without Firebase config.

## M5 — Reference features (the patterns agents will copy)

**T-050 `listing` (CacheOnly, mirror)** · Dep: T-041, T-014, T-015, T-016 · Docs: all of 01–09, 15 · Owns: `lib/features/listing/**`
- Entities, DTO, Drift table with indexes, DAO with filters/sort/search, `ListingSyncSpec`, repository, use cases (`WatchListingsUseCase`, `WatchListingUseCase`, `RefreshListingsUseCase`, `WatchListingSyncStatusUseCase`), `ListingListBloc` + `ListingDetailBloc`, list and detail pages with all UI states, `FEATURE.md`. Acceptance: every row of doc 09 §3 satisfied; list works fully offline; no UI jumps (policy §7); coverage gates.

**T-051 `favorite` (OutboxWrite)** · Dep: T-042, T-050 · Owns: `lib/features/favorite/**`
- Optimistic toggle through outbox via `SetFavoriteUseCase` (owns the "already favorite → no-op" rule) and `WatchFavoriteIdsUseCase`, pending badge, conflict policy `clientWins`, cross-screen consistency via DB streams. Acceptance: scenarios 8–10 end-to-end in integration test.

**T-052 `inquiry` (OutboxWrite with form draft)** · Dep: T-042, T-050 · Owns: `lib/features/inquiry/**`
- Draft persisted while typing, submit via outbox, failure surfaces per-field errors, `askUser` conflict path demonstrated. Acceptance: draft survives kill; validation errors mapped to fields.

**T-053 `booking_demo` (OnlineOnly + RemoteQuery)** · Dep: T-022, T-050 · Docs: 15 · Owns: `lib/features/booking_demo/**`
- Minimal example of an `OnlineOnly` feature with offline-blocked UI, a `RemoteQuery` (quote) and a reusable `FreshnessGuard` before confirmation. Acceptance: offline state tested; no local persistence of sensitive data.

## M6 — Hardening

**T-060 Security hardening** · Dep: M5 · Docs: 11 · Owns: native config, `lib/core/security/**`
- Execute the doc 11 checklist (backup rules, pinning, obfuscation, screen protection, root-detection policy). Acceptance: each checkbox has evidence (test or documented manual verification).

**T-061 Performance pass** · Dep: T-050 · Docs: 10 §6, 06 §6 · Owns: perf tests, profiling notes in `docs/`
- Seed 5k listings; verify budgets; fix hot queries/rebuilds. Acceptance: numbers recorded; budgets met or ADR.

**T-062 Integration test suite** · Dep: T-051, T-052 · Docs: 09 §6 · Owns: `integration_test/**`, fake Directus server
- Implements all six flows. Acceptance: runs in CI nightly and on demand.

**T-063 Release pipeline** · Dep: T-060 · Docs: 10 §4 · Owns: CI release config, fastlane (if chosen)
- Staging distribution, prod build with obfuscation + symbol upload, staged rollout notes. Acceptance: dry-run release produces signed artifacts and uploaded symbols.

## M7 — Scale tooling

**T-070 Feature generator** · Dep: T-050 · Owns: `tool/new_feature/**` (plain Dart script using only `dart:io` + templates; `mason` is not in the locked stack and would need an ADR), `Makefile`
- `make feature name=xyz policy=cache|outbox|online scope=mirror|query` generates the full skeleton (all layers incl. use case skeletons, tests, `FEATURE.md`, DI, route stub) matching the reference features. Acceptance: generated feature passes `make check` untouched.

**T-071 Docs finalization** · Dep: all · Owns: `docs/**`, `.agents/skills/**`
- Align docs with reality (paths, signatures, resolved versions), remove ASSUMPTION markers that were verified, add runbooks (cert rotation, resync, release). Acceptance: a fresh agent can implement a new feature using only the docs + skill, verified by an actual trial feature.

## Base is "done" when

1. `make check` green on clean clone; CI required checks enforced.
2. Reference features `listing`, `favorite`, `inquiry`, `booking_demo` meet the DoD (doc 12) including the offline QA matrix.
3. Sync scenarios 1–18 automated and green; integration flows 1–6 green.
4. Security checklist (doc 11) complete with evidence.
5. Feature generator output passes `make check` without edits.
6. Release dry-run succeeded (signed artifacts, symbols uploaded).
