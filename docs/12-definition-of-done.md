# 12 — Definition of Done

A task is done only when **every** item is true. Agents copy this list into their final report as "verified".

## 1. Code and architecture
- [ ] Only in-scope files changed; no unrelated formatting or refactors.
- [ ] Dependency direction and cross-feature rules respected (`make arch` green).
- [ ] No forbidden-list items (doc 03 §6).
- [ ] Repositories return `Result`/`Stream`; failures are typed and preserved.
- [ ] No new dependency (or ADR approved).
- [ ] Blocs/Cubits depend on use cases only; business rules are in use cases, not Blocs or repository impls.

## 2. Behavior and UX
- [ ] Every screen implements loading (no data), empty, data, error-with-data, stale/offline, and pending/failed-sync states as applicable.
- [ ] UI never blocks on network when local data exists; no full-screen spinner over data.
- [ ] Live updates follow the UI update policy (doc 02 §7); forms never overwritten.
- [ ] Strings via slang for **all** locales; formatting via shared formatters.
- [ ] Accessibility: semantics, tap targets, 1.5× text scale checked.
- [ ] Light and dark themes checked.
- [ ] Failures presented per doc 07 §9 (one surface per cause, no toast for background errors, every error state has an action, user input preserved).

## 3. Data and sync (when applicable)
- [ ] `FEATURE.md` updated (policy, scope, TTL, conflict policy, endpoints, routes, tests).
- [ ] Migration + migration test for schema changes; schema snapshot committed.
- [ ] Sync spec/outbox behavior covered by scenario tests (doc 09 §7).
- [ ] Offline manual QA matrix (§5) executed for affected flows.

## 4. Quality evidence
- [ ] Tests added per matrix (doc 09 §3); coverage gates pass; no skipped/flaky tests.
- [ ] `make check` green locally (paste summary).
- [ ] PR description complete (what/why, screenshots or screen recording for UI, offline behavior, risks, assumptions).
- [ ] No TODO without ticket; no commented-out code; no leftover debug code.
- [ ] Logs contain no PII; new log events follow naming rules.

## 5. Offline manual QA matrix (device or emulator)

| # | Scenario | Expected |
|---|---|---|
| 1 | Fresh install, no network | Empty/offline state, no endless spinner, no crash |
| 2 | Warm cache, airplane mode, cold start | Home renders from cache < 2 s |
| 3 | Open list while online, go offline, scroll/filter | Works locally; offline banner shown |
| 4 | Pull-to-refresh offline | Non-blocking message; data kept |
| 5 | Poor network (throttled, packet loss) | No UI jumps; refresh completes or fails gracefully |
| 6 | Server data changes while viewing list (scrolled) | "N new items" pill; no jump |
| 7 | Server data changes on detail screen | Fields update in place; important change highlighted |
| 8 | Favorite/edit offline → kill app → relaunch online | Change persisted and synced; badge clears |
| 9 | Conflict (edit same entity on another device) | Behaves per declared `ConflictPolicy`; no silent data loss |
| 10 | Token expires during use | Transparent refresh; if refresh fails → login, data/ops kept |
| 11 | Logout with pending ops | Warning; on confirm, user data wiped, public cache kept |
| 12 | Upgrade from previous app version | DB migrates; no data loss in outbox |
| 13 | Device clock set wrong (±1 day) | Sync still correct (cursor from server values) |
| 14 | Backend 5xx/timeouts | Retry/backoff; stale indicator; no crash |
| 15 | Low storage / DB open failure | Graceful recovery path (reset cache, resync) with log |
