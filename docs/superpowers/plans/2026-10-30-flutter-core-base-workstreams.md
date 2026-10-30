# Flutter Core Base — Workstream plan

Ngày: 2026-10-30 (phối hợp bộ spec tích hợp rev6)  
Trạng thái: 5 workstream docs đã có draft; đang chờ review tích hợp; docs/spec only; chưa bắt đầu scaffold hoặc code

## Mục tiêu

Hoàn thiện các quyết định và tài liệu cần thiết để triển khai toàn bộ Flutter Core Base theo spec đã thống nhất, bao gồm core v1 và module offline-first Phase 2. Repo hiện chưa có `pubspec.yaml` hoặc source Flutter; đây là kế hoạch chuẩn bị spec, không phải xác nhận implementation đã bắt đầu.

## Quy tắc phối hợp

- Năm workstream có file sở hữu riêng; không chỉnh cùng một file song song.
- Mỗi workstream hoàn thành spec, acceptance criteria và danh sách quyết định còn mở; không viết source code hoặc thêm dependency vào repo.
- API/backend, security, scope dữ liệu và module ownership là hợp đồng dùng chung. Mâu thuẫn liên workstream được lead tổng hợp trước khi reviewer kết luận.
- Hai reviewer đọc toàn bộ bộ spec đã tích hợp độc lập: reviewer A tập trung kiến trúc, API và tính nhất quán; reviewer B tập trung security/privacy, failure modes, accessibility và release readiness.
- Bắt đầu code chỉ sau khi mọi blocker đã được xử lý, hai reviewer đồng thuận, và các gate kỹ thuật ở spec qua.

## Workstreams

| ID | Owner | Phạm vi | Tài liệu đầu ra | Ranh giới |
|---|---|---|---|---|
| WS1 | Agent 1 | API contract: request/response, DTO mapping, pagination, errors, auth/session behavior, idempotency/versioning prerequisites cho offline sync | `specs/2026-10-30-flutter-core-base/api-contract.md` | Không giả định endpoint nghiệp vụ hoặc khả năng backend chưa xác nhận; đánh dấu contract cần backend quyết định |
| WS2 | Agent 2 | Security và privacy: data classification, secrets, token, PII/logging/crash context, storage/backup/retention, account switching/logout, offline data encryption gates | `specs/2026-10-30-flutter-core-base/security-privacy.md` | Đồng bộ với SecureStorage, Offline-first và API contract; không chọn encryption package khi chưa spike |
| WS3 | Agent 3 | Quy trình thêm feature: folder/layer contract, route/DI registration, shared domain boundary, codegen/migration registration, feature template và Definition of Done | `specs/2026-10-30-flutter-core-base/feature-workflow.md` | Tuân theo architecture hiện tại; không đề xuất core edits cho mỗi feature |
| WS4 | Agent 4 | Accessibility và UI behavior: semantics, focus, text scaling, contrast, responsive, loading/empty/error/offline/conflict states và interaction requirements | `specs/2026-10-30-flutter-core-base/accessibility-ui.md` | Giữ tương thích Material 3/theme; không biến thành visual redesign hoặc design system mới |
| WS5 | Agent 5 | Release và operations: Android/iOS build prerequisites, signing/secrets boundaries, versioning, CI/CD stages, crash/diagnostics, rollout/rollback và release checklist | `specs/2026-10-30-flutter-core-base/release-operations.md` | Bổ sung cho verification/release hiện có; native platform versions và credentials cần đánh dấu nếu chưa được xác minh |

## Thứ tự và phụ thuộc

1. Lead khóa terminology chung: feature, account/tenant `DataScope`, API failure vs sync conflict, và online-only vs offline-first.
2. WS1 và WS2 chạy song song; WS3–WS5 cũng có thể soạn độc lập nhưng phải liên kết tới hợp đồng chung thay vì định nghĩa lại.
3. Lead rà chéo các tài liệu, cập nhật index và các quyết định hiện tại trong 01–05/offline-first cho nhất quán.
4. Reviewer A và B review cùng một revision đã tích hợp, không review bản nháp rời rạc.
5. Mọi blocker được sửa trong docs rồi gửi lại reviewer. Không mở scaffold/code cho tới khi cả hai duyệt.

## Gate trước implementation

- Dependency-only fixture giải được đúng Flutter/Dart pin: `flutter pub get` tạo lockfile, lần chạy tiếp theo với `flutter pub get --enforce-lockfile` qua.
- API contract, security/privacy baseline, feature ownership, accessibility acceptance và release/CI responsibilities được chốt.
- Backend-specific offline prerequisites được xác nhận; nếu chưa có, offline Phase 2 chỉ cache S0/S1 đã khử định danh hoặc giữ non-sensitive draft trong memory; không persist S2/S3 trước security gates và không enqueue business mutation.
- Android/iOS native toolchain và CI release prerequisites được pin hoặc platform được loại khỏi scope.
- Reviewer A và B đồng ý bộ spec tích hợp; checklist/test mapping được chuyển thành implementation plan.

## Ngoài phạm vi của lượt spec này

Không tạo source scaffold, không chỉnh dependency matrix, không tạo endpoint nghiệp vụ, không thêm database/encryption package, và không build/release app. Các việc đó bắt đầu ở implementation phase sau khi gates trên qua.
