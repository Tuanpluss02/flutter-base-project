# Flutter Core Base — Security và Privacy

Ngày: 2026-10-30 (rev6 — tích hợp phản biện reviewer 2)  
Trạng thái: draft để review; docs/spec only; chưa bắt đầu implementation

Điều hướng: [Index](../2026-10-30-flutter-core-base-design.md) · [Storage](04-storage-and-shared-ui.md) · [Network và errors](03-network-and-errors.md) · [Offline-first data](offline-first.md) · [Verification](05-verification-and-release.md)

Tài liệu này chốt baseline bảo mật/privacy cho Core Base v1 và các cổng bắt buộc trước khi thêm PII hoặc bật offline sync (Phase 2). Tài liệu không định nghĩa danh mục dữ liệu sản phẩm, không chọn package mã hoá/database, và không thay thế đánh giá pháp lý hay pentest.

## 1. Phạm vi, nguyên tắc và threat model

Trong phạm vi:
- Cấu hình build và ranh giới secret của client.
- Token/session, phân loại dữ liệu, nơi lưu, backup, retention, logout và chuyển account.
- Logging, crash reporting, transport và các cổng mã hoá local database cho offline-first.
- Acceptance criteria và quyết định còn mở trước khi cho phép PII/offline sync.

Ngoài phạm vi:
- Authorization phía backend, bảo vệ server, hạ tầng CI/CD và ký release (WS5 sở hữu).
- Chứng nhận tuân thủ pháp lý, DPA với nhà cung cấp, pentest và bug bounty.
- Chọn package mã hoá, database, pinning hay crash SDK khi chưa có spike trên toolchain đã pin.
- Chống gian lận, anti-tamper, root/jailbreak detection và bảo vệ trước OS bị compromise.

Nguyên tắc:
- **Deny by default:** field không được phân loại thì coi là S2 (personal) và không được persist.
- **Fail closed:** lỗi storage/session/DB không được biến thành “coi như hợp lệ”, không fallback sang plaintext.
- **Client không phải trust boundary:** mọi thứ nằm trong binary đều có thể bị trích xuất; không đóng secret vào app.
- **Least data:** chỉ lưu trường cần cho tính năng đã được duyệt; không lưu “để sau này dùng”.
- **Một chiều leo thang:** feature chỉ được nâng mức bảo vệ so với baseline, không được hạ.

Threat model v1:

| Tình huống | Năng lực đối thủ | Kiểm soát kỳ vọng | Ghi chú |
|---|---|---|---|
| Mất/trộm thiết bị đang khoá | Cầm máy, không mở khoá | OS encryption + Keychain/Keystore, không đọc token khi khoá | Phụ thuộc OS; không hứa hơn |
| Trích xuất backup | Sao lưu adb/iCloud/iTunes | Loại secure store, DB và cache khỏi backup | Phải kiểm bằng artifact thật |
| App khác trên máy | Đọc sandbox app khác | OS sandbox | Root/jailbreak phá vỡ giả định |
| Kẻ tấn công mạng | MITM, DNS, proxy | HTTPS + TLS verify, không cleartext, không bypass cert | Pinning là quyết định riêng |
| Rò rỉ qua log/crash | Đọc log, crash dashboard | Redaction trước sink; v1 crash là Noop | Không log body/PII |
| Lẫn dữ liệu giữa account | Dùng chung thiết bị | `DataScope`, epoch, clear cache, cấm query chéo | Test bắt buộc |
| Lộ qua repo/build | Đọc repo, log CI, decompile | Config chỉ public, secret scan, secret ở CI store | `--dart-define` không giấu được secret |
| Chụp màn hình / app switcher | Người cầm máy | Quyết định riêng (D11), không mặc định v1 | Feature nhạy cảm phải khai báo |

Residual risk được chấp nhận ở v1: thiết bị root/jailbreak, OS hoặc app debug bị compromise, screen capture/clipboard do người dùng chủ động, và việc người dùng cài CA độc hại trên thiết bị không quản lý. Các risk này phải được ghi trong release notes/known limitations, không được mô tả là “đã bảo vệ”.

## 2. Phân loại dữ liệu

