# Flutter Core Base — Generic API Contract và Backend Prerequisites

Ngày: 2026-10-30 (rev6 — tích hợp phản biện reviewer 2)  
Trạng thái: bộ spec tích hợp đang chờ cả hai reviewer duyệt cùng revision; chưa bắt đầu implementation
Điều hướng: [Index](../2026-10-30-flutter-core-base-design.md) · [Scope và Architecture](01-scope-toolchain-architecture.md), [App runtime](02-app-runtime.md), [Network và errors](03-network-and-errors.md), [Storage](04-storage-and-shared-ui.md), [Verification](05-verification-and-release.md), [Offline-first data](offline-first.md)

---

## 1. Mục tiêu và phạm vi

Tài liệu này xác định **chuẩn giao tiếp HTTP generic**, ranh giới dữ liệu giữa tầng Network và Domain/Presentation, cùng các **điều kiện tiên quyết hạ tầng phía backend (Backend Prerequisites)** để client Flutter vận hành ổn định, an toàn và có thể mở rộng lên offline-first.

### 1.1 Nguyên tắc thiết kế
- **Generic & Protocol-level**: Không định nghĩa endpoint nghiệp vụ cụ thể (như bất động sản, tin đăng, hợp đồng, eKYC, thanh toán...). Mọi ví dụ và cấu trúc trong tài liệu chỉ sử dụng RESTful abstraction generic (`/api/v1/{resource}`, `/api/v1/auth/*`, `/api/v1/{dataset}/sync`).
- **Phân tách rõ ràng giữa v1 và Phase 2**:
  - **v1 Core Base**: Hợp đồng cho kết nối trực tuyến unary qua Dio/Retrofit, phân trang 1-based, ánh xạ lỗi có kiểu (typed error mapping), cơ chế refresh token đơn luồng (single-flight), ngân sách retry tối đa 1 lần cho GET/HEAD và hủy yêu cầu (cancellation).
  - **Phase 2 Offline-first**: Điều kiện tiên quyết backend phục vụ outbox mutation, optimistic concurrency qua version/ETag, phản hồi conflict có snapshot và delta synchronization qua cursor opaque.
- **Không rò rỉ hạ tầng vào Domain/UI**: Toàn bộ DTO, raw JSON, DioException, HTTP status codes và headers đều bị chặn tại ranh giới Repository; UI chỉ nhận Domain Entity và `Result<T>`.

---

## 2. Ranh giới DTO và Repository (DTO/Repository Boundary)

```text
[ Remote API ] 
      │ (JSON over HTTP)
      ▼
[ Retrofit Client / Dio ] ──> Trả về cụ thể: ResourceDto
      │
[ RepositoryImpl ]       ──> Gọi Pure Mapper: ResourceMapper.toEntity(dto)
      │                  ──> Bắt DioException, ánh xạ sang Result.err(AppFailure)
      ▼
[ Domain / UseCase ]     ──> Nhận Result.ok(ResourceEntity) hoặc Result.err(AppFailure)
      │
[ Cubit / UI ]           ──> Không thấy DTO, không thấy Dio, không thấy HTTP Status
```

### 2.1 Quy tắc DTO
1. **Bất biến và Code-generated**: Tất cả DTOs được khai báo bằng `@freezed` kết hợp `json_serializable` (với `fieldRename: FieldRename.snake`). DTO chỉ chứa dữ liệu thô từ transport, không chứa business logic.
2. **Khả năng chịu đựng sai lệch schema (Schema Drift Tolerance)**:
   - Các trường non-critical phải là nullable (`String?`, `int?`).
   - Mọi danh sách (`List<T>`) trong DTO phải có giá trị mặc định `@Default([]) List<T> items` để không bao giờ bị crash bởi `null` từ backend.
   - Enum phải có fallback cho giá trị chưa biết thông qua `@JsonEnum(unknownEnumValue: ResourceStatus.unknown)`.
3. **Không dùng chung DTO làm Entity**: DTO phản ánh schema của server JSON; Entity phản ánh ngôn ngữ nghiệp vụ của ứng dụng (Dart/Domain). Dù hai cấu trúc có thể tương đồng ở v1, việc tách biệt là bắt buộc để thay đổi phía API không làm vỡ Domain model.

### 2.2 Quy tắc Mapper
- Mapper là **pure function** độc lập (hoặc static extension/method trên DTO/Entity), không có side-effects, không phụ thuộc vào context, storage hay network.
- Parse theo schema đã xác nhận: parse timestamp ISO 8601 sang UTC và chuyển đổi kiểu có kiểm tra. Không tự tạo `DateTime.now()` hoặc version mặc định để lấp dữ liệu server bị thiếu; trường optional giữ null, trường bắt buộc thiếu/sai format trả `AppFailure.parse()`.
- Nếu server trả về thiếu trường bắt buộc của Entity mà không thể fallback an toàn, Mapper ném `FormatException` để Repository bắt và chuyển thành `AppFailure.parse()`.

### 2.3 Ví dụ minh họa DTO và Mapper

```dart
// lib/src/features/sample/data/models/item_dto.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_dto.freezed.dart';
part 'item_dto.g.dart';

@freezed
sealed class ItemDto with _$ItemDto {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ItemDto({
    required String id,
    required String title,
    String? description,
    @Default([]) List<String> tags,
    required String createdAt,
    int? version,
  }) = _ItemDto;

  factory ItemDto.fromJson(Map<String, dynamic> json) => _$ItemDtoFromJson(json);
}

// lib/src/features/sample/data/mappers/item_mapper.dart
extension ItemDtoMapper on ItemDto {
  ItemEntity toEntity() {
    return ItemEntity(
      id: id,
      title: title,
      description: description ?? '',
      tags: List.unmodifiable(tags),
      createdAt: DateTime.tryParse(createdAt)?.toUtc() ?? (throw const FormatException('Invalid createdAt')),
      version: version,
    );
  }
}
```

