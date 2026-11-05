# 01 — Architecture

## 1. Goals and non-goals

**Goals:** long-term maintainability for a large team and AI agents working in parallel; fast cold start and instant screens (local-first); predictable data flow; strict boundaries enforced by tooling; production-grade observability and security.

**Non-goals:** supporting web/desktop in the base; real-time collaborative editing (no CRDT); a plugin system; micro-frontends.

## 2. Locked stack

| Concern | Choice | Notes |
|---|---|---|
| State | `flutter_bloc`, `bloc_concurrency` | Bloc by default, Cubit only for trivial UI state. `debounceRestartable()` is our own helper in `shared/bloc/` (no extra package) |
| DI | `injectable` + `get_it` | Constructor injection only |
| Network | `dio` + `retrofit` | One API class per feature |
| Models | `freezed` + `json_serializable` | DTOs and domain entities (`freezed_annotation`, `json_annotation`) |
| Local DB | `drift` + `sqlcipher_flutter_libs` | Reactive streams, migrations, SQLCipher encryption (do not add `sqlite3_flutter_libs` alongside `sqlcipher_flutter_libs`) |
| Router | `auto_route` | Typed routes, guards |
| i18n | `slang`, `slang_flutter`, `intl` | Typed keys + locale-aware number/currency/date formatters |
| Config | `envied` | Compile-time env, obfuscated |
| Realtime | `centrifuge` | Triggers sync only |
| Storage | `flutter_secure_storage`, `shared_preferences` | Secure storage for tokens/DB key; preferences for non-sensitive UI settings (locale/theme) |
| Connectivity | `connectivity_plus` + reachability probe | See doc 02 |
| Media & UI | `cached_network_image` | Disk-cached image loader with size cap (doc 02 §12) |
| Observability | `firebase_core`, `firebase_crashlytics`, `firebase_messaging` | Crash reporting and push notifications |
| Dev tools | `interceptly`, `interceptly_dio` | Network inspector, **dev/staging only**: attached behind a const flavor check so it is tree-shaken from prod (doc 05 §1, doc 11) |
| Core utilities | `clock`, `uuid`, `package_info_plus`, `path_provider`, `path` | Injected time/UUIDs, app version headers, DB file path |
| Lints | `very_good_analysis` + overrides | See doc 10 |
| Tests | `flutter_test`, `bloc_test`, `mocktail`, `http_mock_adapter`, `fake_async` | See doc 09 |
| Codegen (dev_dependencies) | `build_runner`, `freezed`, `json_serializable`, `retrofit_generator`, `injectable_generator`, `auto_route_generator`, `drift_dev`, `envied_generator`, `slang_build_runner` | Companion generators of the packages above; part of the locked stack, no separate ADR. Upgraded together (doc 10 §7) |
| Toolchain | FVM (`.fvmrc` pins Flutter) | Never upgrade Flutter without an ADR |

**Not in the base:** `workmanager`/BGTask, `stream_transform`, `rxdart`, `fpdart`/`dartz`, `go_router`, `hive`/`isar`, `sqlite3_flutter_libs`. Adding any of them (or anything else not in this table) requires an ADR via skill `add-dependency`.

Exact package versions are resolved at bootstrap (ticket T-001) to the latest **mutually compatible stable** set (generator packages often pin `analyzer` ranges). Record the resolved set and any forced pin in `docs/14-decisions.md`. `pubspec.lock` is committed.

## 3. Layers and the dependency rule

```
 presentation  ──►  domain  ◄──  data
 (widgets, Bloc)   (entities,    (DTOs, Retrofit, Drift,
                    repo ifaces,  mappers, repo impls,
                    use cases)    sync specs)
```

| Layer | Contains | May import | MUST NOT import |
|---|---|---|---|
| `presentation` | pages, widgets, Bloc/Cubit, UI mappers | own `domain/usecases` + `domain/entities`, cross-cutting `core/**/usecases`, `shared`, `design_system`, Flutter | any `data/`, any `domain/repositories/`, `core/sync` or `core/database` internals, `dio`, `drift`, `retrofit` |
| `domain` | entities, repository interfaces, use cases, value objects | `core/error`, pure `core/utils`, `dart:*`, `freezed_annotation`, `injectable` (in `domain/usecases/` only) | Flutter, `dio`, `drift`, `retrofit`, `get_it`, any `data/` or `presentation/` |
| `data` | DTOs, Retrofit API, Drift tables/DAOs, mappers, repository impls, `SyncSpec`s | own `domain`, `core`, `dio`, `drift`, `retrofit` | `presentation/`, Flutter widgets |
| `core` | cross-cutting infra (network, db, sync, error, di, router, logging) | other `core`, packages | any `features/` |
| `shared` | widgets/models reused by ≥ 2 features | `core`, `design_system` | any `features/` |

Cross-feature rule: feature A may import feature B's `domain/` **only** (entity or repository interface) and only when the task states it. Prefer passing **ids** between features (routes, events) over passing entities.

### 3.1 Use cases (mandatory, ADR-0011)

**Every operation a Bloc/Cubit performs on data, sync, or session goes through a use case — even when it is a one-line pass-through.** Blocs never import repositories.

