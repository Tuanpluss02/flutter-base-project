# 07 — Error Handling and Logging

## 1. Model

```
Data source (Dio/Drift) ──throws──► AppException (typed)
Repository  guard() ──catches──► Result<T> = Ok<T> | Err<T>(Failure)
Domain / Bloc ──switch on──► Result;  Failure ──► state.failure
Widget ──FailureMessageMapper──► localized text
```

- Exceptions exist **only inside `data/` and `core/`**. They never cross a repository boundary.
- Domain and presentation only know `Result` and `Failure`.
- Streams (`watchX`) signal errors via `Stream.error(AppException→Failure)` rarely; prefer exposing failures through sync status. A stream error MUST be converted by the Bloc (`onError`).

## 2. Reference types (`core/error/`)

```dart
sealed class Result<T> {
  const Result();
  R fold<R>(R Function(T value) ok, R Function(Failure failure) err) => switch (this) {
        Ok<T>(:final value) => ok(value),
        Err<T>(:final failure) => err(failure),
      };
  Result<R> map<R>(R Function(T) f) => switch (this) {
        Ok<T>(:final value) => Ok(f(value)),
        Err<T>(:final failure) => Err(failure),
      };
}
final class Ok<T> extends Result<T> { const Ok(this.value); final T value; }
final class Err<T> extends Result<T> { const Err(this.failure); final Failure failure; }

sealed class Failure {
  const Failure({this.message, this.cause, this.stackTrace});
  final String? message;          // developer-facing only, never shown to users
  final Object? cause;
  final StackTrace? stackTrace;
}
final class NetworkFailure extends Failure { const NetworkFailure({super.cause, super.stackTrace}); }
final class TimeoutFailure extends Failure { ... }
final class UnauthorizedFailure extends Failure { ... }
final class ForbiddenFailure extends Failure { ... }
final class NotFoundFailure extends Failure { ... }
final class ConflictFailure extends Failure { ... }
final class ValidationFailure extends Failure { const ValidationFailure({required this.fieldErrors, ...}); final Map<String, List<String>> fieldErrors; }
final class RateLimitedFailure extends Failure { final Duration? retryAfter; ... }
final class ServerFailure extends Failure { final int? statusCode; ... }
final class StorageFailure extends Failure { ... }          // Drift/secure storage errors
final class UnknownFailure extends Failure { ... }

Future<Result<T>> guard<T>(Future<T> Function() body, {AppLogger? logger}) async {
  try {
    return Ok(await body());
  } on AppException catch (e, s) {
    return Err(e.toFailure(s));
  } on Object catch (e, s) {
    logger?.error('unexpected', error: e, stackTrace: s);   // reported to crash reporter
    return Err(UnknownFailure(cause: e, stackTrace: s));
  }
}
```

`CancelledException` is not converted into a user-visible failure; callers ignore it.

## 3. Rules

1. Every repository method that does I/O returns `Future<Result<T>>` (or a `Stream`); wrap bodies in `guard()`.
2. Never `throw` from domain/presentation code to signal expected outcomes.
3. Never `catch` just to log and continue silently. Catch → map → return, or rethrow.
4. Preserve `cause` and `stackTrace`.
5. `ValidationFailure.fieldErrors` keys are **Directus field names**; the presentation layer maps them to form fields.
6. User-facing text is never built from `Failure.message` or exception text.

## 4. User-facing messages (`FailureMessageMapper`)

One mapper in `shared/`: `String messageFor(Failure f, Translations t)`; one slang key per failure kind (`errors.network`, `errors.timeout`, `errors.unauthorized`, `errors.server`, `errors.unknown`, ...). Features may add specific mappings (e.g. `errors.listing.notAvailable`). Offline gets a calm message with Retry, not an alarming error.

## 5. Global handlers (installed in `bootstrap()`)

- `FlutterError.onError` → `AppLogger.fatal/error` + crash reporter (fatal in release).
- `PlatformDispatcher.instance.onError` → same, return `true`.
- `Isolate.current.addErrorListener` for isolates we spawn.
- A user-friendly fallback `ErrorWidget.builder` in release.
- Bloc: `Bloc.observer = AppBlocObserver` logs transitions at `debug` (redacted) and `onError` at `error`.

## 6. Logging (`core/logging`)

```dart
abstract interface class AppLogger {
  void verbose(String message, {Map<String, Object?> data});
  void debug(String message, {Map<String, Object?> data});
  void info(String message, {Map<String, Object?> data});
  void warning(String message, {Object? error, StackTrace? stackTrace, Map<String, Object?> data});
  void error(String message, {Object? error, StackTrace? stackTrace, Map<String, Object?> data});
}
```

- Implementations: console (dev/staging, colored), crash-reporter sink (release: `info+` as Crashlytics breadcrumbs, `error` as non-fatal), composite.
- **Redaction** is applied centrally before any sink: tokens, passwords, emails, phone numbers, national-id/passport numbers, card/bank numbers, full addresses of users. Redactor has unit tests with a fixture list.
- Structured events use dotted names: `sync.ok`, `outbox.retry`, `auth.refresh.fail`. Include ids, counts, durations; never payload bodies in release.
- Levels: `verbose/debug` off in release; `info` for lifecycle/sync summaries; `warning` for recoverable anomalies; `error` for unexpected failures.
- Crashlytics: set user id as an **opaque hashed id**, never email/phone; attach flavor, locale, app version, sync status keys.
- Report to the crash reporter: `UnknownFailure`, `StorageFailure`, permanent outbox failures, migration failures, global handler errors. Do **not** report expected failures (offline, 401 pre-refresh, validation, 404 on delete).

