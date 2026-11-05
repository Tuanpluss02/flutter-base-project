---
name: create-feature
description: Scaffold a new feature following the 3-layer offline-first architecture, data source decision tree, and FEATURE.md contract.
---

# Skill: Create Feature

Read first: `docs/01-architecture.md` through `docs/09-testing-strategy.md`, `docs/12-definition-of-done.md`, `docs/15-data-source-decision.md`.

## Steps

1. **Decide Data Policy (`docs/15-data-source-decision.md`):**
   - Answer the 6 questions in `docs/15` §1 for each entity/operation:
     - `OnlineOnly` (irreversible/money/identity/instant-exact actions)
     - `RemoteQuery` (server-computed quotes/calculators)
     - `OutboxWrite` (offline-safe user writes with a declared `ConflictPolicy`)
     - `CacheOnly / mirror` (read collection ≤ 5,000 rows and ≤ ~5 MB; local SQL filter/sort/search)
     - `CacheOnly / queryScoped` (larger collections or server-side filtering; cached per `queryKey` in `query_results`)
   - For irreversible actions that depend on mutable facts (price, availability, status), include a reusable `FreshnessGuard` use case (`docs/15` §4).
   - If none apply or product rules are missing → stop and output `BLOCKED`.
2. **Create `lib/features/<feature>/FEATURE.md`:**
   - Copy `docs/templates/FEATURE.md` and fill in every section (Data policy, Data decision record, Directus collections/fields, Entities/tables, Depends on, Routes, Use cases, Blocs, Offline behavior per screen, Tests).
3. **Scaffold the 3-Layer Directory Structure (`A14`):**
   - Once T-070 is complete, run `make feature name=<feature> policy=cache|outbox|online scope=mirror|query` (pure `dart:io` generator in `tool/new_feature/`, no `mason`).
   - Directories:
     - `lib/features/<feature>/domain/{entities,repositories,usecases}`
     - `lib/features/<feature>/data/{local/tables,local/daos,remote,models,mappers,sync,repositories}`
     - `lib/features/<feature>/presentation/{bloc,pages,widgets}`
4. **Implement Respecting `presentation → domain ← data`:**
   - Separate `Entity` (domain), `Dto` (data/models), and `Row` (Drift `@DataClassName`).
   - Expose every Bloc operation via a `@injectable` `*UseCase` class in `domain/usecases/` (skill `add-use-case`).
   - Register routes in `lib/features/<feature>/presentation/<feature>_routes.dart` and add alphabetically to `AppRouter`.
   - Add i18n keys to all locales in `lib/i18n/*.i18n.json`.
5. **Write Mirrored Tests under `test/features/<feature>/` (`docs/09-testing-strategy.md` §3).**
6. **Run `make gen && make check`.**
