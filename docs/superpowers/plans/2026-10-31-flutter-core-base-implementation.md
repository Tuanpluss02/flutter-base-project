# Flutter Core Base + Offline-first Implementation Plan

> **For agentic workers:** REQUIRED EXECUTION: Orca orchestration (xem `Execution model`). Mỗi Task dưới đây là một worker spec tự chứa. Worker đọc Task của mình + các spec được liệt kê, không đọc Task khác để suy diễn interface. Steps dùng checkbox (`- [ ]`) để track.

**Goal:** Triển khai Flutter Core Base v1 (config, DI, network/auth, router, storage, logging, i18n, theme, shared UI, 3 feature mẫu) và module Offline-first Phase 2 (encrypted local DB, outbox, sync/conflict) mặc định tắt, đạt toàn bộ gate trong bộ spec rev6.

**Architecture:** Feature-first với `lib/src/core/` là hợp đồng kỹ thuật, `lib/src/app/` là composition root duy nhất được import feature, `lib/src/features/<name>/` tự chứa data/domain/presentation. Offline-first là module opt-in trong `lib/src/core/offline/`, chỉ bật qua `OFFLINE_ENABLED=true` sau khi ADR + security gates được duyệt.

**Tech Stack:** Flutter stable `3.47.8` / Dart `3.13.7` (FVM), flutter_bloc 9.1.1, get_it 9.3.0 + injectable 3.0.0, dio 5.11.1 + retrofit 4.10.0, auto_route 11.2.0, freezed 4.0.1, slang 4.19.2, flutter_secure_storage 11.2.0, shared_preferences 2.5.6; Phase 2: drift + SQLCipher (chốt sau spike T8).

**Spec:** Toàn bộ bộ spec rev6:
- `docs/superpowers/specs/2026-10-30-flutter-core-base-design.md`
- `docs/superpowers/specs/2026-10-30-flutter-core-base/01-scope-toolchain-architecture.md`
- `docs/superpowers/specs/2026-10-30-flutter-core-base/02-app-runtime.md`
- `docs/superpowers/specs/2026-10-30-flutter-core-base/03-network-and-errors.md`
- `docs/superpowers/specs/2026-10-30-flutter-core-base/04-storage-and-shared-ui.md`
- `docs/superpowers/specs/2026-10-30-flutter-core-base/05-verification-and-release.md`
- `docs/superpowers/specs/2026-10-30-flutter-core-base/offline-first.md`
- `docs/superpowers/specs/2026-10-30-flutter-core-base/api-contract.md`
- `docs/superpowers/specs/2026-10-30-flutter-core-base/security-privacy.md`
- `docs/superpowers/specs/2026-10-30-flutter-core-base/feature-workflow.md`
- `docs/superpowers/specs/2026-10-30-flutter-core-base/accessibility-ui.md`
- `docs/superpowers/specs/2026-10-30-flutter-core-base/release-operations.md`

## Global Constraints

- App root là `pristie/`; mọi path `lib/...`, `test/...`, `config/...` dưới đây tính từ `pristie/` trừ khi ghi rõ.
- Flutter `3.47.8`, Dart `3.13.7`; pin bằng `pristie/.fvmrc`; không chạy `flutter upgrade`.
- `pubspec.lock` commit; CI chạy `flutter pub get --enforce-lockfile`.
- Version dependencies lấy đúng bảng §2.2/§2.3 của spec 01. Không tự nâng/hạ version khi solver fail; dừng và báo lead.
- `lib/src/core/` không import `lib/src/features/`; feature không import feature khác; shared domain chỉ khi thật sự dùng chung.
- Không static global mutable, không EventBus, không `setState` cho async, không ScreenUtil, không hard-code font family.
- UI không gọi Dio/SharedPreferences/plugin trực tiếp; Cubit nhận dependency qua constructor; Cubit gọi UseCase, không gọi repository trực tiếp.
- Chỉ HTTPS ở mọi môi trường; TLS verification luôn bật; không bad-certificate callback/trust-all/tắt hostname check.
- Không secret/token/signing key trong `config/env_*.env`, source, test fixture, log hay crash context.
- Mọi user-facing string qua Slang (`context.t.*`); domain/network không chứa câu chữ UI.
- `AppFailure`/`Result`/`BaseState`/`PagedState` là closed Freezed union; dùng `switch` pattern matching, không `.when()`/`.map()`.
- Chỉ docstring trong code; không viết comment `//`/`/* */` (quy tắc workspace).
- Không chạy `git push`, không merge vào `main`; chỉ commit trên branch làm việc (xem Execution model).
- Offline-first: không persist S2/S3 trước khi T8 ADR + security gates pass; `OFFLINE_ENABLED` mặc định `false`.

## Review Focus

Năm nhóm dễ vỡ nhất, mỗi nhóm phải có test ở Task sở hữu:

1. **Refresh/invalidation storage failure** — refresh 200 nhưng `writeSession` fail, hoặc `beginLogout`/`beginInvalidation` fail: phải khóa auth, trả `AppFailure.localPersistence()`, không dùng token chưa persist, không báo logout thành công. Test ở T2, T5.
2. **Cross-origin credential leak** — absolute URL/redirect sang origin khác không được mang `Authorization`/cookie. Test ở T5.
3. **Cancellation sau close** — `CancelledFailure` không thành UI error, không emit sau `close()`, không gửi crash report. Test ở T1, T5, T7.
4. **Config fail-fast** — thiếu key/key lạ/`APP_ENV` sai/HTTP/prod bật logging/timeout sai phải fail có tên key, không dựa vào `assert`, không in giá trị nhạy cảm. Test ở T1, T4.
5. **Paging/offline data integrity** — loadMore lỗi giữ items + dedupe; offline resync/conflict không mất outbox, account B không đọc dữ liệu account A. Test ở T1, T9.

---

## Execution model (Git + Orca)

**Git**
- Repo root: workspace hiện tại (`/Users/tuanpluss02/Documents/Boltx/BDS/pristie`), chứa `docs/` và `pristie/`.
- Nhánh: `main` (baseline) → `integration/flutter-core-base` (lead tích hợp) → các nhánh `task/t<N>-<slug>` (worker).
- Worker commit trên nhánh của mình. Lead tích hợp bằng cách apply diff/merge trên `integration/flutter-core-base` rồi commit checkpoint; **không** push, **không** merge vào `main`. User review và merge cuối.
- Mọi command git chạy từ repo root; Flutter command chạy trong `pristie/` (hoặc dùng `fvm flutter` với workdir `pristie/`).

**Orca wave map**

| Wave | Worker | Agent gợi ý | Task | Chạy song song |
|---|---|---|---|---|
| 0 | W0 | codex | T0 | Không (serial gate) |
| 1 | W1, W2, W3, W4 | codex, agy, opencode2, codex | T1, T2, T3, T4 | Có |
| 2 | W5, W6, W7 | codex, agy, opencode2 | T5, T6, T8a | Có |
| 3 | W8, W9 | codex, agy | T7, T8b | Có |
| 4 | W10 | codex | T9 | Không |
| 5 | W11 + reviewer | codex + opencode2 | T10 | Reviewer chạy sau khi W11 xong |

**Orca commands (lead)**
```bash
orca status --json
orca orchestration run-create --objective "Flutter Core Base + Offline-first implementation" --json
orca worktree create --repo <repo-id> --name t1-core-contracts --branch task/t1-core-contracts --base-branch integration/flutter-core-base --agent codex --json
orca orchestration worker-start --spec "<nội dung Task T1 + Global Constraints + spec paths>" --worktree <worktree-path> --agent codex --json
orca orchestration check --wait --types "worker_done,escalation,question" --timeout-ms 900000 --json
```
- Mỗi `worker-start` spec phải copy nguyên văn Task tương ứng + `Global Constraints` + danh sách spec file.
- Worker phải chạy đúng acceptance của Task, commit trên nhánh, gửi `worker_done` kèm `--files-modified` và `--report-path`.
- Lead review diff + chạy gate trong worktree integration trước khi mở wave kế tiếp.
- Nếu worker fail: không relaunch mù; đọc receipt/`worker-show`, sửa spec hoặc tách task nhỏ hơn.

---

## File structure (đích cuối)

```text
pristie/
  .fvmrc
  pubspec.yaml / pubspec.lock
  build.yaml
  analysis_options.yaml
  Makefile
  config/env_{dev,stg,prod}.env
  scripts/{ci_local,check_config,check_boundaries,check_secrets}.sh
  lib/
    main.dart
    src/
      app/
        bootstrap.dart
        app.dart
        app_router.dart
        app_router.gr.dart
        injection.dart
        injection.config.dart
        guards/auth_guard.dart
        modules/{network,storage,router}_module.dart
        observability/{app_bloc_observer,error_handlers}.dart
        pages/not_found_page.dart
      core/
        config/app_config.dart
        error/app_failure.dart
        result/result.dart
        presentation/{base_state,base_cubit,paged_state,paged_cubit}.dart
        storage/{secure_storage,local_storage,session,session_token_provider,secure_session_store,adapters}.dart
        auth/{auth_state,auth_coordinator,session_state_sink,session_service}.dart
        network/{dio_factory,app_failure_mapper,token_refresher,api_client}.dart
        network/interceptors/{auth,logging,error_mapping,retry}_interceptor.dart
        observability/{app_logger,redactor,crash_reporter}.dart
        scope/{data_scope,data_classification}.dart
        offline/            # Phase 2, OFFLINE_ENABLED=false mặc định
          db/{offline_database,database_key_manager,migrations}.dart
          outbox/{outbox_operation,outbox_worker}.dart
          sync/{sync_dataset,sync_send_outcome,sync_conflict,sync_coordinator}.dart
          policy/{offline_policy,offline_config}.dart
      shared/
        theme/{app_theme,app_colors,app_text_styles}.dart
        widgets/{app_button,app_error_view,app_loading_view,app_empty_view}.dart
      l10n/{strings.i18n.json,strings_vi.i18n.json,strings.g.dart}
      features/
        _template/README.md
        auth_placeholder/{data,domain,presentation}
        home/{data,domain,presentation}
        settings/{data,domain,presentation}
  test/src/{core,app,features}/...
.github/workflows/ci.yml
docs/adr/0001-offline-database.md
```