---

## 3. Phân trang và Hành vi Empty / 204 (Pagination & Empty/204 Semantics)

### 3.1 Hợp đồng phân trang generic (v1: 1-based Page & Limit)

Client sử dụng mô hình phân trang 1-based đồng nhất cho toàn bộ danh sách trực tuyến trong v1:
- **Request Query Parameters**:
  - `page`: Số nguyên dương, bắt đầu từ `1`.
  - `page_size`: Số nguyên dương, giới hạn bản ghi trên một trang (mặc định 20, max 100).
- **Phản hồi chuẩn từ Backend (Pagination Envelope)**:

```json
{
  "items": [
    { "id": "uuid-1", "title": "Item 1" },
    { "id": "uuid-2", "title": "Item 2" }
  ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total_items": 42,
    "total_pages": 3,
    "has_more": true
  }
}
```

```dart
@freezed
sealed class PagedResponseDto<T> with _$PagedResponseDto<T> {
  @JsonSerializable(genericArgumentFactories: true, fieldRename: FieldRename.snake)
  const factory PagedResponseDto({
    @Default([]) List<T> items,
    required PaginationMetaDto pagination,
  }) = _PagedResponseDto<T>;

  factory PagedResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PagedResponseDtoFromJson(json, fromJsonT);
}

@freezed
sealed class PaginationMetaDto with _$PaginationMetaDto {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory PaginationMetaDto({
    required int page,
    required int page_size,
    required int total_items,
    required int total_pages,
    required bool has_more,
  }) = _PaginationMetaDto;

  factory PaginationMetaDto.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaDtoFromJson(json);
}
```

### 3.2 Ma trận hành vi HTTP Status, Body và Client State

| Tình huống | HTTP Status | Server Body | Xử lý tại Retrofit/Mapper | Trạng thái PagedCubit |
|---|:---:|---|---|---|
| Query trang đầu có dữ liệu | `200 OK` | `{"items": [...], "pagination": {"has_more": true}}` | Parse danh sách DTO -> List Entity | `PagedState(items, hasMore: true)` |
| Query trang đầu rỗng | `200 OK` | `{"items": [], "pagination": {"has_more": false}}` | Parse danh sách rỗng `[]` | `PagedState(items: [], hasMore: false)` |
| Load-more trang cuối | `200 OK` | `{"items": [...], "pagination": {"has_more": false}}` | Nối vào items hiện tại | `PagedState(all, hasMore: false)` |
| Load-more quá số trang | `200 OK` | `{"items": [], "pagination": {"has_more": false}}` | Giữ nguyên items hiện tại | `PagedState(current, hasMore: false)` |
| Resource không tồn tại (`GET /item/{id}`) | `404 Not Found` | Error Envelope (`NOT_FOUND`) | Ném DioException(404) | Trả về `Result.err(NotFoundFailure())` |
| Mutation thành công không cần body | `204 No Content` | *Empty body* | Retrofit trả về `Future<void>` | `Result<void>` (Unit success; `Result.ok(null)` là implementation detail của Dart cho kiểu `void`, không đại diện null entity) |
| Mutation xóa resource | `204 No Content` hoặc `200 OK` | *Empty body* hoặc `{}` | Retrofit trả về `Future<void>` | `Result<void>` (Unit success; `Result.ok(null)` là implementation detail của Dart cho kiểu `void`, không đại diện null entity) |

### 3.3 Quy tắc quan trọng về Empty Body và 204 No Content
1. **Không trả 204 cho Collection Query**: `GET /api/v1/{resources}` không được trả về `204 No Content` khi không có bản ghi nào. Server bắt buộc trả về `200 OK` với mảng `items: []`. Trả 204 cho endpoint danh sách bị coi là vi phạm giao ước (client sẽ gặp lỗi phân tích phân trang).
2. **Mảng rỗng thay vì Null**: Backend tuyệt đối không trả về `"items": null`. Nếu tập dữ liệu rỗng, phải trả `"items": []`. Về phía client, Mapper phòng thủ bằng `@Default([]) List<T> items`.
3. **Xử lý 204 và ngữ nghĩa Result<void> (Unit Success Semantics)**:
   - Các mutation không trả về payload (trả `204 No Content` hoặc `200 OK` với body rỗng) tại tầng Repository/Domain trả về `Result<void>`, thể hiện ngữ nghĩa hoàn tất thao tác thành công (unit success), **tránh giả định hay trả về một business entity mang giá trị null (`Entity? = null`)**.
   - Trong Retrofit client, các endpoint kỳ vọng 204 hoặc rỗng phải được khai báo trả về `Future<void>` hoặc `Future<HttpResponse<void>>`.
   - Dio được cấu hình `validateStatus: (status) => status != null && status >= 200 && status < 300`, do đó status 204 được tính là thành công mà không kích hoạt JSON deserializer.
   - Về mặt kỹ thuật trong Dart, do kiểu `void` không có instance runtime riêng nên cú pháp `const Result.ok(null)` (hoặc biến thể unit tương đương) chỉ thuần túy là **chi tiết triển khai (implementation detail)** để thỏa mãn signature generic `Result<T>` với `T = void`, chứ tầng Domain/UI không xem đây là dữ liệu entity null.

