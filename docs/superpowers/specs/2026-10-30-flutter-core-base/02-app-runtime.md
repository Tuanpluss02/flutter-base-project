# Flutter Core Base — App Runtime

Ngày: 2026-10-30 (rev6 — tích hợp phản biện reviewer 2)  
Trạng thái: bộ spec tích hợp đang chờ cả hai reviewer duyệt cùng revision; chưa bắt đầu implementation

Điều hướng: [Index](../2026-10-30-flutter-core-base-design.md) · [Foundation](01-scope-toolchain-architecture.md), [Network và errors](03-network-and-errors.md), [Verification](05-verification-and-release.md)

### 4.1 Cấu hình

- Cấu hình công khai nằm trong `config/env_dev.json`, `config/env_stg.json`, `config/env_prod.json`; file được truyền khi build bằng `--dart-define-from-file`.
- Bootstrap đọc `String.fromEnvironment` một lần, tạo immutable `AppConfig` type từ `core/config/` rồi inject; không dùng envied, generated env constants, `.env` hoặc flavor entrypoint riêng.
- Keys v1: `APP_ENV` (`dev`, `stg`, `prod`), `API_BASE_URL`, `APP_NAME`, `ENABLE_LOGGING`, `CONNECT_TIMEOUT_MS`, `RECEIVE_TIMEOUT_MS`, `SEND_TIMEOUT_MS`.
- Config thiếu key, `APP_ENV` ngoài enum, `API_BASE_URL` không dùng HTTPS ở mọi môi trường, hoặc timeout không hợp lệ phải fail sớm với lỗi cấu hình có tên key, không in giá trị nhạy cảm. CI kiểm tra `APP_ENV` khớp file config; runtime không thể tự biết nguồn của Dart define. Backend dev local cũng phải dùng HTTPS với certificate được trust; không có HTTP/cleartext exception.
- Các file config chỉ chứa giá trị public. Token, signing key và credential không được đóng vào client binary.
- `ENABLE_LOGGING` điều khiển info/debug/request diagnostics; prod bắt buộc false, `AppConfig` từ chối prod config bật cờ này và AppLogger ép các mức đó tắt. Warning/error đã redact vẫn được phép tới console. Đây là runtime enforcement có typed config failure, không dựa vào Dart `assert` vì assert bị loại khỏi release. CI xác nhận file config, `APP_ENV`, app identifiers và build metadata cùng chỉ tới một environment.
- Lệnh mẫu: `flutter run --dart-define-from-file=config/env_dev.json`.

### 4.2 DI và bootstrap

- Một entry `configureDependencies()` trong app composition; modules đăng ký `NetworkModule`, `StorageModule`, `RouterModule`.
- Bootstrap theo thứ tự: Flutter bindings -> AppConfig -> DI -> storage init -> đọc `SecureStorage.SessionRecord.status` -> recover `logoutPending`/`sessionInvalidationPending` hoặc restore status `active` -> router -> Bloc observer -> runApp. Không gọi `readSession()` khi status không phải `active`. Native launch screen giữ chỗ trong khi storage/session restore đang chạy; Flutter router chưa mount.
- Session restore hoàn tất trước khi router quyết định đích; nếu storage init/record transition/restore thất bại thì fail closed về locked và ghi diagnostic đã redact. `unknown` chỉ tồn tại trong lúc bootstrap; guard vẫn phải defer nếu bị khởi tạo sớm trong test hoặc host khác.
- UI lấy dependency qua factory/router; Cubit nhận dependency qua constructor.

### 4.5 Router