---

### Task 0: Repo, toolchain pin, dependency solver gate, baseline scaffold

**Files:**
- Create: `.gitignore` (root), `pristie/.fvmrc`, `pristie/build.yaml`, `pristie/config/env_dev.env`, `pristie/config/env_stg.env`, `pristie/config/env_prod.env`
- Modify: `pristie/pubspec.yaml`, `pristie/analysis_options.yaml`, `pristie/lib/main.dart` (placeholder tối thiểu), `docs/superpowers/specs/2026-10-30-flutter-core-base-design.md` (thêm link plan)
- Generated: `pristie/pubspec.lock`

**Interfaces:**
- Produces: toolchain pin `3.47.8`; dependency graph khóa; `AppConfig` key set chính xác: `APP_ENV`, `API_BASE_URL`, `APP_NAME`, `ENABLE_LOGGING`, `CONNECT_TIMEOUT_MS`, `RECEIVE_TIMEOUT_MS`, `SEND_TIMEOUT_MS`.

- [ ] **Step 1: Init repo và baseline commit**

Tạo `.gitignore` ở root:
```gitignore
.DS_Store
*.log
.fvm/
```
```bash
git init
git add .
git commit -m "chore: baseline docs and Flutter scaffold"
```
Expected: commit chứa `docs/` + `pristie/`; `.dart_tool/`, `.idea/`, `.DS_Store` bị ignore.

- [ ] **Step 2: Pin FVM 3.47.8**

Tạo `pristie/.fvmrc`:
```json
{"flutter": "3.47.8"}
```
Chạy:
```bash
fvm install 3.47.8
fvm use 3.47.8 --force
fvm flutter --version --machine
```
Expected: JSON có `flutterVersion: "3.47.8"`, `dartSdkVersion: "3.13.7"`.

- [ ] **Step 3: Viết `pubspec.yaml` theo matrix**

Giữ `name: pristie`, `version: 0.1.0+1`, `environment.sdk: ">=3.13.0 <4.0.0"`.

Dependencies đúng pin: `flutter_bloc 9.1.1`, `bloc 9.2.1`, `bloc_concurrency 0.3.0`, `get_it 9.3.0`, `injectable 3.0.0`, `dio 5.11.1`, `retrofit 4.10.0`, `auto_route 11.2.0`, `freezed_annotation 3.1.0`, `json_annotation 4.12.0`, `slang 4.19.2`, `slang_flutter 4.19.0`, `logger 2.8.0`, `flutter_secure_storage 11.2.0`, `shared_preferences 2.5.6`, `collection 1.19.1`, `intl 0.20.3`, `uuid 4.6.0`, `crypto 3.0.8`.

Dev dependencies đúng pin: `freezed 4.0.1`, `build_runner 2.16.1`, `auto_route_generator 10.6.0`, `analyzer ">=13.3.0 <14.0.0"`, `json_serializable 6.15.2`, `retrofit_generator 10.3.2`, `injectable_generator 3.1.3`, `slang_build_runner 4.19.0`, `flutter_gen_runner 5.15.0`, `flutter_launcher_icons 0.14.4`, `flutter_lints 6.0.0`.

Không thêm optional media/device packages. Không thêm package offline trước T8.

- [ ] **Step 4: Chạy dependency-only solver gate**

```bash
cd pristie
fvm flutter pub get
fvm flutter pub get --enforce-lockfile
```
Expected: cả hai exit 0; `pubspec.lock` được tạo. Nếu fail: **dừng**, ghi lại stderr + package conflict, báo lead; không tự đổi version.

- [ ] **Step 5: Viết `build.yaml` tối thiểu**

```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          field_rename: snake
          explicit_to_json: true
          include_if_null: false
```
Không cấu hình `freezed` options đã bị bỏ ở Freezed 4.

- [ ] **Step 6: Viết 3 file config public**

Mỗi file đúng 7 key, `API_BASE_URL` là HTTPS, `APP_ENV` khớp tên file:
```json
{
  "APP_ENV": "dev",
  "API_BASE_URL": "https://api.dev.pristie.example",
  "APP_NAME": "Pristie Dev",
  "ENABLE_LOGGING": true,
  "CONNECT_TIMEOUT_MS": 15000,
  "RECEIVE_TIMEOUT_MS": 30000,
  "SEND_TIMEOUT_MS": 30000
}
```
`env_stg.env`: `APP_ENV=stg`, `APP_NAME=Pristie Staging`, `ENABLE_LOGGING=true`.
`env_prod.env`: `APP_ENV=prod`, `APP_NAME=Pristie`, `ENABLE_LOGGING=false`.

- [ ] **Step 7: Chạy format/analyze baseline**

```bash
cd pristie
fvm dart format --output=none --set-exit-if-changed .
fvm flutter analyze --fatal-infos --fatal-warnings
```
Expected: pass (main.dart placeholder chỉ dùng Flutter SDK).

- [ ] **Step 8: Commit**

```bash
git add pristie/.fvmrc pristie/pubspec.yaml pristie/pubspec.lock pristie/build.yaml pristie/config pristie/analysis_options.yaml pristie/lib/main.dart docs/superpowers/specs/2026-10-30-flutter-core-base-design.md
git commit -m "chore(scaffold): pin toolchain and dependency matrix"
```

**Orca acceptance:** `fvm flutter pub get --enforce-lockfile` pass; `pubspec.lock` tồn tại; 3 config file đúng key; commit trên `task/t0-scaffold`.

---

### Task 1: Core contracts — config, failure/result/state, paging, data scope

**Files:**
- Create: `pristie/lib/src/core/config/app_config.dart`
- Create: `pristie/lib/src/core/error/app_failure.dart` (+ `.freezed.dart`)
- Create: `pristie/lib/src/core/result/result.dart` (+ `.freezed.dart`)
- Create: `pristie/lib/src/core/presentation/base_state.dart`, `base_cubit.dart`, `paged_state.dart`, `paged_cubit.dart` (+ generated)
- Create: `pristie/lib/src/core/scope/data_scope.dart`, `data_classification.dart`
- Create: `pristie/lib/src/core/auth/auth_state.dart`
- Test: `pristie/test/src/core/config/app_config_test.dart`, `pristie/test/src/core/presentation/paged_cubit_test.dart`, `pristie/test/src/core/presentation/base_cubit_test.dart`

**Interfaces:**
- Produces: `AppConfig`, `AppEnvironment`, `AppConfigException`, `parseAppConfig(Map<String,String>)`, `AppFailure` (đúng 14 variant trong spec 03 §4.4), `Result<T>`, `BaseState<T>`, `BaseCubit<T>`, `PagedState<T>`, `PagedCubit<T>`, `PagedPage<T>`, `PagedLoader<T>`, `DataScope`, `DataClassification`, `AuthState`.

- [ ] **Step 1: Viết test config thất bại trước**

`app_config_test.dart` phải assert:
- thiếu `APP_ENV` → `AppConfigException` có `key == 'APP_ENV'`;
- `APP_ENV = 'qa'` → lỗi enum;
- `API_BASE_URL = 'http://localhost'` → lỗi HTTPS;
- `APP_ENV=prod` + `ENABLE_LOGGING=true` → lỗi;
- `CONNECT_TIMEOUT_MS=0`/`abc` → lỗi;
- key lạ `EXTRA=1` → lỗi;
- dev hợp lệ parse đúng `Uri`/`Duration`/bool;
- message lỗi không chứa giá trị token/secret (dùng fixture giả).

- [ ] **Step 2: Chạy test, xác nhận fail**

```bash
cd pristie
fvm flutter test test/src/core/config/app_config_test.dart -r expanded
```
Expected: FAIL do `app_config.dart` chưa tồn tại.

- [ ] **Step 3: Implement `AppConfig`**

Signature bắt buộc:
```dart
enum AppEnvironment { dev, stg, prod }

final class AppConfigException implements Exception {
  const AppConfigException(this.key, this.reason);
  final String key;
  final String reason;
}

final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.appName,
    required this.enableLogging,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.sendTimeout,
  });

  factory AppConfig.fromEnvironment();
  final AppEnvironment environment;
  final Uri apiBaseUrl;
  final String appName;
  final bool enableLogging;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
}

AppConfig parseAppConfig(Map<String, String> values);
```
`fromEnvironment()` chỉ gọi `const String.fromEnvironment('KEY')` một lần cho từng key rồi chuyển vào `parseAppConfig`. Parser: exact key set, enum, HTTPS + host + không query/fragment, timeout > 0, prod `enableLogging == false`.

