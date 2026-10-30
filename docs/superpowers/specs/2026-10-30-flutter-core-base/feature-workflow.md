# Flutter Core Base — Feature Workflow

Ngày: 2026-10-30 (thuộc bộ spec tích hợp rev6)  
Trạng thái: draft để review; theo architecture v1, chưa bắt đầu scaffold hoặc code

Điều hướng: [Index](../2026-10-30-flutter-core-base-design.md) · [Foundation](01-scope-toolchain-architecture.md), [App runtime](02-app-runtime.md), [Storage và shared UI](04-storage-and-shared-ui.md), [Verification](05-verification-and-release.md), [Offline-first data](offline-first.md)

## 1. Mục đích và quy tắc sở hữu

Feature là đơn vị sở hữu một năng lực UI/nghiệp vụ có thể được thêm hoặc gỡ khỏi app qua composition root. Feature code tự chứa data, domain và presentation; `core/` chỉ cung cấp hợp đồng và hạ tầng dùng chung, không biết feature nào đang được cài.

- Feature chỉ phụ thuộc `core/` và `shared/`; không import feature khác.
- `core/` không import feature và không nhận route, binding, model hay điều kiện riêng của feature.
- Thay đổi cần thiết để lắp feature thuộc `app/` composition root hoặc catalog i18n; không sửa `core/`.
- Trước khi tạo feature, tìm capability hiện có trong `core/` và `shared/`, cùng feature gần nhất để dùng lại đúng pattern.
- Tạo feature online-only mặc định. Chỉ dùng offline-first khi feature có policy được duyệt theo [Offline-first data](offline-first.md); không suy ra rằng mọi thao tác đều hỗ trợ offline.

## 2. Cấu trúc thư mục và layer contract

```text
lib/src/features/<feature_name>/
  feature_name.dart                 # public registration surface, nếu cần export
  data/
    datasources/                    # remote/local I/O adapters
    dto/                            # transport models
    mappers/                        # pure DTO ↔ domain mapping
    repositories/                   # repository implementations
  domain/
    entities/                       # feature-owned domain models
    repositories/                   # abstract contracts
    usecases/                       # one operation/policy per use case
  presentation/
    cubit/                          # Cubit and feature state
    pages/                          # route page widgets
    widgets/                        # feature-only UI
    routes/                         # AutoRoute declarations owned by feature
  <matching test tree under test/src/features/<feature_name>/>
```

Chỉ tạo các thư mục cần dùng; feature đơn giản không cần datasource hay abstraction rỗng. Tên `<feature_name>` dùng `snake_case`; tên type dùng `UpperCamelCase`. Cấu trúc trên là mặc định theo feature-first, không tạo `data/` hoặc `presentation/` toàn cục.

| Layer | Được phép phụ thuộc | Trách nhiệm và giới hạn |
|---|---|---|
| `presentation/` | Feature `domain/`, shared widgets/theme, core presentation contracts | Page phát lệnh qua Cubit; Cubit gọi UseCase qua constructor; ánh xạ `AppFailure` sang text bằng slang. Không truy cập Dio, plugin, SQL, DTO hoặc repository implementation. |
| `domain/` | Core domain contracts/types, `shared/domain/` | Entity, repository interface và use case. Không import Flutter, Dio, storage adapter, DTO hay presentation. Dùng `Result<T>`/`AppFailure` theo contract hiện tại. |
| `data/` | Feature `domain/`, core data/network/storage contracts, thư viện đã duyệt | I/O, DTO, mapper thuần, repository implementation và datasource. Adapter đổi lỗi dự kiến thành `Result`; không để exception hạ tầng hoặc DTO đi lên UI/domain. |
| Composition (`app/`) | Public registration của feature và core/app wiring | Gắn route, dependency và guard cần thiết. Không chứa logic nghiệp vụ của feature. |

Luồng mặc định: `Page → Cubit → UseCase → repository interface → repository implementation → datasource`. DTO được map thành entity trước khi tới domain. Cubit không gọi repository trực tiếp. Nếu use case chỉ forward `Result`, theo quy ước App Runtime hiện tại và không thêm lớp chỉ để chuyển tiếp.

### 2.1 Ranh giới domain dùng chung

