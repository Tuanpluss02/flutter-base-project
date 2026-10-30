# Flutter Core Base — Scope, Toolchain và Architecture

Ngày: 2026-10-30 (rev6 — tích hợp phản biện reviewer 2)  
Trạng thái: bộ spec tích hợp đang chờ cả hai reviewer duyệt cùng revision; chưa bắt đầu implementation

Điều hướng: [Index](../2026-10-30-flutter-core-base-design.md) · [App runtime](02-app-runtime.md), [Network và errors](03-network-and-errors.md)

## 1. Mục tiêu và phi mục tiêu

Mục tiêu:
- Khởi tạo app mẫu trong dưới 30 phút từ checkout sạch: hiển thị native launch screen, login dummy, home và settings.
- Có một cách chuẩn cho network, lỗi, routing, state, DI, i18n và cấu hình.
- Thêm feature mà không sửa `lib/src/core/`; cho phép đăng ký feature ở composition root `lib/src/app/`.
- Đổi môi trường chỉ bằng file cấu hình build; không sửa Dart code.
- Giữ module Firebase, push, socket, media, QR và eKYC ngoài base.

Phi mục tiêu:
- Không có auth thật, booking, payment, PDF, calendar, video hoặc nghiệp vụ BDS.
- Không có Design System hoàn chỉnh; chỉ theme slot và widget nền.
- Không có monorepo nhiều packages trong v1.
- Không hỗ trợ deep link native trong v1.

Thành công khi:
- Một lockfile giải được với toolchain đã pin và CI enforce lockfile.
- Scaffold mẫu qua dependency resolution, codegen, analyze, test và release build.
- Feature mới có thể được đăng ký ở `src/app/` mà không thay đổi `src/core/`.
- Dev/stg/prod dùng file config tương ứng; prod tắt info/debug/request diagnostics (`ENABLE_LOGGING=false`), chỉ cho warning/error đã redact qua console.

## 2. Toolchain và dependencies

### 2.1 Toolchain

- Flutter stable `3.47.8`, Dart `3.13.7`; pin Flutter bằng FVM `.fvmrc`.
- Không yêu cầu `flutter upgrade`. Dev và CI cài đúng version từ `.fvmrc`.
- SDK constraint trong `pubspec.yaml`: `>=3.13.0 <4.0.0`.
- Không dùng từ “latest” trong dependency policy. Direct dependencies và generators phải có version constraint cụ thể; `pubspec.lock` được commit và là nguồn chính xác cho resolved graph.
- V1 target Android và iOS. Native toolchain (JDK, Gradle/AGP, Kotlin, Android minSdk, Xcode, CocoaPods, iOS deployment target) phải được pin trong tài liệu scaffold trước khi build platform; chưa định nghĩa ở spec này thì không mở rộng target sang platform khác.

### 2.2 Runtime dependencies

Các version dưới đây là baseline đã đối chiếu metadata pub.dev ngày 2026-10-30. Khi tạo scaffold, constraints và lockfile phải cùng giải được với codegen matrix §2.3; solver failure là chốt dừng, không tự nâng/lùi version.

| Package | Version |
|---|---:|
| `flutter_bloc` | `9.1.1` |
| `bloc` | `9.2.1` |
| `bloc_concurrency` | `0.3.0` |
| `get_it` | `9.3.0` |
| `injectable` | `3.0.0` |
| `dio` | `5.11.1` |
| `retrofit` | `4.10.0` |
| `auto_route` | `11.2.0` |
| `freezed_annotation` | `3.1.0` |
| `json_annotation` | `4.12.0` |
| `slang` / `slang_flutter` | `4.19.2` / `4.19.0` |
| `logger` | `2.8.0` |
| `flutter_secure_storage` | `11.2.0` |
| `shared_preferences` | `2.5.6` |
| `collection`, `intl`, `uuid`, `crypto`, `url_launcher` | `1.19.1`, `0.20.3`, `4.6.0`, `3.0.8`, `6.3.3` |
| `cached_network_image`, `flutter_cache_manager`, `flutter_svg`, `rive` | `4.0.6`, `3.4.6`, `2.3.2`, `0.14.11` |
| `permission_handler`, `device_info_plus`, `package_info_plus` | `13.0.2`, `13.3.0`, `10.2.2` |

