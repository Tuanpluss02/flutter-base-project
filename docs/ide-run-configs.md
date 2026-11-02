# IDE run configurations

Repo này dùng ba env có sẵn trong `config/`:

| Env | File | App name |
|---|---|---|
| dev | `config/env_dev.env` | Pristie Dev |
| stg | `config/env_stg.env` | Pristie Staging |
| prod | `config/env_prod.env` | Pristie |

Flavor ở đây là **env qua `--dart-define-from-file`**, không phải native Android product flavor hay iOS build configuration. Bundle id và app name native không đổi theo env.

## VS Code

Mở repo root, sau đó chọn cấu hình trong Run and Debug:

- `Pristie Dev (debug|profile|release)`
- `Pristie Staging (debug|profile|release)`
- `Pristie Prod (debug|profile|release)`

Config nằm ở `.vscode/launch.json`.

## IntelliJ IDEA / Android Studio

Mở repo root (thư mục có `pubspec.yaml`), chọn một trong các cấu hình:

- `Pristie Dev`
- `Pristie Staging`
- `Pristie Prod`

Config nằm trong `.run/`. Flutter plugin của JetBrains không lưu mode trong từng run config; chọn mode bằng nút **Run**, **Debug** hoặc **Profile** trên toolbar.

## Xcode

Mở `ios/Runner.xcworkspace`, chọn scheme:

- `dev` — Run dùng Debug, Profile dùng Profile, Archive dùng Release
- `stg` — tương tự
- `prod` — tương tự

Mỗi scheme chạy pre-action `scripts/ios_apply_dart_defines.sh <env>`, script đọc `config/env_<env>.env` và ghi `DART_DEFINES` vào `ios/Flutter/Generated.xcconfig` trước khi build. Vì vậy áp dụng được cả khi chạy trực tiếp từ Xcode.

Lần đầu trên checkout mới, chạy một lần để tạo `Generated.xcconfig`:

```bash
fvm flutter build ios --config-only
```

`Generated.xcconfig` là file generated và đã bị gitignore. Khi chạy `flutter run/build` từ terminal, Flutter tự ghi đè `DART_DEFINES` theo tham số CLI; pre-action chỉ dùng cho các scheme Xcode ở trên. Vì vậy khi chạy CLI, luôn truyền `--dart-define-from-file=config/env_<env>.env` (như trong Makefile và các config IDE), không dựa vào scheme pre-action.

## Ghi chú

- Không dùng `--flavor` trên Android vì project chưa khai báo `productFlavors`.
- Scheme `dev|stg|prod` của Xcode chỉ là alias env, không tạo thêm iOS build configuration hay đổi bundle id.
- Nếu cần native flavor thật (bundle id/app name riêng, build configuration riêng), đó là thay đổi riêng và cần cập nhật Android Gradle + Xcode project.