- [ ] **Step 4: Implement `AppFailure`, `Result`, `BaseState`, `PagedState`**

Copy đúng union/signature trong spec 03 §4.4. Thêm:
```dart
typedef AsyncResult<T> = Future<Result<T>>;
typedef PagedLoader<T> = Future<Result<PagedPage<T>>> Function(int page);

@freezed
class PagedPage<T> with _$PagedPage<T> {
  const factory PagedPage({
    @Default(<T>[]) List<T> items,
    required bool hasMore,
  }) = _PagedPage<T>;
}

enum AuthState { unknown, authenticated, unauthenticated, locked }

@freezed
class DataScope with _$DataScope {
  const factory DataScope({required String accountId, String? tenantId}) = _DataScope;
}

enum DataClassification { s0, s1, s2, s3 }
```

- [ ] **Step 5: Implement `BaseCubit<T>` và `PagedCubit<T>`**

`BaseCubit<T>`:
```dart
abstract class BaseCubit<T> extends Cubit<BaseState<T>> {
  BaseCubit() : super(BaseState<T>.initial());
  void safeEmit(BaseState<T> state);
  Future<void> execute(Future<Result<T>> Function() operation);
}
```
`execute`: emit loading; `Result.ok` → data; `Result.err(cancelled)` → không đổi state; `Result.err(other)` → error; nếu `isClosed` thì bỏ mọi emit.

`PagedCubit<T>` constructor `PagedCubit({required PagedLoader<T> loadPage, required String Function(T) idOf})`; methods `loadFirst()`, `loadMore()`, `refresh()`; 1-based; dedupe theo `idOf`; `hasMore=false` khi server hết hoặc page rỗng; `refresh()` hủy loadMore đang chạy (dùng generation counter) và bắt đầu page 1; `loadMore` fail giữ items + set `loadMoreFailure`; `loadFirst` fail set `loadFirstFailure` + giữ items cũ nếu refresh.

- [ ] **Step 6: Viết test paging + base cubit**

Assert tối thiểu:
- loadFirst page 1 → items, `page == 1`, `hasMore`;
- loadMore page 2 có item trùng id → không nhân đôi;
- loadMore trả `Err(server)` → `items` giữ nguyên, `loadMoreFailure != null`, `isLoadingMore == false`;
- refresh khi loadMore đang chạy → kết quả loadMore cũ bị bỏ;
- close rồi `execute` async hoàn tất → không emit;
- `Err(cancelled)` → state không đổi, không error.

- [ ] **Step 7: Chạy test + codegen + analyze**

```bash
cd pristie
fvm dart run build_runner build -d
fvm flutter test test/src/core/config test/src/core/presentation -r expanded
fvm flutter analyze --fatal-infos --fatal-warnings
```
Expected: PASS toàn bộ.

- [ ] **Step 8: Commit**

```bash
git add pristie/lib/src/core/config pristie/lib/src/core/error pristie/lib/src/core/result pristie/lib/src/core/presentation pristie/lib/src/core/scope pristie/test/src/core/config pristie/test/src/core/presentation
git commit -m "feat(core): add config, failure, result, base and paged state contracts"
```

**Orca acceptance:** tests + analyze pass; `AppFailure` có đúng 14 variant; không dùng `.when()`/`.map()`.

---

### Task 2: Storage, session record, and observability

**Files:**
- Create: `pristie/lib/src/core/storage/secure_storage.dart`, `local_storage.dart`, `session.dart`, `session_token_provider.dart`, `secure_session_store.dart`, `adapters/flutter_secure_storage_adapter.dart`, `adapters/shared_preferences_adapter.dart`
- Create: `pristie/lib/src/core/observability/app_logger.dart`, `redactor.dart`, `crash_reporter.dart`
- Create: `pristie/lib/src/core/auth/session_state_sink.dart`, `auth_session_controller.dart`
- Test: `pristie/test/src/core/storage/session_storage_test.dart`, `pristie/test/src/core/observability/redaction_test.dart`

**Interfaces:**
- Produces: `SecureStorage`, `LocalStorage`, `Session`, `SessionRecord`, `SessionStatus`, `SessionTokenProvider`, `SessionStateSink`, `AuthSessionController`, `SecureSessionStore`, `AppLogger`, `Redactor`, `CrashReporter`, `NoopCrashReporter`.
- Consumes: `Result`, `AppFailure`, `AuthState` từ T1.

- [ ] **Step 1: Viết test storage thất bại trước**

`session_storage_test.dart` assert:
- `writeSession` ghi cả cặp; `readSession` trả đủ 2 token; `hasSession == true` chỉ khi `active`;
- `writeSession` fail giữa chừng → `AppFailure.localPersistence()`, không còn token cũ/mới;
- `beginLogout` ghi `logoutPending` durable; `readSession` trả `ok(null)`; `readRefreshTokenForRevocation` trả refresh token; `clearSession` → `signedOut` + token pair null;
- `beginLogout` write fail → tự gọi `clearSession`; nếu clear cũng fail → `localPersistence`, `readSession` không trả session;
- `beginInvalidation` → `sessionInvalidationPending`, không cấp access token;
- khởi tạo lại store với record pending → không restore session;
- record JSON là một key duy nhất (`session_record_v1`), không tách access/refresh key.

- [ ] **Step 2: Chạy test, xác nhận fail**

```bash
cd pristie
fvm flutter test test/src/core/storage/session_storage_test.dart -r expanded
```
Expected: FAIL do file chưa tồn tại.

- [ ] **Step 3: Implement types + interfaces**

```dart
enum SessionStatus { active, logoutPending, sessionInvalidationPending, signedOut }

@freezed
class Session with _$Session {
  const factory Session({
    required String accessToken,
    required String refreshToken,
    required String tokenType,
    required DateTime expiresAt,
  }) = _Session;
  factory Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);
}

@freezed
class SessionRecord with _$SessionRecord {
  const factory SessionRecord({required SessionStatus status, Session? session}) = _SessionRecord;
  factory SessionRecord.fromJson(Map<String, dynamic> json) => _$SessionRecordFromJson(json);
}

abstract interface class SecureStorage {
  Future<void> init();
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> clear();
}

abstract interface class LocalStorage {
  Future<void> init();
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

abstract interface class SessionTokenProvider {
  Future<Result<Session?>> readSession();
  Future<Result<String?>> readRefreshTokenForRevocation();
  Future<Result<bool>> hasSession();
  Future<Result<void>> writeSession(Session session);
  Future<Result<void>> beginLogout();
  Future<Result<void>> beginInvalidation();
  Future<Result<void>> clearSession();
}
```

`SessionStateSink`:
```dart
abstract interface class SessionStateSink {
  Future<Result<void>> logout();
  Future<Result<void>> invalidateSession();
}

abstract interface class AuthSessionController implements SessionStateSink {
  Stream<AuthState> get authStateStream;
  int get sessionEpoch;
  bool get isRequestGateOpen;
  Future<AuthState> restore();
  Future<Result<void>> login(Session session);
}
```

- [ ] **Step 4: Implement `SecureSessionStore`**

Một record JSON duy nhất dưới key `session_record_v1`; `readSession` chỉ trả session khi `status == active`; `readRefreshTokenForRevocation` chỉ khi `logoutPending`; `clearSession` ghi `signedOut` + session null; mọi lỗi plugin map `AppFailure.localPersistence()`. `beginLogout` ghi record pending (giữ session) trước; nếu write fail → gọi `clearSession()`; nếu clear fail → `localPersistence`. `beginInvalidation` tương tự nhưng status `sessionInvalidationPending`. `writeSession` ghi đè cả record active trong một lần write; fail → `clearSession()` và trả `localPersistence`.

- [ ] **Step 5: Implement adapters + in-memory fakes**

- `FlutterSecureStorageAdapter`: `AndroidOptions(encryptedSharedPreferences: true)`, `IOSOptions(accessibility: KeychainAccessibility.unlocked_this_device)`, `resetOnError: false`.
- `SharedPreferencesAdapter`: chỉ locale/theme/install marker.
- In-memory fakes đặt trong `test/src/core/storage/fakes/`, không vào `lib/`.

- [ ] **Step 6: Implement redaction + logger + crash reporter**

`Redactor.allowedLogKeys` = `event, operation, method, routeTemplate, statusCode, durationMs, retryCount, correlationId, dataset, syncState, appVersion, buildNumber, os, stage`. `Redactor.redact(Map<String,Object?>)` chỉ giữ key allowlist, bỏ nested map/list, truncate string > 200 ký tự.

`AppLogger` methods `debug/info/warning/error(String event, {Map<String,Object?>? fields})`; khi `enableDiagnostics == false` thì `debug/info` no-op, `warning/error` vẫn qua redactor. Không dùng `print`/`debugPrint`.

`CrashReporter.report(Object error, StackTrace stackTrace, {Map<String, Object?>? context})`; `NoopCrashReporter` không làm gì.

- [ ] **Step 7: Viết test redaction + logging**

Fixture chứa `Authorization`, `cookie`, `access_token`, `password`, `query`, body PII, route param → assert không key/value nào xuất hiện trong output. Assert prod (`enableDiagnostics=false`) không phát info/debug nhưng warning/error vẫn phát đã redact.