---

## 4. Chuẩn hóa lỗi HTTP và Typed Error Mapping (Typed HTTP Error Mapping)

### 4.1 Định dạng Error Envelope khuyến nghị từ Backend (RFC 7807 target profile)

> **Lưu ý kiến trúc (Căn chỉnh với spec 03-network-and-errors)**:  
> Spec `03-network-and-errors.md` đã thống nhất **hoãn việc áp đặt một response envelope hoặc error envelope dùng chung (`ApiEnvelope<T>`)** cho toàn bộ backend trong v1. Vì vậy:
> - Cấu trúc error envelope kiểu RFC 7807 dưới đây được định nghĩa là **hồ sơ mục tiêu khuyến nghị (recommended target profile)** cho các API mới phát triển hoặc các backend thuộc diện kiểm soát trực tiếp (controlled APIs), **chứ không phải là yêu cầu bắt buộc phổ quát (universal requirement)** cho toàn bộ backend trong v1.
> - Các backend hiện hữu hoặc các dịch vụ có format legacy đã xác nhận sẽ được xử lý bằng các **endpoint adapters / mappers cụ thể** tại tầng Data của từng feature.
> - Parser generic dùng chung (`ApiEnvelope<T>` / shared error envelope converter) sẽ được hoãn lại, chờ xác nhận chính thức từ phía backend và một spike kỹ thuật độc lập (về custom converter, xử lý 204/empty body và error body) trước khi đưa vào Core Base.

Đối với các endpoint tuân thủ target profile chuẩn RFC 7807, phản hồi lỗi (HTTP 4xx và 5xx) nên trả về payload JSON có cấu trúc thống nhất:

```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "The request payload failed input validation.",
    "trace_id": "req_01hgb89z4v9q7c",
    "details": {
      "email": "Email format is invalid",
      "password": "Password must be at least 8 characters"
    }
  }
}
```

- `code`: Chuỗi định danh lỗi dạng máy đọc được (`SCREAMING_SNAKE_CASE`), ổn định qua các phiên bản API.
- `message`: Mô tả lỗi kỹ thuật/diagnostic phục vụ developer, **không dùng hiển thị trực tiếp cho người dùng cuối** (UI hiển thị thông qua slang l10n).
- `trace_id`: Mã định danh tương quan (correlation ID) phân tán để tra cứu log.
- `details`: Map tùy chọn chứa chi tiết lỗi từng trường (`field -> reason`), sử dụng cho lỗi validation (400 hoặc 422).

### 4.2 Ma trận ánh xạ HTTP Status sang `AppFailure`

`AppFailure` là Freezed closed union đã được chốt tại spec 03:
`network`, `timeout`, `cancelled`, `unauthorized`, `forbidden`, `notFound`, `conflict`, `validation`, `rateLimit`, `server`, `payloadTooLarge`, `parse`, `localPersistence`, `unknown`.

```text
HTTP / Transport Layer                        AppFailure (Closed Union)
┌───────────────────────────────────────┐    ┌──────────────────────────────────────────────┐
│ SocketException / ConnectionError     │───>│ AppFailure.network()                         │
│ Connect/Send/Receive Timeout          │───>│ AppFailure.timeout()                         │
│ CancelToken.cancel()                  │───>│ AppFailure.cancelled()                      │
│ 401 Unauthorized (sau auth refresh)  │───>│ AppFailure.unauthorized()                   │
│ 403 Forbidden                         │───>│ AppFailure.forbidden()                      │
│ 404 Not Found                         │───>│ AppFailure.notFound()                       │
│ 413 Payload Too Large / local bound  │───>│ AppFailure.payloadTooLarge()               │
│ 409 VERSION_MISMATCH / 412             │───>│ SyncSendOutcome.versionConflict            │
│ 409 REQUEST_IN_PROGRESS (same key)    │───>│ SyncSendOutcome.requestInProgress          │
│ 422 Unprocessable Entity              │───>│ AppFailure.validation(fields: Map)           │
│ 400 Bad Request (có details)          │───>│ AppFailure.validation(fields: Map)           │
│ 400 Bad Request (không details)       │───>│ AppFailure.server(400) hoặc unknown()        │
│ 429 Too Many Requests (Retry-After)   │───>│ AppFailure.rateLimit(retryAfter: Duration?) │
│ 500..599 Server Errors                │───>│ AppFailure.server(statusCode)                │
│ FormatException / TypeError           │───>│ AppFailure.parse()                          │
│ SecureStorage read/write/clear failure│───>│ AppFailure.localPersistence()               │
└───────────────────────────────────────┘    └──────────────────────────────────────────────┘
```

Chi tiết quy tắc mapping:
1. **Lỗi 400 và 422 (Validation)**:
   - Với endpoint tuân thủ target profile hoặc legacy adapter đã xác nhận, ánh xạ stable machine-readable field/code sang `Map<String, ValidationIssue>` trong `AppFailure.validation(fields)`.
   - Không đưa raw `message` hoặc raw `details` của server vào presentation. Unknown validation code map sang `ValidationIssue.invalid`; UI localization chọn nội dung từ Slang.
   - Nếu 400 không có code/field nhận diện được, map về `AppFailure.server(400)` hoặc `AppFailure.unknown()`; raw body chỉ được giữ tại diagnostic boundary đã redact, không log.
   - `409 REQUEST_IN_PROGRESS` của cùng idempotency key map thành `SyncSendOutcome.requestInProgress`; giữ operation `pending`, tôn trọng `Retry-After`/backoff và retry cùng operation/key.
   - Canonical version-conflict code là `VERSION_MISMATCH`; `412 Precondition Failed` với ETag mismatch cũng conflict. Cả hai map thành `SyncSendOutcome.versionConflict`, không phải `AppFailure.conflict()` và không đổi `SyncConflict` thành generic transport error. 409 code khác không được đoán là version conflict.