Spec này **không** đưa ra danh mục dữ liệu sản phẩm. Product + backend phải cung cấp field inventory và owner cho từng field trước khi feature đó lưu dữ liệu. Bảng dưới chỉ định nghĩa mức nhạy cảm và ví dụ theo nhóm privacy; ví dụ không phải danh mục sản phẩm và không được dùng làm danh sách field.

| Mức | Định nghĩa | Ví dụ theo nhóm privacy | Nơi được phép |
|---|---|---|---|
| S0 — Public | Không gắn với cá nhân, công khai được | Tên app, base URL, nhãn i18n, theme token | Mọi nơi, kể cả log |
| S1 — Internal | Vận hành/nội bộ, không phải PII | Locale, theme, lựa chọn UI, metadata sync đã khử định danh | Prefs, DB, cache, log metadata |
| S2 — Personal (PII) | Gắn hoặc có thể gắn với một người/thiết bị | Định danh, liên hệ, nội dung người dùng tạo, dữ liệu giao dịch, ảnh/tệp cá nhân | Chỉ sau khi qua §9; mặc định không persist |
| S3 — Secret | Lộ ra là mất kiểm soát truy cập | Access/refresh token, mật khẩu, khoá ký, khoá mã hoá, Authorization header | Chỉ SecureStorage/in-memory; không DB/log/crash/backup |

Quy tắc phân loại:
- Field chưa có phân loại hoặc chưa rõ nguồn gốc mặc định là S2; không được persist cho tới khi có quyết định.
- Hash, token hoá hoặc che một phần PII không tự động hạ mức: nếu còn tái định danh được thì vẫn là S2. Chỉ số tổng hợp nhỏ có thể tái định danh cũng giữ S2.
- Metadata như `accountId`, `tenantId`, device id, IP, thời điểm và tần suất hoạt động là S1/S2 tuỳ khả năng gắn với người; không mặc định là S1 chỉ vì “chỉ là metadata”.
- Mỗi feature phải khai báo classification cho từng dataset/field trong `OfflinePolicy`/`SyncDataset` (offline-first §10); thiếu khai báo thì feature không được bật offline cache.
- Mỗi dataset cần một bản khai báo tối thiểu: tên dataset, field, classification, mục đích, nơi lưu, retention, owner và feature được phép đọc. Khai báo này là input cho D1, không phải danh mục sản phẩm do spec này định nghĩa.
- `Session`/token là S3. Preference (locale/theme) là S1. Business record mặc định S2 cho tới khi product chứng minh ngược.

Ma trận nơi lưu:

| Nơi lưu | S0 | S1 | S2 | S3 |
|---|---|---|---|---|
| SecureStorage | – | – | Không | Có (token/khoá) |
| LocalStorage/prefs | Có | Có | Không | Không |
| Local database | Có | Có | Chỉ sau §9 | Không bao giờ |
| Image/HTTP cache | Có | Có | Chỉ sau §9 + policy cache | Không |
| Log | Có | Metadata đã redact | Không | Không |
| Crash context | Có | Metadata đã redact | Không | Không |
| Backup | Có | Có | Không (mặc định) | Không |
| Network | Có | Có | Có, qua TLS tới API đã duyệt | Chỉ header/body auth tới API origin |

## 3. Config và secrets

