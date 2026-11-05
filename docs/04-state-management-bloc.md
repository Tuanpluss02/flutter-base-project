# 04 — State Management (Bloc)

## 1. Bloc vs Cubit

- **Bloc** (default): any async flow, anything reacting to repository streams, anything with more than ~2 interactions.
- **Cubit**: only trivial synchronous/local UI state (tab index, toggle, password visibility).
- Never put business logic in `StatefulWidget`s.

## 2. Scope and lifetime

| Kind | Examples | Registration | Provided |
|---|---|---|---|
| Page Bloc | `ListingListBloc`, `ListingDetailBloc` | `@injectable` (factory) | `BlocProvider(create: (_) => getIt())` in the `Page` |
| Global Bloc | `SessionBloc`, `ConnectivityBloc`, `SyncStatusBloc`, `AppStatusBloc`, `AppSettingsBloc`, `LocaleBloc` | `@lazySingleton` | once at `App` root |

Rules: page Blocs never outlive their page; global Blocs hold only app-wide state; constructor-inject **use cases only** — never repositories, DAOs, `Dio`, `SyncCoordinator`, or other Blocs (see `docs/01` §3.1).

## 3. State shape

One immutable `freezed` class per Bloc. Standard fields for data screens (names are fixed so tooling and widgets can be shared):

```dart
@freezed
abstract class ListingListState with _$ListingListState {
  const factory ListingListState({
    @Default(LoadStatus.initial) LoadStatus status,        // initial | loading | ready
    @Default(<Listing>[]) List<Listing> items,
    @Default(ListingFilter.empty) ListingFilter filter,
    @Default(false) bool isRefreshing,                      // background refresh in flight
    @Default(false) bool isStale,                           // older than TTL or last refresh failed
    DateTime? lastSyncedAt,
    Failure? failure,                                       // last non-blocking failure; cleared by FailureConsumed
  }) = _ListingListState;
}
```

- `status == initial/loading` **and no items** → skeleton. Items present → render them, regardless of `isRefreshing`.
- Do not model "error" as a status that hides data. Failure is an overlay on top of data.
- One-shot UI effects (snackbar/navigation) are derived from `failure`/`message` fields and consumed with an explicit event (`FailureConsumed`) via `BlocListener`. Do not add a parallel effects stream.

## 4. Events

`sealed class ListingListEvent` with small `final class` subtypes. Names: `Started`, `Refreshed`, `FilterChanged`, `FailureConsumed`, `FavoriteToggled`, ... Events carry **ids and primitives**, not entities fetched elsewhere.

## 5. Concurrency transformers (mandatory table)

| Event kind | Transformer |
|---|---|
| Subscribe to a repository stream (`Started`) | `restartable()` (or `droppable()` if idempotent) |
| Search / filter typing | `debounce(300 ms)` + `restartable()` |
| Pull-to-refresh / retry | `droppable()` |
| Submit / create / pay | `droppable()` (prevents double submit) |
| Toggle (favorite) | `sequential()` per bloc, or `droppable()` with optimistic outbox write |
| Pagination `LoadMore` | `droppable()` |
| Default | `sequential()` |

Never rely on the default transformer by accident; set it per `on<Event>`.

`restartable()`, `droppable()`, `sequential()` come from `bloc_concurrency`. `bloc_concurrency` has **no debounce**, so the base ships one helper (no extra package, no `stream_transform`/`rxdart`):

```dart
// lib/shared/bloc/transformers.dart (owned by T-016)
EventTransformer<E> debounceRestartable<E>({Duration duration = const Duration(milliseconds: 300)}) =>
    (events, mapper) => restartable<E>()(events.debounce(duration), mapper);
```

`debounce` is a small private `Stream` extension in the same file (Timer-based, cancels on listen cancel), unit-tested with `fakeAsync`. `LoadStatus` (`initial | loading | ready`) lives in `lib/shared/bloc/load_status.dart`, and `SafeEmitterX<S>` (`emit.safe(state)` checking `!isDone`) + `SafeCubitX<S>` (`safeEmit(state)` checking `!isClosed`) live in `lib/shared/bloc/safe_emit.dart` (never in `lib/core/`, which would violate `A16`). Do **not** force a `BaseBloc` inheritance hierarchy. Blocs import these helpers from `shared/bloc/`.

