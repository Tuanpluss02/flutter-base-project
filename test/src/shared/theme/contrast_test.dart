import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:base/src/shared/theme/app_colors.dart';
import 'package:base/src/shared/theme/app_theme.dart';

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = math.max(foregroundLuminance, backgroundLuminance);
  final darker = math.min(foregroundLuminance, backgroundLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AppTheme body text contrast', () {
    test('light theme meets WCAG AA', () {
      final scheme = AppTheme.light.colorScheme;

      expect(
        _contrastRatio(scheme.onSurface, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(scheme.onError, scheme.error),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('dark theme meets WCAG AA', () {
      final scheme = AppTheme.dark.colorScheme;

      expect(
        _contrastRatio(scheme.onSurface, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(scheme.onPrimary, scheme.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(scheme.onError, scheme.error),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('AppColors status text contrast', () {
    test('light status colors are readable on surface', () {
      final theme = AppTheme.light;
      final colors = AppColors.of(theme);
      final surface = theme.colorScheme.surface;

      for (final color in colors.asMap.values) {
        expect(
          _contrastRatio(color, surface),
          greaterThanOrEqualTo(4.5),
          reason: '$color must be readable on $surface',
        );
      }
    });

    test('dark status colors are readable on surface', () {
      final theme = AppTheme.dark;
      final colors = AppColors.of(theme);
      final surface = theme.colorScheme.surface;

      for (final color in colors.asMap.values) {
        expect(
          _contrastRatio(color, surface),
          greaterThanOrEqualTo(4.5),
          reason: '$color must be readable on $surface',
        );
      }
    });
  });

  test('both themes expose the AppColors extension', () {
    expect(AppTheme.light.extension<AppColors>(), isNotNull);
    expect(AppTheme.dark.extension<AppColors>(), isNotNull);
    expect(AppTheme.light.useMaterial3, isTrue);
    expect(AppTheme.dark.useMaterial3, isTrue);
  });
}
