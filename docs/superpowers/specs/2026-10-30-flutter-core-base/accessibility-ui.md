# Flutter Core Base — Accessibility và UI Acceptance

Ngày: 2026-10-30 (thuộc bộ spec tích hợp rev6)  
Trạng thái: draft; acceptance cho scaffold và feature UI, cần review trước implementation

Điều hướng: [Index](../2026-10-30-flutter-core-base-design.md) · [App runtime](02-app-runtime.md), [Network và errors](03-network-and-errors.md), [Storage và shared UI](04-storage-and-shared-ui.md), [Offline-first data](offline-first.md), [Verification](05-verification-and-release.md)

## 1. Phạm vi và nguyên tắc

Tài liệu này đặt tiêu chí kiểm tra accessibility cho UI Flutter của core base và feature. Nó bổ sung hành vi và khả năng kiểm chứng, không định nghĩa nghiệp vụ, luồng sản phẩm, nhận diện trực quan hoặc design system mới.

- Dùng Material 3, `ColorScheme`, `AppTheme.light/dark`, text styles và ThemeExtension đã định nghĩa trong shared theme. Shared widget phải kế thừa theme; feature không hardcode font family, màu hoặc kích thước thay thế theme.
- Dùng Slang và `context.t.*` cho mọi nội dung người dùng nhìn/nghe thấy, kể cả nhãn semantics, thông báo validation, trạng thái và hành động. Không đặt câu chữ giao diện trong domain/network.
- Duy trì phân lớp hiện có: view trình bày state và chuyển tương tác tới Cubit; không đưa I/O hoặc quy tắc nghiệp vụ vào widget để phục vụ accessibility.
- Ưu tiên semantics native của Material widget; chỉ thêm semantics tùy chỉnh khi semantics mặc định thiếu hoặc sai. Không thêm dependency accessibility/UI.
- Tiêu chí áp dụng cho Android và iOS v1. Hành vi riêng theo nền tảng, web/desktop và yêu cầu tiêu chuẩn pháp lý của từng thị trường còn mở cho tới khi có quyết định.

## 2. Semantics và screen reader

- Mỗi control tương tác có tên accessible được dịch, vai trò phù hợp và trạng thái hiện tại cần thiết (ví dụ selected, checked, disabled, expanded hoặc busy). Tên không chỉ dựa vào icon, màu sắc hoặc vị trí.
- Hình ảnh trang trí không được đọc thành nội dung; hình ảnh truyền tải thông tin phải có nhãn mô tả ngắn, được bản địa hóa nếu nội dung do app cung cấp. Không lặp lại nội dung đã được đọc từ text kế cận.
- Nhóm các thành phần có quan hệ thành một đơn vị đọc hợp lý; không gộp nhóm nếu làm mất khả năng thao tác riêng trên các control con.
- Thứ tự đọc đi theo thứ tự nội dung và thao tác nhìn thấy, không nhảy ngẫu nhiên giữa vùng màn hình. Nội dung mới xuất hiện không được làm người dùng mất vị trí đọc một cách bất ngờ.
- Thông báo thay đổi trạng thái quan trọng (ví dụ tải hoàn tất, lỗi cần xử lý, conflict) phải được screen reader nhận biết qua semantics phù hợp; tránh đọc lặp liên tục khi state phát nhiều lần.
- Không dùng `ExcludeSemantics`/`MergeSemantics` làm mất tên, vai trò, trạng thái hoặc thao tác cần thiết. Không tạo semantics action không thể thực hiện bằng touch hoặc bàn phím hỗ trợ.

## 3. Focus, bàn phím và thao tác

- Các control có thể thao tác phải có focus target rõ ràng, thứ tự focus logic và khả năng kích hoạt bằng input phù hợp trên nền tảng. Không có focus trap ngoài thành phần modal chuẩn của Material.
- Khi focus vào control, trạng thái focus phải phân biệt được bằng theme và không chỉ dựa vào màu. Focus không bị che khuất bởi bàn phím ảo, thanh điều hướng hoặc overlay.
- Mở/đóng dialog, menu hoặc route không để focus vào widget đã bị gỡ. Sau khi đóng overlay, focus trở lại control đã mở nó khi hợp lý; nếu control không còn tồn tại, đặt focus tại điểm nội dung kế tiếp có ý nghĩa.
- Nút đang loading hoặc disabled phải công bố trạng thái đó và không nhận kích hoạt lặp. Không làm mất focus khi chuyển giữa idle/loading/result nếu control vẫn còn.
- Trên Android/iOS, kiểm tra điều hướng bằng screen reader và bàn phím ngoài khi nền tảng/test host hỗ trợ. Phạm vi keyboard navigation hoàn chỉnh cho tablet/desktop/web cần được chốt riêng trước khi mở rộng platform.