2. **Lỗi 429 Rate Limit**:
   - Interceptor đọc header `Retry-After`.
   - Nếu `Retry-After` là số giây (integer): chuyển thành `Duration(seconds: seconds)`.
   - Nếu `Retry-After` là HTTP Date (RFC 7231): tính khoảng thời gian chênh lệch so với thời gian hiện tại.
   - Nếu không có header: trả về `AppFailure.rateLimit(null)`.
3. **Bảo mật và Redaction**:
   - Body lỗi và headers được redact trước khi ghi log hoặc gửi CrashReporter. Tuyệt đối không đưa mật khẩu, token, thông tin PII từ `details` vào raw log.

---

## 5. Giao thức Auth và Quản lý Session (Auth & Session Protocol)

### 5.1 Transport Authorization
Mọi request cần xác thực phải mang header:
`Authorization: Bearer <access_token>`

### 5.2 Hợp đồng Refresh Token Endpoint
- **URL**: `POST /api/v1/auth/refresh` (generic endpoint).
- **Request**:
  - Không kèm `AuthInterceptor` (sử dụng Dedicated No-Auth Dio instance để tránh đệ quy).
  - Body:
    ```json
    {
      "refresh_token": "def50200..."
    }
    ```
- **Response thành công (`200 OK`)**:
  ```json
  {
    "access_token": "eyJhbGciOi...",
    "refresh_token": "def50200...",
    "token_type": "Bearer",
    "expires_in": 3600
  }
  ```
- **Yêu cầu xoay vòng Refresh Token (Token Rotation)**: Mỗi lần refresh thành công, server trả về một `refresh_token` mới; token cũ bị vô hiệu hóa ngay lập tức. Client ghi đè đồng thời cả cặp token vào SecureStorage.

### 5.3 Ma trận xử lý phản hồi từ Refresh Endpoint

| Mã trạng thái | Nguyên nhân | Hành vi Client | Trạng thái Session |
|---|---|---|---|
| `200 OK` | Refresh hợp lệ | Lưu session mới, tiếp tục các request đang chờ trong queue | Duy trì, cập nhật token |
| `400 Bad Request` | Refresh token sai format/thu hồi | Hủy queue; invalidation tăng epoch và khóa auth trước khi clear token | Clear thành công thì đưa về Login; clear lỗi thì giữ locked, trả `localPersistence` |
| `401 Unauthorized` | Refresh token hết hạn/không hợp lệ | Hủy queue; invalidation tăng epoch và khóa auth trước khi clear token | Clear thành công thì đưa về Login; clear lỗi thì giữ locked, trả `localPersistence` |
| `403 Forbidden` | Tài khoản bị khóa/thu hồi quyền | Hủy queue; invalidation tăng epoch và khóa auth trước khi clear token | Clear thành công thì đưa về Login; clear lỗi thì giữ locked, trả `localPersistence` |
| `429 Too Many Requests` | Quá giới hạn gọi refresh | Không logout, giữ nguyên session, trả `RateLimitFailure` cho caller | Duy trì session |
| `5xx` / Network Timeout | Server lỗi tạm thời/rớt mạng | Không logout, giữ nguyên session, trả lỗi hạ tầng tương ứng | Duy trì session |

### 5.4 Điều phối Single-Flight và Session Epoch

```text
Request A (GET)  ──[401]──┐
Request B (GET)  ──[401]──┼──> [ AuthCoordinator (Single-Flight Lock) ]
Request C (POST) ──[401]──┘         │
                                    ├──> Gửi 1 request: POST /api/v1/auth/refresh (Dedicated Dio)
                                    │         │
                                    │         ▼
                                    │    Server: 200 OK (Cặp token mới)
                                    │
                                    ├──> Cập nhật SecureStorage (Cặp token mới)
                                    ├──> Request A (GET): Gắn token mới, REPLAY (1 lần)
                                    ├──> Request B (GET): Gắn token mới, REPLAY (1 lần)
                                    └──> Request C (POST): KHÔNG REPLAY, trả lỗi 401 về caller
```

Quy tắc bắt buộc:
1. **Single-flight Refresh**: Khi nhiều request nhận 401 đồng thời, chỉ một network request duy nhất được gửi tới `/auth/refresh`. Các request khác đợi Future chung của lượt refresh đó.
2. **Session Epoch**: `sessionEpoch` là process-local monotonic counter; mỗi logout/invalidation tăng đúng một đơn vị và không reset trong process lifetime. Process restart tạo epoch mới trước session restore vì request/callback cũ không còn sống. Logout persist `SessionRecord.logoutPending`; `invalidateSession()` persist `sessionInvalidationPending` trước khi clear. Pending write lỗi thì thử clear session ngay và không báo operation thành công nếu cả hai lỗi. Refresh trả về dưới epoch cũ luôn bị discard.
3. **Chính sách Replay**:
   - Request gốc nhận 401 chỉ được tự động replay tối đa **1 lần duy nhất** sau khi refresh thành công, và **chỉ áp dụng cho request idempotent (GET hoặc HEAD)**.
   - Các mutation (POST, PUT, PATCH, DELETE) tuyệt đối **không tự động replay** sau khi refresh token để ngăn ngừa tạo trùng lặp giao dịch ngoài ý muốn; lỗi 401 được trả về cho UseCase/Cubit xử lý.

