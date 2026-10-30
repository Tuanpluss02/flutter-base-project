# Flutter Core Base — Offline-first data

Ngày: 2026-10-30 (rev6 — tích hợp phản biện reviewer 2)  
Trạng thái: bộ spec tích hợp đang chờ cả hai reviewer duyệt cùng revision; chưa bắt đầu implementation

Điều hướng: [Index](../2026-10-30-flutter-core-base-design.md) · [Architecture](01-scope-toolchain-architecture.md), [App runtime](02-app-runtime.md), [Network và errors](03-network-and-errors.md), [Storage](04-storage-and-shared-ui.md), [Verification](05-verification-and-release.md)

## 1. Mục tiêu và ranh giới

Offline-first nghĩa là UI đọc trạng thái nghiệp vụ từ local database; thao tác đọc không cần mạng nếu dữ liệu đã có. Các thay đổi được xác nhận local trước, sau đó đồng bộ lên server khi có thể. Server vẫn là authority cho dữ liệu dùng chung và quyền nghiệp vụ.

Đây là module mở rộng Phase 2, không thuộc điều kiện nghiệm thu Core Base v1 scaffold và không làm phình dependency lockfile ban đầu. Từng feature phải opt-in và khai báo dữ liệu nào được cache, thao tác nào được phép thực hiện offline, thời hạn dữ liệu, conflict policy và yêu cầu bảo vệ dữ liệu. Không mặc định mọi màn hình hoặc mutation đều dùng được offline.

Đợt đầu không hứa background sync đáng tin cậy, realtime, đồng bộ đa thiết bị tức thời, hay giải quyết conflict nghiệp vụ tự động. Sync tiến hành khi app mở, khi resume, sau khi mutation enqueue và theo thao tác refresh của người dùng; connectivity trigger chỉ thêm sau khi chốt dependency. OS có thể trì hoãn hoặc không chạy tác vụ nền.

## 2. Kiến trúc và nguồn dữ liệu

```text
Page -> Cubit -> UseCase -> Repository interface
                         -> Local database (read/write, transaction)
                         -> Remote API (pull/push)

Remote DTO -> Mapper -> local tables -> watched/query stream -> Entity -> UI
```

- Đây là repository pattern opt-in cho feature offline-first; data flow unary qua Retrofit trong App Runtime vẫn áp dụng cho feature online-only.
- Local database là nguồn đọc duy nhất cho UI sau khi feature bật offline cache. Repository không trả DTO trực tiếp từ network cho Cubit.
- Query local trả dữ liệu đã lưu ngay cả khi stale; offline-aware feature state giữ `data` cùng metadata sync (syncing/stale/last success/background failure). Không emit `Loading`/`Error` thay thế cached data khi background sync chạy hoặc thất bại. `BaseState<T>` hiện tại giữ nguyên cho flow đơn giản/online-only; offline module định nghĩa state contract riêng.
- Repository điều phối remote fetch, map DTO, transaction cập nhật local rồi để query phát dữ liệu mới. Mọi thao tác nhiều bảng cần transaction.
- Database schema và migrations thuộc data layer; Cubit/Widget không biết SQL, table hoặc sync cursor.
- Không dùng `LocalStorage` cho business records, outbox, cursor hoặc auth/session record; nó chỉ dành cho preference như locale/theme. Auth transition status nằm trong atomic `SecureStorage.SessionRecord` theo 04 §4.7.

## 3. Local persistence và schema

- Dùng một relational local database làm nền tảng cho records, indexes, sync metadata và outbox. Chọn package cụ thể sau spike dependency/migration trên toolchain đã pin; không thêm dependency vào matrix trước khi spike qua.
- `DataScope` là khóa dữ liệu gồm `accountId` và `tenantId/workspaceId` (nullable nếu sản phẩm xác nhận single-tenant). Mọi business/outbox row dùng scope trong key/index; mọi DAO/query/outbox claim bắt buộc scope hiện tại. Chuyển scope dừng worker và tăng `dataScopeEpoch`; mọi write xác nhận scope + epoch. `sessionEpoch` trong auth chỉ fence token refresh, không thay cho `dataScopeEpoch`.
- Mỗi bảng business có primary key ổn định của domain/server. Với record tạo offline, client sinh UUID trước khi enqueue; backend phải chấp nhận client ID hoặc feature phải giữ record local-only cho tới khi online. Nếu server ID khác, bắt buộc có transactional remap qua row, foreign key và pending outbox payload.
- Metadata sync tối thiểu: server `version`/ETag, `deletedAt`/tombstone khi cần, dataset cursor và monotonic local sequence cho queue order. `lastSyncedAt` là theo dataset. Outbox là authority cho pending operation; tránh duy trì hai trạng thái sync độc lập trên row và queue. Không dùng device wall-clock làm thứ tự authority.
- Migration phải giữ local data qua upgrade; destructive migration chỉ được dùng khi có quyết định xóa data và có đường xử lý phiên bản cũ. Migration lỗi phải fail có kiểm soát, không âm thầm reset database.
- Cache policy (TTL/retention, giới hạn dung lượng, refresh) do feature khai báo. Cache eviction không được xóa pending outbox operation.

