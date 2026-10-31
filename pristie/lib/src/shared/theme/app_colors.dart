import 'package:flutter/material.dart';

/// Semantic status colors that are not part of the Material [ColorScheme].
@immutable
final class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.online,
    required this.offline,
    required this.stale,
  });

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color online;
  final Color offline;
  final Color stale;

  static const light = AppColors(
    success: Color(0xFF2E6B34),
    warning: Color(0xFF7A4B00),
    danger: Color(0xFFB3261E),
    info: Color(0xFF0B57D0),
    online: Color(0xFF2E6B34),
    offline: Color(0xFF5C5F5C),
    stale: Color(0xFF7A4B00),
  );

  static const dark = AppColors(
    success: Color(0xFF83D98F),
    warning: Color(0xFFFFB95C),
    danger: Color(0xFFFFB4AB),
    info: Color(0xFF9ECAFF),
    online: Color(0xFF83D98F),
    offline: Color(0xFFC4C7C3),
    stale: Color(0xFFFFB95C),
  );

  /// Returns the extension registered by [AppTheme], falling back to [light].
  static AppColors of(ThemeData theme) =>
      theme.extension<AppColors>() ?? AppColors.light;

  Map<String, Color> get asMap => <String, Color>{
    'success': success,
    'warning': warning,
    'danger': danger,
    'info': info,
    'online': online,
    'offline': offline,
    'stale': stale,
  };

  @override
  AppColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? online,
    Color? offline,
    Color? stale,
  }) {
    return AppColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      online: online ?? this.online,
      offline: offline ?? this.offline,
      stale: stale ?? this.stale,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) {
      return this;
    }
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      online: Color.lerp(online, other.online, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
      stale: Color.lerp(stale, other.stale, t)!,
    );
  }
}
