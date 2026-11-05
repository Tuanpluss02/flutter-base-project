---
name: add-dependency
description: Propose and add a new package dependency via an Architecture Decision Record (ADR).
---

# Skill: Add Dependency

Read first: `AGENTS.md` Rule 7, `docs/10-quality-gates-ci.md` §7, `docs/14-decisions.md`.

## Steps

1. **Check Locked Stack First (`docs/01-architecture.md` §2):**
   - If the package is already in the locked stack, no new ADR is needed.
   - If the task can be solved cleanly with Dart/Flutter stdlib or an existing package (e.g. `Result` in `core/error`), do NOT add a dependency.
2. **Draft an ADR in `docs/14-decisions.md`:**
   - Copy `docs/templates/ADR.md` and append the next sequential `ADR-XXXX` entry to `docs/14-decisions.md` with status `Proposed`.
   - Document: Context, Alternatives considered, License/maintenance check (released within 12 months, null-safe, platform support for Android/iOS, native binary size impact), and Consequences.
3. **Stop for Human Approval (`AGENTS.md` §4 & `docs/14`):**
   - Only a human reviewer can transition an ADR from `Proposed` to `Accepted`. Report `BLOCKED` referencing the proposed ADR unless the user explicitly instructed adding the dependency in the prompt.
4. **Once Accepted:**
   - Add the package alphabetically to `pubspec.yaml` (merge hotspot — minimal diff).
   - Run `make bootstrap && make check` and verify OSV vulnerability scan passes.