## 4. Read và refresh contract

- Màn hình subscribe/query local; lần mở đầu chưa có cache có thể hiện empty/loading local và trạng thái cần tải, nhưng không coi `network unavailable` là empty result.
- Sync cycle push pending operations trước, rồi pull delta độc lập theo dataset; operation conflict/needsAttention chặn entity liên quan nhưng không nhất thiết chặn dataset khác. Apply page/delta và cursor trong cùng transaction để crash không làm mất khoảng dữ liệu. Cursor cần `minSupportedCursor`/`resyncRequired`; full refresh dùng staging generation rồi swap nguyên tử, không xóa pending local work.
- Dữ liệu server cập nhật vào local theo upsert có kiểm soát. Không ghi đè row có local pending mutation bằng một pull cũ; merge/rebase theo server version và policy của feature.
- Xóa từ server cần tombstone hoặc API contract tương đương; tombstone retention phải dài hơn giới hạn offline được hỗ trợ. Cursor cũ hơn retention phải trả yêu cầu resync; tránh row đã xóa bị resurrect bởi pull cũ.

## 5. Offline mutation và outbox

Chỉ mutation được feature đánh dấu `offlineAllowed` mới được chấp nhận offline.

- Chỉ persist local row/draft và outbox sau khi backend contract, classification và encryption/backup gates của feature đều được duyệt. Trước các gate đó, chỉ giữ draft không nhạy cảm trong memory. Khi feature offline đã được bật, trong một local transaction cập nhật local row hoặc draft và thêm outbox operation. Chỉ báo “đã lưu trên thiết bị/chờ đồng bộ”; không báo “đã hoàn tất trên server”. Pending mutation phải giữ base snapshot/inverse change hoặc được tách thành draft overlay, để discard/rejection có thể rollback có kiểm soát mà không làm hỏng server-confirmed row. Không tự discard.
- Outbox operation có ID ổn định, `DataScope`/`dataScopeEpoch`, entity key, operation/payload version, monotonic sequence, base server version, group/dependency khi cần, state, attempt metadata, lease owner/expiry, và idempotency key UUID sinh lúc enqueue, bất biến qua retry/crash. Key scoped theo `DataScope`; backend giữ và replay response gốc trong retention dài hơn operation retry window. Payload phải đủ để retry sau app restart; không lưu access/refresh token hay dữ liệu bí mật không cần thiết. V1 không hỗ trợ file upload/download offline. Mỗi endpoint phải có bounded-payload policy được feature/backend xác nhận trước khi bật; vượt giới hạn map thành `AppFailure.payloadTooLarge()` và không commit mutation/outbox.
- Outbox Worker ở application layer phía trên Dio; Dio interceptor không retry mutation, còn worker retry operation theo chính sách outbox. Worker lấy operation theo thứ tự phụ thuộc trên cùng entity; claim operation có lease/locking để không gửi trùng từ nhiều trigger trong cùng process. Khi app khởi động, lease hết hạn và operation kẹt `syncing` được recover về `pending`. Đánh dấu ack và cập nhật row trong transaction sau server ack.
- Retry lỗi network/timeout/5xx/429 ở application-level Outbox Worker bằng backoff có jitter và tôn trọng `Retry-After`; cancellation không tính là lỗi nghiệp vụ. Không retry vô hạn nhanh. Lỗi auth pause queue cho tới khi session cùng account hợp lệ; validation/forbidden và 404 không phải DELETE chuyển operation sang `needsAttention`; DELETE 404 là synced. `409 REQUEST_IN_PROGRESS` giữ pending với cùng key; chỉ version mismatch đã nhận diện mới vào conflict.
- Exactly-once qua mạng không được giả định. Backend contract tối thiểu phải xác định idempotency key scope/retention và replay status + response gốc; `version`/ETag, stable `VERSION_MISMATCH` code và snapshot trong conflict response hoặc feature GET resolver; delta cursor, tombstone và hành vi `resyncRequired`. Nếu API chưa có contract này, không enqueue business mutation; chỉ cache S0/S1 đã khử định danh và giữ draft không nhạy cảm trong memory, không persist draft nghiệp vụ.
- Update/delete đối với cùng entity phải được serialize hoặc coalesce theo policy được định nghĩa; không xóa operation chưa ack một cách âm thầm.

