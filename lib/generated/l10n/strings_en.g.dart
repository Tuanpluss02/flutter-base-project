///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$en app = Translations$app$en.internal(_root);
	late final Translations$common$en common = Translations$common$en.internal(_root);
	late final Translations$login$en login = Translations$login$en.internal(_root);
	late final Translations$home$en home = Translations$home$en.internal(_root);
	late final Translations$settings$en settings = Translations$settings$en.internal(_root);
	late final Translations$error$en error = Translations$error$en.internal(_root);
	late final Translations$offline$en offline = Translations$offline$en.internal(_root);
}

// Path: app
class Translations$app$en {
	Translations$app$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Base'
	String get name => 'Base';
}

// Path: common
class Translations$common$en {
	Translations$common$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Retry'
	String get retry => 'Retry';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Loading'
	String get loading => 'Loading';

	/// en: 'Nothing here yet'
	String get empty => 'Nothing here yet';
}

// Path: login
class Translations$login$en {
	Translations$login$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Sign in'
	String get title => 'Sign in';

	/// en: 'Email'
	String get email => 'Email';

	/// en: 'Password'
	String get password => 'Password';

	/// en: 'Sign in'
	String get submit => 'Sign in';

	/// en: 'This field is required'
	String get required => 'This field is required';

	/// en: 'Incorrect email or password'
	String get invalidCredentials => 'Incorrect email or password';
}

// Path: home
class Translations$home$en {
	Translations$home$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Home'
	String get title => 'Home';

	/// en: 'Load more'
	String get loadMore => 'Load more';

	/// en: 'Demo item $id'
	String item({required Object id}) => 'Demo item ${id}';
}

// Path: settings
class Translations$settings$en {
	Translations$settings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Settings'
	String get title => 'Settings';

	/// en: 'Theme'
	String get theme => 'Theme';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Sign out'
	String get logout => 'Sign out';

	/// en: 'Are you sure you want to sign out?'
	String get logoutConfirm => 'Are you sure you want to sign out?';

	/// en: 'System'
	String get themeSystem => 'System';

	/// en: 'Light'
	String get themeLight => 'Light';

	/// en: 'Dark'
	String get themeDark => 'Dark';

	/// en: 'English'
	String get english => 'English';

	/// en: 'Vietnamese'
	String get vietnamese => 'Vietnamese';
}

// Path: error
class Translations$error$en {
	Translations$error$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'No internet connection. Check your connection and try again.'
	String get network => 'No internet connection. Check your connection and try again.';

	/// en: 'The request timed out. Try again.'
	String get timeout => 'The request timed out. Try again.';

	/// en: 'Your session has expired. Please sign in again.'
	String get unauthorized => 'Your session has expired. Please sign in again.';

	/// en: 'You do not have permission to do this.'
	String get forbidden => 'You do not have permission to do this.';

	/// en: 'We could not find what you were looking for.'
	String get notFound => 'We could not find what you were looking for.';

	/// en: 'This data has changed. Refresh and try again.'
	String get conflict => 'This data has changed. Refresh and try again.';

	/// en: 'Please check the information you entered.'
	String get validation => 'Please check the information you entered.';

	/// en: 'Too many requests. Wait a moment and try again.'
	String get rateLimit => 'Too many requests. Wait a moment and try again.';

	/// en: 'Something went wrong on our side. Try again later.'
	String get server => 'Something went wrong on our side. Try again later.';

	/// en: 'The selected file is too large.'
	String get payloadTooLarge => 'The selected file is too large.';

	/// en: 'We could not read the response. Try again.'
	String get parse => 'We could not read the response. Try again.';

	/// en: 'We could not save your changes on this device.'
	String get localPersistence => 'We could not save your changes on this device.';

	/// en: 'Something went wrong. Try again.'
	String get unknown => 'Something went wrong. Try again.';
}

// Path: offline
class Translations$offline$en {
	Translations$offline$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Offline'
	String get offline => 'Offline';

	/// en: 'Showing saved data'
	String get stale => 'Showing saved data';

	/// en: 'Waiting to sync'
	String get pending => 'Waiting to sync';

	/// en: 'Syncing'
	String get syncing => 'Syncing';

	/// en: 'This item needs your attention'
	String get conflict => 'This item needs your attention';

	/// en: 'Some changes need your attention'
	String get needsAttention => 'Some changes need your attention';

	/// en: 'Last synced'
	String get lastSynced => 'Last synced';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.name' => 'Base',
			'common.retry' => 'Retry',
			'common.cancel' => 'Cancel',
			'common.loading' => 'Loading',
			'common.empty' => 'Nothing here yet',
			'login.title' => 'Sign in',
			'login.email' => 'Email',
			'login.password' => 'Password',
			'login.submit' => 'Sign in',
			'login.required' => 'This field is required',
			'login.invalidCredentials' => 'Incorrect email or password',
			'home.title' => 'Home',
			'home.loadMore' => 'Load more',
			'home.item' => ({required Object id}) => 'Demo item ${id}',
			'settings.title' => 'Settings',
			'settings.theme' => 'Theme',
			'settings.language' => 'Language',
			'settings.logout' => 'Sign out',
			'settings.logoutConfirm' => 'Are you sure you want to sign out?',
			'settings.themeSystem' => 'System',
			'settings.themeLight' => 'Light',
			'settings.themeDark' => 'Dark',
			'settings.english' => 'English',
			'settings.vietnamese' => 'Vietnamese',
			'error.network' => 'No internet connection. Check your connection and try again.',
			'error.timeout' => 'The request timed out. Try again.',
			'error.unauthorized' => 'Your session has expired. Please sign in again.',
			'error.forbidden' => 'You do not have permission to do this.',
			'error.notFound' => 'We could not find what you were looking for.',
			'error.conflict' => 'This data has changed. Refresh and try again.',
			'error.validation' => 'Please check the information you entered.',
			'error.rateLimit' => 'Too many requests. Wait a moment and try again.',
			'error.server' => 'Something went wrong on our side. Try again later.',
			'error.payloadTooLarge' => 'The selected file is too large.',
			'error.parse' => 'We could not read the response. Try again.',
			'error.localPersistence' => 'We could not save your changes on this device.',
			'error.unknown' => 'Something went wrong. Try again.',
			'offline.offline' => 'Offline',
			'offline.stale' => 'Showing saved data',
			'offline.pending' => 'Waiting to sync',
			'offline.syncing' => 'Syncing',
			'offline.conflict' => 'This item needs your attention',
			'offline.needsAttention' => 'Some changes need your attention',
			'offline.lastSynced' => 'Last synced',
			_ => null,
		};
	}
}
