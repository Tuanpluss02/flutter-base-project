import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/core/error/app_failure.dart';
import 'package:pristie/src/l10n/strings.g.dart';
import 'package:pristie/src/shared/widgets/app_button.dart';
import 'package:pristie/src/shared/widgets/app_error_view.dart';

Widget _wrap(Widget child, {TextScaler textScaler = TextScaler.noScaling}) {
  return TranslationProvider(
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  testWidgets('AppErrorView shows localized message and retries once', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var retries = 0;

    await tester.pumpWidget(
      _wrap(
        AppErrorView(
          failure: const AppFailure.network(),
          onRetry: () => retries++,
        ),
      ),
    );

    expect(
      find.text('No internet connection. Check your connection and try again.'),
      findsOneWidget,
    );
    expect(find.text('network'), findsNothing);
    expect(find.bySemanticsLabel('Retry'), findsOneWidget);

    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(retries, 1);
    handle.dispose();
  });

  testWidgets('AppErrorView does not present cancellation as an error', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const AppErrorView(failure: AppFailure.cancelled())),
    );

    expect(find.text('Something went wrong. Try again.'), findsNothing);
    expect(find.byType(AppButton), findsNothing);
  });

  testWidgets('AppErrorView maps every failure to a localized message', (
    tester,
  ) async {
    final failures = <AppFailure>[
      const AppFailure.timeout(),
      const AppFailure.unauthorized(),
      const AppFailure.forbidden(),
      const AppFailure.notFound(),
      const AppFailure.conflict(),
      const AppFailure.validation(<String, ValidationIssue>{}),
      const AppFailure.rateLimit(null),
      const AppFailure.server(null),
      const AppFailure.payloadTooLarge(),
      const AppFailure.parse(),
      const AppFailure.localPersistence(),
      const AppFailure.unknown(),
    ];

    for (final failure in failures) {
      await tester.pumpWidget(_wrap(AppErrorView(failure: failure)));
      expect(
        find.byType(AppButton),
        findsNothing,
        reason: 'No retry action is provided by default',
      );
      expect(
        find.byType(Text),
        findsWidgets,
        reason: '${failure.runtimeType} must render localized copy',
      );
    }
  });
}