---

## 6. Hủy yêu cầu, Retry và Idempotency (Cancellation, Retry, and Idempotency)

### 6.1 Hủy yêu cầu (Cancellation Semantics)
- Mọi thao tác async và network request đều nhận một `CancelToken` thuộc sở hữu của Cubit hoặc scope thực thi.
- Khi Cubit bị `close()` hoặc người dùng rời màn hình, `CancelToken.cancel()` được gọi ngay lập tức.
- Dio ném `DioExceptionType.cancel`. Interceptor giữ nguyên trạng thái này.
- Tại tầng UI và Presentation, `CancelledFailure` **bị bỏ qua hoàn toàn** (silent): không hiển thị banner lỗi, không toast, không emit state sau close và không gửi báo cáo tới CrashReporter.

### 6.2 Ngân sách Retry nghiêm ngặt (Strict Client Retry Budget)
Để bảo vệ hạ tầng backend khỏi hiện tượng bão yêu cầu (retry storm):
1. **Quy tắc 1 lần duy nhất cho GET/HEAD**:
   - Chỉ tự động retry tối đa **1 lần** cho request GET/HEAD gặp lỗi tạm thời (`network` hoặc `timeout`).
   - Sử dụng exponential backoff có jitter (ví dụ: chờ 1s ± 200ms trước khi thử lại).
2. **Tính loại trừ của ngân sách follow-up**:
   - Một request GET/HEAD chỉ có ngân sách tối đa 1 follow-up: hoặc 1 lần retry do mạng/timeout, hoặc 1 lần replay sau refresh 401. Không bao giờ cộng dồn hai loại thử lại trên cùng một request.
3. **Cấm tự động retry tại transport layer cho**:
   - HTTP 4xx (400, 401, 403, 404, 409, 422...).
   - HTTP 5xx Server errors.
   - Lỗi parse dữ liệu (`FormatException`).
   - Yêu cầu đã bị hủy (`cancel`).
   - Toàn bộ mutation (POST, PUT, PATCH, DELETE): không retry ở tầng Dio.

### 6.3 Hợp đồng Idempotency cho Mutations (Mutation Idempotency Protocol)

Khi thực hiện mutation (đặc biệt trong Phase 2 Outbox Worker hoặc khi retry mutation trên tầng nghiệp vụ):
- **Request Header**:
  `Idempotency-Key: <UUIDv4>`
- **Yêu cầu đối với Backend**:
  1. **Khóa nhận diện**: Backend liên kết `Idempotency-Key` với bộ khóa: `{accountId, tenantId, HTTP method, endpoint path}`.
  2. **Xử lý yêu cầu đang xử lý (In-flight request)**: Nếu một request mang `Idempotency-Key` trùng lặp đến trong lúc request đầu tiên đang thực thi, server phải trả về `409 Conflict` (với code `REQUEST_IN_PROGRESS`) hoặc giữ kết nối chờ kết quả đầu tiên, không thực thi song song.
  3. **Lưu vết và Replay kết quả (Response Caching & Replay)**:
     - Khi request đầu tiên hoàn tất (thành công hoặc thất bại nghiệp vụ), backend lưu trạng thái phản hồi gốc: `{status_code, headers, body}`.
     - Khi request sau đến cùng `Idempotency-Key`, backend trả lại **chính xác phản hồi gốc** đã lưu mà không chạy lại logic nghiệp vụ.
  4. **Thời gian lưu giữ (Retention Window)**: Thời gian lưu giữ và đối soát trùng lặp `Idempotency-Key` trên backend **bắt buộc phải vượt quá thời hạn sống tối đa được phê duyệt của hàng đợi offline và cửa sổ retry thao tác** (maximum offline queue age / operation retry window). Giá trị thời gian lưu giữ cụ thể không giả định cố định ở 24 giờ mà là một **cổng quyết định backend/product (backend/product gate)** cần được phê duyệt và chốt SLA trước khi triển khai hàng đợi mutation trong Phase 2.

---

## 7. Điều kiện tiên quyết cho Đồng bộ Offline-First (Phase 2 Sync Prerequisites)

*Phần này quy định các chuẩn backend bắt buộc để kích hoạt Phase 2 Offline-First (spec `offline-first.md`). Nếu backend chưa đáp ứng các hợp đồng này, client chỉ cache dữ liệu S0/S1 đã khử định danh hoặc giữ draft không nhạy cảm ở memory; không persist S2/S3 và không enqueue mutation nghiệp vụ.*

### 7.1 Optimistic Concurrency & Versioning
Để phát hiện và xử lý xung đột ghi dữ liệu giữa nhiều thiết bị:
1. **Server Version / ETag**:
   - Mỗi bản ghi nghiệp vụ trên server phải có một thuộc tính `version` nguyên dương tăng đơn điệu (monotonic integer: 1, 2, 3...) hoặc header HTTP `ETag` mạnh (strong ETag).
2. **Conditional Update**:
   - Khi client gửi mutation cập nhật (PUT/PATCH/DELETE), client gửi kèm phiên bản cơ sở:
     - Qua header: `If-Match: "<ETag>"` hoặc
     - Trong payload JSON: `"base_version": 4`