## 6. Handler pattern with use cases and repository streams

```dart
// domain/usecases/watch_listings_use_case.dart
@injectable
class WatchListingsUseCase {
  WatchListingsUseCase(this._repo);
  final ListingRepository _repo;
  Stream<List<Listing>> call(ListingFilter filter) => _repo.watchListings(filter);
}

// domain/usecases/refresh_listings_use_case.dart
@injectable
class RefreshListingsUseCase {
  RefreshListingsUseCase(this._repo);
  final ListingRepository _repo;
  Future<Result<void>> call({bool force = false}) => _repo.refresh(force: force);
}

// domain/usecases/watch_listing_sync_status_use_case.dart
@injectable
class WatchListingSyncStatusUseCase {
  WatchListingSyncStatusUseCase(this._repo);
  final ListingRepository _repo;
  Stream<SyncStatus> call() => _repo.watchSyncStatus();
}
```

```dart
// presentation/bloc/listing_list_bloc.dart
@injectable
class ListingListBloc extends Bloc<ListingListEvent, ListingListState> {
  ListingListBloc(this._watchListings, this._refresh, this._watchSyncStatus)
      : super(const ListingListState()) {
    on<ListingListStarted>(_onStarted, transformer: restartable());
    on<ListingListRefreshed>(_onRefreshed, transformer: droppable());
    on<ListingFilterChanged>(_onFilterChanged, transformer: debounceRestartable());
    on<FailureConsumed>((e, emit) => emit(state.copyWith(failure: null)));
  }

  final WatchListingsUseCase _watchListings;
  final RefreshListingsUseCase _refresh;
  final WatchListingSyncStatusUseCase _watchSyncStatus;

  Future<void> _onStarted(ListingListStarted e, Emitter<ListingListState> emit) async {
    emit(state.copyWith(status: state.items.isEmpty ? LoadStatus.loading : state.status));
    unawaited(_refresh());                            // background, single-flight inside the sync layer
    await Future.wait([
      emit.forEach<List<Listing>>(
        _watchListings(state.filter),
        onData: (items) => state.copyWith(status: LoadStatus.ready, items: items),
        onError: (error, _) => state.copyWith(failure: error.toFailure()),
      ),
      emit.forEach<SyncStatus>(
        _watchSyncStatus(),
        onData: (s) => state.copyWith(
            isRefreshing: s.isRefreshing, lastSyncedAt: s.lastSyncedAt, isStale: s.isStale),
      ),
    ]);
  }
}
```

Rules: the Bloc imports only `domain/usecases/*`, entities and core cross-cutting use cases. Sync status comes from the feature's own `Watch…SyncStatusUseCase`, never from `SyncCoordinator` in the Bloc. Each Bloc action maps to exactly one use case call (or a small number of them); do not compose business rules in the handler.

## 7. Bloc ↔ Bloc and cross-screen data

- **Forbidden:** one Bloc holding or listening to another Bloc.
- Share data through **repositories** (streams from the DB are the shared bus). Example: favorite toggled on detail → DB changes → list Bloc's stream emits.
- Need to react to a global change in a page (e.g. session ended)? Do it in the widget tree with `BlocListener<SessionBloc, ...>` or via the router guard, not inside another Bloc.

## 8. Error handling in Blocs

Repositories return `Result`; Blocs `switch` on it and put a `Failure` into state. Never `try/catch` around repository calls in a Bloc (they don't throw). Map `Failure` → text in the **widget layer** through `FailureMessageMapper` (doc 07).

## 9. Testing (required)

Use `bloc_test` with the **real use cases built over a hand-written fake repository** (keeps tests behavior-focused and avoids mocking concrete classes). Per Bloc, cover: initial state; happy path; empty data; failure with data present (data kept); failure with no data; refresh in-flight dedupe (`droppable`); filter debounce; each event's transformer behavior; and `close()` cancels subscriptions. See doc 09.

## 10. Do / Don't

Do: keep state minimal and derived values in getters; use `buildWhen`/`BlocSelector`; keep handlers small and private; close everything.
Don't: emit after `close`; call `emit` in callbacks outside handlers; store `BuildContext`; put `Stream`/`Future`/controllers in state; navigate from a Bloc.