- [ ] **Step 8: Chạy test + analyze + commit**

```bash
cd pristie
fvm dart run build_runner build -d
fvm flutter test test/src/core/storage test/src/core/observability -r expanded
fvm flutter analyze --fatal-infos --fatal-warnings
git add pristie/lib/src/core/storage pristie/lib/src/core/observability pristie/lib/src/core/auth/session_state_sink.dart pristie/test/src/core/storage pristie/test/src/core/observability
git commit -m "feat(core): add session storage and redacted observability"
```

**Orca acceptance:** atomic/pending/fail-closed tests pass; redaction fixture không lộ secret/PII; `NoopCrashReporter` là default.

---

### Task 3: Theme, localization, and shared accessibility widgets

**Files:**
- Create: `pristie/lib/src/shared/theme/app_theme.dart`, `app_colors.dart`, `app_text_styles.dart`
- Create: `pristie/lib/src/l10n/strings.i18n.json`, `strings_vi.i18n.json`, `pristie/slang.yaml`
- Generated: `pristie/lib/src/l10n/strings.g.dart`
- Create: `pristie/lib/src/shared/widgets/app_button.dart`, `app_error_view.dart`, `app_loading_view.dart`, `app_empty_view.dart`
- Test: `pristie/test/src/core/presentation/app_error_view_test.dart`, `app_button_test.dart`, `pristie/test/src/shared/theme/contrast_test.dart`

**Interfaces:**
- Produces: `AppTheme.light/dark`, `AppColors` (ThemeExtension), `AppButton`, `AppErrorView`, `AppLoadingView`, `AppEmptyView`, catalog key set.
- Consumes: `AppFailure` từ T1.

- [ ] **Step 1: Viết test widget thất bại trước**

`app_error_view_test.dart`: pump `AppErrorView(failure: AppFailure.network(), onRetry: ...)` trong `MaterialApp` có localization; assert text localized, không hiện raw `network`, tap retry gọi callback đúng 1 lần, `ensureSemantics()` thấy nút có label.
`app_button_test.dart`: loading → không nhận tap, có semantics busy/disabled; min size ≥ 48×48; text scale 2.0 không overflow.
`contrast_test.dart`: tính contrast ratio cho cặp text/background chính ở light/dark; assert ≥ 4.5 cho body text.

- [ ] **Step 2: Chạy test, xác nhận fail**

```bash
cd pristie
fvm flutter test test/src/core/presentation test/src/shared/theme -r expanded
```
Expected: FAIL do widget/theme chưa tồn tại.

- [ ] **Step 3: Implement theme**

`AppTheme.light/dark` dùng `ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF0B6E4F), brightness: ...))`; `AppColors` ThemeExtension chứa `success`, `warning`, `danger`, `info`, `online`, `offline`, `stale`; `AppTextStyles` lấy từ `textTheme` (không hard-code font family). Không ScreenUtil.

- [ ] **Step 4: Tạo catalog Slang**

`slang.yaml`:
```yaml
base_locale: en
fallback_strategy: base_locale
input_directory: lib/src/l10n
input_file_pattern: .i18n.json
output_directory: lib/src/l10n
output_file_name: strings.g.dart
flutter_integration: true
```
`strings.i18n.json` + `strings_vi.i18n.json` phải có đủ key (namespace bằng dấu chấm):
`app.name`, `common.retry`, `common.cancel`, `common.loading`, `common.empty`, `login.title`, `login.email`, `login.password`, `login.submit`, `login.invalidCredentials`, `home.title`, `home.loadMore`, `settings.title`, `settings.theme`, `settings.language`, `settings.logout`, `settings.logoutConfirm`, `error.network`, `error.timeout`, `error.unauthorized`, `error.forbidden`, `error.notFound`, `error.conflict`, `error.validation`, `error.rateLimit`, `error.server`, `error.payloadTooLarge`, `error.parse`, `error.localPersistence`, `error.unknown`, `offline.offline`, `offline.stale`, `offline.pending`, `offline.syncing`, `offline.conflict`, `offline.lastSynced`.

- [ ] **Step 5: Implement shared widgets**

- `AppButton({required String label, VoidCallback? onPressed, bool isLoading = false, IconData? icon})`: `Semantics(button: true, enabled: ..., label: label, child: ...)`; loading hiển thị indicator + chặn tap; `ConstrainedBox(minHeight: 48, minWidth: 48)`.
- `AppErrorView({required AppFailure failure, VoidCallback? onRetry})`: switch pattern matching sang `context.t.error.*`; `AppButton` retry; không toast/navigate.
- `AppLoadingView`, `AppEmptyView`: semantics label localized, không đọc lặp.

- [ ] **Step 6: Generate + test + analyze**

```bash
cd pristie
fvm dart run build_runner build -d
fvm flutter test test/src/core/presentation test/src/shared/theme -r expanded
fvm flutter analyze --fatal-infos --fatal-warnings
```
Expected: PASS; generated `strings.g.dart` commit.

- [ ] **Step 7: Commit**

```bash
git add pristie/slang.yaml pristie/lib/src/l10n pristie/lib/src/shared pristie/test/src/core/presentation pristie/test/src/shared
git commit -m "feat(ui): add Material 3 theme, slang catalogs and accessible shared widgets"
```

**Orca acceptance:** widget tests pass ở textScale 2.0; không hard-code string; catalog đủ key en/vi; contrast AA cho cặp chính.

---

### Task 4: CI gates, local scripts, Makefile

**Files:**
- Create: `.github/workflows/ci.yml`
- Create: `pristie/scripts/ci_local.sh`, `check_config.sh`, `check_boundaries.sh`, `check_secrets.sh`
- Create: `pristie/Makefile`
- Create: `pristie/test/fixtures/config/{dev_valid,prod_logging_on,http_url,missing_key,extra_key}.env`
- Test: chạy script trên fixture âm/dương

**Interfaces:**
- Produces: `make ci`, `make gen`, `make analyze`, `make test`, `make config-check`, `make boundary-check`, `make secret-check`; CI chạy cùng lệnh canonical.

- [ ] **Step 1: Viết `check_config.sh`**

Với từng file `config/env_{dev,stg,prod}.env`, parser `.env` phải kiểm tra exact key set, key thiếu/thừa/trùng, `APP_ENV` khớp file, `API_BASE_URL` bắt đầu bằng `https://`, `APP_NAME` không rỗng, `ENABLE_LOGGING` là `true|false`, timeout là số dương; prod bắt buộc `ENABLE_LOGGING=false`. Script nhận `--fixtures` để chạy bộ fixture âm và assert exit != 0.

- [ ] **Step 2: Viết `check_boundaries.sh`**

Fail nếu:
```bash
rg -n "package:pristie/src/features/|src/features/" lib/src/core && exit 1
rg -n "package:pristie/src/features/" lib/src/features/*/domain lib/src/features/*/presentation | rg -v "features/.*_template" && exit 1
rg -n "\bprint\(|debugPrint\(" lib && exit 1
```
Cho phép `_template/README.md`, test fixture; kiểm tra core không import feature.

- [ ] **Step 3: Viết `check_secrets.sh`**

Yêu cầu Gitleaks `8.30.1`; fail nếu version khác. Chạy `gitleaks dir . --redact --exit-code 1`; nếu `.git` tồn tại chạy `gitleaks git . --redact --exit-code 1`. Không in report chưa redact.

- [ ] **Step 4: Viết `ci_local.sh` + Makefile**

`ci_local.sh` đúng thứ tự spec 05 §6:
```bash
set -euo pipefail
fvm flutter --version --machine | jq -e '.frameworkVersion == "3.47.8"'
fvm flutter pub get --enforce-lockfile
fvm dart run build_runner build -d
git diff --exit-code
test -z "$(git ls-files --others --exclude-standard)"
fvm dart format --output=none --set-exit-if-changed .
fvm flutter analyze --fatal-infos --fatal-warnings
fvm dart run slang analyze --full --exit-if-changed
fvm flutter test
scripts/check_config.sh
scripts/check_boundaries.sh
scripts/check_secrets.sh
```
`Makefile` target `ci` gọi script; `gen/analyze/test/run-dev/build-apk-dev/build-prod` dùng `fvm flutter` + config file.

- [ ] **Step 5: Viết GitHub Actions workflow**

Jobs: `verify` (checkout, cài Flutter `3.47.8` từ `.fvmrc`, cache, chạy `ci_local.sh`), `android` (build AAB prod bằng `config/env_prod.env`), `ios` (macOS, `flutter build ios --release --no-codesign --dart-define-from-file=config/env_prod.env`). Pin action major versions; không đưa secret vào workflow.

- [ ] **Step 6: Test script trên fixture**

```bash
cd pristie
bash scripts/check_config.sh
bash scripts/check_config.sh --fixtures test/fixtures/config
bash scripts/check_boundaries.sh
```
Expected: config hợp lệ pass; từng fixture âm fail; boundary pass ở baseline.

- [ ] **Step 7: Commit**

```bash
git add .github pristie/scripts pristie/Makefile pristie/test/fixtures/config
git commit -m "ci: add canonical verification gates and scripts"
```

**Orca acceptance:** `make config-check` pass; fixture âm fail đúng; workflow chứa đủ 12 bước verify của spec 05.

---

### Task 5: Network, auth refresh, retry and cancellation

