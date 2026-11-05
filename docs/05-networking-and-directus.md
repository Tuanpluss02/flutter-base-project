# 05 — Networking and Directus

> **ASSUMPTION banner:** no OpenAPI/API doc for the Directus backend has been confirmed yet. Everything marked ASSUMPTION below follows standard Directus REST behavior. The first agent implementing a Directus call MUST verify it against the backend team's API-docs repo (or a live dev instance). If it differs: **stop and report** (`AGENTS.md` §4).

## 1. Dio setup

One `Dio` instance per base URL, created in `core/network/dio_factory.dart`, registered in a DI module.

| Option | Value |
|---|---|
| `connectTimeout` | 10 s |
| `sendTimeout` | 15 s |
| `receiveTimeout` | 20 s |
| `responseType` | JSON |
| Default headers | `Accept: application/json`, `Accept-Language: <locale>`, `X-App-Version`, `X-Platform` |

**Interceptor order (outermost → innermost); do not reorder without an ADR:**

1. `InterceptlyDioInterceptor` (package `interceptly_dio`) — **dev/staging only** (never in prod builds). Added only when `AppConfig.flavor != Flavor.prod` (a compile-time constant from `main_<flavor>.dart`) so the inspector is tree-shaken from prod; a test asserts the prod interceptor list has exactly items 2–5.
2. `AuthInterceptor` (a `QueuedInterceptor`) — attaches `Authorization: Bearer`, on 401 performs a **single-flight** refresh and retries the request once.
3. `RetryInterceptor` — retries **GET/HEAD only** on connection errors/timeouts/502/503/504; max 2 retries; exponential backoff 500 ms, 1.5 s with jitter. Never retries POST/PATCH/DELETE (the outbox owns those retries).
4. `LoggingInterceptor` — structured, **redacted** (headers `Authorization`, `Cookie`; body fields `password`, `token`, `refresh_token`, `phone`, `email`, id numbers). Bodies logged only at `verbose` in dev.
5. `ErrorMappingInterceptor` — converts `DioException` to a typed `AppException` (§5) and puts it in `DioException.error`.

## 2. Retrofit conventions

- One abstract `@RestApi()` class per feature: `features/<f>/data/remote/<f>_api.dart`, registered through an injectable module (`@module`) — Retrofit classes are not annotated `@injectable` directly.
- API methods return **DTOs** (or `DirectusList<Dto>`), never entities, never `Result`. Errors surface as exceptions that the repository's `guard()` converts.
- Use generic envelopes from `core/network`: `DirectusItem<T>` (`{ "data": T }`), `DirectusList<T>` (`{ "data": [T], "meta": {...} }`), `DirectusErrors`.
- Query building goes through `DirectusQuery` (a typed builder): `fields`, `filter` (nested operators), `sort`, `limit`, `offset`/`page`, `search`, `meta`, `deep`. No hand-concatenated query strings in features.
- DTOs: `@freezed` + `@JsonSerializable(fieldRename: FieldRename.snake)`; every field explicit; unknown enum values map to an `unknown` member instead of throwing; dates parsed as UTC.

## 3. Directus contract (ASSUMPTION — verify)

| Need | Endpoint / syntax |
|---|---|
| Login | `POST /auth/login` `{email,password,mode:"json"}` → `{data:{access_token,refresh_token,expires}}` (`expires` in ms) |
| Refresh | `POST /auth/refresh` `{refresh_token,mode:"json"}` (refresh tokens rotate; persist the new one atomically) |
| Logout | `POST /auth/logout` `{refresh_token}` |
| Current user | `GET /users/me?fields=...` |
| List items | `GET /items/<collection>?fields=&filter[...]&sort=&limit=&offset=&meta=filter_count` |
| One item | `GET /items/<collection>/<id>` |
| Create / update / delete | `POST /items/<c>` · `PATCH /items/<c>/<id>` · `DELETE /items/<c>/<id>` |
| Delta filter | `filter[date_updated][_gte]=<ISO>` with `sort=date_updated,id` |
| Health/reachability | `GET /server/ping` (and `/server/health`) |
| Assets | `GET /assets/<id>?width=&height=&fit=&quality=&format=webp` |
| Error body | `{ "errors": [ { "message": "...", "extensions": { "code": "..." } } ] }` |

### Backend requirements checklist (send to the backend team)

