# Flutter Core Base — Release và Operations

Ngày: 2026-10-30 (thuộc bộ spec tích hợp rev6)  
Trạng thái: đề xuất bổ sung; các giá trị được ghi rõ là cần xác minh chưa phải quyết định đã chốt

Điều hướng: [Index](../2026-10-30-flutter-core-base-design.md) · [Foundation](01-scope-toolchain-architecture.md), [App runtime](02-app-runtime.md), [Verification](05-verification-and-release.md), [Offline-first](offline-first.md)

## 1. Phạm vi và trạng thái quyết định

Tài liệu này bổ sung quy trình build, ký, phát hành và vận hành cho target Android/iOS v1. Các yêu cầu được coi là baseline; mọi giá trị ghi “cần xác minh” phải được chốt trong scaffold/CI setup trước khi bật release lane. Repo hiện chưa có Flutter source, `pubspec.yaml`, CI workflow, signing setup hoặc store integration, vì vậy đây là hợp đồng vận hành, không phải mô tả pipeline đang chạy.

| Hạng mục | Yêu cầu đã xác định | Cần xác minh trước implementation/release |
|---|---|---|
| Flutter/Dart | Flutter stable `3.47.8`, Dart `3.13.7`, Flutter pin qua FVM `.fvmrc`; CI phải cài đúng pin | Runner image và cách cài FVM/tool cache |
| Android | Phải pin JDK, Gradle wrapper, Android Gradle Plugin, Kotlin, compile/target/min SDK và build-tools tương thích với Flutter pin | Từng version cụ thể; xác nhận trên macOS/Linux runner và thiết bị hỗ trợ |
| iOS | Release build trên macOS; phải pin Xcode, CocoaPods và iOS deployment target tương thích | Từng version cụ thể; runner macOS, signing/export profile và thiết bị hỗ trợ |
| Ký | Credential release chỉ nằm trong secret store của CI hoặc signing service được duyệt | Secret manager, owner, rotation, store accounts và quy trình cấp quyền |
| Crash | Core có `CrashReporter` boundary và chỉ một boundary gửi report; Firebase không thuộc v1 mặc định | Có bật crash backend không, vendor, retention, vùng lưu trữ và alert owner |
| Phát hành | Môi trường app: dev, staging, production; file config public truyền khi build | Tên app/store track, approver, rollout threshold và rollback quyền hạn |

Không pin native version bằng suy đoán. Chọn bộ version cùng lúc với scaffold, thử build sạch bằng Flutter/FVM pin và ghi các version đã xác nhận vào tài liệu toolchain/CI. Nếu một target chưa đạt gate, loại target đó khỏi release scope cho tới khi gate qua; không âm thầm phát hành bằng toolchain khác.

## 2. Gate toolchain Android/iOS

- Mỗi CI job lấy Flutter từ `.fvmrc` và xác nhận `flutter --version --machine` khớp Flutter `3.47.8`/Dart `3.13.7`. Không chạy `flutter upgrade` trong pipeline.
- Android release gate xác nhận JDK, Gradle wrapper, AGP, Kotlin, SDK levels/build-tools, NDK (nếu thực sự cần) và Android SDK components đã được pin và cài sẵn. CI in version metadata vào job log; mismatched version làm job fail trước dependency/build stages.
- iOS gate chạy trên macOS runner và xác nhận Xcode, CocoaPods, iOS deployment target cùng signing/export configuration đã pin. Không dùng `--no-codesign` để thay cho release signing; tùy chọn này chỉ dùng cho compile validation của spec §6.
- Native pin cần có compatibility record: Flutter/Dart pin, native toolchain versions, runner image, ngày kiểm tra và kết quả clean build. Upgrade một thành phần yêu cầu chạy lại dependency resolution, codegen check, analyze, test và release build trên cả hai target.
- Lockfile được commit và CI chạy `flutter pub get --enforce-lockfile`. Dependency solver failure hoặc generated diff là gate fail, không tự nâng/hạ version trong release job.

## 3. Signing, credentials và secrets

