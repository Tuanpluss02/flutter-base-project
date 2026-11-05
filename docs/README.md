# Docs Index

Reading order for anyone (human or agent) joining the project. `AGENTS.md` at the repo root is the entry point and always wins on conflict.

| # | Doc | Purpose |
|---|---|---|
| 01 | architecture.md | Layers, folder layout, boundaries, bootstrap sequence |
| 02 | offline-first-and-sync.md | The core of the app: read flow, delta sync, outbox, conflicts, UI update policy |
| 03 | code-conventions.md | Naming, style, forbidden/required patterns, git rules |
| 04 | state-management-bloc.md | Bloc/Cubit rules, templates, concurrency, testing |
| 05 | networking-and-directus.md | Dio, interceptors, Retrofit, Directus contract, auth, realtime |
| 06 | database-drift.md | Drift conventions, migrations, encryption, performance |
| 07 | error-handling-logging.md | Result/Failure model, global handlers, logging, redaction |
| 08 | routing-di-i18n-theming.md | auto_route, injectable, slang, design system, a11y |
| 09 | testing-strategy.md | Test pyramid, required tests per change, coverage gates |
| 10 | quality-gates-ci.md | Lints, architecture checks, `make` targets, CI, release |
| 11 | security.md | Storage, encryption, hardening checklist |
| 12 | definition-of-done.md | DoD checklist + offline manual QA matrix |
| 13 | base-build-plan.md | Ordered tickets to build the base itself (with acceptance criteria) |
| 14 | decisions.md | ADRs (decisions already made + how to add one) |
| 15 | data-source-decision.md | Decision tree: local vs remote, per entity/operation, with freshness guard |
| — | templates/ | `FEATURE.md`, `ADR.md`, `PR.md` templates |

Agent skills live in `.agents/skills/<name>/SKILL.md`. If a tool expects another location (`.opencode/skills`, `.claude/skills`, ...), symlink the folder; never duplicate content.

## Status markers used in these docs

- **MUST / MUST NOT**: enforced by review or CI.
- **SHOULD**: default; deviate only with a one-line justification in the PR.
- **ASSUMPTION**: not yet verified against the real system; the first agent touching it MUST verify and, if wrong, stop and report (see `AGENTS.md` §4).
- Code blocks marked *reference* show intent and constraints, not final signatures.
