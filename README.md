# Flutter Base

Reusable Flutter base for Android and iOS. It includes clean architecture, fail-closed configuration, offline sync primitives, and Login/Home/Settings demo features that show how to extend the app.

Starting a new product with an AI coding agent? Follow [Agent Setup Guide](AGENT_SETUP.md).

---

## 1. Quick Start

### Prerequisites
- [FVM](https://fvm.app/) (Flutter Version Management) >= 3.2.0
- JDK 17 (OpenJDK 17 recommended)
- macOS with Xcode 27+ & CocoaPods 1.16+ (for iOS development)

### Toolchain Setup
```bash
# Pin Flutter version via FVM
fvm install 3.47.8
fvm use 3.47.8

# Fetch dependencies and enforce lockfile integrity
fvm flutter pub get --enforce-lockfile
```

---

## 2. Running the Application

Configurations are maintained via `.env` files located in `config/`:
- `config/env_dev.env`: Development environment (logging enabled)
- `config/env_uat.env`: UAT environment
- `config/env_prod.env`: Production environment (`ENABLE_LOGGING=false` enforced)

Run the app with a native flavor and its matching config file:
```bash
# Run in development mode
fvm flutter run --flavor dev --dart-define-from-file=config/env_dev.env

# Run in UAT mode
fvm flutter run --flavor uat --dart-define-from-file=config/env_uat.env

# Run in production mode
fvm flutter run --release --flavor prod --dart-define-from-file=config/env_prod.env
```

---

## 3. Code Generation

Code generation produces serialization (`freezed`, `json_serializable`), routing (`auto_route`), dependency injection (`injectable`), and localization (`slang`):

```bash
fvm dart run build_runner build -d
```

---

## 4. Verification & CI Gate

Run the local continuous integration verification gate:

```bash
bash scripts/ci_local.sh
```

The CI script verifies:
1. Flutter toolchain pinning (`3.47.8`).
2. Lockfile immutability (`--enforce-lockfile`).
3. Clean code generation workspace (zero uncommitted diffs).
4. Code formatting standards (`dart format`).
5. Static analysis (`flutter analyze --fatal-infos --fatal-warnings`).
6. Slang translation analysis (`slang analyze --full --exit-if-changed`).
7. Flutter unit and widget test suite (239+ tests passing).
8. Configuration format and allowlist validation (`check_config.sh`).
9. Clean architectural boundaries enforcement (`check_boundaries.sh`).
10. Gitleaks secret leak scanner (`check_secrets.sh`).

---

## 5. Architectural Boundaries

- **`lib/src/core/`**: Foundational domain primitives, configuration, networking (`Dio`, `Retrofit`), storage (`SecureStorage`, encrypted DB), auth session coordination, and offline outbox/sync engine.
- **`lib/src/app/`**: Composition root, dependency injection (`injection.dart`, modules), routing (`app_router.dart`), and global error handling.
- **`lib/src/features/`**: Independent, self-contained business features (e.g. `auth_placeholder`, `home`, `settings`). Features must **never** import other features directly; cross-feature communication occurs via core abstractions or deep links.

---

## 6. Documentation & References

- [Toolchain Specifications](docs/toolchain.md)
- [Release Verification Runbook](docs/runbooks/release-verification.md)
- [IDE Launch Configurations](docs/ide-run-configs.md)
- [Core Base Design Specifications](docs/superpowers/specs/2026-10-30-flutter-core-base-design.md)
- [Implementation Plan](docs/superpowers/plans/2026-10-31-flutter-core-base-implementation.md)