- `config/env_dev.json`, `env_stg.json`, `env_prod.json` chỉ chứa key public trong allowlist: `APP_ENV`, `API_BASE_URL`, `APP_NAME`, `ENABLE_LOGGING`, `CONNECT_TIMEOUT_MS`, `RECEIVE_TIMEOUT_MS`, `SEND_TIMEOUT_MS`. CI phải kiểm tra `APP_ENV` khớp filename, app/bundle identifier và build metadata; runtime một mình không thể xác minh nguồn của Dart define.
- Không đưa token, API secret, signing key, mật khẩu, connection string hay private key vào file config, `--dart-define`, asset, source, test fixture hoặc generated file. Giá trị `--dart-define` được biên dịch vào binary nên không phải nơi giấu secret.
- Pre-scaffold source/config scan dùng Gitleaks v8.30.1 đã pin và fail nếu có finding; scan Git history khi checkout có history. Trước khi bật CI, chốt image digest theo runner architecture và secret masking owner. CI xác nhận chính xác config key allowlist; trước release, scan artifact đã giải nén bằng cùng phiên bản Gitleaks. Log/report scan luôn bật redaction.
- Secret thật chỉ tồn tại ở backend hoặc secret store của CI (signing, store credential). Không in secret ra log CI; mask biến môi trường.
- Mobile “public key” (nếu backend yêu cầu) phải được coi là public: giới hạn theo platform/bundle id, quota, rotation; không dùng làm authorization hay bằng chứng tin cậy.
- Dev/stg không được dùng chung credential với prod. Máy dev không giữ khoá prod. Dev config không được đóng vào bản prod.
- `ENABLE_LOGGING` điều khiển log info/debug, request và diagnostic thông thường; prod bắt buộc false và AppLogger ép các mức này tắt. Warning/error đã redact được phép qua console sink; không có file/persistent sink mặc định. `AppConfig` từ chối prod config bật cờ này; CI xác nhận env file/APP_ENV/app identifier/build metadata cùng khớp. Không dựa vào Dart `assert` vì assert bị loại ở release. Debug build không được phát hành; release không debuggable và không có debug override cho auth/network.
- Khi nghi lộ secret: thu hồi/rotate trước, sửa nguyên nhân sau; ghi incident note; không chỉ xoá commit.
- Không dùng `.env`, envied, file Dart theo flavor hoặc bad-certificate bypass (01 §3, 02 §4.1).

## 4. Token và session

Lưu trữ (đồng bộ 04 §4.7):
- Access/refresh token chỉ nằm trong `SecureStorage` qua `SessionTokenProvider`; không nằm trong prefs, DB business, outbox, cache, log, crash context hoặc URL.
- Android: dùng encrypted preferences do plugin hỗ trợ, và file secure store phải bị loại khỏi backup/auto-backup.
- iOS: Keychain dùng `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`: chỉ đọc khi thiết bị mở khóa và không migrate qua backup sang thiết bị khác. Hành vi phải được xác nhận trên signed build và thiết bị thật trước khi bật auth trên iOS; CI không-code-sign chỉ kiểm tra cấu hình tĩnh.
- iOS Keychain tồn tại qua uninstall: app phải xử lý trường hợp cài lại vẫn còn session cũ. Trước khi D13 được chốt, lần chạy đầu sau cài mới phải xoá session Keychain còn sót nếu không chứng minh được cùng account/thiết bị; không hiển thị dữ liệu của lần cài trước.
- `writeSession` ghi đủ cặp; nếu ghi lỗi phải xoá cả cặp (04). Không để access token của phiên cũ đi cùng refresh token mới.

Sử dụng:
- Token chỉ được gắn vào request tới đúng API origin đã cấu hình. Không gắn vào request tới host khác, URL tuyệt đối do server trả, hay request refresh.
- Không đặt token trong query string, deep link, tên file, analytics event hoặc thông báo lỗi.
- Trong memory: giữ ở auth/session layer; không đưa vào widget state, `toString`, exception message hoặc `Map` được log.
- Refresh theo 03: single-flight, dedicated no-auth Dio, epoch; callback của epoch cũ không được ghi token sau logout/expire.
- Refresh token rotation là yêu cầu ở [API contract](api-contract.md) §5.2; TTL, reuse detection, revoke-on-logout và multi-device vẫn cần backend cam kết (WS1). Chưa có cam kết thì không được coi các kiểm soát đó là đã có.
- 403 không logout, 429 giữ session, refresh 400/401/403 mới invalidate session (03) — đây là hành vi bảo mật, không chỉ UX.
- Logout đóng request gate volatile, tăng epoch, ghi atomic `SessionRecord.logoutPending`, rồi publish AuthState locked; pending record không bao giờ được restore authenticated. Backend revoke chỉ chạy khi contract đã xác nhận, dùng dedicated no-auth client và refresh token chỉ đọc được qua revoke path. Revoke thành công thì ghi `signedOut`; lỗi mạng giữ status pending để retry sau restart. Khi backend chưa hỗ trợ revoke, ghi `signedOut` trực tiếp và không tuyên bố server-side revoke.
- Session expiry/refresh bị từ chối đóng request gate, tăng epoch và ghi `SessionRecord.sessionInvalidationPending` trước clear; không yêu cầu server revoke. Nếu transition pending thất bại, lập tức thử `clearSession()`; nếu cả hai storage operations lỗi, app giữ process locked, trả typed persistence failure, không báo operation thành công và nêu rõ không có durable confirmation. Bootstrap chỉ restore status `active`; status pending được recover trước khi router mount.
- Không hỗ trợ “remember me” mặc định; nếu product thêm, phải chỉ rõ thời hạn và cách revoke.
- App-level lock (PIN/sinh trắc học) không thuộc v1; nếu thêm phải là lớp tăng cường, không thay thế token expiry/revoke.

