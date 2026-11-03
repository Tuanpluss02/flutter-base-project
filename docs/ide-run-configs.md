# IDE run configurations

Repo này dùng ba env có sẵn trong `config/`:

| Env | File | App name |
|---|---|---|
| dev | `config/env_dev.env` | Base Dev |
| uat | `config/env_uat.env` | Base UAT |
| prod | `config/env_prod.env` | Base |

Mỗi env có Android product flavor và iOS scheme riêng. Luôn truyền `--flavor` cùng `--dart-define-from-file` của đúng env.

## VS Code

Mở repo root, sau đó chọn cấu hình trong Run and Debug:

- `Base Dev (debug|profile|release)`
- `Base UAT (debug|profile|release)`
- `Base Prod (debug|profile|release)`

Config nằm ở `.vscode/launch.json`.

## IntelliJ IDEA / Android Studio

Mở repo root (thư mục có `pubspec.yaml`), chọn một trong các cấu hình:

- `Base Dev`
- `Base UAT`
- `Base Prod`

Config nằm trong `.run/`. Flutter plugin của JetBrains không lưu mode trong từng run config; chọn mode bằng nút **Run**, **Debug** hoặc **Profile** trên toolbar.

## Xcode

Mở `ios/Runner.xcworkspace`, chọn scheme:

- `dev` — Run dùng Debug, Profile dùng Profile, Archive dùng Release
- `uat` — tương tự
- `prod` — tương tự

Mỗi scheme chọn build configuration riêng cho bundle ID và tên app native. Scheme cũng chạy pre-action `scripts/ios_apply_dart_defines.sh <env>` để áp dụng Dart defines khi build trực tiếp trong Xcode.

Lần đầu trên checkout mới, chạy một lần để tạo `Generated.xcconfig`:

```bash
fvm flutter build ios --config-only --flavor dev --dart-define-from-file=config/env_dev.env
```

`Generated.xcconfig` là file generated và đã bị gitignore. Khi chạy `flutter run/build` từ terminal, Flutter tự ghi `DART_DEFINES` theo tham số CLI. Vì vậy luôn truyền cả `--flavor <env>` và `--dart-define-from-file=config/env_<env>.env` (như trong Makefile và các config IDE).

Pre-action của Xcode ghi Dart defines vào một file generated dùng chung. Khi build trực tiếp trong Xcode, chỉ chạy một scheme tại một thời điểm để tránh env này ghi đè defines của env khác.

## Ghi chú

- Bundle ID: `com.stormx.base.dev`, `com.stormx.base.uat`, `com.stormx.base`.
- Có thể cài ba bản song song vì mỗi flavor có bundle ID riêng.
