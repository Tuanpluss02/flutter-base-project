---
name: add-api-endpoint
description: Add a Directus Retrofit endpoint, Freezed DTO, mapper, and contract/error tests.
---

# Skill: Add API Endpoint

Read first: `docs/05-networking-and-directus.md`, `docs/07-error-handling-logging.md`, `docs/15-data-source-decision.md`.

## Steps

1. **Verify Backend Contract & Update `FEATURE.md` (`docs/05` §3, `docs/15` §7):**
   - Confirm endpoint path, query parameters, `date_updated` format, and error codes (`extensions.code`). If the backend contract differs from `docs/05`, stop and report `BLOCKED`.
   - Document the collection, requested fields, filters, and data source policy in `FEATURE.md`.
2. **Create/Update DTO (`lib/features/<feature>/data/models/<name>_dto.dart`):**
   - Use `@freezed` (`abstract class <Name>Dto with _$<Name>Dto`) + `@JsonSerializable(fieldRename: FieldRename.snake)`.
   - Map unknown enum values to an `unknown` fallback member (`@JsonKey(unknownEnumValue: ...)`).
   - Parse timestamps as UTC; keep raw `date_updated` string for sync cursors.
3. **Declare Retrofit Method (`lib/features/<feature>/data/remote/<feature>_api.dart`):**
   - Return `DirectusItem<<Name>Dto>` or `DirectusList<<Name>Dto>`.
   - Build query params with `DirectusQuery` (never hand-concatenate query strings).
   - Attach the appropriate `CallClass` (`read`, `syncPage`, `write`, `auth`, `upload`, `probe`) in `Options.extra`.
   - For `RemoteQuery` / `OnlineOnly` methods (`docs/05` §12), accept an optional `CancelToken` mapped from domain `CancelHandle`.
4. **Error Mapping & Special Directus Rules (`docs/05` §10):**
   - Ensure `X-Request-Id` is propagated into `AppException`/`Failure.requestId`.
   - For `fetchById` / detail endpoints: map HTTP `403` (`FORBIDDEN`) to `NotFoundFailure` (Directus returns 403 for nonexistent or inaccessible item IDs); keep `ForbiddenFailure` for collection-level calls.
5. **Write Mapper (`lib/features/<feature>/data/mappers/<name>_mapper.dart`):**
   - Pure extensions converting `<Name>Dto` → Drift Companion/Row (`toRow()`) and Row → Domain Entity (`toEntity()`).
6. **Write Tests (`docs/05` §9, `docs/09` §3):**
   - Contract test with recorded Directus JSON fixture in `test/fixtures/directus/`.
   - Mapper unit tests covering all fields, nullable fields, unknown enums, and UTC dates.
   - Error-mapping test (including `403 → NotFoundFailure` on detail endpoints and `requestId` propagation).