## 5. Lưu trữ, backup, retention

Bản đồ lưu trữ v1:

| Dữ liệu | Nơi lưu | Backup | Ghi chú |
|---|---|---|---|
| Token/session | SecureStorage | Loại trừ | S3; xoá khi logout/expiry |
| Locale/theme/UI prefs | LocalStorage | Cho phép | S1; không chứa PII |
| Business cache/outbox/draft | Local DB (Phase 2) | Loại trừ mặc định | S2 chỉ sau §9 |
| Ảnh/HTTP cache | `cached_network_image`/cache manager | Loại trừ | S2 chỉ sau §9 + policy |
| Log | Sink/console | Không | Không persist mặc định; redact trước |
| Crash | Noop v1 | Không | Bật sau D5 |

Backup:
- Android: đặt `allowBackup=false` nếu không có nhu cầu backup hợp lệ; nếu bật, phải có `fullBackupContent`/`dataExtractionRules` loại secure store, local DB, outbox, cache và file tạm chứa dữ liệu người dùng. Kiểm trên manifest đã merge và artifact release, không chỉ file nguồn.
- iOS: app container được backup mặc định. DB, outbox, cache và file chứa S2 phải được loại khỏi iCloud/iTunes backup (hoặc đặt ở thư mục không được backup) cho tới khi có policy restore được duyệt. Keychain item dùng accessibility device-bound.
- Không backup khoá mã hoá DB cùng DB. Khôi phục DB mà thiếu khoá phải vào đường reset/re-sync có kiểm soát, không crash loop và không mở plaintext.
- Khôi phục backup sang thiết bị khác không được làm lộ dữ liệu account cũ; nếu không xác thực được cùng account, phải xoá hoặc yêu cầu đăng nhập lại trước khi đọc.
- Kiểm backup exclusion bằng thiết bị/emulator thật ít nhất một lần trước release có PII.

Retention:
- Token: đến expiry/logout/revoke; không cho phép gia hạn vô hạn — refresh token phải rotation hoặc có TTL.
- Prefs: đến khi user đổi hoặc app bị xoá.
- Cache: theo TTL/feature policy; eviction không xoá pending outbox (offline-first §3).
- Outbox/conflict: đến khi synced/discarded theo policy; không tự xoá pending/conflict.
- Tombstone: theo retention server, không theo tuổi cố định (offline-first §10).
- Log: không persist ở v1; nếu bật sink, retention ngắn do D14 chốt và không chứa S2/S3.
- Crash: Noop ở v1; nếu bật, retention và quyền truy cập do D5 chốt.
- Xoá account: phải có đường xoá local data (DB, outbox, cache, prefs, image cache) sau xác nhận; không chỉ xoá token.
- Xoá app: không được giả định là đã xoá Keychain trên iOS (xem §4).

## 6. Logout và chuyển account

Thứ tự logout tường minh:
1. Tăng `sessionEpoch` và `dataScopeEpoch`; dừng sync worker và mọi trigger nền.
2. Cancel request đang chạy bằng `CancelToken`; callback đến sau bị bỏ, không ghi DB/token.
3. Đồng bộ đóng request gate và tăng epoch; ghi atomic `SessionRecord.logoutPending` trước khi publish AuthState locked hoặc thực hiện revoke/clear. Nếu pending write thất bại, gọi `clearSession()` ngay; nếu cả hai storage writes fail, giữ process locked, trả local-persistence failure và không báo logout hoàn thành.
4. Nếu backend revoke contract đã được xác nhận, đọc refresh token qua revoke-only API và gọi dedicated no-auth client. Lỗi mạng giữ `logoutPending` để retry sau restart; bootstrap không restore session. Revoke success/server invalid hoặc backend chưa hỗ trợ revoke thì ghi `signedOut` và bỏ cả cặp token; không claim server revoke nếu endpoint chưa được xác nhận.
5. Khi `signedOut` đã durable, clear in-memory session/cache và image/HTTP cache nếu policy yêu cầu (bắt buộc với S2).
6. Reset route stack về Login, không giữ back stack tới màn hình cần auth (02 §4.5). AuthState locked không được mở protected route hoặc cho submit Login cho tới khi `SessionRecord.status == signedOut` đã ghi bền vững.
7. Chỉ xoá local DB/outbox/draft khi người dùng chọn rõ ràng và đã xác nhận; cảnh báo nếu còn mutation chưa sync.

