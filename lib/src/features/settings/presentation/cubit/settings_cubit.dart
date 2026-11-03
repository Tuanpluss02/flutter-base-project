import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:base/src/core/error/app_failure.dart';
import 'package:base/src/core/result/result.dart';
import 'package:base/src/core/storage/local_storage.dart';
import 'package:base/generated/l10n/strings.g.dart';

import '../../domain/usecases/logout_use_case.dart';

final class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = AppLocale.en,
    this.isLoggingOut = false,
    this.failure,
  });

  final ThemeMode themeMode;
  final AppLocale locale;
  final bool isLoggingOut;
  final AppFailure? failure;

  SettingsState copyWith({
    ThemeMode? themeMode,
    AppLocale? locale,
    bool? isLoggingOut,
    AppFailure? failure,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    locale: locale ?? this.locale,
    isLoggingOut: isLoggingOut ?? this.isLoggingOut,
    failure: failure,
  );
}

final class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._storage, this._logout) : super(const SettingsState());

  static const themeModeKey = 'theme_mode';
  static const localeKey = 'locale';

  final LocalStorage _storage;
  final LogoutUseCase _logout;

  Future<void> load() async {
    final savedTheme = _storage.getString(themeModeKey);
    final savedLocale = _storage.getString(localeKey);
    final themeMode =
        ThemeMode.values.where((mode) => mode.name == savedTheme).firstOrNull ??
        ThemeMode.system;
    final locale =
        AppLocale.values
            .where((value) => value.languageCode == savedLocale)
            .firstOrNull ??
        AppLocale.en;
    await LocaleSettings.setLocale(locale);
    if (!isClosed) emit(state.copyWith(themeMode: themeMode, locale: locale));
  }

  Future<void> changeTheme(ThemeMode themeMode) async {
    try {
      await _storage.setString(themeModeKey, themeMode.name);
      if (!isClosed) emit(state.copyWith(themeMode: themeMode));
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(failure: const AppFailure.localPersistence()));
      }
    }
  }

  Future<void> changeLocale(AppLocale locale) async {
    try {
      await _storage.setString(localeKey, locale.languageCode);
      await LocaleSettings.setLocale(locale);
      if (!isClosed) emit(state.copyWith(locale: locale));
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(failure: const AppFailure.localPersistence()));
      }
    }
  }

  Future<void> logout() async {
    if (state.isLoggingOut) return;
    emit(state.copyWith(isLoggingOut: true));
    final result = await _logout.call();
    if (isClosed) return;
    switch (result) {
      case Ok<void>():
        emit(state.copyWith(isLoggingOut: false));
      case Err<void>(failure: CancelledFailure()):
        emit(state.copyWith(isLoggingOut: false));
      case Err<void>(:final failure):
        emit(state.copyWith(isLoggingOut: false, failure: failure));
    }
  }
}
