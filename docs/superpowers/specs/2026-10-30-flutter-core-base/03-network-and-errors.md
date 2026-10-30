# Flutter Core Base — Network và Error Handling

Ngày: 2026-10-30 (rev6 — tích hợp phản biện reviewer 2)  
Trạng thái: bộ spec tích hợp đang chờ cả hai reviewer duyệt cùng revision; chưa bắt đầu implementation

Điều hướng: [Index](../2026-10-30-flutter-core-base-design.md) · [Foundation](01-scope-toolchain-architecture.md), [App runtime](02-app-runtime.md), [API contract](api-contract.md), [Security và privacy](security-privacy.md), [Storage và shared UI](04-storage-and-shared-ui.md)

### 4.3 Network và session

`DioFactory.create` nhận `AppConfig`, `SessionTokenProvider` và interceptors mở rộng. Base options dùng JSON, connect/receive/send timeout từ config và `receiveDataWhenStatusError: true`. TLS verification luôn bật; mọi môi trường chỉ dùng HTTPS, không có cleartext dev exception.

Request interceptor:
1. `AuthInterceptor` gắn access token nếu có.
2. `LoggingInterceptor` chỉ ghi metadata allowlist (method, route template đã khử định danh, status, duration, correlation ID); không serialize/log request/response body, headers, query string hoặc URL path có thể chứa identifier. Redaction chạy trước sink. Correlation ID chỉ là diagnostic metadata, không hiển thị trong UI. `ENABLE_LOGGING=false` ở prod tắt info/debug/request diagnostics; warning/error đã redact vẫn được phép qua console, không persist.
3. `ErrorMappingInterceptor` giữ nguyên cancellation và chuyển lỗi còn lại qua typed mapper.

Auth contract:
- Với request cần xác thực, `AuthInterceptor` chỉ gửi `Authorization` khi origin chuẩn hóa (scheme, host, port) trùng origin của `API_BASE_URL`; từ chối absolute URL khác origin trước khi gửi. Tắt tự động follow redirect cho request có credential; nếu transport buộc follow, chỉ tiếp tục cùng origin và không forward `Authorization`/cookie qua origin khác. Request public không mang token vẫn theo policy redirect của endpoint.
- `Session` model và `SessionTokenProvider` (đọc/ghi/xóa token) thuộc core storage contract. `TokenRefresher` ở `core/network/` có `Future<Result<Session>> refresh(String refreshToken)`; implementation tại `app/` dùng dedicated no-auth client và API cụ thể. `AuthCoordinator` chỉ phụ thuộc interface này, không biết endpoint hoặc DTO.
- `SessionStateSink` có `Future<Result<void>> logout()` và `Future<Result<void>> invalidateSession()`; coordinator serialize các auth transition, đóng request gate volatile ngay lập tức, ghi bền vững `SessionRecord` status pending trước khi publish `AuthState.locked`. Nếu ghi pending thất bại, gọi atomic `clearSession()` ngay; nếu cả hai lỗi, giữ process locked và trả `localPersistence` (logout không được báo thành công). Status và session cùng một secure record enum loại trừ nhau, nên không thể đồng thời tồn tại logout/invalidation pending. Nếu cả pending-write lẫn clear đều fail thì không có bằng chứng durable về transition; UI phải báo logout chưa hoàn tất, khuyến khích retry trước khi đóng app, và không hứa trạng thái sau restart.
- Explicit logout dừng sync, hủy request và tăng epoch. Khi backend có revoke contract đã xác nhận, `logoutPending` giữ refresh token trong SecureStorage chỉ cho dedicated no-auth revoke; lỗi mạng giữ status pending để retry sau restart, không restore auth. Khi revoke thành công/server xác nhận invalid hoặc backend chưa hỗ trợ revoke, ghi `signedOut` và bỏ cả cặp token. Không tuyên bố server-side revoke nếu endpoint chưa được xác nhận. Kết quả `logout()` là `ok` khi local `signedOut` đã durable; khi vẫn `logoutPending` thì trả typed retryable failure và Login submit vẫn bị khóa.
- Refresh điều phối bằng một `AuthCoordinator` single-flight để nhiều 401 đồng thời chỉ tạo một refresh request.
- Refresh dùng Dio riêng không gắn AuthInterceptor, hoặc request rõ ràng `no_auth`; refresh 401 không được quay lại cùng interceptor.
- Refresh endpoint 400/401/403 gọi `invalidateSession()`; epoch/request gate bị vô hiệu trước khi ghi `sessionInvalidationPending`, status pending commit trước public locked state và token clear. Chỉ sau khi record signedOut durable request nhận `unauthorized`; storage failure giữ app locked và trả `localPersistence`, không khôi phục auth state. 429 giữ session và trả `RateLimitFailure`; timeout/network/5xx và 4xx khác giữ session, trả failure đã map cho request gốc.
- Nếu refresh trả 200 nhưng ghi cặp token mới vào SecureStorage thất bại, không dùng token mới trong memory hoặc replay request; bỏ response, tăng epoch, set status `sessionInvalidationPending` trước khi clear cặp cũ, chuyển auth state locked và trả `localPersistence` cho mọi waiter. Status pending giữ durable trước mọi session read khi bootstrap.
- 403 của request gốc là forbidden; không refresh và không logout.
- Session epoch tăng khi logout/expire. Refresh hoàn tất với epoch cũ bị bỏ, không được ghi lại token sau logout.
- Request gốc chỉ replay tối đa một lần sau refresh và chỉ với GET/HEAD. Request mutation không tự replay; lỗi 401 của nó được trả về caller.
- GET/HEAD có tối đa một lần gọi lại request gốc: một lần backoff retry cho timeout/network error, hoặc một lần replay sau refresh 401. Không cộng dồn hai loại follow-up trên cùng request. Không tự retry 4xx, 5xx, cancellation hoặc lỗi parse. Với mutation, không retry/replay; 401 có thể refresh session nhưng request gốc vẫn trả lỗi.
- CancelToken thuộc operation/Cubit; cancel khi close/dispose. Cubit kiểm tra `isClosed` trước mọi emit bất đồng bộ; `DioExceptionType.cancel` không thành UI error, không emit sau close và không gửi CrashReporter.

