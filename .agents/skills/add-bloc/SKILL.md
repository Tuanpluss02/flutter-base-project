---
name: add-bloc
description: Implement a feature Bloc or Cubit with sealed events, immutable freezed state, concurrency transformers, and use-case-only dependencies.
---

# Skill: Add Bloc

Read first: `docs/04-state-management-bloc.md`, `docs/03-code-conventions.md`, `docs/07-error-handling-logging.md` §9, ADR-0014 in `docs/14-decisions.md`.

## Rules (enforced by `arch_check.dart` A15, A16)

1. **Dependencies:**
   - Constructor parameters MUST be `*UseCase` classes only. Never inject repositories, DAOs, API classes, `SyncCoordinator`, or other Blocs/Cubits.
   - Page Blocs are annotated `@injectable` (factory); global Blocs are `@lazySingleton`.
   - From `core/**`, only `**/usecases/**`, `core/error/**`, `core/utils/**`, and `core/router/**` may be imported. Shared Bloc utilities (`LoadStatus`, `debounceRestartable`, `SafeEmitterX`, `SafeCubitX`) are imported from `package:<app>/shared/bloc/...`.
2. **Events & State:**
   - Events: `sealed class <Subject>Event` with `final class` subtypes carrying only IDs/primitives (never entities from other screens).
   - State: single immutable `@freezed abstract class <Subject>State with _$<Subject>State` including standard fields (`status`, `items`, `isRefreshing`, `isStale`, `lastSyncedAt`, `failure`).
   - Use `emit.safe(state)` (`SafeEmitterX`) / `safeEmit(state)` (`SafeCubitX`) from `lib/shared/bloc/safe_emit.dart` after async gaps so cancelled handlers or closed Cubits never throw `StateError`. Do **not** extend a `BaseBloc`.
   - Never hide existing `items` when a background refresh fails; surface `failure` as an overlay and clear it via `FailureConsumed`.
3. **Transformers (mandatory per `docs/04` §5 — set on every `on<Event>`):**
   - Subscribe to repository stream (`Started`): `restartable()` (or `droppable()` if idempotent)
   - Search / filter typing: `debounceRestartable()` (`300 ms` debounce + `restartable()` from `lib/shared/bloc/transformers.dart`)
   - Pull-to-refresh / retry: `droppable()`
   - Submit / create / pay: `droppable()` (prevents double submit)
   - Toggle (favorite): `sequential()` per bloc, or `droppable()` with optimistic outbox write
   - Pagination `LoadMore`: `droppable()`
   - Default for other events: `sequential()`
4. **Testing (`docs/04` §9):**
   - Create `test/features/<feature>/presentation/bloc/<name>_bloc_test.dart` using `bloc_test` with real use cases over a fake repository.
   - Cover: initial state, happy path, empty state, failure with cached data preserved, failure with empty data, transformer deduplication/debounce, and subscription cleanup on `close()`.
5. **Update `FEATURE.md`** "Blocs" table.