Quy tắc:
- Session expiry/401 **không** phải logout dữ liệu: giữ DB/outbox scoped theo account, chỉ resume khi cùng account đăng nhập lại (offline-first §8). UI không được hiển thị dữ liệu cũ khi chưa xác thực lại.
- Logout không được âm thầm xoá pending mutation; ngược lại, không được để account sau đọc dữ liệu account trước.
- Chuyển account phải đi qua logout + login, không “switch” khi session đang hoạt động. Khi `DataScope` đổi: dừng worker, tăng epoch, clear in-memory/image cache, reset navigation; mọi query/outbox claim phải dùng scope hiện tại.
- Nếu chọn shared DB + scope: mọi DAO/query bắt buộc scope, có test cố tình query chéo phải fail. Nếu chọn DB-per-account: tên file không chứa PII, khoá mã hoá theo account, xoá file khi account bị remove theo policy.
- Màn hình Login/không đăng nhập không được hiển thị tên, email, avatar hay dữ liệu của account trước (shared-device privacy).
- “Xoá dữ liệu trên thiết bị” là hành động riêng, có confirm và mô tả hậu quả (mất draft chưa sync); không gộp mặc định vào logout.
- Push notification, widget, app switcher snapshot và clipboard ngoài v1; nếu thêm, phải có policy che nội dung (D11).

## 7. Logging và crash reporting

- `AppLogger` chỉ log metadata đã redact. `ENABLE_LOGGING=false` ở prod tắt info/debug/request diagnostics; redacted warning/error chỉ được phép tới console, không persistent sink. Không log request/response body/header/query.
- Redaction deny-by-default: sink chỉ nhận field allowlist; không truyền nguyên object/exception/response. Redactor chạy trước mọi sink, gồm console, file, crash và analytics.
- Không log: `Authorization`, cookie, token/password/secret, query string, request/response body, header, URL có path chứa định danh, tên file/đường dẫn có username, payload outbox, nội dung entity, ảnh.
- Được log: tên operation, loại failure, status code, thời lượng, retry count, dataset/sync state, correlation id không chứa PII. Route breadcrumb chỉ route name, không param/query.
- Không dùng `print`/`debugPrint` trong code sản phẩm; không log trong vòng lặp dữ liệu lớn.
- Log của plugin/native (Dio, image loader, secure storage, platform channel) phải tắt hoặc đi qua cùng redaction; không bật verbose native log trong release.
- Message lỗi trả UI chỉ là chuỗi localized generic; correlation ID chỉ thuộc diagnostic metadata và không được hiển thị trong UI. Không trả raw server message, stack hay exception.
- `CrashReporter.report` nhận `context` đã redact; v1 dùng `NoopCrashReporter`. Không report cancellation, không report lặp ở Cubit và repository (03, 04).
- Bật crash SDK thật chỉ sau D5: có đánh giá PII/scrub, cơ sở pháp lý/consent, DPA, retention, quyền truy cập, opt-out và region. Không gửi screenshot, file đính kèm, breadcrumb request hay user identifier thô.
- Analytics/product telemetry ngoài v1. Nếu thêm, phải định nghĩa event schema không PII và cùng gate consent như crash.
- Log CI không chứa secret; artifact log không chứa token/body.

## 8. Transport