## 4. Text scaling, contrast và touch targets

- Không khóa text scaling hoặc cắt nội dung khi người dùng tăng cỡ chữ. Các màn hình core/widget được kiểm tra ở text scale 2.0; nội dung có thể xuống dòng, cuộn hoặc đổi bố cục để giữ đủ thông tin và hành động.
- Tránh chiều cao cố định cho vùng chứa chữ nhiều dòng và nút có label dài. Text không bị ellipsis nếu phần bị ẩn chứa thông tin hoặc thao tác cần thiết; nếu cắt nội dung là quyết định sản phẩm, phải có cách tiếp cận nội dung đầy đủ và được đặc tả riêng.
- Màu chữ/nền, icon có ý nghĩa và chỉ báo focus phải đạt contrast tối thiểu WCAG 2.2 AA: 4.5:1 cho chữ thường, 3:1 cho chữ lớn và thành phần đồ họa cần thiết. Kiểm tra cả theme sáng/tối và trạng thái enabled/error/selected.
- Không truyền trạng thái chỉ bằng màu; bổ sung text, icon có semantics hoặc hình thức phân biệt khác.
- Vùng chạm của control tương tác tối thiểu 48×48 logical pixels, kể cả khi glyph/icon nhìn thấy nhỏ hơn. Các control gần nhau không gây kích hoạt nhầm; khoảng cách/layout được kiểm tra trên thiết bị nhỏ.

## 5. Responsive và localization expansion

- UI dùng constraint/layout Flutter và theme hiện có; không giả định một chiều rộng hoặc dùng ScreenUtil. Nội dung có thể cuộn khi không đủ không gian.
- Không overflow, clip mất nội dung hoặc che hành động tại kích thước 360dp và 768dp đã nêu trong verification spec, kể cả ở text scale 2.0. Với kích thước hẹp, ưu tiên xếp dọc hoặc xuống dòng thay vì thu nhỏ chữ.
- Bố cục rộng hơn có thể dùng không gian hợp lý nhưng không tạo flow hoặc điều hướng mới. Cách trình bày hai pane, breakpoint cụ thể và hành vi landscape chưa được chốt; không coi chúng là yêu cầu scaffold nếu chưa có quyết định.
- Chuỗi dịch có thể dài hơn nguồn tiếng Anh; widget phải cho phép wrap/resize và không dựa vào chuỗi dịch để tính kích thước cố định. Kiểm tra ít nhất locale `en` và `vi`; bổ sung pseudo-localization hoặc locale dài khi bộ test hỗ trợ.
- Ngày, số, thời lượng và định dạng khác phải đi theo locale/format hiện có; không ghép chuỗi dịch bằng nối đoạn nếu thứ tự ngữ pháp có thể khác.
- Nếu thiếu bản dịch, dùng cơ chế fallback của Slang; không hiện key kỹ thuật hoặc chuỗi rỗng như nội dung cuối cùng. Chính sách chất lượng dịch ngoài `en`/`vi` cần owner sản phẩm xác nhận.

## 6. UI state: loading, empty, error, offline và conflict

### Core và online-only

- Loading có semantics trạng thái bận phù hợp; indicator trang trí không tạo thông báo screen reader lặp. Khi có nội dung ổn định, không che toàn màn hình bằng spinner nếu trạng thái chỉ là thao tác nền.
- Empty state chỉ biểu thị kết quả rỗng đã biết. Nó không được dùng để che lỗi network hoặc thiếu dữ liệu do tải chưa hoàn tất.
- Error hiển thị localized message từ presentation mapping và hành động retry nếu flow hiện có cho phép. Phù hợp với `AppErrorView`: widget không tự toast hoặc điều hướng. Lỗi kỹ thuật/raw exception không được đưa ra UI.
- Cancellation không được trình bày như lỗi; không phát thông báo lỗi hoặc hành động retry cho operation đã hủy.
- Validation cần gắn lỗi với field tương ứng bằng semantics và nội dung đã dịch; lỗi không chỉ được nhận biết qua viền màu. Focus tới lỗi đầu tiên chỉ khi tương tác hiện có xác định điều đó, không tự thêm submission flow.

### Feature opt-in offline-first

