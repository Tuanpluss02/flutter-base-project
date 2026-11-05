---
name: add-use-case
description: Create a single-operation domain use case for Bloc/Cubit data, sync, or session access (ADR-0011).
---

# Skill: Add Use Case

Read first: `docs/01-architecture.md` §3.1, `docs/04-state-management-bloc.md` §6, `docs/09-testing-strategy.md` §3.

## Rules (enforced by `arch_check.dart` A1, A16, A17)

1. **Location & Naming:**
   - File: `lib/features/<feature>/domain/usecases/<verb>_<noun>_use_case.dart` (or `lib/core/<module>/usecases/` for cross-cutting use cases).
   - Class: `<Verb><Noun>UseCase` annotated with `@injectable`.
   - Single public method: `call(...)`.
2. **Return Types:**
   - Reactive reads: `Watch<Noun>UseCase` returns `Stream<T>`.
   - Commands / mutations / refreshes / remote queries: `Future<Result<T>> call(...)`.
3. **Dependencies:**
   - May depend ONLY on: own feature's repository interfaces, another feature's `domain` repository interface (only if listed in `FEATURE.md` "Depends on"), `Clock`, UUID generator, pure domain value objects/services.
   - MUST NOT import other `*_use_case.dart` files, `/data/`, `package:flutter/`, or `package:get_it`.
4. **Responsibility:**
   - Put all business rules (validation, deduplication, freshness checks, derivations) inside the use case. Pass-through use cases are expected when no extra business rule applies.
5. **Testing:**
   - Add `test/features/<feature>/domain/usecases/<verb>_<noun>_use_case_test.dart` using a hand-written fake repository. Test delegation, every business rule branch, and `Err` propagation.
6. **Update `FEATURE.md`** "Use cases" table.