- `config/env_dev.env`, `config/env_stg.env`, `config/env_prod.env` chỉ chứa cấu hình public trong allowlist `APP_ENV`, `API_BASE_URL`, `APP_NAME`, `ENABLE_LOGGING`, `CONNECT_TIMEOUT_MS`, `RECEIVE_TIMEOUT_MS`, `SEND_TIMEOUT_MS`; `APP_ENV` phải khớp file/môi trường build. Không đưa token, API secret, private key, keystore, provisioning profile hay credential vào Dart define, source, artifact metadata hoặc log. Client-side value không phải secret vì có thể trích xuất từ binary.
- Android signing key/keystore và password được lấy từ CI secret store hoặc signing service; không commit keystore, `key.properties`, export file hay credential. Material tạm được tạo/đưa vào job với quyền tối thiểu, không cache hoặc upload chung với artifact, và bị xóa khi job kết thúc. Release lane xác nhận package/application ID đúng production trước khi ký.
- iOS certificate/private key, provisioning profile, App Store Connect/API credential và keychain password được giữ trong secret store/signing service. Import vào keychain tạm theo job, giới hạn quyền theo environment, dọn keychain và file provisioning sau job. Không chia sẻ credential giữa dev, staging và production nếu store/account hỗ trợ tách biệt.
- Tách credential cho CI validation, staging và production. Production signing/deploy chỉ khả dụng trên protected branch/tag và protected environment; yêu cầu approver độc lập với người khởi tạo release khi nền tảng CI hỗ trợ.
- Chỉ định owner và backup owner, rotation/revocation procedure, ngày hết hạn, secret access audit và xử lý compromise trước lần phát hành đầu. Các lựa chọn secret store, signing service, key custody và retention hiện **cần xác minh**; không đặt credential thật trong spec hoặc repo.

## 4. Version và build number

- Dùng `version: MAJOR.MINOR.PATCH+BUILD` trong `pubspec.yaml` làm nguồn version chung. Phần trước `+` là version người dùng thấy; build number sau `+` phải tăng đơn điệu cho từng binary gửi lên store, kể cả khi semver chưa đổi.
- Android map version sang `versionName` và build number sang `versionCode`; iOS map sang `CFBundleShortVersionString` và `CFBundleVersion`. Không sửa các giá trị native riêng lẻ để chúng lệch khỏi pubspec/build invocation.
- Release candidate lấy version từ tag đã xác thực hoặc release metadata của CI; build number cấp duy nhất, không tái sử dụng sau khi upload. Quy tắc tag (ví dụ `vMAJOR.MINOR.PATCH`), build-number allocator, cách xử lý hotfix và version chính thức đầu tiên **cần xác minh** trước khi pipeline được bật.
- CI lưu version, build number, commit SHA, Flutter/Dart/native toolchain versions, environment config identity và build timestamp trong release metadata. Chỉ ghi tên/ID config, không ghi giá trị secret.
- Bản dev/staging cần nhận diện rõ trong tên/package/bundle identifier và không được nhầm với production; cách cấu hình application IDs, display names và store listing **cần xác minh** trong scaffold.

## 5. CI stages và artifacts

Các stage dưới đây mở rộng đúng lệnh trong [Verification](05-verification-and-release.md). Workflow syntax, CI vendor, cache keys, runner sizing và trigger cụ thể **cần xác minh**; không thay đổi command canonical nếu chưa cập nhật verification spec.

| Stage | Thực hiện | Gate/output |
|---|---|---|
| 1. Source và toolchain | Checkout immutable commit/tag; cài FVM pin; kiểm tra `flutter --version --machine`; kiểm tra Android/iOS native pins trên runner phù hợp | Fail khi version lệch; lưu commit và toolchain metadata |
| 2. Dependencies, generated code và secret scan | Trong CI đã được bật: cài Gitleaks `8.30.1` từ image đã pin; kiểm tra exact config key allowlist và `APP_ENV`/prod logging; chạy `gitleaks git . --redact --exit-code 1` khi checkout có Git history và `gitleaks dir . --redact --exit-code 1`; chạy `flutter pub get --enforce-lockfile`; `dart run build_runner build -d`; `git diff --exit-code`; kiểm tra file untracked | `APP_ENV` khớp file; exact allowlist pass; không đổi lockfile/generated outputs, không sinh artifact ngoài dự kiến, không secret finding |
| 3. Static checks và tests | `dart format --output=none --set-exit-if-changed .`; `flutter analyze --fatal-infos --fatal-warnings`; `slang analyze --full --exit-if-changed`; `flutter test` | Mọi lệnh thành công; áp dụng tests/acceptance trong §6 của verification spec |
| 4. Platform release validation | Android build production AAB bằng config prod; macOS iOS compile validation `flutter build ios --release --no-codesign --dart-define-from-file=config/env_prod.env`; kiểm tra config prod có `APP_ENV=prod`/`ENABLE_LOGGING=false`, app/bundle IDs đúng environment, không cleartext traffic | Build Android và iOS compile thành công; iOS no-codesign chỉ là validation, không phải artifact store-ready |
| 5. Signed candidate | Chạy signing trên protected release job với credential production; đóng gói Android App Bundle và iOS archive/export theo store policy đã xác minh; giải nén artifact và chạy Gitleaks `8.30.1` với `gitleaks dir <unpacked-artifact-dir> --redact --exit-code 1` | Artifact ký được, install/validate được, secret scan sạch; giữ checksum và release metadata |
| 6. Promotion | `--dart-define-from-file` biên dịch config vào app; dev/stg/prod dùng artifact riêng từ cùng commit với config tương ứng. Candidate chỉ promote qua track/review trong đúng environment; không đổi config sau build | Checksum/commit/config identity khớp environment; không gọi artifact prod và staging là cùng binary |