## 6. Conflict và server authority

Không có generic last-write-wins dựa trên timestamp thiết bị.

- Read-only/reference data: server snapshot thắng; cache có thể thay thế theo version/cursor.
- User-owned draft/local-only data: local thắng cho tới khi user publish hoặc xóa theo policy.
- Shared business entity và mutation cạnh tranh: API dùng optimistic concurrency (`version`/ETag/conditional update); `409/412` trả remote snapshot/version. Giữ server snapshot riêng; optimistic value là pending overlay/draft có base version, không ghi đè server-confirmed row. Conflict được lưu bền vững (`local`, `remote`, `baseVersion`) để feature merge/chọn bản/yêu cầu user xử lý sau restart.
- Mỗi feature ghi conflict matrix cho create/update/delete, field-level merge được phép, và hành vi khi entity đã bị xóa trên server. Nếu không có policy, thao tác đó online-only.

Kết quả sync là typed riêng với HTTP `AppFailure`, để request đang xử lý và version conflict không nhập nhằng:

```dart
sealed class SyncSendOutcome {
  const factory SyncSendOutcome.synced() = SyncSent;
  const factory SyncSendOutcome.retryable(AppFailure failure, Duration? retryAfter) = SyncRetryable;
  const factory SyncSendOutcome.requestInProgress(Duration? retryAfter) = SyncRequestInProgress;
  const factory SyncSendOutcome.versionConflict(SyncConflict conflict) = SyncVersionConflict;
  const factory SyncSendOutcome.needsAttention(AppFailure failure) = SyncNeedsAttention;
}

class SyncConflict {
  const SyncConflict({required this.localOverlay, required this.remoteSnapshot,
    required this.baseVersion, required this.serverVersion});
  final Object localOverlay;
  final Object remoteSnapshot;
  final String baseVersion;
  final String serverVersion;
}
```

`AppFailure.conflict()` chỉ là failure generic cho flow online-only, không mang sync payload. Offline mutation chỉ được enable khi backend trả snapshot hoặc feature có GET resolver; nếu GET cũng fail, worker trả `needsAttention` và giữ operation.

## 7. Connectivity, trigger và trạng thái đồng bộ

Connectivity signal chỉ là gợi ý; request thực tế mới xác định có kết nối tới API hay không.

- Sync trigger: app bootstrap sau khi session restore, app resume, mutation enqueue, user refresh/retry. Connectivity chuyển về khả dụng chỉ là trigger tùy chọn sau khi dependency được duyệt; tới lúc đó không có connectivity listener. Debounce và single-flight theo account/dataset.
- Sync không block app startup; bootstrap mở local DB, khởi tạo UI từ cache, rồi sync nền trong lifecycle app.
- Outbox transitions: `pending -> syncing -> synced | pending(retry) | conflict | needsAttention`; `syncing -> pending` khi lease hết hạn/app restart; `conflict -> pending(resolved)` với operation/key mới hoặc `discarded`; `needsAttention -> pending(edited)` với operation/key mới hoặc `discarded`. `401` suspends queue, `403/422` -> `needsAttention`, `409 REQUEST_IN_PROGRESS` -> `pending(retry)` với cùng key, `409 VERSION_MISMATCH`/`412` -> `conflict`, `429/5xx/network` -> `pending` backoff, DELETE 404 được coi synced. Code 409 không nhận diện giữ operation trong `needsAttention` với typed server failure; không tự gán conflict. Không xóa pending/conflict operation tự động. Dataset có thể có `lastSuccessfulSyncAt`/stale indicator.
- Sync progress/error không thay thế nội dung đã cache. UI dùng typed state để phân biệt offline, stale, pending và conflict; localization thuộc feature/UI.
- Không cam kết tác vụ tiếp tục sau khi OS suspend/kill app. Nếu sau này yêu cầu background sync, cần spike riêng cho Android/iOS scheduling, battery, constraints và eventual-delivery semantics.

## 8. Account, bảo mật và lifecycle