- Entity thuộc một feature ở `features/<owner>/domain/`; không chuyển sang shared chỉ vì một feature khác muốn import nó.
- Chỉ đưa type vào `shared/domain/` khi đó là khái niệm sản phẩm thực sự dùng chung, có cùng semantics và lifecycle ở nhiều feature. Ghi rõ owner/meaning và nơi quản lý thay đổi trong review.
- `shared/domain/` không chứa DTO, repository implementation, API envelope, UI state hay tiện ích chung chung. Không dùng shared như cách né dependency giữa hai feature.
- Nếu hai feature cần khái niệm giống tên nhưng khác semantics, giữ hai entity riêng và map tại boundary. Nếu semantics thật sự chung nhưng model hiện tại thuộc feature, đổi ownership chỉ qua quyết định kiến trúc; không import chéo tạm thời.
- Core chứa abstraction kỹ thuật ổn định (ví dụ `AppFailure`, `Result`, storage/network interfaces), không chứa business entity.

## 3. Điểm đăng ký và thứ tự thêm feature

Các bước dưới đây giả định scaffold đã tạo composition root theo [App Runtime](02-app-runtime.md). Một feature mới không yêu cầu chỉnh `lib/src/core/`.

1. **Chốt contract và scope.** Xác định use case, owner của domain model, online-only hay offline policy, failure/empty/loading/cancel behavior và acceptance cases. Với offline-first, hoàn tất các prerequisite/backend contract trong offline spec trước khi enqueue mutation.
2. **Tạo skeleton feature.** Tạo đúng các layer cần thiết, public route/page, Cubit/state, use case, repository contract/implementation và datasource nếu cần. Giữ dependency một chiều theo bảng trên.
3. **Thêm route.** Khai báo page route trong feature `presentation/routes/`, áp dụng guard theo auth policy đã có, rồi nối route feature vào route collection/`AppRouter` aggregation tại `lib/src/app/`. Core route guard/observer được tái sử dụng; feature không thêm redirect owner thứ hai. Regenerate AutoRoute outputs theo generator đã pin.
4. **Thêm DI.** Đăng ký bindings feature-owned qua Injectable module/registration surface của feature; thêm module vào aggregator `configureDependencies()` tại `lib/src/app/injection.dart`. Use case/Cubit/repository/datasource lifetimes rõ ràng theo repo pattern; app composition tạo feature, core không dò hoặc tự đăng ký feature.
5. **Thêm localization.** Thêm key có namespace feature vào Slang source catalog `lib/src/l10n/strings.i18n.json` và locale tương ứng (`strings_vi.i18n.json`); regenerate theo cấu hình `slang.yaml`. UI chỉ gọi `context.t.*`; không hard-code user-facing string, không đặt câu dịch ở domain/data. Nếu feature chưa hỗ trợ locale khác, bổ sung bản dịch fallback có chủ đích theo chính sách catalog hiện hành.
6. **Thêm tests và fakes.** Đặt test mirror dưới `test/src/features/<feature_name>/`. Test mapper/use case/Cubit theo behavior, repository với fake datasource, widget/page states và route/DI registration ở mức phù hợp. Dùng in-memory storage/test doubles; không dùng network thật.
7. **Regenerate và kiểm tra boundary.** Chạy codegen, kiểm tra generated diff sạch, format/analyze/test và lệnh CI hiện có. Xác nhận core boundary scan không phát hiện import feature. Xác nhận app chỉ thay đổi ở composition/configuration points đã nêu.

Route, DI aggregator và locale catalog là điểm tích hợp tập trung được phép chỉnh khi feature được thêm. Không tạo global feature registry tự động, không sửa bootstrap/core để nhận biết feature, và không thêm dependency mới nếu chưa qua dependency/spec gate.

## 4. Code generation và artifact conventions

- Dùng đúng generator, version, annotation, `build.yaml` và options đã chốt trong Foundation/App Runtime. Không thêm generator hoặc builder config riêng trong feature trừ khi cần cho model cụ thể và được review.
- Freezed DTO dùng `fromJson` cùng `json_serializable`; entity chỉ bật serialization nếu có nhu cầu persistence/API rõ ràng. Mapper vẫn là hàm thuần, không giấu I/O trong generated converter.
- AutoRoute output chỉ sinh từ khai báo route; Injectable output chỉ sinh từ module/binding khai báo. Slang output chỉ sinh từ catalog và `slang.yaml`. Không chỉnh tay generated file.
- Generated files được commit theo policy scaffold. Sau generation, chạy lại generator và yêu cầu không có diff hoặc untracked generated artifact; CI kiểm tra điều này theo [Verification](05-verification-and-release.md).
- Dùng Dart pattern matching cho Freezed unions; không dùng `.when()`/`.map()` trong code mới theo App Runtime. Không sinh model generic envelope khi API contract chưa xác nhận.
- Nếu generator không hỗ trợ cấu trúc feature dự kiến, ghi blocker và cập nhật spec/tooling trước; không thêm workaround tùy tiện vào core.