1. Every synced collection exposes `date_created` and **`date_updated` (indexed)**, UTC, millisecond precision.
2. **Soft delete** (`status = deleted/archived` or `deleted_at`) for synced collections, included in delta queries; otherwise provide an id-list endpoint for reconciliation.
3. Stable, documented field names; no breaking changes without versioned fields. API docs/OpenAPI exported per release.
4. UUID primary keys that **accept client-supplied ids** on create.
5. Conflict detection for offline writes (Flow/hook returning 409 when `base_server_updated_at` ≠ current `date_updated`) — see ADR-0004.
6. Rate limits documented; `Retry-After` on 429.
7. Role/permission model per collection that supports the field lists the app requests.
8. A separate staging environment with seed data representative of production volume (for sync tests).
9. A way to read the **minimum supported app version** per platform (e.g. `/server/info` or a settings item) and a **maintenance flag**, returning 503 + `Retry-After` while in maintenance (§13).
10. Consistent error bodies (`errors[].extensions.code`) for every failure, including proxy/gateway errors returned as JSON.
11. **Push notifications:** a collection/endpoint to register and unregister an FCM device token per user (`token`, `platform`, `app_version`, `locale`), and a documented notification payload (`type`, target `collection` + `id`, optional deep-link path). Data messages carry ids only, never PII.
12. **Realtime transport confirmation:** confirm whether the backend exposes a **Centrifugo** endpoint (matching the locked `centrifuge` client in §6) or Directus native WebSocket (`/websocket`), along with channel naming conventions and token handshake format. If Directus native WebSocket is used without Centrifugo, stop and raise an ADR before T-043.

## 4. Auth and token handling

- Tokens persist **only** in `flutter_secure_storage`; in-memory copy in `SessionStore`. Access token never logged.
- **Single-flight refresh:** one refresh at a time; concurrent 401s await the same future; the retried requests use the new token. If refresh fails with 401/403 → emit `SessionExpired`, pause sync/outbox (keep ops), route to login via guard.
- Proactive refresh when `expires` is within 60 s.
- Refresh-token rotation: write the new refresh token **before** discarding the old; handle a crash between response and write by treating a failed refresh as session expiry.
- Logout: call `/auth/logout` best-effort, clear tokens, clear user-scoped DB data, cancel realtime.

## 5. Error mapping (ErrorMappingInterceptor → AppException → Failure)

| Condition | AppException | Failure (doc 07) |
|---|---|---|
| connect/send/receive timeout | `TimeoutException` | `TimeoutFailure` |
| no connectivity / socket / TLS | `NetworkException` | `NetworkFailure` |
| 401 | `UnauthorizedException` | `UnauthorizedFailure` |
| 403 | `ForbiddenException` | `ForbiddenFailure` |
| 404 | `NotFoundException` | `NotFoundFailure` |
| 409 / Directus conflict code | `ConflictException` | `ConflictFailure` |
| 400/422 with `errors[]` | `ValidationException(fieldErrors)` | `ValidationFailure` |
| 429 | `RateLimitedException(retryAfter)` | `RateLimitedFailure` |
| 5xx | `ServerException(status)` | `ServerFailure` |
| cancelled | `CancelledException` | (ignored by callers) |
| anything else | `UnknownException` | `UnknownFailure` |

## 6. Realtime (centrifuge)

- Single `RealtimeConnection` in `core/realtime`, started after login, stopped on logout. Reconnect with exponential backoff; token refresh hook.
- Realtime events **do not update the UI directly.** They map to `SyncCoordinator.requestSync(collection, reason: realtime)` (optionally applying the payload to the DB via the same upsert path if the payload is the full row).
- Channels are declared per feature in its sync/realtime config and documented in `FEATURE.md`.
- Missing events must be harmless: the next TTL/resume sync converges state.

## 7. Configuration and transport security

- Base URLs/keys come from `envied` (obfuscated), per flavor. No URL literals elsewhere.
- Certificate pinning: decided in ADR-0009 (default: **enabled for prod** with backup pins and a documented rotation procedure).
- HTTPS only; cleartext blocked via platform config.
- Request size limits and gzip: accept `gzip`; request only needed `fields`.

## 8. Uploads and large payloads

Multipart uploads use `Dio` `FormData` with progress callbacks and cancel tokens; they are `OnlineOnly` unless a feature declares otherwise. Never hold large files in memory; stream from disk.

## 9. Testing networking

- Retrofit APIs: contract tests with `http_mock_adapter` (recorded Directus fixtures in `test/fixtures/directus/`).
- Interceptors: unit tests for each (401 single-flight with N concurrent requests, retry matrix, redaction, error mapping table above).
- Repositories use **fake remote data sources**, not real Dio.

## 10. Request ids and Directus error codes (ASSUMPTION — verify codes against the backend)

- The logging interceptor generates a UUID v4 `X-Request-Id` per request, attaches it, logs it, and `ErrorMappingInterceptor` copies it into the `AppException`/`Failure` (`requestId`). Ask backend to log it.
- Mapping is **table-driven** (`core/network/error_code_map.dart`, unit-tested) and **`extensions.code` takes priority over the HTTP status** when it is more specific; unknown code → fall back to the status table in §5.