3. **Hợp đồng phản hồi Xung đột (409 Conflict / 412 Precondition Failed)**:
   - Nếu dữ liệu trên server đã bị thay đổi bởi tác nhân khác (phiên bản hiện tại trên server > base_version của client), server từ chối ghi và trả về `HTTP 409 Conflict` (hoặc `412 Precondition Failed`).
   - Body phản hồi xung đột nên cung cấp snapshot hiện tại của server để client so sánh hoặc hiển thị UI giải quyết. Nếu API không trả snapshot, feature phải có GET resolver theo entity ID; nếu cả hai đều không khả dụng thì backend gate chưa qua và offline mutation không được enable:

```json
{
  "error": {
    "code": "VERSION_MISMATCH",
    "message": "Resource version mismatch. The resource has been updated elsewhere."
  },
  "conflict": {
    "base_version": 3,
    "server_version": 5,
    "server_record": {
      "id": "uuid-001",
      "title": "Updated Title on Server",
      "version": 5,
      "updated_at": "2026-10-30T14:20:00Z"
    }
  }
}
```

### 7.2 Hợp đồng Kéo dữ liệu Delta (Delta Sync & Cursors)

Để đồng bộ các thay đổi mới nhất về local database mà không phải tải lại toàn bộ dataset:
- **Endpoint generic**:
  `GET /api/v1/{dataset}/sync?since_cursor=<opaque_string>&limit=100`
- **Quy ước Cursor Opaque**:
  - `since_cursor`: Client gửi lại chuỗi cursor nhận được từ lần sync thành công trước. Client coi cursor là một **opaque string** (chuỗi đen), không phân tích timestamp, sequence hay ID bên trong.
  - Lần sync đầu tiên: `since_cursor` bị bỏ qua hoặc truyền rỗng.
- **Phản hồi Delta chuẩn từ Backend**:

```json
{
  "items": [
    {
      "id": "item-uuid-101",
      "version": 4,
      "deleted": false,
      "updated_at": "2026-10-30T14:25:00Z",
      "data": {
        "title": "Cleaned up title",
        "status": "active"
      }
    },
    {
      "id": "item-uuid-102",
      "version": 5,
      "deleted": true,
      "deleted_at": "2026-10-30T14:28:00Z"
    }
  ],
  "next_cursor": "cur_01hgb9a8bc43d7",
  "has_more": false,
  "server_time": "2026-10-30T14:30:00Z",
  "min_supported_cursor": "cur_01hf0000000000",
  "resync_required": false
}
```

### 7.3 Bản ghi Tombstone và Xóa dữ liệu (Tombstones & Deletions)
- Khi một bản ghi bị xóa trên server, server không được xóa vật lý ngay lập tức mà phải phát sinh một bản ghi **tombstone**:
  `{ "id": "...", "deleted": true, "deleted_at": "..." }`.
- **Thời gian lưu giữ Tombstone (Tombstone Retention Window)**:
  - Server **bắt buộc phải lưu giữ tombstone trong khoảng thời gian dài hơn thời hạn offline tối đa được phê duyệt** của hệ thống (approved maximum offline duration).
  - Quy ước dọn dẹp tombstone (tombstone pruning) trên backend phải gắn liền với hợp đồng cursor/retention của server, **không được xóa tombstone tùy tiện chỉ dựa vào một mốc tuổi cố định** (như giả định 30 ngày hay 90 ngày).
  - Thời hạn lưu giữ chính xác là một **cổng quyết định backend/product (backend/product gate)** cần được phê duyệt và đồng thuận cùng dung lượng lưu trữ hạ tầng.
- Nếu tombstone bị dọn dẹp trước khi client kịp sync (client offline lâu hơn retention window), cursor của client sẽ bị coi là quá hạn và server phải kích hoạt yêu cầu resync để tránh làm sống lại bản ghi đã xóa (resurrection anomaly).

### 7.4 Hết hạn Cursor và Yêu cầu Resync (`resync_required`)
- Nếu `since_cursor` của client đã quá cũ (vượt quá thời gian lưu giữ tombstone hoặc server đã dọn dẹp lịch sử delta trước `min_supported_cursor`):
  - Server phản hồi `HTTP 410 Gone` hoặc trả về cờ `"resync_required": true`.
  - **Quy trình Full Snapshot Resync với Staging và Atomic Swap**:
    1. **Staging Generation**: Client tuyệt đối **không được xóa sạch (wipe) trực tiếp dữ liệu cache cục bộ** ngay khi nhận cờ resync. Thay vào đó, client tải baseline snapshot đầy đủ mới từ server và ghi vào một staging generation/phân vùng tạm trong local database.
    2. **Hoán đổi nguyên tử (Atomic Swap)**: Sau khi toàn bộ baseline snapshot mới đã được tải và ghi thành công vào staging, client thực thi hoán đổi nguyên tử (atomic swap) trong một transaction của local database giữa baseline snapshot mới và dataset cũ.
    3. **Bảo toàn Outbox và Pending Overlays (Preserve Outbox & Pending Overlays)**: Toàn bộ outbox operations (`pending outbox operations`), local drafts và các bản vá/lớp phủ cục bộ (`pending overlays`/inverse changes) chưa được server xác nhận **bắt buộc phải được giữ nguyên vẹn** trong suốt quá trình staging và swap. Sau khi swap hoàn tất, client rebase và áp lại các pending overlays lên baseline snapshot mới; resync không bao giờ được phép xóa hoặc làm mất các thao tác cục bộ đang chờ gửi lên server của người dùng.

