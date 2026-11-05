---
name: pre-pr-check
description: Verify all quality gates, architecture rules, Definition of Done items, and report format before completing a task or opening a PR.
---

# Skill: Pre-PR Check

Read first: `AGENTS.md` §3, §6, §7, `docs/03-code-conventions.md` §8, `docs/10-quality-gates-ci.md`, `docs/12-definition-of-done.md`.

## Checklist

1. **Scope & Merge Hotspots (`AGENTS.md` §3, §6):**
   - Run `git status` and `git diff --stat`. Verify only files in `Owns:` (plus alphabetically sorted entries in merge-hotspot files) were modified.
   - Check PR diff size target (≤ 400 non-generated lines) and file size limits (≤ 300 target, ≤ 500 max).
2. **Code Generation & Quality Gate (`docs/10` §1, `A13`):**
   - Run `make gen` (if any annotated files or schema snapshots changed).
   - Verify all generated files live exclusively inside `generated/` (`lib/generated/**`, `packages/*/lib/generated/**`, `test/generated/**`) and none are tracked by git.
   - Run `make check` (`format-check` + `analyze` + `arch` + `i18n-check` + `test` + `coverage`). Every step MUST pass.
3. **Definition of Done (`docs/12-definition-of-done.md`):**
   - All 4 UI states + offline/stale/pending indicators implemented where applicable.
   - `FEATURE.md` updated in the same change.
   - All required unit/widget/golden/sync-scenario tests added per `docs/09` §3.
4. **Output Final Report (`AGENTS.md` §7):**
   - End response with the exact `STATUS / TASK / CHANGES / CHECKS / ASSUMPTIONS / FOLLOW-UPS / BLOCKED-ON` block.