- One class per operation. File `domain/usecases/<verb>_<noun>_use_case.dart`; class `<Verb><Noun>UseCase`; annotated `@injectable`; exposes a single public `call(...)`.
- Reads: `Watch<Noun>UseCase` returns `Stream<T>`. Operations: `Future<Result<T>> call(...)`.
- A use case may depend on repository interfaces (own feature; another feature's **domain** only if listed in `FEATURE.md` "Depends on"), `Clock`, the UUID generator. It MUST NOT depend on other use cases, DAOs, APIs, Flutter, or `get_it`. Shared logic between use cases goes into a pure domain service/value object.
- **Business rules live in the use case** (dedupe, validation, derivations, freshness checks). Repository implementations contain only persistence/sync mechanics. Blocs contain only UI state transitions.
- Use cases are stateless and do no caching (the DB is the cache).
- Cross-cutting use cases (sync status, connectivity, outbox summary, session) live in `core/<module>/usecases/` and are the only `core` imports presentation may use besides tokens/formatters.
- Each repository exposes `Stream<SyncStatus> watchSyncStatus()` for its own collection so feature Blocs get `isRefreshing/lastSyncedAt/isStale` through a feature use case, without knowing collection names.
- Pass-through use cases are expected, not a smell. The generator (T-070) creates them.

## 4. Repository layout

```
lib/
├── main_dev.dart  main_staging.dart  main_prod.dart   # flavor entry points → bootstrap()
├── app/                      # App widget, MaterialApp.router, global BlocProviders, bootstrap()
├── core/
│   ├── config/               # Env (envied), flavor, AppConfig
│   ├── database/             # AppDatabase, connection, converters, migrations, core tables
│   ├── di/                   # injection.dart, modules/ (Dio, DB, storage, clock, logger)
│   ├── error/                # Result, Failure, AppException, guard()
│   ├── logging/              # AppLogger, redaction, crash reporter
│   ├── network/              # Dio factory, interceptors/, DirectusQuery, envelopes, connectivity
│   ├── realtime/             # centrifuge connection manager
│   ├── router/               # AppRouter, guards
│   ├── security/             # secure storage, DB key, session store
│   ├── sync/                 # SyncCoordinator, SyncRegistry, DeltaSyncRunner, Outbox, conflict policies
│   └── utils/                # pure helpers (Clock, debounce, ...)
├── shared/                   # shared widgets/models; bloc/ (LoadStatus, debounceRestartable, safe_emit), sync/, error/ (FailurePresenter, FailureMessageMapper)
├── i18n/                     # slang JSON sources (*.i18n.json) only
├── generated/                # ALL generated code in lib/ (git-ignored; mirrors lib/ via build.yaml + slang + drift steps)
└── features/
    └── <feature>/
        ├── FEATURE.md        # contract of the feature (template in docs/templates)
        ├── data/
        │   ├── local/        # tables/, daos/
        │   ├── remote/       # <feature>_api.dart (Retrofit)
        │   ├── models/       # *_dto.dart
        │   ├── mappers/      # dto <-> entity <-> row mappers
        │   ├── sync/         # <feature>_sync_spec.dart
        │   └── repositories/ # <feature>_repository_impl.dart
        ├── domain/
        │   ├── entities/
        │   ├── repositories/ # abstract interface classes
        │   └── usecases/
        └── presentation/
            ├── bloc/
            ├── pages/
            └── widgets/
packages/
└── design_system/            # tokens, theme, components (feature-agnostic); generated assets in packages/design_system/lib/generated/
test/                         # mirrors lib/ + test/support/ (builders, fakes) + test/generated/ (git-ignored schema verifier helpers)
integration_test/
tool/                         # arch_check.dart, scripts
docs/  .agents/skills/
```

Local packages (existing: `design_system`; others such as payments/eKYC) live in `packages/`, never import from `lib/`, and expose a small public API.

## 5. Model separation (mandatory)

| Model | Where | Purpose | Example |
|---|---|---|---|
| **Entity** | `domain/entities` | Business object; immutable; no JSON | `Listing` |
| **DTO** | `data/models` | Exact wire shape of Directus; `fromJson/toJson` | `ListingDto` |
| **Row** | Drift-generated (`@DataClassName('ListingRow')`) | Exact DB shape | `ListingRow` |

Mappers are explicit pure functions/extensions (`ListingDto.toRow()`, `ListingRow.toEntity()`), unit-tested. Never reuse a DTO as an entity or expose a Row outside `data/`.

## 6. App bootstrap sequence (`app/bootstrap.dart`)

Order matters; do not reorder without an ADR.

1. `WidgetsFlutterBinding.ensureInitialized()`
2. Load `AppConfig` (flavor + envied)
3. Install **global error handlers** (`FlutterError.onError`, `PlatformDispatcher.instance.onError`) → `AppLogger` → crash reporter
4. Initialize Firebase (Crashlytics collection by flavor)
5. `configureDependencies(environment)` (injectable)
6. Open the database (key from secure storage; run migrations)
7. Restore session (tokens) → guards decide the initial route
8. Start `SyncCoordinator` (non-blocking: **never await network before `runApp`**)
9. `runApp(App())`

Cold start MUST render the first frame from local data without waiting for any network call.

## 7. Flavors and config

Three flavors: `dev`, `staging`, `prod` (Android product flavors + iOS schemes + `main_<flavor>.dart`). Differences are limited to: base URL, realtime URL, Firebase project, app id suffix, app name/icon, logging verbosity, interceptly enabled (dev/staging only). Do not use `kDebugMode` for behavior that differs per environment: use flavor config.

## 8. Feature contract (`FEATURE.md`)

Every feature MUST contain a `FEATURE.md` (template: `docs/templates/FEATURE.md`) declaring: purpose, entities, **data policy** (`CacheOnly` / `OutboxWrite` / `OnlineOnly`), Directus collections + fields, sync scope (mirror vs query-scoped), TTL, conflict policy, routes, Blocs, offline behavior per screen, and test list. It is what an agent reads first when modifying a feature, and MUST be updated in the same PR as behavior changes.
