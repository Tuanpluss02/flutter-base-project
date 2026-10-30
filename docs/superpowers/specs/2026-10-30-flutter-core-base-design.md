# Flutter Core Base — Spec Index

Ngày: 2026-10-30 (rev6 — tích hợp phản biện reviewer 2)  
Trạng thái: bộ spec tích hợp đang chờ hai reviewer approve cùng một revision. Chưa bắt đầu implementation.

Bộ spec được tách theo chủ đề để mỗi phần có phạm vi đọc và review rõ ràng. Nội dung kỹ thuật đã chốt được giữ trong các tài liệu bên dưới.

| Tài liệu | Phạm vi |
|---|---|
| [01 — Scope, toolchain và architecture](2026-10-30-flutter-core-base/01-scope-toolchain-architecture.md) | Mục tiêu, dependencies, toolchain, layering và composition boundaries |
| [02 — App runtime](2026-10-30-flutter-core-base/02-app-runtime.md) | Config, bootstrap, DI, router, state, paging và data flow |
| [03 — Network và error handling](2026-10-30-flutter-core-base/03-network-and-errors.md) | Dio/Retrofit, auth refresh, retry, cancellation, Result và failures |
| [04 — Storage và shared UI](2026-10-30-flutter-core-base/04-storage-and-shared-ui.md) | Token/preferences storage, logging, i18n và theme |
| [05 — Testing và release](2026-10-30-flutter-core-base/05-verification-and-release.md) | Test matrix, CI, môi trường, quyết định và pre-scaffold checklist |
| [Offline-first data](2026-10-30-flutter-core-base/offline-first.md) | Local database, repository read path, outbox, sync, conflict, account scope và security (Phase 2) |
| [API contract](2026-10-30-flutter-core-base/api-contract.md) | REST boundary, pagination/204, error mapping, auth và backend prerequisites cho sync |
| [Security và privacy](2026-10-30-flutter-core-base/security-privacy.md) | Phân loại dữ liệu, secrets, token, logging, retention và privacy gates |
| [Feature workflow](2026-10-30-flutter-core-base/feature-workflow.md) | Quy trình, layer ownership, đăng ký route/DI, codegen và Definition of Done |
| [Accessibility và UI acceptance](2026-10-30-flutter-core-base/accessibility-ui.md) | Semantics, focus, scaling, contrast và hành vi trạng thái UI |
| [Release và operations](2026-10-30-flutter-core-base/release-operations.md) | Signing, versioning, CI artifact, promotion, rollout/rollback |

## Cổng trước scaffold

Chỉ bắt đầu scaffold sau khi hai reviewer approve cùng một revision và dependency-only fixture resolve bằng đúng FVM/Flutter pin: chạy `flutter pub get` để tạo lockfile, rồi chạy lại `flutter pub get --enforce-lockfile` thành công. Nếu reviewer còn blocker, cập nhật spec và review lại; nếu solver fail, cập nhật dependency matrix trước khi viết app code. Không bắt đầu implementation/code trước hai gate này.

## Offline-first

Offline-first là module Phase 2, không thuộc scaffold v1. Bản Phase 2 riêng trước đây đã được hai reviewer đồng thuận; revision tích hợp hiện tại đang chờ cả hai review lại. Các cổng DB/backend/security trước implementation được liệt kê tại [Offline-first data](2026-10-30-flutter-core-base/offline-first.md).


## Kế hoạch triển khai

- [Flutter Core Base — Workstream plan](../plans/2026-10-30-flutter-core-base-workstreams.md) mô tả 5 workstream, phụ thuộc và gate trước khi bắt đầu code.
- [Flutter Core Base — Implementation plan](../plans/2026-10-31-flutter-core-base-implementation.md) mô tả chi tiết từng task, execution model với Orca và acceptance criteria.