## 5. Test ownership và trạng thái UI

Feature sở hữu tests cho behavior của chính nó; core tests chỉ kiểm chứng abstraction/hạ tầng. Mỗi requirement behavior có ít nhất một test tương ứng, đặc biệt cho mapper, failure policy, cancellation và navigation nếu feature có các behavior đó.

- **Cubit/use case:** success, typed failure, validation/empty data nếu áp dụng, cancellation không thành UI error và không emit sau close.
- **Repository/mapper:** DTO mapping, response edge case theo API contract, lỗi hạ tầng thành failure; domain không phụ thuộc response shape.
- **Presentation:** loading, empty, populated, error/retry và offline/stale/pending/conflict nếu feature có contract tương ứng; localized labels và semantics được kiểm tra theo UI spec.
- **Route/DI:** route được discover/resolve, guard phù hợp và dependencies được construct từ app registration; test không cần khởi tạo service thật.
- **Offline-first:** transaction, DataScope isolation, outbox/idempotency/conflict cases theo offline spec; không áp checklist này cho feature online-only.

Test doubles đặt cạnh feature tests hoặc trong helper test-only phù hợp. Không thêm production fake, global test registry hay feature-specific test hook vào core.

## 6. Definition of Done

Một feature hoàn tất khi tất cả điều kiện áp dụng dưới đây được thỏa mãn:

- [ ] Phạm vi, owner, data flow, online/offline policy, failure behavior và acceptance cases được mô tả.
- [ ] Source nằm trong `features/<feature_name>/`; chỉ có layer/thư mục cần dùng và dependency direction đúng contract.
- [ ] Không có import giữa features; không có business model/route/DI registration trong core; không có I/O trong UI/domain.
- [ ] Route và guard đã được nối tại `src/app/`; feature có thể đăng ký mà không đổi `src/core/`.
- [ ] DI bindings được đăng ký qua app composition; constructor dependencies và lifecycle được kiểm chứng.
- [ ] Mọi user-facing string có key trong Slang catalog cho locale được hỗ trợ; generated localization đã cập nhật.
- [ ] DTO/mapper/repository/use case/Cubit/page tests phù hợp với behavior; loading, empty, error, retry, cancel và offline states được bao phủ khi áp dụng.
- [ ] Codegen chạy thành công; không sửa generated artifact bằng tay và lần chạy kế tiếp không tạo diff.
- [ ] Format, `flutter analyze --fatal-infos --fatal-warnings`, `slang analyze --full --exit-if-changed` và `flutter test` qua theo lệnh chuẩn của repo; offline feature chạy thêm contract tests tương ứng.
- [ ] `core/` feature-import boundary check qua; config/logging không lộ token, PII hoặc payload.
- [ ] Mọi file ngoài feature đều thuộc route/DI/catalog/test aggregation cần thiết; không có source core hoặc dependency change cho riêng feature.

## 7. Checklist khởi tạo feature

Copy checklist này vào pull request/implementation task khi scaffold đã tồn tại:

```text
Feature: <feature_name>
Owner: <team/person>
Mode: online-only | offline-first (link approved policy)
Routes: <route names and auth policy>
Shared domain types: <none or type + shared meaning/owner>
Localization namespace: <feature key prefix>
Acceptance cases: <links or test names>

[ ] Confirmed no existing core/shared capability or feature to reuse
[ ] Created only required feature-first layers
[ ] Kept DTO/entity/UI state ownership within the correct layer
[ ] Added route declaration and app route aggregation
[ ] Added Injectable bindings and app DI aggregation
[ ] Added locale keys/translations and regenerated Slang output
[ ] Added behavior tests and required failure/state cases
[ ] Ran generators; generated diff is clean
[ ] Ran format, analyze, localization analysis, and feature/full tests
[ ] Confirmed feature can be composed without edits to src/core/
[ ] Reviewed privacy, logs, accessibility, and offline policy where applicable
```

## 8. Open decisions

This workflow assumes the scaffold exposes a stable feature route collection and Injectable registration aggregation from `src/app/`. If the generated AutoRoute or Injectable APIs differ from that shape, update this document after the dependency-only fixture/scaffold establishes the concrete API; do not invent a core hook. Feature-specific persistence package, offline database registration, and background sync remain governed by the separate offline-first spike and approval gates.
