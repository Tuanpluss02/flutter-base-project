# 03 — Code Conventions

## 1. Language rules

- Dart 3 features are expected: `sealed` classes, records (local use only, never in public APIs), pattern matching, `switch` expressions, `final class` / `interface class`.
- **Imports & `part` directives:** always use `package:` imports (`always_use_package_imports`) for `import` and `export`. No relative `import`/`export`. No barrel files (they hide dependencies from the architecture checker). Import the exact file. For `part` directives pointing into `lib/generated/**` (required by `freezed`/`source_gen` `build_extensions`), use the relative path to `lib/generated/...` (`part` in Dart does not support `package:` URIs).
- **Null-safety:** avoid `!`. If unavoidable, add a one-line reason comment. Prefer pattern matching / early return.
- **Types:** no `dynamic`, no implicit `dynamic` (strict-casts/inference/raw-types on). Explicit return types on all public members. No `as` across layers.
- **Immutability:** domain/state classes are immutable (`freezed` or `final` fields + `const` constructors). With `freezed` v3+, declare single-constructor classes as `abstract class Foo with _$Foo` and union types as `sealed class Foo with _$Foo`. Collections exposed from domain are unmodifiable.
- **Async:** every `Future` is awaited or explicitly wrapped in `unawaited(...)` with a reason. No `async` without `await`. Dispose every `StreamSubscription`/`Timer`/controller.
- **Time:** never call `DateTime.now()` directly; inject `Clock` (`package:clock`). Persist/compare in UTC.
- **Equality:** use `freezed` value equality; no manual `==` unless justified.
- **Enums:** use enhanced enums; store DB/wire values via an explicit `wireValue`, never `name` index.
- **Extensions** only for mappers and tiny helpers; no extension on `BuildContext` that hides logic.

## 2. Naming

| Thing | Rule | Example |
|---|---|---|
| Files/folders | `snake_case.dart` | `listing_repository_impl.dart` |
| Classes | `UpperCamelCase` | `ListingRepositoryImpl` |
| Entity | plain noun | `Listing` |
| DTO | `<Name>Dto` | `ListingDto` |
| Drift table class | plural noun + `@DataClassName('<Name>Row')` | `Listings` → `ListingRow` |
| DAO | `<Name>Dao` | `ListingDao` |
| Retrofit API | `<Feature>Api` | `ListingApi` |
| Repository | interface `<Name>Repository`, impl `<Name>RepositoryImpl` | |
| Sync spec | `<Name>SyncSpec` | |
| Use case | file `<verb>_<noun>_use_case.dart`, class `<Verb><Noun>UseCase`, single public `call()`; reads `Watch…` | `SetFavoriteUseCase`, `WatchListingsUseCase` |
| Bloc | `<Feature><Subject>Bloc`, events `<Subject>Event` (sealed), states `<Subject>State` | `ListingListBloc` |
| Event | past-tense or intent noun: `ListingListStarted`, `ListingListRefreshed`, `ListingFilterChanged` | |
| Page | `<Name>Page` (route-level), `<Name>View` (pure UI under provider) | |
| Widget | noun, no `Widget` suffix | `ListingCard` |
| Private members | `_leadingUnderscore` | |
| Booleans | `is/has/can/should` | `isStale` |
| Streams | `watch<Thing>()` | `watchListings()` |
| Test files | `<source_name>_test.dart` mirroring `lib/` path | |
| Slang keys | `feature.section.key` lowerCamel | `listing.detail.contactAgent` |
| Constants | `lowerCamelCase`; no `SCREAMING_CASE` | |

## 3. Widgets

- `const` constructors everywhere possible. Prefer widget **classes** over helper methods returning widgets.
- Pages: `XPage` (provides Bloc via `BlocProvider`, `@RoutePage`) wraps `XView` (consumes Bloc). `XView` is testable with a fake Bloc.
- Keep `build` free of logic: derive display values in the Bloc state or a small presenter/mapper.
- Use `BlocSelector`/`buildWhen` to limit rebuilds; list items use stable `ValueKey(id)`.
- Every screen defines **all four states**: loading (no data yet), empty, error, data (+ stale/offline indicators). See `docs/12`.
- No hard-coded sizes/colors/strings: `context.t` (slang), `context.tokens` / design-system tokens.
- Accessibility: semantic labels for icons/images, min tap target 48×48, text scales to at least 1.5×, sufficient contrast (see doc 08).

## 4. Comments and docs

- Explain **why**, not what. No commented-out code. No change-log comments.
- Doc comments (`///`) required on: `core/` public APIs, repository interfaces, `SyncSpec`s, non-obvious algorithms.
- A non-obvious decision → ADR (doc 14), not a long comment.

## 5. Git and PR rules

- Branch: `feat|fix|chore|refactor|docs|test/PROJ-123-short-name`.
- Commits: Conventional Commits (`feat(listing): add mirror sync spec`). Scope = feature or core module.
- One concern per PR; target ≤ 400 changed lines (excluding generated/lockfile). Bigger → split.
- PR description uses `docs/templates/PR.md`: what/why, screenshots for UI, offline behavior verified, test evidence, risks.
- Never force-push shared branches; never commit generated files, secrets, `.env`, IDE files, build output.
- Don't mix mechanical changes (renames/format) with logic changes.

## 6. Forbidden list (CI or review rejects)

`print`/`debugPrint` · `dynamic` · unjustified `!` / `late` / `as` · empty `catch` · `catch (e)` without handling · `Future.delayed` as a synchronization mechanism · `BuildContext` after `await` without `mounted` · `getIt<...>()` outside DI modules and composition roots · `DateTime.now()` outside `Clock` · hard-coded strings/colors/URLs/keys · logic in widgets · cross-feature `data/presentation` imports · Bloc→Bloc references · Bloc importing a repository, DAO, API class or `SyncCoordinator` (use cases only) · `setState` in feature pages (use Bloc; allowed only for purely local ephemeral UI like animations/controllers) · `Navigator.push` (use auto_route) · global mutable state · `// ignore` without reason · TODO without ticket · files > 500 lines.

## 7. Required list

`const` where possible · explicit types · `Result` at repository boundaries · a use case for every Bloc→data operation · `AppLogger` for diagnostics · `Clock` for time · slang for text · tokens for style · tests for every behavior change · `FEATURE.md` updated · `dispose`/`close` for everything created.

## 8. Self-review checklist (agents run this before reporting)

1. Did I touch only files in scope? 2. Dependency direction intact? 3. Any forbidden-list item? 4. Errors → `Failure` everywhere? 5. All UI states handled incl. offline/stale? 6. Strings/colors via slang/tokens? 7. Tests added per doc 09 matrix? 8. `FEATURE.md`/docs updated? 9. `make check` green? 10. Any assumption to report?