- Router và route table nằm ở `src/app/app_router.dart`; khai báo bằng `auto_route`.
- Routes v1: `/` (HomeRoute, initial), `/login`, `/settings`, catch-all `*` (NotFoundRoute) đặt cuối. HomeRoute là protected route; không có Flutter SplashRoute trong v1.
- Native launch screen giữ UI trong khi bootstrap restore session. Sau khi router mount, initial `/` vào AuthGuard và redirect về Home hoặc Login theo session.
- `AuthState` trong core auth contract có các giá trị `unknown`, `authenticated`, `unauthenticated`, `locked`; guard defer khi state còn unknown, đưa locked về Login với trạng thái lỗi persistence, và không cho vào protected route.
- Một `AuthGuard` cùng `ReevaluateListenable.stream(authStateStream.distinct())` sở hữu mọi auth redirect: unauthenticated vào protected route -> Login; authenticated vào Login -> Home. Không có GuestGuard riêng. AuthCoordinator/Cubit không gọi router.
- Login thành công dùng `replaceAll([HomeRoute()])`; không phục hồi route pending trong v1.
- Logout/expiry đưa stack về login và không để back quay lại màn hình cần auth.
- Deep link native và universal/app links ngoài phạm vi v1. App không quảng bá “deep-link ready”; cấu hình `deepLinkBuilder: (_) => DeepLink.defaultPath` để platform path luôn về root `/`, sau đó AuthGuard áp chính sách session. Unknown in-app route được match bằng `AutoRoute(path: '*', page: NotFoundRoute.page)` đặt cuối.

| Tình huống | Kết quả |
|---|---|
| Cold start, session unknown/restoring | Native launch screen giữ chỗ; router chưa mount |
| Restore authenticated | Router mount tại `/`; AuthGuard cho vào Home |
| Restore unauthenticated hoặc fail closed | Router mount tại `/`; AuthGuard redirect tới Login |
| Secure storage đang xử lý logout pending/không thể xác nhận session | AuthState locked; không mở protected route hoặc gửi request |
| Login thành công | Replace all tới Home; không giữ route pending |
| Session hết hạn | Clear session một lần, guard đưa stack tới Login |
| Người đã đăng nhập mở Login | AuthGuard đưa về Home |
| Unknown in-app route | `AutoRoute(path: '*', page: NotFoundRoute.page)` |
| Platform gửi initial deep link | DeepLink.defaultPath đưa về `/`; AuthGuard áp chính sách session và path bị bỏ qua ở v1 |
- Route logging không ghi query string hoặc thông tin PII.

### 4.6 State và model

- State duy nhất là Bloc/Cubit; cấm `setState` cho logic async và cấm EventBus.
- `BaseCubit<T>` nhận UseCase qua constructor, emit initial/loading/data/error.
- `BaseCubit` cung cấp `safeEmit(state)` có guard `isClosed`; callback async sau close bị bỏ.
- Paging dùng `PagedCubit<T>` với `PagedState<T>` riêng và manual in-flight gate; không biểu diễn trang bằng union `BaseState<List<T>>`. `droppable()` là transformer cho Bloc event, không áp trực tiếp lên Cubit method.
- Paging 1-based. Dedupe theo stable entity id; `hasMore=false` khi server báo hết hoặc page rỗng. Refresh hủy loadMore đang chạy và bắt đầu từ page 1. Close hủy request.
- `PagedState<T>` giữ đồng thời `items`, `page`, `hasMore`, `isLoadingFirst`, `isLoadingMore`, `loadFirstFailure` và `loadMoreFailure`. Lỗi loadMore giữ nguyên items và phát footer error/retry; lỗi refresh giữ items cũ và failure riêng. Không emit `BaseState.error` làm mất items.
- DTO và Entity dùng Freezed; DTO có `fromJson`, Entity chỉ serialize nếu cần. Mapper là pure function.
- `AppBlocObserver` log transition/error đã redact; chỉ một boundary chịu trách nhiệm report crash.

## 5. Data flow

```
Page -> Cubit -> UseCase.call -> Repository interface
     -> RepositoryImpl -> Retrofit client/Dio -> Server

Server JSON -> DTO -> Mapper -> Entity -> UseCase -> Cubit state -> Page
```

- Cubit gọi UseCase, không gọi repository trực tiếp.
- UseCase chỉ forward Result khi không có orchestration nghiệp vụ.
- RepositoryImpl là boundary map lỗi network/parse dự kiến sang Result.
- Không parse JSON hoặc chạy I/O trong Cubit/Widget.
- `build.yaml` cấu hình đúng builder options cho Freezed và json_serializable; generated files được kiểm tra diff trong CI.