- Mọi row/outbox phải scoped theo account/tenant; query luôn áp scope hiện tại. Không sync operation của account A bằng session account B. Session expiry không xóa pending data hoặc draft.
- Session expiry/401: dừng sync, tăng session/account epoch, hủy request đang chạy, ngăn callback cũ ghi DB; giữ database và outbox scoped theo account, chỉ resume khi cùng account đăng nhập lại. Expiry không đồng nghĩa logout/xóa dữ liệu. Explicit logout ghi durable `SessionRecord.logoutPending` trước revoke/clear, dừng sync và không được âm thầm xóa pending mutation; cache purge chỉ sau lựa chọn rõ ràng/confirm của người dùng và policy retention đã duyệt. Account isolation phải được đảm bảo khi chuyển account; spike chọn database-per-account hoặc shared DB có account scope + kiểm tra truy cập tập trung.
- App sandbox không đồng nghĩa business data đã được mã hóa phù hợp. Cho tới khi DB key lifecycle, at-rest encryption và Android/iOS backup exclusion được chốt, không lưu PII hoặc tài liệu nhạy cảm vào cache/outbox. Spike phải quyết định encryption baseline, SecureStorage-backed key, key-loss recovery (re-sync, không crash) và backup restore policy; feature classification chỉ được nâng mức bảo vệ, không hạ baseline. Không đưa dữ liệu nhạy cảm vào log/crash context.
- Token vẫn ở `SessionTokenProvider` trong secure storage; không lưu token trong database business hoặc outbox.

## 9. Failure handling và observability

- Dùng `Result<T>`/`AppFailure` hiện có cho lỗi request; domain/UI có sync-specific state cho conflict, pending và needs-attention, không nhét raw exception vào state.
- Database open/migration/write failure dùng `AppFailure.localPersistence()` đã có trong closed union; mutation không được báo thành công local nếu transaction thất bại. `SyncConflict` chứa local overlay, remote snapshot và base version; không ép payload conflict vào `AppFailure.conflict()` transport-level hiện có.
- Log chỉ metadata đã redact: operation type, retry count, duration, dataset; không log payload, PII, token hoặc nội dung entity.
- Có cách người dùng retry operation `needsAttention`, xem trạng thái pending và xóa/discard draft chỉ khi feature cho phép; hành vi phải rõ ràng, không tự discard.

## 10. Kiểm chứng và quyết định còn mở

Offline-first là Phase 2; không chặn nghiệm thu scaffold v1. Trước khi approve module hoặc đưa vào feature, spike dependency/database và backend contract trên đúng Flutter pin:

- Migrations từ database rỗng và ít nhất một schema version cũ; transaction rollback khi lỗi.
- Query local trả cache khi API offline; refresh cập nhật cache mà không làm mất pending local write.
- Outbox tồn tại qua process restart; crash sau server ack nhưng trước local ack replay an toàn; idempotency key giữ nguyên, queue không gửi operation sai `DataScope`.
- Conflict overlay survives restart; 409/412, server delete/tombstone, duplicate response, 401/logout/account switch giữa sync và migration failure.
- App upgrade với pending queue, cursor hết hạn/resync, DB corruption, backup restore, queue cap, clock change và 429 pause/backoff.
- Phase 2 account isolation: account B không query được record/outbox của A; session expiry giữ DB/outbox scoped; logout khi pending operation không làm mất mutation.
- `REQUEST_IN_PROGRESS` không tạo `SyncConflict`, operation và idempotency key không đổi; `VERSION_MISMATCH`/412 tạo `SyncConflict` với snapshot trong response hoặc feature GET resolver.
- Cold start mở local UI trước khi sync; sync không block router/UI.

Các quyết định cần chốt trước implementation: database package và analyzer/path dependency compatibility; mã hóa/backup/key lifecycle; server ID/idempotency/delta/version contract; account+tenant `DataScope` và logout retention; connectivity dependency; background sync có cần thiết không. Cần cập nhật mục tiêu architecture/bootstrap/tests trong spec core khi Phase 2 được approve; feature migration phải đăng ký ở composition root để thêm feature không buộc sửa `core/`. Nếu backend chưa có contract idempotency/version, giới hạn đợt đầu ở cache S0/S1 đã khử định danh và draft không nhạy cảm chỉ trong memory; không persist S2/S3 trước security gates và không enqueue mutation nghiệp vụ. Mỗi feature phải khai báo `OfflinePolicy`/`SyncDataset` (DataScope, cursor, TTL, allowed operations, conflict policy, classification); thao tác nhạy cảm/không thể đảo ngược như payment, ký, phê duyệt luôn online-only. `needsAttention` edit tạo operation và idempotency key mới; discard rollback overlay. Queue có max-age/cap và backpressure; không evict pending/conflict. Local paging là contract riêng, không dùng ngầm `PagedCubit` in-memory. `PagedCubit` hiện quản lý page trong memory; feature có dữ liệu lớn cần quyết định riêng về local paging/query contract, không áp dụng paging network v1 một cách ngầm định. Tombstone retention/pruning phải theo server cursor/retention contract, không xóa tombstone chỉ theo tuổi cố định.