- Chỉ HTTPS tới API đã cấu hình ở mọi môi trường. Không có HTTP dev exception; local backend phải dùng HTTPS với certificate được trust (02 §4.1).
- TLS verification luôn bật; không `badCertificateCallback`, không trust-all, không tắt hostname check. Không có đường tắt bằng cờ debug trong release.
- Android: `usesCleartextTraffic=false` và/hoặc network security config chặn cleartext; không cho user CA trong prod trừ khi có quyết định. iOS: ATS bật, không `NSAllowsArbitraryLoads` cho API.
- `AuthInterceptor` chỉ gắn token cho đúng origin; request tuyệt đối/redirect sang host khác phải bị chặn hoặc strip `Authorization`/cookie. Tắt follow redirect tự động hoặc kiểm origin trước khi gửi lại header.
- Không đưa PII/token vào query string; dùng body hoặc id. Nếu API bắt buộc query, phải ghi exception và redact ở mọi log/crash.
- Giới hạn timeout theo config. V1 không hỗ trợ file upload/download; từng endpoint có bounded-payload policy được xác nhận trước khi bật, oversize trả `AppFailure.payloadTooLarge()` mà không dump nội dung. Không bật endpoint upload nếu chưa có giới hạn và policy được phê duyệt.
- Certificate pinning không thuộc v1. Nếu security/backend yêu cầu, phải có pin set, rotation, backup pin, ngày hết hạn và fallback policy; không thêm package pinning trước spike (D9).
- Không hứa chống MITM trên thiết bị đã bị compromise hoặc có CA độc hại; ghi rõ giới hạn.

## 9. Cổng mã hoá local database (offline-first Phase 2)

Offline-first bị chặn cho tới khi các cổng dưới pass và được ghi bằng chứng. Không cổng nào được “tạm bỏ” để kịp tính năng.

| Cổng | Yêu cầu | Bằng chứng |
|---|---|---|
| G1 — Inventory | Field inventory + classification + owner cho từng dataset/field đã được product/backend duyệt; default S2 | Bảng inventory có version |
| G2 — Isolation | Chốt DB-per-account hay shared DB + scope; chứng minh không đọc/ghi chéo account/tenant | Test query chéo fail; test switch account |
| G3 — Encryption | Chọn cơ chế mã hoá at-rest qua spike trên đúng Flutter pin; dùng authenticated encryption; không plaintext fallback; chấp nhận được về hiệu năng | Spike report + dependency được duyệt vào matrix |
| G4 — Key lifecycle | Khoá sinh trên thiết bị, lưu trong Keystore/Keychain qua SecureStorage; không nằm trong DB/code/log/backup; có rotation/version | Test + mô tả lifecycle |
| G5 — Key loss | Mất khoá/DB hỏng/wrong key là typed failure; có đường reset + re-sync, không crash loop, không mở plaintext | Test wrong key, corrupt DB, restore |
| G6 — Migration | Nếu có DB plaintext cũ: migrate sang encrypted trong transaction/swap nguyên tử; lỗi thì giữ nguyên DB cũ để retry có kiểm soát, nhưng không mount/đọc DB đó để phục vụ UI và không fallback plaintext; app ở trạng thái locked với typed migration failure, không mất pending | Test migration + rollback, xác nhận plaintext DB không được query khi migration fail |
| G7 — Backup/restore | DB + khoá bị loại khỏi backup; restore thiếu khoá phải reset/re-sync có confirm; kiểm trên thiết bị thật | Kết quả kiểm backup Android/iOS |
| G8 — Tamper/downgrade | Sửa file, hạ version, crash giữa write/process kill không làm lộ dữ liệu hay mất outbox | Test crash/tamper |
| G9 — Vận hành | Đo dung lượng, thời gian mở/migrate, memory trên máy thấp; log không PII | Số đo + ngưỡng được duyệt |
| G10 — Dependency | Package chỉ được thêm sau spike, có license/security review và version pin; không chọn trong spec này | Cập nhật 01 §2.2 bởi lead |

Quy tắc trước khi G1–G10 pass:
- Không lưu S2/S3 vào local DB, outbox, draft, image cache hay file. Chỉ cache dữ liệu S0/S1 hoặc dữ liệu đã khử định danh không thể tái định danh.
- Nếu feature cần PII để hoạt động, feature đó online-only và chỉ giữ trong memory trong phiên; không persist.
- Không enqueue business mutation (offline-first §5, §10) vì backend idempotency/version contract cũng chưa chốt.
- Mã hoá cấp field không thay thế mã hoá DB nếu index/query vẫn lộ giá trị hoặc metadata; nếu chọn hướng này phải chứng minh trong G3.
- Không log khoá, salt, nonce, đường dẫn DB hoặc lỗi mở DB chứa dữ liệu.
- Root/jailbreak không được coi là đã giải quyết bởi mã hoá; residual risk phải ghi rõ.