| `extensions.code` (Directus) | Failure |
|---|---|
| `INVALID_CREDENTIALS` | `InvalidCredentialsFailure` (login only) |
| `TOKEN_EXPIRED`, `INVALID_TOKEN` | triggers the refresh path in `AuthInterceptor`; if refresh fails → `UnauthorizedFailure` |
| `FORBIDDEN` | `ForbiddenFailure` — **but** Directus returns 403 for items the role cannot read, including nonexistent ids: for `fetchById`/detail, map 403 to `NotFoundFailure`; keep `ForbiddenFailure` for collection-level calls |
| `ROUTE_NOT_FOUND` | `NotFoundFailure` |
| `INVALID_PAYLOAD`, `FAILED_VALIDATION`, `UNPROCESSABLE_CONTENT`, `INVALID_QUERY` | `ValidationFailure` (`INVALID_QUERY` is a client bug: also report to crash reporter) |
| `RECORD_NOT_UNIQUE` | `ConflictFailure(duplicate)` (outbox create rule, doc 02 §8) |
| `REQUESTS_EXCEEDED` | `RateLimitedFailure` |
| `SERVICE_UNAVAILABLE` | `MaintenanceFailure` if maintenance flag/`Retry-After`, else `ServerFailure` |
| `INTERNAL_SERVER_ERROR` | `ServerFailure` |

If the real backend uses different codes: **stop and report** (`AGENTS.md` §4).

## 11. Timeouts by call class

Each request declares a `CallClass` via `Options.extra`; the factory applies the timeouts. No ad-hoc timeouts in features.

| CallClass | connect | send | receive | Notes |
|---|---|---|---|---|
| `read` (list/detail) | 10 s | 15 s | 20 s | GET retry allowed (2) |
| `syncPage` | 10 s | 15 s | 30 s | Adaptive page size below |
| `write` (PATCH/POST/DELETE) | 10 s | 15 s | 20 s | No auto-retry (outbox owns) |
| `auth` (login/refresh) | 10 s | 10 s | 10 s | |
| `upload` | 10 s | stall-based | stall-based | Fail if no progress for 30 s; never a total timeout |
| `probe` (`/server/ping`) | 3 s | 3 s | 3 s | |

**Adaptive page size (sync):** on a timeout during `syncPage`, halve `limit` (200 → 100 → 50, min 25) for the rest of that run; after 3 consecutive successful runs restore 200. Slow networks are never "fixed" by shortening timeouts or retrying non-idempotent calls.

## 12. Cancellation

- `RemoteQuery`/`OnlineOnly` repository methods accept an optional `CancelHandle` (pure Dart class in `core/utils`; the data layer maps it to Dio's `CancelToken`). Use cases forward it.
- Blocs using `restartable()` for search/filter cancel the previous call; Bloc `close()` cancels in-flight calls.
- A cancelled call yields `CancelledException`, which callers ignore (no failure UI, no log above `debug`).
- Sync/outbox calls are not cancelled on screen exit (they belong to the app, not a screen).

## 13. Server states: maintenance, force-update, circuit breaker

- **Global `AppStatusBloc`** (global Bloc, doc 04 §2) consumes cross-cutting use cases and exposes: `ok | maintenance | updateRequired | contractBroken(collections)`. Router guards and the shell read it.
- **Maintenance:** 503 with `Retry-After` or the backend flag (checklist item 9). Pause sync and outbox, **do not increment outbox `attempt_count` or backoff exponent**, probe every 30–60 s, resume automatically. UI per doc 07 §9.
- **Force update:** HTTP 426, or version below the server's minimum (checked at start and on resume, cached 1 h). Blocks the app behind `ForceUpdateGuard` with a store link; local data stays untouched.
- **Circuit breaker (`NetworkCircuitBreaker`, `core/network`):** after 5 consecutive network/5xx failures within 60 s from *background* sync/outbox calls, open for 30 s, then 60 s, 120 s (max 5 min); a successful probe closes it. While open, background calls are skipped (no battery/server hammering). **User-initiated actions bypass the breaker** (they always attempt the request).
- **Captive portals / proxies:** a response whose content-type is not JSON where JSON is expected (HTML login page) becomes `NetworkFailure(unexpectedContent)`, not a parsing error. The reachability probe requires the body to be exactly `pong`.

## 14. Network behavior checklist (tests required)

Table-driven tests for: error-code map; `CallClass` timeouts applied; adaptive page size; breaker open/close and user-action bypass; maintenance pause without consuming attempts; force-update trigger; captive-portal HTML response; cancellation on `restartable()`; `requestId` propagation from request to `Failure`.