Optional media/device packages stay unused unless a sample feature needs them. Không thêm package ngoài stack này nếu chưa có quyết định spec.

### 2.3 Dev dependencies và solver gate

Code generation matrix được chọn để analyzer constraints giao nhau:

| Package | Version / constraint |
|---|---:|
| `freezed` | exact `4.0.1` |
| `build_runner` | exact `2.16.1` |
| `auto_route_generator` | exact `10.6.0` |
| `analyzer` | resolved trong `>=13.3.0 <14.0.0` |
| `json_serializable` | exact `6.15.2` |
| `retrofit_generator` | exact `10.3.2` |
| `injectable_generator` | exact `3.1.3` |
| `slang_build_runner` | exact `4.19.0` |
| `flutter_gen_runner` | exact `5.15.0` |
| `flutter_launcher_icons` | exact `0.14.4` |
| `flutter_lints` | exact `6.0.0` |

`freezed 4.0.1` phải pin exact; không dùng caret vì `4.0.2+` yêu cầu analyzer 14. `auto_route_generator 10.6.0` cần analyzer <14, còn `build_runner 2.16.1` cần analyzer >=13.3. Bỏ khuyến nghị `custom_lint` + `freezed_lint` vì analyzer constraints của chúng không tương thích matrix này.

Trước khi tạo source scaffold, tạo dependency-only fixture tạm ngoài repo (chỉ `pubspec.yaml`, không có app source), chạy `flutter pub get` bằng đúng Flutter/FVM version để tạo lockfile; sau đó chạy lại `flutter pub get --enforce-lockfile` để xác nhận lockfile giải đúng. Lưu lockfile và kết quả vào tài liệu scaffold. Nếu một trong hai bước fail, dừng và sửa version matrix trong spec trước khi viết app code. CI scaffold dùng lockfile đã commit và chạy `flutter pub get --enforce-lockfile`; CI cũng kiểm tra codegen không làm thay đổi generated files đã commit.

Các package loại khỏi v1: `centrifuge, vnpay_ekyc, vietqr, syncfusion_pdfviewer, calendar_view, timeline_tile, video_player, better_player_plus, audio_session, flutter_volume_controller, photo_view, webview_flutter, flutter_widget_from_html, html, pull_to_refresh_flutter3, two_dimensional_scrollables, flutter_screenutil, dotted_line, screenshot, image_gallery_saver_plus, share_plus, image_picker, image, path_provider, ntp, smooth_sheets, event_bus, rxdart, interceptly*, protobuf override`.

## 3. Kiến trúc

```
lib/
  main.dart
  src/
    app/
      bootstrap.dart
      app.dart
      app_router.dart
      injection.dart
    core/
      config/
        app_config.dart    # AppConfig immutable type
      di/
      network/
      error/
      router/              # guard/observer abstractions; không import feature
      logging/
      storage/
      utils/
    shared/
      domain/               # entity dùng chung giữa features
      widgets/
      theme/
    l10n/
    features/
      _template/
      auth_placeholder/
      home/
      settings/
```

Nguyên tắc:
- `core/` không import `features/`; không chứa route table hoặc đăng ký dependency của feature.
- Composition root ở `app/` có thể import feature để đăng ký route, guard và dependency. Đây là nơi thay đổi khi thêm feature.
- Feature phụ thuộc vào core và shared; feature không import feature khác. Domain object dùng chung phải được đặt ở `shared/domain/`, không đưa vào core.
- Không static global mutable. `AppConfig` immutable và được inject. Type/validation của `AppConfig` thuộc `core/config/`; `app/` chỉ đọc `String.fromEnvironment`, tạo instance khi bootstrap và đăng ký DI. `core/` không import từ `app/`.
- UI không gọi Dio, SharedPreferences hay Firebase trực tiếp.
- Mỗi feature tự chứa `data/domain/presentation`; DTO/Entity không gom toàn cục.

Khác biệt với code cũ: không dùng FlavorConfig static, file env Dart rời, bad-certificate bypass, EventBus loading, layer-first folder, ScreenUtil hoặc font family hardcode.
