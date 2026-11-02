///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsVi extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsVi({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.vi,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <vi>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsVi _root = this; // ignore: unused_field

	@override 
	TranslationsVi $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsVi(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$vi app = _Translations$app$vi._(_root);
	@override late final _Translations$common$vi common = _Translations$common$vi._(_root);
	@override late final _Translations$login$vi login = _Translations$login$vi._(_root);
	@override late final _Translations$home$vi home = _Translations$home$vi._(_root);
	@override late final _Translations$settings$vi settings = _Translations$settings$vi._(_root);
	@override late final _Translations$error$vi error = _Translations$error$vi._(_root);
	@override late final _Translations$offline$vi offline = _Translations$offline$vi._(_root);
}

// Path: app
class _Translations$app$vi extends Translations$app$en {
	_Translations$app$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get name => 'Pristie';
}

// Path: common
class _Translations$common$vi extends Translations$common$en {
	_Translations$common$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get retry => 'Thử lại';
	@override String get cancel => 'Hủy';
	@override String get loading => 'Đang tải';
	@override String get empty => 'Chưa có nội dung';
}

// Path: login
class _Translations$login$vi extends Translations$login$en {
	_Translations$login$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Đăng nhập';
	@override String get email => 'Email';
	@override String get password => 'Mật khẩu';
	@override String get submit => 'Đăng nhập';
	@override String get required => 'Trường này là bắt buộc';
	@override String get invalidCredentials => 'Email hoặc mật khẩu không đúng';
}

// Path: home
class _Translations$home$vi extends Translations$home$en {
	_Translations$home$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trang chủ';
	@override String get loadMore => 'Tải thêm';
	@override String item({required Object id}) => 'Mục mẫu ${id}';
}

// Path: settings
class _Translations$settings$vi extends Translations$settings$en {
	_Translations$settings$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Cài đặt';
	@override String get theme => 'Giao diện';
	@override String get language => 'Ngôn ngữ';
	@override String get logout => 'Đăng xuất';
	@override String get logoutConfirm => 'Bạn có chắc muốn đăng xuất?';
	@override String get themeSystem => 'Theo hệ thống';
	@override String get themeLight => 'Sáng';
	@override String get themeDark => 'Tối';
	@override String get english => 'Tiếng Anh';
	@override String get vietnamese => 'Tiếng Việt';
}

// Path: error
class _Translations$error$vi extends Translations$error$en {
	_Translations$error$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get network => 'Không có kết nối mạng. Kiểm tra kết nối và thử lại.';
	@override String get timeout => 'Yêu cầu đã hết thời gian chờ. Hãy thử lại.';
	@override String get unauthorized => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
	@override String get forbidden => 'Bạn không có quyền thực hiện thao tác này.';
	@override String get notFound => 'Không tìm thấy nội dung bạn cần.';
	@override String get conflict => 'Dữ liệu đã thay đổi. Hãy làm mới và thử lại.';
	@override String get validation => 'Vui lòng kiểm tra lại thông tin đã nhập.';
	@override String get rateLimit => 'Quá nhiều yêu cầu. Đợi một lát rồi thử lại.';
	@override String get server => 'Đã xảy ra lỗi từ phía máy chủ. Hãy thử lại sau.';
	@override String get payloadTooLarge => 'Tệp đã chọn quá lớn.';
	@override String get parse => 'Không thể đọc phản hồi. Hãy thử lại.';
	@override String get localPersistence => 'Không thể lưu thay đổi trên thiết bị này.';
	@override String get unknown => 'Đã xảy ra lỗi. Hãy thử lại.';
}

// Path: offline
class _Translations$offline$vi extends Translations$offline$en {
	_Translations$offline$vi._(TranslationsVi root) : this._root = root, super.internal(root);

	final TranslationsVi _root; // ignore: unused_field

	// Translations
	@override String get offline => 'Ngoại tuyến';
	@override String get stale => 'Đang hiển thị dữ liệu đã lưu';
	@override String get pending => 'Đang chờ đồng bộ';
	@override String get syncing => 'Đang đồng bộ';
	@override String get conflict => 'Mục này cần bạn xử lý';
	@override String get needsAttention => 'Một số thay đổi cần bạn xử lý';
	@override String get lastSynced => 'Đồng bộ lần cuối';
}

/// The flat map containing all translations for locale <vi>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsVi {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.name' => 'Pristie',
			'common.retry' => 'Thử lại',
			'common.cancel' => 'Hủy',
			'common.loading' => 'Đang tải',
			'common.empty' => 'Chưa có nội dung',
			'login.title' => 'Đăng nhập',
			'login.email' => 'Email',
			'login.password' => 'Mật khẩu',
			'login.submit' => 'Đăng nhập',
			'login.required' => 'Trường này là bắt buộc',
			'login.invalidCredentials' => 'Email hoặc mật khẩu không đúng',
			'home.title' => 'Trang chủ',
			'home.loadMore' => 'Tải thêm',
			'home.item' => ({required Object id}) => 'Mục mẫu ${id}',
			'settings.title' => 'Cài đặt',
			'settings.theme' => 'Giao diện',
			'settings.language' => 'Ngôn ngữ',
			'settings.logout' => 'Đăng xuất',
			'settings.logoutConfirm' => 'Bạn có chắc muốn đăng xuất?',
			'settings.themeSystem' => 'Theo hệ thống',
			'settings.themeLight' => 'Sáng',
			'settings.themeDark' => 'Tối',
			'settings.english' => 'Tiếng Anh',
			'settings.vietnamese' => 'Tiếng Việt',
			'error.network' => 'Không có kết nối mạng. Kiểm tra kết nối và thử lại.',
			'error.timeout' => 'Yêu cầu đã hết thời gian chờ. Hãy thử lại.',
			'error.unauthorized' => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
			'error.forbidden' => 'Bạn không có quyền thực hiện thao tác này.',
			'error.notFound' => 'Không tìm thấy nội dung bạn cần.',
			'error.conflict' => 'Dữ liệu đã thay đổi. Hãy làm mới và thử lại.',
			'error.validation' => 'Vui lòng kiểm tra lại thông tin đã nhập.',
			'error.rateLimit' => 'Quá nhiều yêu cầu. Đợi một lát rồi thử lại.',
			'error.server' => 'Đã xảy ra lỗi từ phía máy chủ. Hãy thử lại sau.',
			'error.payloadTooLarge' => 'Tệp đã chọn quá lớn.',
			'error.parse' => 'Không thể đọc phản hồi. Hãy thử lại.',
			'error.localPersistence' => 'Không thể lưu thay đổi trên thiết bị này.',
			'error.unknown' => 'Đã xảy ra lỗi. Hãy thử lại.',
			'offline.offline' => 'Ngoại tuyến',
			'offline.stale' => 'Đang hiển thị dữ liệu đã lưu',
			'offline.pending' => 'Đang chờ đồng bộ',
			'offline.syncing' => 'Đang đồng bộ',
			'offline.conflict' => 'Mục này cần bạn xử lý',
			'offline.needsAttention' => 'Một số thay đổi cần bạn xử lý',
			'offline.lastSynced' => 'Đồng bộ lần cuối',
			_ => null,
		};
	}
}