---

## 8. Phân định Baseline v1 và Quyết định Backend Còn Mở

### 8.1 Bảng phân định phạm vi tính năng

| Thành phần / Giao ước | v1 Core Base (In-Scope) | Phase 2 Offline-First | Backend RFC (Còn Mở / Chưa Chốt) |
|---|:---:|:---:|:---:|
| **Mô hình kết nối** | Trực tuyến Unary (Retrofit/Dio) | Outbox Worker + Local DB | WebSocket / Server-Sent Events |
| **Phân trang** | 1-based `page` & `page_size` | Cursor delta theo dataset | Keyset pagination cho UI lớn |
| **Empty / 204** | Chuẩn hóa `204`, mảng rỗng `[]`; mutation 204 map sang `Result<void>` (unit success, không giả định null entity) | Như v1 | Streaming NDJSON / Chunked |
| **Ánh xạ lỗi** | Typed mapping sang `AppFailure` union; profile RFC-style là mục tiêu khuyến nghị cho API mới/controlled, endpoint adapters xử lý confirmed legacy formats | Thêm `SyncConflict` model & typed local persistence failure | Shared parser chỉ sau converter spike và backend xác nhận |
| **Session & Auth** | Bearer, single-flight refresh, epoch | Giữ nguyên + scope DataScope & dataScopeEpoch | Multi-account token switching |
| **Retry & Idempotency** | 1 follow-up GET/HEAD, cancel token | Idempotency-Key UUID trong Outbox; retention > max offline queue age / retry window (chờ gate backend/product) | Backend deduplication store SLA & retention window chốt với Product |
| **Optimistic Concurrency** | Không áp dụng | `version` / `ETag` + 409/412 snapshot hoặc feature GET resolver | Thuật toán CRDT / 3-way auto merge |
| **Delta Sync & Tombstone** | Không áp dụng | `since_cursor`, tombstone retention > offline window (cổng backend/product); 410 resync dùng staging + atomic swap và bảo toàn outbox/pending overlays | Phân vùng dataset theo quyền RBAC, SLA retention và pruning contract cho tombstone/cursor |

### 8.2 Danh sách quyết định Backend còn mở (Unresolved Backend Decisions)

Các mục sau đây là câu hỏi kiến trúc đang chờ phía Backend xác nhận trước khi Phase 2 có thể bắt đầu code:

1. **Chuẩn hóa Error Envelope và Spike Shared Parser**:
   - *Hiện trạng*: Spec `03-network-and-errors.md` đã hoãn áp đặt shared envelope (`ApiEnvelope<T>`) trong v1; định dạng RFC 7807 (§4) hiện là target profile khuyến nghị cho API mới/controlled. Các backend legacy có thể trả về error format riêng (`{"message": "error", "status": 400}` hoặc plain text), được xử lý qua endpoint adapters chuyên biệt.
   - *Quyết định còn mở*: Cần spike kỹ thuật riêng (về custom Retrofit converter, xử lý 204/empty body và error body) và sự xác nhận từ backend trước khi đưa generic envelope parser vào Core Base.
2. **Cơ chế lưu trữ và thời gian sống của Idempotency-Key**:
   - *Câu hỏi*: Backend sử dụng hạ tầng nào để dedup (Redis key with TTL hay database deduplication table)? SLA cam kết về retention window của `Idempotency-Key` là bao lâu?
   - *Nguyên tắc & Cổng quyết định*: Thời gian lưu giữ bắt buộc phải vượt quá thời hạn tối đa được phê duyệt của hàng đợi offline và cửa sổ retry của client (maximum offline queue age / operation retry window). Giá trị thời hạn cụ thể là một **cổng quyết định backend/product (backend/product gate)** cần ký duyệt, không mặc định cố định 24 giờ.
   - *Rủi ro*: Nếu retention ngắn hơn thời gian mutation tồn tại trong offline queue, việc gửi lại mutation khi có mạng có thể gây lặp thao tác phía server.
3. **Định dạng và thời hạn lưu giữ Tombstone**:
   - *Câu hỏi*: Cơ chế xóa trên database của Backend là soft-delete (`deleted_at IS NOT NULL`) hay sử dụng bảng audit/change-log riêng? Hợp đồng dọn dẹp tombstone (tombstone pruning) gắn với server cursor và retention như thế nào?
   - *Nguyên tắc & Cổng quyết định*: Thời hạn lưu giữ tombstone phải dài hơn khoảng thời gian offline tối đa mà hệ thống hỗ trợ. Giá trị retention cụ thể không giả định cố định 30 ngày mà là một **cổng quyết định backend/product (backend/product gate)**. Dọn dẹp tombstone phải theo server cursor contract, không xóa tùy tiện theo tuổi cố định; cursor cũ hơn retention window phải kích hoạt `resync_required`.
4. **Hạ tầng hỗ trợ Opaque Cursor cho Delta Sync**:
   - *Câu hỏi*: Backend sinh cursor dựa trên log sequence number (Postgres WAL / Debezium) hay dựa trên `updated_at + id`?
   - *Rủi ro*: Nếu dựa trên `updated_at`, rủi ro trôi đồng hồ hoặc hai bản ghi cùng millisecond có thể làm sót bản ghi khi phân trang.
