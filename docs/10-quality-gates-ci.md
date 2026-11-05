# 10 — Quality Gates, CI, Release

## 1. `make` targets (single source of truth; CI calls the same targets)

| Target | Does |
|---|---|
| `make bootstrap` | `fvm install`, `flutter pub get` (app + `packages/*`), `make gen` |
| `make gen` | In order: (1) if `drift_schemas/*.json` exist, `drift_dev schema steps` → `lib/generated/core/database/schema_versions.g.dart` and `drift_dev schema generate` → `test/generated/migrations/` (doc 06 §4); (2) `dart run build_runner build --delete-conflicting-outputs` in app and packages (with `build.yaml` `build_extensions` routing all `*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `*.config.dart` into `lib/generated/**`); (3) slang → `lib/generated/i18n/` |
| `make watch` | `build_runner watch` |
| `make format` / `make format-check` | `dart format --set-exit-if-changed` (page width 100) |
| `make analyze` | `flutter analyze --fatal-infos --fatal-warnings` (app + packages) |
| `make arch` | `dart run tool/arch_check.dart` (§3) |
| `make i18n-check` | all locales have identical key sets |
| `make test` | `flutter test --coverage --test-randomize-ordering-seed random` |
| `make coverage` | `dart run tool/coverage_gate.dart` (thresholds from doc 09) |
| `make check` | `format-check` → `analyze` → `arch` → `i18n-check` → `test` → `coverage` |
| `make run-dev` | `flutter run --flavor dev -t lib/main_dev.dart` |
| `make build-android-dev` / `build-ios-dev` | debug-signed flavor builds (CI smoke) |

`make check` is the **definition of green** for every agent and every PR.

## 2. Static analysis baseline (`analysis_options.yaml`, *reference*)

```yaml
include: package:very_good_analysis/analysis_options.yaml
formatter:
  page_width: 100
analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  exclude:
    - "lib/generated/**"
    - "packages/*/lib/generated/**"
    - "test/generated/**"
  errors:
    invalid_annotation_target: ignore       # freezed/json_serializable
    missing_required_param: error
    missing_return: error
    dead_code: error
linter:
  rules:
    always_use_package_imports: true
    prefer_relative_imports: false
    avoid_print: true
    avoid_dynamic_calls: true
    unawaited_futures: true
    use_build_context_synchronously: true
    public_member_api_docs: false
    lines_longer_than_80_chars: false
    cancel_subscriptions: true
    close_sinks: true
    prefer_const_constructors: true
    require_trailing_commas: true
    only_throw_errors: true
```

Adding an `ignore` to the analyzer config or disabling a rule requires an ADR.

## 3. Architecture checker (`tool/arch_check.dart`) — rules to implement

The script parses `import` directives (no resolution needed) and fails with `file:line rule` messages:

| ID | Rule |
|---|---|
| A1 | `features/*/domain/**` must not import `package:flutter/`, `dio`, `drift`, `retrofit`, `get_it`, any `/data/` or `/presentation/`; `package:injectable` is allowed only in `**/domain/usecases/**` |
| A2 | `features/*/presentation/**` must not import any `/data/` path, `package:dio`, `package:drift`, `package:retrofit` |
| A3 | `features/A/**` must not import `features/B/data|presentation/**` (A ≠ B); `features/B/domain/**` allowed only if listed in A's `FEATURE.md` "Depends on" |
| A4 | `core/**` and `shared/**` must not import `features/**` |
| A5 | `packages/**` must not import `package:<app>/` |
| A6 | In `lib/**`, `package:get_it` is allowed only in `core/di/**`, `app/**`, `*_page.dart` (`test/**` is excluded) |
| A7 | No relative `import`/`export` (`part`/`part of` pointing to `lib/generated/**` may use relative paths); no barrel files (files containing only `export`) in `lib/**` outside `core/di` (package entrypoints `packages/*/lib/<pkg>.dart` are allowed) |
| A8 | No `print(`/`debugPrint(` in `lib/` |
| A9 | `DateTime.now()` only in `core/utils/clock*.dart` |
| A10 | No `Navigator.push`/`Navigator.of(...).push` |
| A11 | Any file > 500 lines (non-generated) fails; > 300 warns |
| A12 | `// TODO` without `(TICKET-123)`; `// ignore` without a reason after ` - ` or `: ` |
| A13 | All generated files MUST live inside `generated/` (`lib/generated/**`, `packages/*/lib/generated/**`, `test/generated/**`) and must not be tracked by git (`git ls-files` check); any `*.g.dart`, `*.freezed.dart`, `*.gr.dart`, or `*.config.dart` outside a `generated/` directory fails. `drift_schemas/*.json` are source and MUST be tracked |
| A14 | Each `features/*/` has `FEATURE.md`, `data/`, `domain/`, `presentation/` |
| A15 | Bloc classes are not injected with other Blocs (constructor param types ending `Bloc`/`Cubit` forbidden in `*_bloc.dart`) |
| A16 | `presentation/**` (and any `*_bloc.dart`/`*_cubit.dart`) must not import `/domain/repositories/`, `core/sync/**` (coordinator, outbox, runner), `core/database/**`, or `core/network/**`; from `core/**` only `**/usecases/**`, `core/error/**`, `core/utils/**` (formatters, `CancelHandle`), and `core/router/**` (in pages/routes) are allowed (`shared/**` is allowed). Bloc/Cubit constructor parameter types must end with `UseCase` |
| A17 | Files in `domain/usecases/` must be named `*_use_case.dart`, declare a class `*UseCase` with a `call(` method, and must not import other `*_use_case.dart` files, `/data/`, `package:flutter/` or `get_it` |

The script has its own tests with violating/valid fixtures. New rules require updating this table.

## 4. CI pipeline (platform-agnostic; implement in the chosen CI)

**On every PR (required checks, blocking merge):**
1. Checkout, restore caches (pub, FVM, Gradle, Pods, build_runner).
2. `make bootstrap`
3. `make format-check` · `make analyze` · `make arch` · `make i18n-check`
4. `make test` · `make coverage` (upload coverage + test reports)
5. Android debug build + iOS no-codesign build (smoke) — can run only when native/pubspec files change.
6. Dependency scan: OSV scanner on `pubspec.lock`; fail on known critical/high vulns without an ADR exception.
7. PR checks: Conventional Commit title, PR template filled, size warning > 400 lines, secret scan (gitleaks or equivalent).

**Nightly:** integration tests on emulator/simulator, golden diff report, `dart pub outdated` report, full sync scenario soak (randomized order).

**Release (tag `vX.Y.Z`):**
1. `make check` + integration tests.
2. Build flavor `staging` → distribute to QA (Firebase App Distribution/TestFlight/internal track).
3. Build `prod` with `--obfuscate --split-debug-info=build/symbols`, upload symbols (Crashlytics), Android mapping/R8 (if enabled), iOS dSYMs.
4. Signing keys and secrets only from CI secret store. Version from tag: `version: X.Y.Z+<build>` (build = CI run number).
5. Staged rollout (Android 5–10–50–100%, iOS phased release); auto-halt criteria on crash-free < 99.5%.
6. Changelog from Conventional Commits.

Branch protection: `main` protected, required checks above, ≥ 1 human review (agents' PRs included), linear history, no direct pushes.

## 5. Local hooks (optional, recommended)

`lefthook`: pre-commit → `dart format` on staged files + `flutter analyze` on changed files; pre-push → `make arch` + affected tests. Hooks never replace CI.

## 6. Performance budgets (tracked, not blocking at first)

Cold start to first frame from warm DB: < 2 s on a mid-range Android; frame build/raster p95 < 16 ms on list/detail screens; release APK/AAB size trend tracked per PR (warn on +5%); DB list queries per doc 06 §6. Profile with DevTools before merging heavy-list changes.

## 7. Dependency hygiene

Monthly `dart pub outdated`; upgrades in dedicated `chore(deps)` PRs, one concern each. Generator-package upgrades must be done together and verified with `make gen && make check`. Abandoned packages (no release in 12 months and open critical issues) get an ADR with a replacement plan.
