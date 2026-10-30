# Flutter Core Base — Storage, Logging, i18n và Theme

Ngày: 2026-10-30 (rev6 — tích hợp phản biện reviewer 2)  
Trạng thái: bộ spec tích hợp đang chờ cả hai reviewer duyệt cùng revision; chưa bắt đầu implementation

Điều hướng: [Index](../2026-10-30-flutter-core-base-design.md) · [Security và privacy](security-privacy.md), [Offline-first data](offline-first.md), [Accessibility](accessibility-ui.md), [Network và errors](03-network-and-errors.md), [Verification](05-verification-and-release.md)

### 4.7 Storage

Interfaces: `SecureStorage`, `LocalStorage`, `SessionTokenProvider`; mọi thao tác plugin chỉ trong implementation. Session API trả typed `Result` để storage failure không bị nuốt.

- Secure store giữ access/refresh token và hỗ trợ read/write/delete/clear.
- SecureStorage giữ một record nguyên tử `SessionRecord(status, session?)`; status là enum loại trừ nhau: `active`, `logoutPending`, `sessionInvalidationPending`, `signedOut`. Không có record được xem như `signedOut`. `SessionTokenProvider` có `Future<Result<Session?>> readSession()`, `Future<Result<String?>> readRefreshTokenForRevocation()` (chỉ khi status là `logoutPending`), `Future<Result<bool>> hasSession()`, `Future<Result<void>> writeSession(Session)` (pair-atomic), `Future<Result<void>> beginLogout()`, `Future<Result<void>> beginInvalidation()` và `Future<Result<void>> clearSession()`. Chỉ status `active` được restore/cấp access token; `hasSession()` false ở các status khác.
- `beginLogout()`/`beginInvalidation()` atomically persist status trước khi token clear; `logoutPending` giữ Session trong secure storage chỉ để dedicated revoke flow nếu backend contract đã chốt, còn `sessionInvalidationPending` không cấp token. `clearSession()` atomically ghi `signedOut` và bỏ token pair. Nếu pending write thất bại, gọi `clearSession()` ngay; nếu cả hai lỗi, trả `localPersistence`, giữ process locked và không tuyên bố logout thành công. Vì không có durable write nào thành công, app phải nói rõ trạng thái logout chưa được lưu và yêu cầu retry trước khi đóng app; nếu process bị kết thúc trong tình trạng này, không thể đảm bảo lần khởi động sau vẫn biết transition đã thất bại. Không có API nào dùng `LocalStorage` cho marker/session.
- LocalStorage chỉ giữ preferences không nhạy cảm như locale/theme. Business data/cache/outbox thuộc local database contract trong [Offline-first data](offline-first.md), không lưu qua preference store.
- Bootstrap await storage init và đọc `SessionRecord.status` trước restore; `logoutPending` chỉ revoke theo backend contract rồi chuyển `signedOut`, `sessionInvalidationPending` chuyển `signedOut` không revoke. Nếu secure store không đọc/ghi được, fail closed thành locked. Refresh rotation chỉ tiếp tục request sau atomic write session mới thành công.
- Android dùng cấu hình encrypted preferences được plugin hỗ trợ và loại secure-store data khỏi backup. iOS dùng `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`; xác minh trên signed build và thiết bị thật theo security-privacy.md trước khi bật auth.
- Test dùng in-memory implementation.

### 4.8 Logging, i18n và theme

- `AppLogger` wrap logger; prod tắt info/debug/request diagnostics theo `ENABLE_LOGGING=false`, chỉ warning/error đã redact được phép tới console. Redaction áp dụng trước khi log; không persistent sink mặc định.
- `CrashReporter` có method thật `report(Object error, StackTrace stackTrace, {Map<String, Object?>? context})`; v1 dùng `NoopCrashReporter`. Không report cancellation và không report lặp ở Cubit lẫn repository.
- FlutterError và PlatformDispatcher error handlers được nối vào một reporting boundary. Route breadcrumb/query được redact.
- Slang: `strings.i18n.json` (en), `strings_vi.i18n.json`, checked-in config `slang.yaml`, init `TranslationProvider` ở app root và persist locale qua LocalStorage. Shared widgets dùng `context.t.*`.
- Theme dùng Material 3, `ColorScheme`, `AppTheme.light/dark`, token colors/text styles qua ThemeExtension. Không ScreenUtil.
