import 'package:flutter/material.dart';

/// Theme-derived text styles.
///
/// Font families stay owned by the Material text theme; widgets must not
/// hard-code them.
final class AppTextStyles {
  const AppTextStyles._();

  static TextTheme themeOf(BuildContext context) => Theme.of(context).textTheme;

  static TextStyle display(BuildContext context) =>
      themeOf(context).displaySmall!;

  static TextStyle headline(BuildContext context) =>
      themeOf(context).headlineSmall!;

  static TextStyle title(BuildContext context) => themeOf(context).titleMedium!;

  static TextStyle body(BuildContext context) => themeOf(context).bodyMedium!;

  static TextStyle label(BuildContext context) => themeOf(context).labelLarge!;

  static TextStyle caption(BuildContext context) => themeOf(context).bodySmall!;
}
