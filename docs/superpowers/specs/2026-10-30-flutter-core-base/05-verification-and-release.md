# Flutter Core Base — Testing, Release và Checklist

Ngày: 2026-10-30 (rev6 — tích hợp phản biện reviewer 2)  
Trạng thái: bộ spec tích hợp đang chờ cả hai reviewer duyệt cùng revision; chưa bắt đầu implementation

Điều hướng: [Index](../2026-10-30-flutter-core-base-design.md) · [Foundation](01-scope-toolchain-architecture.md), [App runtime](02-app-runtime.md), [Accessibility](accessibility-ui.md), [Release operations](release-operations.md), [Feature workflow](feature-workflow.md), [Storage and shared UI](04-storage-and-shared-ui.md)

## 6. Testing và nghiệm thu

Test bắt buộc:
- Unit: AppConfig runtime validation (APP_ENV enum, HTTPS mọi environment, prod info/debug/request logging hard-off không dựa vào assert; redacted warning/error permitted), DioErrorMapper, DTO mapper (không bịa timestamp/version), TokenRefresher/AuthCoordinator single-flight, refresh-fail và invalidation storage-failure policy, refresh 429 preservation, logout-pending restore/revoke retry, logout-during-refresh epoch, one-follow-up retry budget, cancellation/no-emit-after-close, PagedCubit/PagedState loadMore failure giữ items.
- API client: success DTO, 204, empty body và error body mapping.
- Router: session unknown/restore, unauthenticated redirect, authenticated Login -> Home, logout stack, unknown route -> wildcard NotFound, platform initial path -> `/` then AuthGuard.
- Widget/accessibility: AppErrorView localized failure/retry; AppButton loading; SemanticsTester cho tên/role/state/focus order; 360dp/768dp layouts và textScale 2.0; contrast/touch-target checklist theo accessibility-ui.md.
- Integration-level fakes: 401 refresh thành công, 401 refresh hết hạn, 403 không logout, 429 refresh giữ session, network/5xx refresh không logout, cancel không hiển thị/report/emit sau close, storage init failure fail-closed.
- Storage/reporting: failed refresh `writeSession` never uses unpersisted tokens and fails all waiters; `SessionRecord` status is exclusive/atomic; restart never restores pending statuses; explicit logout revoke retry and final `signedOut` transition are covered; pending-write failure attempts clear and never reports success if both fail; FlutterError/PlatformDispatcher forwards one redacted report.
- Privacy/i18n/security: no request/response body/header/query/PII or route-param identifiers reach logs; authenticated absolute URLs on other origins are rejected and cross-origin redirects never forward credentials; locale persists/restores; secret-scan and config allowlist gates pass.
- Account/transport: account B cannot read account A data; session expiry preserves DB/outbox; static scan rejects bad-certificate callback/trust-all/hostname-check bypass; every environment rejects HTTP URL.
- Mọi requirement ở trên phải được ánh xạ tới test file trước khi implementation bắt đầu; mọi file core mới có test tương ứng.

Test-file map dự kiến cho implementation (điều chỉnh tên khi scaffold tạo đúng cấu trúc, giữ nguyên nhóm coverage):

| Nhóm | File dự kiến |
|---|---|
| Config, failure mapping, DTO và client | `test/src/core/config/app_config_test.dart`, `test/src/core/network/app_failure_mapper_test.dart`, `test/src/core/network/dto_mapper_test.dart`, `test/src/core/network/api_client_test.dart` |
| Auth/session, refresh, logout, epoch và router | `test/src/core/auth/auth_coordinator_test.dart`, `test/src/app/router/auth_guard_test.dart` |
| Storage và privacy | `test/src/core/storage/session_storage_test.dart`, `test/src/core/observability/redaction_test.dart` |
| Shared UI và accessibility | `test/src/core/presentation/app_error_view_test.dart`, `test/src/core/presentation/app_button_test.dart` |
| Offline Phase 2, chỉ sau các gate | `test/src/core/offline/account_scope_test.dart`, `test/src/core/offline/outbox_worker_test.dart`, `test/src/core/offline/conflict_resolution_test.dart` |

Config CI phải xác nhận key set đúng chính xác, không chỉ kiểm tra giá trị: `scripts/check_config.sh` parse từng file `.env`, từ chối key thiếu/thừa/trùng và kiểm tra value theo môi trường như bước 5.