- Cached content tiếp tục được đọc khi refresh nền đang chạy hoặc thất bại; trạng thái syncing/stale/last success/background failure được trình bày riêng với nội dung, không thay nội dung bằng loading/error.
- Offline, stale, pending sync và lỗi đồng bộ là các trạng thái riêng biệt, có thông tin accessible và localized. Connectivity chỉ là tín hiệu; UI không khẳng định trạng thái server chỉ từ connectivity.
- Mutation offline chỉ được xác nhận là đã lưu local/chờ đồng bộ theo contract; UI không thông báo rằng server đã hoàn tất. Hành động offline chỉ xuất hiện nếu feature policy cho phép.
- Conflict phải thông báo rõ cần xử lý và giữ các thao tác theo conflict policy của feature. Không tự chọn bản, tự discard hoặc tạo generic merge flow. Nếu chưa có policy, mutation tương ứng online-only.
- `needsAttention`/validation/forbidden phải giữ lỗi có thể hiểu được và hành động do feature quy định; không tự retry liên tục. Pending/conflict operation không bị UI ẩn hoặc xóa tự động.
- Screen reader được thông báo khi trạng thái sync/conflict thay đổi theo cách cần người dùng chú ý, nhưng không bị spam bởi từng retry/background transition.

## 7. Checklist nghiệm thu và kiểm thử

Checklist dưới đây áp dụng cho scaffold shared widgets và từng feature có UI. Kết quả phải được kiểm tra trên Android/iOS target của feature, qua widget test và kiểm tra accessibility thủ công khi semantics/assistive technology cần xác nhận.

- [ ] Accessibility audit của Flutter không báo lỗi semantics nghiêm trọng trên các màn hình và shared widgets.
- [ ] Screen reader đọc đúng tên, vai trò, giá trị/trạng thái và thứ tự cho control; icon trang trí không bị đọc, nội dung có nghĩa không bị bỏ sót.
- [ ] Mọi hành động hiện có có thể được focus và kích hoạt; thứ tự focus logic, focus indicator nhìn thấy, không có focus trap ngoài modal chuẩn.
- [ ] Mở/đóng overlay hoặc chuyển state không làm focus mất vào node đã gỡ; trạng thái loading/disabled được công bố và ngăn kích hoạt lặp.
- [ ] Không có text clipping, overflow hoặc thao tác bị che ở 360dp và 768dp, textScale 2.0, locale `en` và `vi`.
- [ ] Contrast đạt AA cho text và thành phần đồ họa cần thiết ở light/dark theme và các trạng thái được kiểm tra; trạng thái không phụ thuộc màu đơn lẻ.
- [ ] Mỗi control đạt tối thiểu 48×48 logical pixels và có khoảng cách tránh chạm nhầm.
- [ ] Loading, empty, error và cancelled được phân biệt; lỗi localized có retry chỉ khi flow hiện có cho phép, cancellation không bị báo thành lỗi.
- [ ] Với feature offline-first: cached content tồn tại trong refresh/error; offline/stale/pending/conflict/needs-attention phân biệt rõ, localized và không làm mất hay tự discard mutation.
- [ ] Widget tests dùng `WidgetTester.ensureSemantics()`/`SemanticsTester` hoặc assertion semantics tương ứng cho shared controls, `AppErrorView`, và trạng thái mới của feature.
- [ ] Kiểm tra thủ công VoiceOver và TalkBack cho một lượt đọc, thao tác chính, lỗi và thay đổi trạng thái; ghi thiết bị/OS và kết quả khi feature được triển khai.

Verification spec hiện yêu cầu widget test `AppErrorView` localized failure/retry, `AppButton` loading, kích thước 360dp/768dp và textScale 2.0. Những test đó phải bao gồm các assertion accessibility liên quan ở checklist trên; không thay đổi CI gate hoặc thêm package chỉ vì tài liệu này.

## 8. Câu hỏi cần quyết định trước khi triển khai liên quan

- Có yêu cầu tuân thủ tiêu chuẩn hoặc audit accessibility ngoài contrast AA và kiểm tra trên nền tảng v1 không?
- Platform nào cần hỗ trợ bàn phím ngoài như input chính, và có cần web/desktop/tablet/landscape acceptance không?
- Ai sở hữu tiêu chuẩn dịch, pseudo-localization và fallback cho locale ngoài `en`/`vi`?
- Với mỗi feature, state/action offline và conflict nào cần được đưa tới người dùng, theo policy nào?

Các lựa chọn trên chưa được giả định trong scaffold. Khi chưa có quyết định feature/platform, giữ hành vi theo Material 3 và state contract hiện hành, đồng thời ghi rõ giới hạn trong acceptance của feature.