**Files:**
- Create: `pristie/lib/src/core/network/dio_factory.dart`, `app_failure_mapper.dart`, `token_refresher.dart`, `api_client.dart`
- Create: `pristie/lib/src/core/network/interceptors/auth_interceptor.dart`, `logging_interceptor.dart`, `error_mapping_interceptor.dart`, `retry_interceptor.dart`
- Create: `pristie/lib/src/core/auth/session_service.dart`, `auth_coordinator.dart`
- Test: `pristie/test/src/core/network/app_failure_mapper_test.dart`, `dto_mapper_test.dart`, `pristie/test/src/core/network/api_client_test.dart`, `pristie/test/src/core/auth/auth_coordinator_test.dart`, `pristie/test/src/core/network/retry_cancel_test.dart`

**Interfaces:**
- Consumes: `AppConfig`, `AppFailure`, `Result`, `AuthState`, `SessionTokenProvider`, `SessionStateSink`, `AuthSessionController`, `SecureSessionStore` (T1/T2).
- Produces: `DioFactory.create`, `AppFailureMapper.map(DioException)`, `TokenRefresher.refresh(String)`, `AuthCoordinator` (`ensureSession`, `logout`, `invalidateSession`), `SessionService` (implements `AuthSessionController`), `ApiClient` Retrofit sample.

- [ ] **Step 1: Viết test mapper thất bại trước**

Assert mapping: socket → `network`; connect/send/receive timeout → `timeout`; cancel → `cancelled`; 401 → `unauthorized`; 403 → `forbidden`; 404 → `notFound`; 409/412 online → `conflict`; 422 và 400 có fields → `validation` với `ValidationIssue`; 429 + `Retry-After: 30` → `rateLimit(Duration(seconds: 30))`; 429 + HTTP date → duration tương ứng; 5xx → `server(code)`; JSON parse → `parse`; unknown → `unknown`.

- [ ] **Step 2: Implement `AppFailureMapper` + DioFactory**

`DioFactory.create({required AppConfig config, required SessionTokenProvider tokenProvider, required AuthSessionController session, TokenRefresher? refresher, AppLogger? logger})`:
- `BaseOptions(baseUrl: config.apiBaseUrl, connectTimeout: ..., receiveTimeout: ..., sendTimeout: ..., contentType: Headers.jsonContentType, validateStatus: (s) => s != null && s >= 200 && s < 300, receiveDataWhenStatusError: true)`.
- Interceptor order: Auth → Logging → ErrorMapping → Retry.
- `followRedirects = false` nếu request mang credential.

- [ ] **Step 3: Implement AuthInterceptor origin policy**

Chuẩn hóa origin `(scheme, host, port)` của `request.uri` và `config.apiBaseUrl`; nếu khác origin:
- request có credential → throw `DioException(error: AppFailure.forbidden(), type: DioExceptionType.badResponse)` trước khi gửi;
- không có credential → cho phép nhưng không gắn token.
`Authorization: Bearer <access>` chỉ khi `session.status == active` và cùng origin. Redirect 3xx cross-origin: không forward `Authorization`/cookie.

- [ ] **Step 4: Implement LoggingInterceptor**

Chỉ log `method`, `routeTemplate` (bắt buộc lấy từ `extra['routeTemplate']`; nếu thiếu dùng `'unknown_route'`, không dùng raw path), `statusCode`, `durationMs`, `correlationId`; không body/header/query/URL đầy đủ. `enableLogging=false` → chỉ warning/error đã redact.

- [ ] **Step 5: Implement RetryInterceptor**

Chỉ GET/HEAD; lỗi `network`/`timeout`; tối đa 1 lần; backoff `Duration(seconds: 1) ± 200ms` (inject `Random` + delay function để test). Đánh dấu `extra['followUpUsed']=true`; nếu đã dùng thì không retry. Không retry 4xx/5xx/parse/cancel/mutation. Nếu request 401 đã replay sau refresh thì cũng set `followUpUsed` để không cộng dồn.

- [ ] **Step 6: Implement `AuthCoordinator`**

```dart
abstract interface class TokenRefresher {
  Future<Result<Session>> refresh(String refreshToken);
}

final class AuthCoordinator {
  AuthCoordinator({
    required SessionTokenProvider tokens,
    required AuthSessionController session,
    required TokenRefresher refresher,
    LogoutRevoker? revoker,
  });

  Future<Result<Session>> ensureSession(int requestEpoch);
  Future<Result<void>> logout();
  Future<Result<void>> invalidateSession();
}

abstract interface class LogoutRevoker {
  Future<Result<void>> revoke(String refreshToken);
}
```
Rules:
- single-flight `Future<Result<Session>>? _inFlight`; nhiều 401 chỉ 1 refresh;
- refresh 200 → `writeSession`; nếu write fail → `beginInvalidation` + `clearSession` + trả `localPersistence` cho mọi waiter; không dùng token mới;
- 400/401/403 → `invalidateSession()` (gate + epoch + pending + clear); clear fail → `locked` + `localPersistence`;
- 429 → giữ session, trả `rateLimit`; network/5xx/4xx khác → giữ session, trả failure;
- epoch cũ → discard response, không ghi token;
- `logout()`: tăng epoch, đóng gate, `beginLogout`; nếu có revoker (optional) gọi trước khi clear; revoke network fail → giữ `logoutPending` + trả retryable failure; không revoker/revoke success → `clearSession` → `signedOut`; pending write fail → thử clear; cả hai fail → `localPersistence`, giữ locked, không báo success.
- `invalidateSession()`: tăng epoch, gate, `beginInvalidation`, `clearSession`; fail → `locked` + `localPersistence`.
- `ensureSession` chỉ trả session khi status active và epoch khớp.

- [ ] **Step 7: Implement `SessionService`**

`SessionService implements AuthSessionController` và là owner duy nhất của `authStateStream`, `sessionEpoch`, request gate:
```dart
final class SessionService implements AuthSessionController {
  SessionService({required SessionTokenProvider tokens});
  @override Stream<AuthState> get authStateStream;
  @override int get sessionEpoch;
  @override bool get isRequestGateOpen;
  @override Future<AuthState> restore();
  @override Future<Result<void>> login(Session session);
  @override Future<Result<void>> logout();
  @override Future<Result<void>> invalidateSession();
}
```
`restore()` đọc `SessionRecord.status`: `active` → authenticated; `logoutPending`/`sessionInvalidationPending` → xử lý pending rồi unauthenticated hoặc locked; `signedOut`/không có record → unauthenticated; storage failure → locked. `login()` chỉ gọi `tokens.writeSession`; fail → localPersistence, không phát authenticated. Mỗi transition tăng epoch đúng một lần và emit state sau khi durable write xong.

- [ ] **Step 8: Implement ApiClient sample + tests**

Retrofit `@RestApi()` với:
```dart
@GET('/api/v1/items')
Future<PagedResponseDto<ItemDto>> getItems(@Query('page') int page, @Query('page_size') int pageSize);

@POST('/api/v1/auth/refresh')
Future<RefreshResponseDto> refresh(@Body() RefreshRequestDto body);
```
DTO Freezed + json_serializable, field snake_case; 204 → `Future<void>`. Test success DTO, 204, empty body, error body bằng fake `HttpClientAdapter` (không dùng network thật).

- [ ] **Step 9: Viết auth coordinator tests**

Assert:
- 5 request 401 đồng thời → đúng 1 lần `refresher.refresh`;
- refresh 200 nhưng `writeSession` fail → mọi waiter `localPersistence`, không request replay, auth locked;
- refresh 400/401/403 → `invalidateSession` trước clear; clear fail → locked + localPersistence;
- refresh 429 → session giữ, `rateLimit`; 500/network → session giữ;
- mutation 401 → refresh nhưng request gốc trả unauthorized, không replay;
- GET 401 → replay đúng 1 lần; retry budget không cộng dồn;
- logout epoch cũ: refresh hoàn tất sau logout bị discard;
- logout pending write fail → clear được gọi; cả hai fail → localPersistence, không success.

- [ ] **Step 10: Chạy test + analyze + commit**

```bash
cd pristie
fvm dart run build_runner build -d
fvm flutter test test/src/core/network test/src/core/auth -r expanded
fvm flutter analyze --fatal-infos --fatal-warnings
git add pristie/lib/src/core/network pristie/lib/src/core/auth pristie/test/src/core/network pristie/test/src/core/auth
git commit -m "feat(network): add dio pipeline, typed errors, single-flight auth and retry budget"
```

**Orca acceptance:** single-flight/epoch/storage-failure/cross-origin/cancel tests pass; không log body/header/query.

---

### Task 6: App runtime — bootstrap, DI, router, auth guard

**Files:**
- Modify: `pristie/lib/main.dart`
- Create: `pristie/lib/src/app/bootstrap.dart`, `app.dart`, `app_router.dart`, `injection.dart`
- Create: `pristie/lib/src/app/modules/network_module.dart`, `storage_module.dart`, `router_module.dart`
- Create: `pristie/lib/src/app/network/api_token_refresher.dart`, `auth_logout_revoker.dart`
- Create: `pristie/lib/src/app/guards/auth_guard.dart`
- Create: `pristie/lib/src/app/observability/app_bloc_observer.dart`, `error_handlers.dart`
- Create: `pristie/lib/src/app/pages/not_found_page.dart`
- Create (placeholder cho tới T7): `pristie/lib/src/features/{auth_placeholder,home,settings}/presentation/pages/*_page.dart` với `StatelessWidget` tối thiểu
- Generated: `app_router.gr.dart`, `injection.config.dart`
- Test: `pristie/test/src/app/router/auth_guard_test.dart`, `pristie/test/src/app/bootstrap_test.dart`