Sau khi pass, baseline vẫn là: feature chỉ được nâng mức bảo vệ, không hạ; mọi dataset mới phải khai báo classification và qua review.

## 10. Verification và acceptance

Bắt buộc trong scaffold v1 (map vào 05 §6):
- Config: thiếu key, key lạ, `APP_ENV` ngoài enum, mọi URL non-HTTPS, timeout sai fail sớm; CI xác nhận file/env/app identifier khớp và prod đặt `ENABLE_LOGGING=false` (không dùng Dart assert).
- Secret scan: Gitleaks v8.30.1 scan current source/config là gate scaffold; history scan chạy khi checkout có Git history. Runner image digest và secret masking owner phải được chốt trước khi CI được bật. Scan artifact đã giải nén là gate release. Mọi scan dùng redacted output và fail khi có finding.
- Token: `writeSession` atomic; auth request gate đóng đồng bộ trước I/O, logout ghi `SessionRecord.status=logoutPending` trước revoke/clear, expiry ghi `sessionInvalidationPending` trước clear; restart với status pending không restore session; clear failure giữ app locked; `hasSession` false khi status không phải `active`.
- Redaction: fixture chứa Authorization/cookie/token/password/query/body PII không xuất hiện ở bất kỳ sink nào; route param bị redact.
- Crash: FlutterError/PlatformDispatcher đi qua một boundary, context đã redact, cancellation không bị report.
- Transport: build check không cleartext; source/static check không có bad-certificate callback, trust-all hoặc tắt hostname verification; token không gắn sai origin (test redirect/absolute URL).
- Backup: manifest/artifact Android loại secure store + DB; iOS kiểm tra exclusion và Keychain accessibility.
- Release transport: kiểm ATS/cleartext policy, token-origin và cross-origin redirect behavior bằng cấu hình/artifact platform.
- PII/privacy/accessibility: semantics, screen-reader order, scale/contrast/touch-target acceptance theo accessibility-ui.md; secret scan repo/artifact theo lệnh Gitleaks đã pin.
- Account/logout: logout không còn back stack; account B không đọc được dữ liệu account A; session expiry không xoá DB/outbox; route params/query bị redact trong diagnostics.

Bắt buộc trước khi bật PII/offline (Phase 2):
- Toàn bộ G1–G10 có bằng chứng và được reviewer B/security chấp thuận.
- Test: DB sai khoá, DB bị sửa, migrate lỗi, process kill giữa transaction, restore backup thiếu khoá, switch account khi worker đang chạy, logout khi outbox pending.
- Kiểm thủ công trên Android/iOS thật: backup/restore, uninstall/reinstall iOS, app switcher/screenshot (theo D11), log release không PII.

## 11. Quyết định phải chốt trước PII/offline sync

Bảng này chỉ bổ sung phần security/privacy. Các prerequisite backend cho offline sync (idempotency key, version/ETag, delta cursor, tombstone retention) thuộc [API contract](api-contract.md) và vẫn phải đóng trước khi enqueue mutation.