## 7. Testing

`guard()` mapping table tests; redactor tests; every repository: one test per failure kind it can produce; global-handler smoke test that an uncaught error reaches the logger/reporter fake.

## 8. Additional failure types (extend the sealed `Failure`)

| Failure | Raised when | Notes |
|---|---|---|
| `ParsingFailure` | DTO deserialization fails (`CheckedFromJsonException`, `FormatException`, `TypeError` from a response) | `guard()` MUST map these to `ParsingFailure`, not `UnknownFailure`. Reported to crash reporter with the collection/endpoint (no payload). |
| `ContractMismatchFailure` | Too many rows/fields in a response don't match the expected shape (§10) | Treated as backend/app version drift. |
| `InvalidCredentialsFailure` | Login rejected with invalid credentials | Auth feature only. |
| `MaintenanceFailure` | Server reports maintenance (doc 05 §13) | Drives the global maintenance state; never counted against retry attempts. |
| `UpdateRequiredFailure` | Server says this app version is no longer supported (doc 05 §13) | Drives force-update guard. |

Every `Failure` carries an optional `requestId` (the `X-Request-Id` of the failing request, doc 05 §10). Support screens may show it as a short "error code".

## 9. Error UX policy (where a failure is shown)

The same failure is presented differently depending on context. Implement in `shared/` (`FailurePresenter`) so features do not decide ad hoc.

Contexts: **A** screen already has data · **B** screen has no data · **C** user-initiated action (submit/confirm) · **D** background sync/outbox.

| Failure | A (has data) | B (no data) | C (user action) | D (background) |
|---|---|---|---|---|
| Network / Timeout | Offline banner + stale indicator; **no toast** | Error state, offline variant, Retry | Inline message near the action, **keep user input**, Retry. For `OutboxWrite`: no error at all (accepted locally, pending badge) | Silent; log; retry/backoff |
| Server 5xx | One snackbar (max 1 per 30 s per screen) + stale | Error state + Retry | Message + Retry | Backoff; log |
| Unauthorized (after failed refresh) | One-time dialog → login; **keep drafts and outbox** | Same | Same | Pause sync/outbox; route to login |
| Forbidden | "No permission" notice | "No permission" state | Message | Mark op `failed` |
| NotFound | "No longer available" state with back action | Same | Message | Treat per doc 02 §8 |
| Validation | Field-level errors on the form; never only a snackbar | n/a | Field-level errors | `failed` + stored field errors surfaced in the failed-row UI |
| RateLimited | n/a | Retry after N s | Disable action with countdown | Honor `Retry-After` |
| Storage | Recovery dialog (reset cache + resync) after logging | Same | Same | Log + report |
| Parsing / ContractMismatch | Keep cached data, show stale; report | Error state with generic message | Generic message | Quarantine/pause (§10) |
| Maintenance | Global maintenance banner | Maintenance screen | Disable action | Pause without consuming attempts |
| UpdateRequired | Force-update screen | Same | Same | Stop sync |
| Unknown | Generic message + error code | Generic error state + error code | Generic message + error code | Log + report |

Rules:
1. **One surface per cause:** banner OR snackbar OR error state, never two.
2. **Never toast for background (D) failures.**
3. **Errors never replace existing data**; they overlay it.
4. **Every error state has an action** (Retry / Back / Login / Update).
5. User text always comes from `FailureMessageMapper`; never raw exception or server text.
6. Offline is calm and informational, not red/alarming.
7. Preserve user input on any failure.

## 10. Parsing errors and poison rows

A single malformed record must not block a whole collection forever.

- **Per-row mapping:** inside `applyPage`, wrap **only the DTO→Row mapper** per row. On failure: skip the row, insert into `sync_quarantine (collection, entity_id, server_updated_at, error)`, log `sync.row_skipped {collection, id, reason}`, count it. Rate-limit crash-reporter non-fatals to once per collection per hour.
- **Cursor still advances** past quarantined rows (otherwise the same row blocks every sync). Quarantined rows are retried on forced full resync, `schemaVersion` bump, or app upgrade.
- **Contract break detection:** if **≥ 20% of rows in a page (and ≥ 5 rows)** fail mapping, treat the whole page as a contract mismatch: **do not advance the cursor**, return `Err(ContractMismatchFailure)`, keep cached data, mark the collection `contractBroken` (UI shows stale, never an error wall), report with a sample of field names (no values). Next TTL tries again; an app update usually fixes it.
- **Unknown enum values / extra fields** are not errors: DTOs tolerate them (`unknown` enum member, ignore extra keys).
- A missing **required** field (`id`, `date_updated`/cursor source) is a mapping failure for that row.
- Never `try/catch` parsing in widgets or Blocs.

Tests: scenarios 19–20 in doc 09 §7.