**Interfaces:**
- Consumes: toàn bộ T1, T2, T5; route pages placeholder.
- Produces: `bootstrap()`, `configureDependencies({required AppConfig config})`, `AppRouter`, `AuthGuard`, `AppBlocObserver`, `installErrorHandlers`, `ApiTokenRefresher implements TokenRefresher`, `AuthLogoutRevoker implements LogoutRevoker` (optional, chỉ bật khi backend revoke contract được xác nhận; mặc định null).

- [ ] **Step 1: Viết test guard/router thất bại trước**

Assert:
- `AuthState.unknown` → navigation bị defer (resolver chưa gọi next);
- `unauthenticated` vào Home → redirect `/login`;
- `authenticated` vào Login → redirect `/`;
- logout → stack về Login, back không quay lại Home;
- unknown route → `NotFoundPage`;
- platform initial path `https://host/anything` → router mount tại `/`, guard áp session;
- deep link path bị bỏ qua ở v1.

- [ ] **Step 2: Implement DI modules + `configureDependencies`**

`StorageModule`: `SecureStorage`, `LocalStorage`, `SessionTokenProvider` (SecureSessionStore).
`NetworkModule`: `TokenRefresher` (`ApiTokenRefresher` dùng dedicated no-auth Dio + `/api/v1/auth/refresh`), `SessionService` (bind cả `AuthSessionController` và `SessionStateSink`), `AuthCoordinator`, `Dio` (app client), `ApiClient`. `LogoutRevoker` chỉ bind khi backend revoke contract đã được xác nhận; mặc định không bind.
`RouterModule`: `AppRouter`.
`configureDependencies` gọi `getIt.init()` generated; đăng ký `AppConfig`, `AppLogger`, `CrashReporter`, `SessionService`; idempotent khi test.

- [ ] **Step 3: Implement bootstrap fail-closed**

Đúng thứ tự:
```dart
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  await configureDependencies(config: config);
  await getIt<SecureStorage>().init();
  await getIt<LocalStorage>().init();
  final installMarker = getIt<LocalStorage>().getString('install_marker');
  if (installMarker == null) {
    await getIt<SessionTokenProvider>().clearSession();
    await getIt<LocalStorage>().setString('install_marker', 'v1');
  }
  final authState = await getIt<SessionService>().restore();
  final router = getIt<AppRouter>();
  Bloc.observer = AppBlocObserver(logger: getIt<AppLogger>());
  installErrorHandlers(getIt<CrashReporter>());
  runApp(App(config: config, router: router, authState: authState));
}
```
Nếu `AppConfig.fromEnvironment()` ném `AppConfigException`, bắt trước khi khởi tạo DI và `runApp` một `ConfigErrorApp` tối thiểu chỉ hiển thị tên key lỗi (không in value). Nếu bất kỳ bước storage/session nào fail → `AuthState.locked`, diagnostic đã redact, vẫn `runApp` tới Login (không mở protected route).

- [ ] **Step 4: Implement router + guard**

`app_router.dart`:
```dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter(this.authGuard);
  final AuthGuard authGuard;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, path: '/', initial: true, guards: [authGuard]),
    AutoRoute(page: LoginRoute.page, path: '/login'),
    AutoRoute(page: SettingsRoute.page, path: '/settings', guards: [authGuard]),
    AutoRoute(page: NotFoundRoute.page, path: '*'),
  ];

  @override
  DeepLink? buildDeepLink(Uri uri) => const DeepLink.defaultPath();
}
```
`AuthGuard extends AutoRouteGuard implements ReevaluateListenable`; `reevaluateListenable` = auth state stream distinct; `onNavigation`: unknown → defer; authenticated + Login → replace Home; unauthenticated/locked + protected → replace Login; locked hiển thị trạng thái lỗi persistence ở Login.

- [ ] **Step 5: Implement app shell + observer + error handlers**

`App` dùng `MaterialApp.router` với `theme: AppTheme.light`, `darkTheme: AppTheme.dark`, `themeMode` từ settings (tạm `ThemeMode.system`), `localizationsDelegates` + `TranslationProvider` của Slang, `routerConfig: router.config()`. `AppBlocObserver` log redacted state transition; `FlutterError.onError` + `PlatformDispatcher.instance.onError` gọi đúng một `CrashReporter.report`, bỏ cancellation.

- [ ] **Step 6: Chạy codegen + test router/bootstrap**

```bash
cd pristie
fvm dart run build_runner build -d
fvm flutter test test/src/app -r expanded
fvm flutter analyze --fatal-infos --fatal-warnings
```
Expected: PASS; `app_router.gr.dart` + `injection.config.dart` generated.

- [ ] **Step 7: Commit**

```bash
git add pristie/lib/main.dart pristie/lib/src/app pristie/lib/src/features/*/presentation/pages pristie/test/src/app
git commit -m "feat(app): add bootstrap, DI modules, guarded router and error boundary"
```

**Orca acceptance:** guard matrix pass; bootstrap fail-closed; app chạy `flutter run --dart-define-from-file=config/env_dev.env` hiển thị Login/Home placeholder.

---

### Task 7: Sample features + feature template + composition wiring

**Files:**
- Create: `pristie/lib/src/features/auth_placeholder/{domain,data,presentation}/...`
- Create: `pristie/lib/src/features/home/{domain,data,presentation}/...`
- Create: `pristie/lib/src/features/settings/{domain,data,presentation}/...`
- Create: `pristie/lib/src/features/_template/README.md`
- Modify: `pristie/lib/src/app/app_router.dart`, `pristie/lib/src/app/injection.dart`, `pristie/lib/src/l10n/strings*.json`
- Test: `pristie/test/src/features/**`

**Interfaces:**
- Consumes: T1, T2, T3, T5, T6.
- Produces: 3 feature hoàn chỉnh; mỗi feature tự đăng ký route/DI qua file `feature.dart` hoặc module riêng; composition root chỉ thêm 3 dòng đăng ký. `LoginUseCase` nhận `AuthSessionController` và gọi `login(Session)`; không tự ghi token.

- [ ] **Step 1: Viết test login/home/settings thất bại trước**

- Login: submit rỗng → validation localized; submit hợp lệ → `SessionTokenProvider.writeSession` được gọi 1 lần với dummy session; thành công → `replaceAll([HomeRoute()])`.
- Home: `PagedCubit` load page 1 → list; loadMore → page 2; loadMore fail → footer error + retry, items giữ nguyên; cancel → không error.
- Settings: đổi theme/locale → `LocalStorage` ghi đúng key; logout → `AuthCoordinator.logout()` gọi 1 lần; logout fail `localPersistence` → hiện lỗi localized, không về Login.
- Accessibility: mỗi page có semantics label cho control chính; textScale 2.0 không overflow ở 360dp.

- [ ] **Step 2: Implement auth_placeholder feature**

`LoginCubit` gọi `LoginUseCase`; `LoginUseCase` nhận `AuthSessionController` và gọi `login(Session(accessToken: 'demo-access', refreshToken: 'demo-refresh', tokenType: 'Bearer', expiresAt: DateTime.now().add(const Duration(hours: 1))))`; không gọi network. Sau thành công `router.replaceAll([HomeRoute()])`. Không lưu credential thật; dummy token chỉ dành cho scaffold.

- [ ] **Step 3: Implement home feature**

`DemoItem` entity, `DemoItemsRepository` in-memory 3 trang (mỗi trang 20 item), `GetItemsUseCase`, `HomeCubit extends PagedCubit<DemoItem>`, `HomePage` list + loadMore + `AppErrorView`; route `HomeRoute`. Không gọi Dio.

- [ ] **Step 4: Implement settings feature**

`SettingsCubit` giữ `ThemeMode` + `Locale`; đọc/ghi `LocalStorage` key `theme_mode`, `locale`; `LogoutUseCase` gọi `AuthCoordinator.logout()`; UI có confirm dialog localized; logout thành công → guard tự redirect; thất bại → `AppErrorView`/SnackBar localized (không raw error).

- [ ] **Step 5: Viết `_template/README.md`**

Checklist copy từ `feature-workflow.md` §7; cấu trúc thư mục; quy tắc không sửa `core/`; lệnh codegen/analyze/test; Definition of Done.

- [ ] **Step 6: Nối composition + catalog**

Thêm route/DI/catalog còn thiếu vào `app_router.dart`, `injection.dart`; đảm bảo `core/` không đổi. Chạy codegen.

- [ ] **Step 7: Chạy test + analyze + boundary + commit**

```bash
cd pristie
fvm dart run build_runner build -d
fvm flutter test test/src/features test/src/app -r expanded
fvm flutter analyze --fatal-infos --fatal-warnings
bash scripts/check_boundaries.sh
git add pristie/lib/src/features pristie/lib/src/app pristie/lib/src/l10n pristie/test/src/features
git commit -m "feat(features): add login, home, settings and feature template"
```

**Orca acceptance:** 3 feature chạy end-to-end trên app; boundary check pass; `core/` diff rỗng trong task này.

---