V1 dùng Retrofit cho client mẫu nhưng không áp đặt một response envelope cho mọi backend. Retrofit trả DTO cụ thể; repository map DTO sang entity. Shared `ApiEnvelope<T>` chỉ thêm sau một spike riêng về converter, 204/empty/error body.

### 4.4 Error handling và Result

`AppFailure` là Freezed union. Danh sách đóng: `network`, `timeout`, `cancelled`, `unauthorized`, `forbidden`, `notFound`, `conflict`, `validation`, `rateLimit`, `server`, `payloadTooLarge`, `parse`, `localPersistence`, `unknown`. Mapping canonical: 400 recognized fields / 422 -> validation; 401 sau auth policy -> unauthorized; 403 -> forbidden; 404 -> notFound; 409/412 online version error -> generic conflict; 429 -> rateLimit; 5xx -> server; bounded payload violation -> payloadTooLarge. Offline sync xử lý `REQUEST_IN_PROGRESS`/version mismatch trước mapper và trả `SyncSendOutcome`, không dùng `AppFailure.conflict()` để mang snapshot. Cause và stack chỉ ở diagnostic boundary, không đưa raw exception vào state/UI.

`Result<T>` và `BaseState<T>` dùng Freezed. Đặt tên variant tránh va chạm `dart:core.Error`:

```dart
@freezed
sealed class AppFailure with _$AppFailure {
  const factory AppFailure.network() = NetworkFailure;
  const factory AppFailure.timeout() = TimeoutFailure;
  const factory AppFailure.cancelled() = CancelledFailure;
  const factory AppFailure.unauthorized() = UnauthorizedFailure;
  const factory AppFailure.forbidden() = ForbiddenFailure;
  const factory AppFailure.notFound() = NotFoundFailure;
  const factory AppFailure.conflict() = ConflictFailure;
  const factory AppFailure.validation(Map<String, ValidationIssue> fields) = ValidationFailure;
  const factory AppFailure.rateLimit(Duration? retryAfter) = RateLimitFailure;
  const factory AppFailure.server(int? statusCode) = ServerFailure;
  const factory AppFailure.payloadTooLarge() = PayloadTooLargeFailure;
  const factory AppFailure.parse() = ParseFailure;
  const factory AppFailure.localPersistence() = LocalPersistenceFailure;
  const factory AppFailure.unknown() = UnknownFailure;
}

enum ValidationIssue { required, invalidFormat, tooShort, tooLong, alreadyUsed, invalid }

@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.ok(T data) = Ok<T>;
  const factory Result.err(AppFailure failure) = Err<T>;
}

@freezed
sealed class BaseState<T> with _$BaseState<T> {
  const factory BaseState.initial() = Initial<T>;
  const factory BaseState.loading() = Loading<T>;
  const factory BaseState.data(T data) = Data<T>;
  const factory BaseState.error(AppFailure failure) = ErrorState<T>;
}

@freezed
class PagedState<T> with _$PagedState<T> {
  const factory PagedState({
    @Default([]) List<T> items,
    @Default(1) int page,
    @Default(true) bool hasMore,
    @Default(false) bool isLoadingFirst,
    @Default(false) bool isLoadingMore,
    AppFailure? loadFirstFailure,
    AppFailure? loadMoreFailure,
  }) = _PagedState<T>;
}
```

`BaseState<T>` dành cho request đơn giản. `PagedCubit<T>` dùng `PagedState<T>` để giữ items cùng progress/failure của trang; footer failure không thay thế data.

- Dùng Dart switch/pattern matching; không dùng Freezed `.when()`/`.map()` trong code mới.
- Repository implementation bắt lỗi hạ tầng đã dự kiến và trả `Result`; không nuốt lỗi lập trình.
- Failure UI text được dịch ở presentation qua slang; domain/network không chứa câu chữ cho người dùng.
- `AppErrorView` hiển thị localized message và retry callback; không tự toast hoặc điều hướng.
- Cancelled là trạng thái bỏ qua, không hiển thị như lỗi.