| ID | Quyết định | Owner | Chặn |
|---|---|---|---|
| D1 | Field inventory + classification + owner cho từng dataset | Product + backend | Mọi persist S2 |
| D2 | Backend cam kết token: TTL, rotation/reuse detection (rotation đã yêu cầu ở api-contract §5.2), revoke, multi-device | WS1 + backend | Session hardening, offline sync |
| D3 | Backup/restore policy Android/iOS (bật/tắt, loại trừ gì, xử lý restore) | Mobile + product | Mọi persist S2 |
| D4 | Logout retention: giữ hay xoá cache/outbox/draft; ai xác nhận; thời hạn | Product + legal | Logout/account switch có PII |
| D5 | Crash reporting: có bật không, vendor, consent/legal basis, DPA, retention, region | Product + legal | Bật crash SDK |
| D6 | Cơ chế mã hoá DB + key lifecycle + rotation | Spike + security | Offline DB |
| D7 | Account isolation: DB-per-account hay shared scope; xoá khi remove account | Spike + backend | Offline DB, account switch |
| D8 | Privacy policy/notice, legal basis, data residency, quyền xoá/truy cập của người dùng | Product + legal | PII feature |
| D9 | Có cần certificate pinning không; pin set/rotation/fallback | Security + backend | Nếu bật pinning |
| D10 | Policy image/HTTP cache cho S2 (bật/tắt, TTL, clear on logout) | Mobile + product | Ảnh/tài liệu PII |
| D11 | App switcher/screenshot/clipboard protection cho màn hình nhạy cảm | Product | Feature nhạy cảm |
| D12 | Secret scanner version/config, CI masking và artifact review owner | WS5 | Pinned source/config scan trước scaffold; image digest + masking owner trước khi bật CI; artifact scan trước release thật |
| D13 | Xử lý Keychain còn session sau uninstall iOS | Mobile | Release iOS có auth thật |
| D14 | Retention số cụ thể cho cache/outbox/log/crash | Product + legal | Persist dài hạn |

Mặc định khi chưa quyết: không persist S2, crash là Noop, không bật offline DB, không pinning, không cache ảnh PII, logout ghi `signedOut` local và giữ offline data theo account scope (không xoá outbox); server revoke chỉ được gọi nếu backend contract được xác nhận.

## 12. Open blockers

Chặn implementation PII/offline (phải đóng trước):
- D1, D3, D6, D7, D8: thiếu các quyết định này thì không được lưu PII, không được bật local DB/outbox.
- D2: API contract đã yêu cầu rotation nhưng backend chưa cam kết TTL/revoke/reuse detection; chưa có thì không được coi session là “production-grade”, và offline sync vẫn bị chặn bởi idempotency/version backend (WS1).
- D5: chưa có consent/DPA/retention thì `CrashReporter` phải giữ Noop; không thêm SDK.
- D4: chưa chốt thì logout không được tự xoá pending mutation; đồng thời không được để account sau thấy dữ liệu account trước.

Không chặn scaffold v1 nhưng phải theo dõi:
- D9 (pinning) — mặc định không làm ở v1.
- D10, D11 — chỉ áp dụng khi có feature ảnh/màn hình nhạy cảm.
- D12 — Gitleaks v8.30.1 và lệnh scan đã chốt tại §10; source/config scan bằng binary đã pin là gate scaffold; runner image digest/secret masking owner phải được xác nhận trước khi bật CI; artifact scan là gate release. Các hạng mục CI còn mở không chặn scaffold.
- D13 — cần trước khi auth thật chạy trên iOS.
- D14 — cần trước khi bật log/crash persist.

Rủi ro còn mở:
- Backend chưa cam kết token rotation/revoke/reuse detection và idempotency; mọi tuyên bố “an toàn khi retry” phải chờ WS1.
- Chưa chọn package mã hoá/database; mọi ước lượng hiệu năng/khả năng migrate chỉ là giả thuyết tới khi spike.
- Chưa có thiết bị/CI iOS thật để kiểm backup/Keychain; D13 và phần iOS của G7 chưa thể đóng.
- Chưa có quyết định pháp lý về consent/crash/PII; không được tự suy ra từ tài liệu này.

## 13. Tham chiếu

- [Scope, toolchain và architecture](01-scope-toolchain-architecture.md) — config, dependency matrix, ranh giới client.
- [App runtime](02-app-runtime.md) — bootstrap fail-closed, route/log policy.
- [Network và errors](03-network-and-errors.md) — auth refresh, redaction, cancellation.
- [API contract](api-contract.md) — token/refresh, error/redaction, idempotency và version.
- [Storage và shared UI](04-storage-and-shared-ui.md) — `SecureStorage`, `SessionTokenProvider`, backup, logger, crash.
- [Offline-first data](offline-first.md) — `DataScope`, outbox, retention, encryption gates.
- [Verification và release](05-verification-and-release.md) — test matrix và CI.
- [Workstream plan](../../plans/2026-10-30-flutter-core-base-workstreams.md) — WS2 scope và gate.

Việc thêm tài liệu này vào index và cập nhật quyết định chung thuộc lead; WS2 không sửa 01–05, offline-first hoặc workstream plan.