### Task 8a: Offline spike — dependency + encryption ADR (gate)

**Files:**
- Create: `docs/adr/0001-offline-database.md`
- Create: `pristie/tool/offline_spike/` (fixture tạm, không commit generated build)
- Modify: `pristie/pubspec.yaml` + `pubspec.lock` **chỉ sau khi ADR được duyệt**

**Interfaces:**
- Produces: quyết định package DB + version pin + bằng chứng encryption/key lifecycle; nếu gate fail, T8b/T9 bị chặn.

- [ ] **Step 1: Spike ứng viên**

Chạy fixture ngoài app (cùng Flutter pin) với 2 ứng viên theo thứ tự:
1. `drift` + `sqlcipher_flutter_libs` (+ `path_provider`).
2. `sqflite_sqlcipher` (+ `path_provider`).
Mỗi ứng viên: tạo DB encrypted, ghi/đọc, đóng/mở lại, sai key phải fail typed, `PRAGMA rekey` chạy được, build Android debug + iOS no-codesign.

- [ ] **Step 2: Viết ADR**

`docs/adr/0001-offline-database.md` ghi: package + version exact, lý do chọn, license, analyzer compatibility, kết quả 4 test trên, key lifecycle (sinh 32 bytes, lưu SecureStorage key `db_key_v1`, rotation/rekey, key loss → reset/re-sync), backup exclusion plan Android/iOS, rủi ro còn mở.

- [ ] **Step 3: Gate check**

Nếu cả 2 fail hoặc vượt analyzer constraint: **dừng T8b/T9**, báo lead + đề xuất phương án; không thêm dependency. Nếu pass: thêm dependency đã chọn vào `pubspec.yaml`, chạy `fvm flutter pub get`, commit `pubspec.lock` + ADR.

- [ ] **Step 4: Commit**

```bash
git add docs/adr/0001-offline-database.md pristie/pubspec.yaml pristie/pubspec.lock pristie/tool/offline_spike
git commit -m "docs(offline): decide encrypted database package and spike evidence"
```

**Orca acceptance:** ADR có bằng chứng build/test; dependency thêm đúng version; không có plaintext fallback.

---

### Task 8b: Offline DB foundation — schema, scope, key lifecycle, backup exclusion

**Files:**
- Create: `pristie/lib/src/core/offline/db/offline_database.dart`, `database_key_manager.dart`, `migrations.dart`, `tables.dart` (+ generated)
- Create: `pristie/lib/src/core/offline/policy/offline_config.dart`, `offline_policy.dart`
- Create: `pristie/lib/src/core/offline/scope/data_scope_store.dart`
- Create: `pristie/lib/src/app/platform/backup_exclusion.dart`, native channel handlers Android/iOS
- Modify: `pristie/android/app/src/main/AndroidManifest.xml`, `pristie/ios/Runner/Info.plist` (backup/ATS/keychain)
- Test: `pristie/test/src/core/offline/database_test.dart`, `scope_isolation_test.dart`, `key_loss_test.dart`

**Interfaces:**
- Consumes: T2 `SecureStorage`, T8a ADR.
- Produces: `OfflineDatabase.open(DataScope)`, `DatabaseKeyManager.loadOrCreate()`, `OfflineConfig`, `OfflinePolicy`, tables `offline_items`, `offline_outbox`, `offline_conflicts`, `offline_sync_state`, `offline_meta`.

- [ ] **Step 1: Viết test DB thất bại trước**

Assert:
- mở DB với key → create/read/update;
- đóng/mở lại → data còn;
- sai key → `AppFailure.localPersistence()` (typed), không crash loop, không trả plaintext;
- DB corrupt → typed failure + reset path;
- `DataScope(accountId: 'A')` không đọc được row của `'B'`; query thiếu scope → compile-time hoặc runtime fail;
- migration v1 → v2 giữ data;
- `OFFLINE_ENABLED=false` → `OfflineDatabase.open` không được gọi.

- [ ] **Step 2: Implement key manager + DB abstraction**

`DatabaseKeyManager`: `Future<Result<Uint8List>> loadOrCreate()`; key 32 bytes random (`Random.secure()`), lưu SecureStorage key `db_key_v1` base64; nếu thiếu → tạo; nếu đọc fail → `localPersistence`; không log key/path. `rekey()` dùng `PRAGMA rekey`.

`OfflineDatabase` interface (không leak drift/sqflite ra ngoài):
```dart
abstract interface class OfflineDatabase {
  Future<Result<void>> open(DataScope scope);
  Future<Result<void>> close();
  Future<Result<List<Map<String, Object?>>>> query(OfflineQuery query);
  Future<Result<void>> transaction(Future<void> Function(OfflineTransaction tx) action);
}

final class OfflineQuery {
  const OfflineQuery({
    required this.table,
    required this.scope,
    this.whereSql,
    this.whereArgs = const [],
    this.orderBy,
    this.limit,
  });
  final String table;
  final DataScope scope;
  final String? whereSql;
  final List<Object?> whereArgs;
  final String? orderBy;
  final int? limit;
}

abstract interface class OfflineTransaction {
  Future<void> insert(String table, Map<String, Object?> values);
  Future<void> update(String table, Map<String, Object?> values, {required String whereSql, required List<Object?> whereArgs});
  Future<List<Map<String, Object?>>> select(OfflineQuery query);
}

abstract interface class BackupExclusion {
  Future<Result<void>> excludeFromBackup(String path);
}
```
Implementation package-specific nằm trong `core/offline/db/impl/`. `OfflineConfig`:
```dart
final class OfflineConfig {
  const OfflineConfig({this.enabled = const bool.fromEnvironment('OFFLINE_ENABLED', defaultValue: false)});
  final bool enabled;
}
```
`OfflinePolicy`:
```dart
enum OfflineOperation { create, update, delete }
enum ConflictPolicy { serverWins, featureResolver, manual }

@freezed
class OfflinePolicy with _$OfflinePolicy {
  const factory OfflinePolicy({
    required String dataset,
    required DataClassification classification,
    required Duration ttl,
    required Set<OfflineOperation> allowedOperations,
    required ConflictPolicy conflictPolicy,
  }) = _OfflinePolicy;
}
```

- [ ] **Step 3: Schema + scope + migrations**

Tables tối thiểu: `offline_items` (`id`, `account_id`, `tenant_id`, `data_json`, `version`, `deleted_at`, `updated_at`, `pending_overlay_json`), `offline_outbox` (`id`, `account_id`, `tenant_id`, `data_scope_epoch`, `entity_key`, `operation`, `payload_version`, `payload_json`, `base_version`, `sequence`, `state`, `attempt_count`, `next_attempt_at`, `lease_owner`, `lease_expires_at`, `idempotency_key`, `created_at`), `offline_conflicts` (`id`, `operation_id`, `local_json`, `remote_json`, `base_version`, `server_version`, `created_at`), `offline_sync_state` (`dataset`, `account_id`, `tenant_id`, `cursor`, `last_synced_at`, `min_supported_cursor`, `resync_required`). Mọi bảng business/outbox có `account_id` + `tenant_id` trong PK/index.

- [ ] **Step 4: Backup/ATS/keychain config**

Android: `android:allowBackup="false"`, `android:fullBackupContent="false"`, `android:usesCleartextTraffic="false"`, network security config chặn cleartext; DB path dùng `noBackupFilesDir` (platform channel hoặc path_provider + copy? chọn `getApplicationSupportDirectory` + `BackupExclusion` channel).
iOS: `NSAppTransportSecurity` chỉ default (không arbitrary loads); Keychain `unlocked_this_device`; set `NSURLIsExcludedFromBackupKey` cho DB file qua platform channel; `UIFileSharingEnabled=false`.

- [ ] **Step 5: Chạy test DB + build platform**

```bash
cd pristie
fvm dart run build_runner build -d
fvm flutter test test/src/core/offline/database_test.dart test/src/core/offline/scope_isolation_test.dart test/src/core/offline/key_loss_test.dart -r expanded
fvm flutter build apk --debug
fvm flutter build ios --release --no-codesign --dart-define-from-file=config/env_prod.env
```
Expected: PASS; build Android/iOS thành công với package Phase 2.

- [ ] **Step 6: Commit**

```bash
git add pristie/lib/src/core/offline pristie/android pristie/ios pristie/test/src/core/offline pristie/pubspec.yaml pristie/pubspec.lock
git commit -m "feat(offline): add encrypted scoped database foundation and backup exclusion"
```

**Orca acceptance:** wrong-key/corrupt/migration/scope tests pass; OFFLINE_ENABLED=false không mở DB; Android/iOS build pass.

---

### Task 9: Offline outbox, sync engine, conflict, feature opt-in

**Files:**
- Create: `pristie/lib/src/core/offline/outbox/{outbox_operation,outbox_worker}.dart`
- Create: `pristie/lib/src/core/offline/sync/{sync_dataset,sync_send_outcome,sync_conflict,sync_coordinator}.dart`
- Create: `pristie/lib/src/core/offline/policy/offline_policy.dart` (nếu chưa có)
- Modify: `pristie/lib/src/features/home/...` (opt-in cache read + offline/stale/pending UI)
- Test: `pristie/test/src/core/offline/outbox_worker_test.dart`, `sync_coordinator_test.dart`, `conflict_resolution_test.dart`, `account_scope_test.dart`, `pristie/test/src/features/home/offline_home_test.dart`

