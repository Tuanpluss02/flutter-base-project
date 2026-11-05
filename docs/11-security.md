# 11 — Security

Baseline: OWASP MASVS (L1 mandatory, L2 for auth/payment/eKYC areas). The app handles PII (contact data, KYC), financial flows (VNPay/VietQR), and high-value-client behavior; treat it as sensitive.

## 1. Checklist (each item has an owner ticket in doc 13, T-060)

**Storage**
- [ ] Tokens only in `flutter_secure_storage` (iOS Keychain `first_unlock_this_device`, Android Keystore-backed); never in `SharedPreferences`, DB, logs, or crash reports.
- [ ] Local DB encrypted (SQLCipher, ADR-0003); key in secure storage.
- [ ] Android: `allowBackup=false` and data-extraction rules excluding DB, prefs, secure storage; iOS: DB file flagged `isExcludedFromBackup`.
- [ ] PII minimization: store only fields the UI needs offline; sensitive KYC data is **never** cached locally beyond the flow that needs it, and is wiped on completion/logout.
- [ ] Clipboard: never auto-copy sensitive data; clear after timeout when the user copies it.

**Network**
- [ ] HTTPS only; cleartext disabled (Android network security config, iOS ATS).
- [ ] Certificate pinning for prod API/realtime hosts with backup pin + rotation runbook (ADR-0009).
- [ ] No secrets in the app binary that grant privileged access. Anything in `envied` is public-by-obfuscation, not secret; privileged operations require user tokens and server-side authorization.
- [ ] Token refresh single-flight; refresh-token rotation handled; session invalidation on logout/password change.

**App hardening**
- [ ] Release builds: `--obfuscate --split-debug-info`; R8/ProGuard on Android (rules for reflection-using packages).
- [ ] Root/jailbreak and debugger detection: **policy decided in ADR** (default: detect and warn; block only in payment/eKYC flows).
- [ ] Screenshot/screen-recording protection (`FLAG_SECURE` / iOS secure field overlay) on eKYC, payment, ID-document screens and when the app is backgrounded (app-switcher blur).
- [ ] Biometric/app-lock optional for returning users; auto-lock timeout configurable.
- [ ] Deep links and push payloads are untrusted input: validate scheme/host/params; never execute actions without user confirmation.
- [ ] WebViews (if any): allowlist of origins, no JS bridge exposing sensitive APIs, disable file access.
- [ ] Permissions requested just in time, least privilege, with rationale text.

**Code & process**
- [ ] No secrets in git; `.env`, keystores, `google-services.json` handling documented; secret scanning in CI.
- [ ] Logs redacted (doc 07); no PII in analytics or Crashlytics.
- [ ] Dependency vulnerability scan in CI (doc 10).
- [ ] Input validation on all user input (client-side for UX, server is authoritative); sanitize anything rendered as rich text/HTML.
- [ ] Debug/dev tools (interceptly, sync debug screen) compiled out of prod (`flavor == prod` guard + test asserting absence).
- [ ] Threat model document for payment/eKYC/auth reviewed before first release; pen-test before launch.

## 2. Data classification

| Class | Examples | Rules |
|---|---|---|
| Public | listings, projects, amenities | cacheable, unencrypted logs OK |
| Internal | agent assignments, favorites, saved searches | encrypted DB, no logs of content |
| Sensitive | contact details, inquiries, KYC, payment refs | encrypted DB only if required offline; redact everywhere; wipe on logout |
| Secret | tokens, DB key | secure storage only |

## 3. Incident readiness

Remote kill-switch/force-update via config (guard: `ForceUpdateGuard`); ability to revoke sessions server-side; documented procedure to rotate pinned certs and API keys; crash-free and auth-failure dashboards.
