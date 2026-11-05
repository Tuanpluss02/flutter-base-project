# AGENTS.md — Flutter Luxury Real Estate App

> Binding for every AI agent and every human contributor. Read it fully before touching anything.
> If this file conflicts with another document, **this file wins**. Detailed rules live in `docs/`.
> If your tool expects another filename (`GEMINI.md`, `CLAUDE.md`, ...), create a one-line file pointing here or symlink it.

## 1. Project in one paragraph

A long-lived, large-team, **offline-first** Flutter app for luxury real estate. Backend: Directus (REST + realtime).
Stack (locked, see `docs/01-architecture.md`): Bloc, injectable + get_it, Dio + Retrofit, freezed + json_serializable,
auto_route, slang (i18n), envied, Drift (SQLite) as the local DB, centrifuge (realtime), Firebase (messaging, crashlytics).
Architecture: **feature-first, three layers per feature** (presentation / domain / data). Local DB is the single source of truth for the UI.

## 2. Hard rules (non-negotiable)

1. **Do exactly what the task asks. Nothing more.** No drive-by refactors, renames, reformatting, dependency bumps, or "improvements" outside the task scope.
2. **Dependency direction:** `presentation → domain ← data`. `domain` is pure Dart (no `flutter`, `dio`, `drift`, `retrofit`, `get_it`; `injectable` annotations allowed in `domain/usecases/` only). **Blocs depend on use cases only**: never on repositories, DAOs, API classes or `SyncCoordinator` (rule 12).
3. **No cross-feature imports** of another feature's `data/` or `presentation/`. Only another feature's `domain/` (entities, repository interfaces) may be imported, and only when the task says so.
4. **UI reads only from the local DB** via use cases that wrap repository streams. UI/Bloc never calls repositories, Retrofit or Dio directly. (Exceptions: `OnlineOnly` / `RemoteQuery` operations declared in `FEATURE.md`. Deciding local vs remote: `docs/15-data-source-decision.md`; no decision record = BLOCKED.)
5. **Repositories return `Result<T>` or `Stream`s.** Never let exceptions cross a layer boundary. No empty `catch`. No `catch (e)` that swallows.
6. **Never hand-edit generated files — all generated output MUST live under a `generated/` folder** (`lib/generated/**`, `packages/*/lib/generated/**`, `test/generated/**`, including `*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `*.config.dart`, slang output, and drift migration/verifier output). They are git-ignored; run `make gen`. No generated file may sit next to hand-written source files. `drift_schemas/*.json` snapshots are source: commit them, never edit a released one.
7. **No new dependency** without an approved ADR (use skill `add-dependency`). Do not change versions in `pubspec.yaml` unless the task says so.
8. **No `print` / `debugPrint`.** Use `AppLogger`. Never log tokens, emails, phone numbers, ID numbers.
9. **No hard-coded user-visible strings** (use slang), **colors, text styles, spacing, radii** (use `design_system` tokens).
10. **No `dynamic`, no unjustified `!`, no `as` casts across layers, no `late` (except DI/test setup).** Use sealed classes + pattern matching.
11. **No business logic in widgets.** No `BuildContext` use after `await` without a `mounted` check.
12. **Bloc rules:** sealed events, immutable freezed state, correct transformer (see `docs/04`), no Bloc→Bloc dependency, **constructor takes use cases only** (every data/sync/session operation goes through a use case, even a one-line pass-through), page Blocs are `@injectable` factories.
13. **Schema change = migration + migration test + version bump** (skill `db-migration`). Never edit a released migration.
14. **Time and ids:** persist all timestamps in UTC. Entities created offline use client-generated UUID v4 as primary key.
15. **Secrets:** never commit secrets or `.env` files. Tokens live only in `flutter_secure_storage`.
16. **Tests are part of the change** (see matrix in `docs/09`). Never lower coverage thresholds, delete or skip tests to go green.
17. **No `// ignore:` or `// ignore_for_file:`** without a one-line reason on the same line.
18. **No `TODO` without a ticket:** `TODO(PROJ-123): ...`. No commented-out code.
19. **Changes to `lib/core/**` public APIs require an ADR** (`docs/14-decisions.md`). Additive, backwards-compatible internals are fine.
20. **Size limits:** target ≤ 300 lines per file (hard max 500), ≤ 60 lines per function, ≤ 400 changed lines per PR.

## 3. Task protocol (follow in order)

1. **Scope:** write down (in your head or plan) the exact files you will create/modify. Everything else is read-only. If the task has an `Owns:` list, you may touch **only** those paths plus the merge-hotspot files in §6.
2. **Read** the docs for your task type (table in §5). Use the matching skill in `.agents/skills/` if one exists.
3. **Plan** in ≤ 10 lines. If the plan needs something in §4, stop.
4. **Implement the smallest change** that satisfies the acceptance criteria. Follow the reference feature (`features/listing`, `features/favorite`) when one exists.
5. **Verify:** run `make gen` (if you changed annotated code) then `make check`. It must be green. Fix your own failures; do not weaken checks.
6. **Self-review** with the checklist in `docs/12-definition-of-done.md`.
7. **Report** using the format in §7.

## 4. Stop-and-report triggers (do NOT guess)

Stop, do not write more code, and output a `BLOCKED` report (§7) when:

- the task needs a **new dependency**, a **new top-level folder**, or a change to **`lib/core/**` public API**;
- the **backend contract differs** from `docs/05` (e.g. no `date_updated`, no soft delete, different pagination/filter syntax);
- two documents **contradict** each other, or the task contradicts this file;
- the task needs product behavior that is **not specified** (copy, flows, permissions, business rules);
- you would have to touch **files outside your `Owns:` list** or more than ~15 files;
- a check fails for a reason **outside your change** (broken main, flaky test, tooling).

Do **not** stop for: naming, file placement, choosing between patterns already defined in `docs/`, or small implementation details. Use the documented default and mention it in the report under "Assumptions".

## 5. Which doc to read

| Task type | Read | Skill |
|---|---|---|
| New feature | 01, 03, 04, 12 | `create-feature` |
| Use case (every Bloc operation) | 01 §3, 04 | `add-use-case` |
| Bloc / page logic | 04, 03 | `add-bloc` |
| New endpoint / DTO | 05, 07 | `add-api-endpoint` |
| Deciding local vs remote | 15, 02 | `create-feature` |
| Read-only cached data (mirror) | 02, 05, 06 | `add-synced-entity` |
| Offline write (favorite, draft, form) | 02, 05, 06 | `add-offline-write` |
| DB table / column change | 06 | `db-migration` |
| Auth, tokens, encryption, logging | 05, 07, 11 | — |
| Router, DI, i18n, theme | 08 | — |
| Tests | 09 | — |
| CI, lint, release | 10 | — |
| Add a package | 14 | `add-dependency` |
| Before opening a PR | 12 | `pre-pr-check` |
| Building the base itself | 13 (in order) | — |

## 6. Parallel work (multiple agents run concurrently)

- One task = one branch = one agent. Branch: `feat/PROJ-123-short-name`. Commits: Conventional Commits.
- Touch only your `Owns:` paths. **Merge-hotspot files** (edit minimally, keep entries alphabetically sorted, never reformat the rest):
  `pubspec.yaml`, `lib/core/database/app_database.dart` (table/DAO lists), `lib/core/sync/sync_registry.dart`,
  `lib/core/router/app_router.dart` (feature route list), `lib/i18n/*.i18n.json`, `docs/14-decisions.md`.
- Rebase on `main` before reporting done. Resolve conflicts by keeping both sides' entries, never by discarding the other agent's lines.
- Never run repo-wide formatters/fixers (`dart fix --apply`, `dart format .`) on files you do not own.

## 7. Report format (always end with this)

```
STATUS: DONE | BLOCKED
TASK: <id / title>
CHANGES: <bullet list of files created/modified, grouped by layer>
CHECKS: make check → PASS/FAIL (+ coverage numbers if tests were added)
ASSUMPTIONS: <defaults you chose from docs, or "none">
FOLLOW-UPS: <ticketable items you noticed but did NOT do, or "none">
BLOCKED-ON: <only if BLOCKED: what is missing, 2-3 options, your recommendation>
```

## 8. Commands (defined in `Makefile`, see `docs/10`)

`make bootstrap` · `make gen` · `make watch` · `make format` · `make analyze` · `make arch` · `make test` · `make coverage` · `make check` (= format-check + analyze + arch + test + coverage gate) · `make run-dev`