5. **Snapshot conflict (409/412)**:
   - Backend nên trả `server_record` và `server_version` trong lỗi conflict. Nếu snapshot không có, feature bắt buộc khai báo GET resolver theo entity ID để lấy bản mới nhất; nếu cả hai đều không khả dụng, operation giữ lại ở `needsAttention`, không tự merge/retry.

---

## 9. Tiêu chuẩn Nghiệm thu (Acceptance Criteria)

Tài liệu này được nghiệm thu thành công khi toàn bộ các điều kiện kiểm thử sau được đáp ứng trong implementation và unit/integration tests:

### AC-1: Ranh giới DTO và Domain
- [ ] Mọi DTO đều được generate bằng `freezed` và `json_serializable` mà không gây lỗi phân tích analyzer.
- [ ] Không có file nào trong `lib/src/features/*/domain/` hoặc `presentation/` import bất kỳ DTO nào hoặc import thư viện `dio`.
- [ ] Mapper ném `FormatException` khi dữ liệu bắt buộc bị thiếu; Repository bắt ngoại lệ này và trả về `Result.err(AppFailure.parse())`.

### AC-2: Phân trang và Xử lý Empty/204
- [ ] Endpoint danh sách trả về mảng rỗng `[]` được ánh xạ thành `PagedState(items: [], hasMore: false)`, không gây crash parsing.
- [ ] Endpoint trả về `204 No Content` được thực thi mà không kích hoạt JSON deserialization, map thành `Result<void>` biểu thị unit success (thành công không kèm entity payload, với `Result.ok(null)` chỉ là implementation detail của Dart).
- [ ] PagedCubit deduplicate các items trùng `id` khi nhận dữ liệu từ các trang kế tiếp.

### AC-3: Ánh xạ lỗi và Redaction
- [ ] Status 401 sau khi auth policy kết luận được map thành `AppFailure.unauthorized()`.
- [ ] Status 403 luôn map thành `AppFailure.forbidden()`; không kích hoạt refresh token và không logout.
- [ ] Status 422 hoặc 400 có field/code đã xác nhận được map thành typed `ValidationIssue`; raw server text không tới UI/log.
- [ ] Status 429 có header `Retry-After: 30` được trích xuất thành `AppFailure.rateLimit(Duration(seconds: 30))`.
- [ ] Body lỗi 4xx/5xx không được log; chỉ metadata allowlist đã redact được gửi tới logging.

### AC-4: Auth Refresh & Concurrency
- [ ] Kiểm thử 5 request đồng thời nhận 401 chỉ kích hoạt đúng 1 network call tới `POST /api/v1/auth/refresh`.
- [ ] Nếu refresh trả về 401/403: session epoch/auth state bị invalidate trước token clear; clear failure giữ app locked/fail-closed và được biểu diễn thành typed persistence failure.
- [ ] Nếu refresh trả về 429 hoặc 500: session được giữ nguyên, không tự động logout.
- [ ] Khi refresh thành công, các request GET/HEAD đang chờ được tự động replay với token mới; các mutation POST/PUT không tự replay mà trả lỗi về caller.
- [ ] `sessionEpoch` tăng monotonic qua ít nhất hai chu kỳ logout/login trong cùng process; kết quả refresh của epoch cũ bị discard và không ghi token.
- [ ] Refresh 200 nhưng atomic `writeSession` thất bại không dùng token mới, không replay request, khóa auth và trả `localPersistence` cho mọi waiter.
- [ ] SecureStorage `SessionRecord` dùng status loại trừ nhau; restart không restore `logoutPending`/`sessionInvalidationPending`; revoke chỉ chạy cho explicit logout; pending-write failure thử clear session và không được báo thành công nếu cả hai thao tác lỗi.

### AC-5: Cancellation & Retry
- [ ] Request bị hủy bởi `CancelToken` không phát ra UI error state, không emit sau khi Cubit closed, và không gửi report tới CrashReporter.
- [ ] Request GET gặp lỗi mạng/timeout được retry tự động tối đa 1 lần; nếu thất bại lần 2 thì trả về lỗi ngay lập tức.
- [ ] Request POST/PUT/DELETE không bao giờ tự động retry ở tầng Dio interceptor.
- [ ] Khi có `Idempotency-Key`, key là chuỗi UUID hợp lệ và không bị thay đổi qua các lần thử lại ở tầng ứng dụng.
- [ ] `409 REQUEST_IN_PROGRESS` không tạo `SyncConflict`, retry giữ nguyên operation và idempotency key; `VERSION_MISMATCH`/412 tạo `SyncSendOutcome.versionConflict` với response snapshot hoặc feature GET resolver.

### AC-6: Điều kiện tiên quyết Offline Sync (Phase 2 Gates)
- [ ] Phase 2 backend gate xác nhận code `VERSION_MISMATCH` và `server_record`/`server_version` trong conflict response, hoặc feature GET resolver lấy được remote snapshot. Nếu không có một trong hai, offline mutation không được enable.
- [ ] Phản hồi sync delta có đầy đủ các trường `items`, `next_cursor`, `has_more` và cờ `resync_required`.
- [ ] Hợp đồng resync 410 / `resync_required` quy định rõ cơ chế staging + atomic swap và bảo toàn nguyên vẹn outbox queue cùng pending overlays.
- [ ] Tombstone retention và Idempotency-Key retention được xác định phải vượt quá thời hạn offline/retry tối đa, với giá trị cụ thể được kiểm soát qua backend/product gates thay vì giả định số ngày/giờ cố định.
- [ ] Tombstone record có định dạng chuẩn `{ "id": String, "deleted": true, "deleted_at": String }`.
