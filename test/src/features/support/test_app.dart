import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:base/src/app/app_router.dart';
import 'package:base/generated/l10n/strings.g.dart';

/// Pumps a routed feature app with translations and a fixed logical viewport.
Future<void> pumpRouterApp(
  WidgetTester tester,
  AppRouter router, {
  TextScaler textScaler = TextScaler.noScaling,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp.router(
        routerConfig: router.config(
          deepLinkBuilder: (_) => DeepLink.defaultPath,
          reevaluateListenable: router.authGuard,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps one page with translations and a fixed logical viewport.
Future<void> pumpFeaturePage(
  WidgetTester tester,
  Widget page, {
  TextScaler textScaler = TextScaler.noScaling,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

  await tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
        home: page,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