CI/pre-scaffold verification plan:
1. Cài FVM-pinned Flutter; kiểm tra `flutter --version --machine` đúng pin.
2. Trên dependency-only fixture, chạy `flutter pub get` để tạo lockfile; chạy lại `flutter pub get --enforce-lockfile` làm gate. Commit lockfile vào scaffold sau khi gate qua.
3. `dart run build_runner build -d`, `git diff --exit-code`, rồi `test -z "$(git ls-files --others --exclude-standard)"` để bắt generated changes và file mới.
4. Trước scaffold, dùng Gitleaks `8.30.1` đã pin để scan source/config bằng `gitleaks dir . --redact --exit-code 1`; scan history bằng `gitleaks git . --redact --exit-code 1` khi checkout có Git history. Trước khi bật CI, pin image digest theo runner architecture và chốt secret masking owner. Sau signed candidate creation, unpack Android/iOS artifacts vào thư mục tạm và chạy `gitleaks dir <unpacked-artifact-dir> --redact --exit-code 1`; fail nếu phát hiện secret và không publish report chưa redact.
5. Config identity checks: chạy `scripts/check_config.sh` cho `config/env_dev.env`, `config/env_stg.env`, `config/env_prod.env`; script phải từ chối fixture bị gán sai `APP_ENV`, sai key set hoặc bật logging ở prod. Compare each environment to its app/bundle identifier mapping and build metadata.
6. `dart format --output=none --set-exit-if-changed .` để check format mà không sửa file.
7. `flutter analyze --fatal-infos --fatal-warnings`.
8. `slang analyze --full --exit-if-changed`.
9. `flutter test` (bao gồm widget semantics và accessibility checks).
10. Build Android release prod bằng file config prod; kiểm tra `APP_ENV=prod`, application ID/config identity match, effective info/debug/request logging off (redacted warning/error permitted), signing/debuggable policy, backup exclusion và không có cleartext traffic.
11. Trên macOS CI, build iOS release prod với `flutter build ios --release --no-codesign --dart-define-from-file=config/env_prod.env`; kiểm tra `APP_ENV=prod`, bundle ID/config identity match, effective info/debug/request logging off (redacted warning/error permitted), ATS và backup exclusion. CI chỉ kiểm tĩnh cấu hình Keychain; trước khi bật auth trên iOS, signed build phải qua kiểm tra thủ công trên thiết bị thật xác nhận `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` và đọc token khi khóa bị từ chối.
12. Script boundary fail nếu `lib/src/core/` import `lib/src/features/`; template-copy check xác nhận thêm feature không làm đổi core.

Không đặt coverage %. CI, scaffold và test được bắt đầu sau khi spec decisions được duyệt và dependency solver gate ở §2.3 qua.

## 7. Chạy app và môi trường

- Dev: `flutter run --dart-define-from-file=config/env_dev.env`.
- Staging: `flutter run --dart-define-from-file=config/env_stg.env`.
- Prod release: `flutter build appbundle --release --dart-define-from-file=config/env_prod.env`.
- `config/env_*.env` chỉ chứa config public; có mẫu committed và CI kiểm tra đủ keys.
- `Makefile` sau khi scaffold: `gen, analyze, test, run-dev, build-apk-dev, build-prod`.
- Không dùng envied generator hoặc file Dart riêng cho từng flavor.

## 8. Quyết định đã chốt

| Chủ đề | Quyết định |
|---|---|
| Config | `--dart-define-from-file` + `String.fromEnvironment`; bỏ envied |
| Dependency pin | Version matrix ở §2; lockfile commit/enforce; resolver pass là chốt trước scaffold |
| Composition | Router/DI ở `src/app/`; core không phụ thuộc feature |
| Auth navigation | AutoRoute guard là owner duy nhất; coordinator không navigate |
| Refresh | Dedicated no-auth Dio, single-flight, epoch; 403 không refresh; một follow-up budget cho GET/HEAD |
| Deep link | Không hỗ trợ native links ở v1; initial path về `/`, AuthGuard áp chính sách session |
| Failure | Closed Freezed union, Dart pattern matching, localization ở UI |
| Paging | Cubit manual gate; loadMore error giữ items |
| API envelope | Generic envelope hoãn; DTO cụ thể trong v1 |
| Optional modules | Firebase/push/socket/media/QR/eKYC ngoài core v1 |

## 9. Checklist trước scaffold

- [ ] Tất cả decision ở §8 và revision tích hợp hiện tại được cả hai reviewer đồng thuận.
- [ ] FVM pin cài được và Flutter/Dart version đúng.
- [ ] Gitleaks `8.30.1` binary đã pin và source/config scan qua trước scaffold; Git history scan chạy khi checkout có history. Trước khi bật CI, image digest và secret masking owner được chốt.
- [ ] Dependency matrix resolve được trên fixture: `flutter pub get` tạo lockfile và lần chạy tiếp `flutter pub get --enforce-lockfile` qua; nếu fail thì sửa spec trước khi scaffold.
- [ ] Native toolchain baseline Android/iOS đã được pin hoặc target tương ứng được loại khỏi scaffold.
- [ ] Auth/session/router matrix và acceptance tests được chuyển thành implementation checklist theo test-file map ở §6; các đường dẫn bên dưới là file dự kiến khi implementation bắt đầu.
- [ ] Thời gian “dưới 30 phút” đo trên checkout sạch, ghi riêng cold-cache/warm-cache và liệt kê rõ thời gian tính từ lúc clone đến lần chạy app mẫu đầu tiên.

Sau khi checklist này qua, mới bắt đầu scaffold/code. Không mở rộng scope ngoài spec nếu chưa có decision docs cập nhật.