**Interfaces:**
- Consumes: T8b DB; T5 network/auth; T1 `AppFailure`/`Result`.
- Produces: `OutboxOperation`, `OutboxState`, `OutboxWorker`, `SyncDataset`, `SyncSendOutcome`, `SyncConflict`, `SyncCoordinator`, `OfflinePolicy`, `SyncStatus`; home feature offline read path.
```dart
enum SyncStatus { online, offline, stale, syncing, pending, conflict, needsAttention }

@freezed
class SyncDataset with _$SyncDataset {
  const factory SyncDataset({
    required String name,
    required OfflinePolicy policy,
    String? cursor,
    DateTime? lastSuccessfulSyncAt,
  }) = _SyncDataset;
}
```

- [ ] **Step 1: Viết test outbox/sync thất bại trước**

Assert:
- enqueue operation trong cùng transaction với local row; idempotency key UUID bất biến qua retry/restart;
- worker claim có lease; 2 trigger đồng thời không gửi trùng;
- `401` → suspend queue; `403/422` → `needsAttention`; `409 REQUEST_IN_PROGRESS` → `pending` cùng key; `429/5xx/network` → backoff + `Retry-After`; DELETE 404 → `synced`;
- `VERSION_MISMATCH`/412 → `versionConflict` + snapshot, operation `conflict`, không mất local overlay;
- restart: `syncing` → `pending`; outbox/conflict survives restart;
- account B không claim/đọc operation account A; logout/expiry giữ DB/outbox;
- resync `410`/`resync_required`: staging + atomic swap, outbox/pending overlay preserved;
- OFFLINE_ENABLED=false → worker không start.

- [ ] **Step 2: Implement outbox types + worker**

`OutboxOperation` Freezed đúng field spec offline-first §5 (id, dataScope, dataScopeEpoch, entityKey, operation, payloadVersion, payloadJson, baseVersion, sequence, state, attemptCount, nextAttemptAt, leaseOwner, leaseExpiresAt, idempotencyKey, createdAt). `OutboxState` enum: `pending, syncing, synced, conflict, needsAttention, discarded`. Worker: claim theo `DataScope` + sequence, lease; gọi `SyncSendOutcome`; ack + update row trong transaction; backoff jitter; không xóa pending/conflict.

- [ ] **Step 3: Implement sync coordinator + conflict**

Push trước, pull delta theo dataset; apply page + cursor trong một transaction; cursor opaque; `min_supported_cursor`/`resync_required` → staging generation + atomic swap, giữ outbox/pending overlays; `SyncConflict` chứa localOverlay/remoteSnapshot/baseVersion/serverVersion; `AppFailure.conflict()` không dùng cho sync.

- [ ] **Step 4: Implement fake sync server cho test**

`test/src/core/offline/fakes/fake_sync_server.dart` implement các kịch bản: success, 409 REQUEST_IN_PROGRESS, 409 VERSION_MISMATCH, 412, 401, 403, 422, 429 + Retry-After, 5xx, network, 410 resync. Không network thật.

- [ ] **Step 5: Home feature opt-in offline read**

`OfflineHomeRepository` đọc local trước; refresh nền cập nhật cache; state giữ `data` + `SyncStatus` (`offline/stale/syncing/pending/conflict`); UI hiển thị banner localized; không emit loading/error thay cached data; mutation vẫn online-only (không có nút mutation offline).

- [ ] **Step 6: Chạy test + analyze + build + commit**

```bash
cd pristie
fvm dart run build_runner build -d
fvm flutter test test/src/core/offline test/src/features/home -r expanded
fvm flutter analyze --fatal-infos --fatal-warnings
fvm flutter build apk --debug
git add pristie/lib/src/core/offline pristie/lib/src/features/home pristie/test/src/core/offline pristie/test/src/features/home
git commit -m "feat(offline): add outbox worker, delta sync, conflict handling and opt-in home cache"
```

**Orca acceptance:** toàn bộ state machine/conflict/resync/scope tests pass; OFFLINE_ENABLED=false giữ app online-only; không mất outbox khi resync/restart.

---

### Task 10: Release hardening, docs, and full verification

**Files:**
- Modify: `pristie/android/app/src/main/AndroidManifest.xml`, `pristie/android/app/build.gradle.kts`, `pristie/android/settings.gradle.kts`, `pristie/android/gradle/wrapper/gradle-wrapper.properties`, `pristie/ios/Runner/Info.plist`, `pristie/ios/Runner.xcodeproj/project.pbxproj` (chỉ config, không signing secret)
- Create: `docs/toolchain.md`, `docs/runbooks/release-verification.md`, `docs/superpowers/plans/2026-10-31-verification-report.md`
- Modify: `docs/superpowers/specs/2026-10-30-flutter-core-base-design.md` (status + link), `pristie/README.md`

- [ ] **Step 1: Android/iOS release config + pin native toolchain**

Android: giữ `applicationId/namespace = com.bolt.pristie`; `android:label="Pristie"`; `minSdk = 24`; `compileSdk`/`targetSdk` lấy theo Flutter 3.47.8 template và ghi giá trị thực vào `docs/toolchain.md`; pin JDK 17, Gradle `8.14`, AGP `8.11.1`, Kotlin `2.2.20` (giá trị hiện có; chỉ đổi nếu build Flutter 3.47.8 fail và ghi lý do). `allowBackup=false`, `fullBackupContent=false`, `usesCleartextTraffic=false`, network security config chặn cleartext; không keystore/key.properties trong repo.
iOS: bundle id `com.bolt.pristie`; display name `Pristie`; deployment target `13.0` (ghi Xcode/CocoaPods thực tế vào `docs/toolchain.md`); ATS default; không `NSAllowsArbitraryLoads`; Keychain accessibility `unlocked_this_device`.

- [ ] **Step 2: Chạy full CI gate**

```bash
cd pristie
bash scripts/ci_local.sh
```
Expected: pass toàn bộ (pub enforce, codegen no-diff, format, analyze, slang analyze, tests, config/boundary/secret).

- [ ] **Step 3: Build release validation**

```bash
cd pristie
fvm flutter build appbundle --release --dart-define-from-file=config/env_prod.env
fvm flutter build ios --release --no-codesign --dart-define-from-file=config/env_prod.env
```
Expected: cả hai thành công; `APP_ENV=prod`, `ENABLE_LOGGING=false`; không cleartext.

- [ ] **Step 4: Kiểm tra artifact security**

Giải nén AAB/APK vào thư mục tạm; chạy `gitleaks dir <unpacked> --redact --exit-code 1`; kiểm tra manifest merged: `allowBackup=false`, `usesCleartextTraffic=false`, không debug; iOS `Info.plist` không arbitrary loads; Keychain accessibility đúng.

- [ ] **Step 5: Reviewer độc lập audit**

Reviewer đọc plan + spec + diff, kiểm 5 Review Focus, test-file map spec 05 §6, security §10, accessibility checklist. Ghi report `docs/superpowers/plans/2026-10-31-verification-report.md` với pass/fail + evidence + blocker.

- [ ] **Step 6: Sửa blocker + chạy lại gate**

Mọi blocker phải sửa và chạy lại `ci_local.sh` + build trước khi kết luận.

- [ ] **Step 7: Commit**

```bash
git add pristie/android pristie/ios pristie/README.md docs/toolchain.md docs/runbooks docs/superpowers/plans/2026-10-31-verification-report.md docs/superpowers/specs/2026-10-30-flutter-core-base-design.md
git commit -m "chore(release): harden platform config and record verification evidence"
```

**Orca acceptance:** `ci_local.sh` pass; Android/iOS release validation pass; Gitleaks artifact scan sạch; reviewer report không còn blocker.

---

## Task → spec coverage map

| Spec requirement | Task |
|---|---|
| Toolchain pin, dependency matrix, solver gate | T0 |
| Config fail-fast, prod logging hard-off | T1, T4 |
| AppFailure/Result/BaseState/PagedState | T1 |
| SessionRecord atomic/pending/fail-closed, backup exclusion | T2, T8b |
| Logging redaction, crash boundary Noop | T2, T6 |
| Theme/i18n/shared widgets/accessibility | T3 |
| CI/Gitleaks/config keys/codegen diff | T4 |
| Dio/auth refresh/single-flight/epoch/retry/cancel/origin | T5 |
| Bootstrap/DI/router/AuthGuard/deep link default | T6 |
| Feature workflow/template/3 sample features | T7 |
| Offline DB/encryption/key lifecycle/migrations | T8a, T8b |
| Outbox/sync/conflict/resync/scope/offline UI | T9 |
| Release config/artifact scan/full verification | T10 |

## Self-review notes

- Không có task nào yêu cầu sửa `lib/src/core/` từ feature; T7 chỉ được sửa `app/` + `l10n/` + feature dirs.
- Mọi Review Focus đều có test ở T1/T2/T5/T9; T4 có fixture config âm.
- Các type xuyên task dùng đúng một tên: `SessionTokenProvider`, `SessionStateSink`, `TokenRefresher`, `AuthCoordinator`, `AuthState`, `PagedLoader`, `SyncSendOutcome`, `SyncConflict`.
- Phase 2 mặc định tắt; T8a là gate cứng, T8b/T9 không bắt đầu nếu ADR fail.
- Plan không chứa commit/merge vào `main`, không push, không secret.