Android store artifact là `.aab`; APK debug/dev nếu có không thay thế release AAB. iOS archive/export artifact (`.xcarchive` và store upload package) phụ thuộc Xcode/export policy đã chọn. CI upload artifacts với access hạn chế, retention có thời hạn và checksum; không đính signing secret/provisioning material. Test report, build log đã lọc, generated diff status và metadata được giữ làm evidence. Retention cụ thể **cần xác minh** theo quy định tổ chức/store.

`05-verification-and-release.md` hiện nêu `flutter build appbundle --release --dart-define-from-file=config/env_prod.env` và iOS `flutter build ios --release --no-codesign --dart-define-from-file=config/env_prod.env`; pipeline phải giữ các lệnh này làm baseline validation cho tới khi scaffold xác nhận lệnh ký/export phù hợp. Make targets dự kiến ở spec đó (`gen`, `analyze`, `test`, `run-dev`, `build-apk-dev`, `build-prod`) là tiện ích sau scaffold, không thay các lệnh CI đã được ghi nếu chưa chuẩn hóa cùng lúc.

## 6. Crash diagnostics và privacy

- `ENABLE_LOGGING=false` trong production tắt info/debug/request diagnostics; warning/error đã redact được phép tới console. Redaction áp dụng trước mọi sink theo quy tắc trong `03-network-and-errors.md` và `04-storage-and-shared-ui.md`; không persistent log sink mặc định.
- `CrashReporter` có boundary thật để nhận uncaught Flutter framework và `PlatformDispatcher` errors; chỉ một boundary chịu trách nhiệm report để tránh duplicate. Cancellation, lỗi đã xử lý thành `Result`, validation/network failure dự kiến và lỗi do user đóng screen không được gửi thành crash.
- Report chỉ gồm loại lỗi, stack đã lọc, app version/build, OS/app lifecycle, stage khái quát và correlation ID ngẫu nhiên nếu có. UI luôn dùng thông báo localized chung, không hiện correlation ID. Không gửi access/refresh token, headers, URL/query, request/response body, PII, ảnh/tài liệu, business record, database/outbox payload hoặc định danh account/tenant. Offline operation diagnostics chỉ metadata đã redact (operation type, retry count, duration, dataset), theo `offline-first.md`.
- Không bật thêm Firebase/crash SDK trong v1 chỉ để thỏa interface; Firebase nằm ngoài core v1. Trước khi gắn backend cần quyết định vendor, consent/notice, retention, data residency, access control, deletion process, symbolication/dSYM/ProGuard/R8 mapping custody, sampling và alert routing. Tất cả giá trị đó **cần xác minh** qua security/privacy review.
- Crash reporting failure không được làm crash thêm hoặc đổi kết quả app operation. Nếu backend chưa được duyệt/cấu hình, implementation phải cung cấp behavior an toàn theo spec (ví dụ không upload, chỉ diagnostic tối thiểu đã lọc tại boundary) và ghi rõ tình trạng trong release evidence.

## 7. Môi trường và promotion

Môi trường app đã định nghĩa là `dev`, `stg`, `prod`, với các file public `.env`: `config/env_dev.env`, `config/env_stg.env`, `config/env_prod.env`; tham số được truyền bằng `--dart-define-from-file`, không dùng envied hay flavor entrypoint Dart riêng. CI kiểm tra `APP_ENV` trong từng file khớp tên file, application/bundle identifier và build metadata; `env_prod.env` phải đặt `ENABLE_LOGGING=false`. Runtime không thể xác minh file nguồn của Dart define, nên build lane phải truyền file environment tường minh. Secrets/signing credential tách theo môi trường và không nằm trong config file.

Promotion dùng cùng một commit nhưng artifact riêng cho `dev`, `stg`, `prod`, vì `--dart-define-from-file` biên dịch endpoint/config vào binary. Mỗi artifact xác nhận endpoint/config identity, application ID, signing identity và store destination; không patch config sau build. Có thể promotion cùng artifact giữa các track chỉ trong cùng environment nếu store hỗ trợ. Workflow/store capability **cần xác minh**.

Production promotion cần release approver, checklist hoàn tất, version/build duy nhất, toàn bộ CI gates xanh, artifact checksum khớp candidate, signing/profile hợp lệ, store privacy metadata/notes đúng và kế hoạch theo dõi sau phát hành. Store account, app identifiers, vùng phát hành, review lead time và approver cụ thể **cần xác minh**.

## 8. Rollout, theo dõi và rollback

- Ưu tiên staged rollout/store phased release nếu store hỗ trợ; bắt đầu theo phần trăm nhỏ rồi mở rộng sau khi đạt cửa sổ quan sát. Phần trăm, thời lượng mỗi bước, error threshold, nguồn metric, dashboard, on-call owner và giờ phát hành **cần xác minh** với product/operations trước release đầu.
- `CrashReporter` v1 là Noop nên không có client crash-free/fatal-crash telemetry từ app. Trước release phải chỉ rõ nguồn theo dõi được duyệt (store/platform diagnostics, backend availability/error metrics hoặc kiểm tra vận hành thủ công); nếu không có crash metric, không đặt rollout gate dựa trên crash-rate. Theo dõi startup/login/API availability và version/build chỉ qua nguồn đã duyệt, không thêm SDK/analytics hoặc payload người dùng theo mặc định.
- Khi vượt ngưỡng đã phê duyệt hoặc có sự cố bảo mật/data loss: dừng hoặc pause rollout, ghi nhận version/build/commit và phạm vi ảnh hưởng, thông báo owner theo incident process, rồi chọn rollback action phù hợp. Mobile store thường không thay thế ngay binary đã cài; rollback thực tế là dừng rollout và phát hành build mới với version/build cao hơn, hoặc tắt/điều chỉnh server-side capability nếu đã có cơ chế tương thích. Không giả định có remote kill switch hay server feature flag trong core v1.
- Trước phát hành, kiểm tra backward compatibility API và dữ liệu local: binary cũ có thể tiếp tục gọi backend; migration không được phá dữ liệu của bản cũ; offline queue/cache không tự xóa khi rollback. Offline Phase 2 contract, migration behavior và cache retention phải theo `offline-first.md`.
- Roll-forward/hotfix cần cùng test/toolchain/signing gates, tăng build number và lưu liên kết incident → candidate → store release. Chỉ store/platform owner được quyền dừng rollout hoặc gửi bản hotfix theo quyền hạn đã xác minh.

## 9. Release checklist

### Trước candidate

- [ ] Spec/toolchain decision đã duyệt; Flutter `3.47.8`/Dart `3.13.7` và native pins khớp CI runner.
- [ ] Lockfile enforce được; codegen không tạo diff hoặc file untracked.
- [ ] Format, analyze, slang analyze và `flutter test` đều qua; platform release validation qua theo `05-verification-and-release.md`.
- [ ] App config đúng environment; prod `ENABLE_LOGGING=false`; binary không chứa secrets; cleartext traffic bị chặn.
- [ ] Android/iOS identifiers, display name, version và build number đúng; build number chưa dùng trên store.
- [ ] Signing certificate/key/profile còn hiệu lực, đúng app/team/store, secret access được audit; symbolication files được lưu riêng và hạn chế quyền.
- [ ] Crash/privacy behavior, permissions, store privacy disclosures, support URL/release notes và localization/store metadata đã được owner xác nhận.

### Trước production promotion

- [ ] Candidate là artifact đã qua staging/internal smoke check; checksum và commit/toolchain metadata khớp.
- [ ] Approver chấp thuận; rollout step, stop criteria, dashboard, on-call contact và rollback/roll-forward owner đã điền.
- [ ] Backend/API tương thích; migration và offline behavior không làm mất dữ liệu hoặc pending work.
- [ ] Upload/promotion nhắm đúng production track/region; xác nhận store processing/review hoàn tất.

### Sau phát hành

- [ ] Xác nhận bản production hiển thị và cài được trên store; kiểm tra startup/login cơ bản trên thiết bị hỗ trợ.
- [ ] Quan sát crash/API/startup metrics trong cửa sổ đã duyệt; ghi quyết định tiếp tục rollout, pause hoặc hotfix.
- [ ] Lưu release evidence: commit, tag, version/build, checks, artifact checksum, toolchain, approver, rollout timestamps và incident/link nếu có.
- [ ] Thu hồi credential/job material tạm; rà audit access và tạo follow-up cho pin/secret expiry hoặc sự cố phát sinh.

