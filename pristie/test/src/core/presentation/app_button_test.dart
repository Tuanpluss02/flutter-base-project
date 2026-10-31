import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pristie/src/l10n/strings.g.dart';
import 'package:pristie/src/shared/widgets/app_button.dart';

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

  testWidgets('loading blocks taps and exposes a disabled busy state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;

    await tester.pumpWidget(
      _wrap(AppButton(label: 'Save', isLoading: true, onPressed: () => taps++)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(taps, 0);

    final data = tester.getSemantics(find.byType(AppButton)).getSemanticsData();
    final flags = data.flagsCollection;
    expect(flags.isButton, isTrue);
    expect(flags.isEnabled, Tristate.isFalse);
    expect(data.hint, 'Loading');
    expect(data.label, 'Save');

    handle.dispose();
  });

  testWidgets('enabled button invokes callback exactly once per tap', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      _wrap(AppButton(label: 'Retry', onPressed: () => taps++)),
    );

    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('meets 48x48 touch target and does not overflow at 2.0 scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          width: 360,
          child: AppButton(
            label: 'A long localized action label that has to wrap',
            onPressed: () {},
          ),
        ),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(AppButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports an icon and keeps the accessible label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      _wrap(
        AppButton(
          label: 'Continue',
          icon: Icons.arrow_forward,
          onPressed: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    expect(find.bySemanticsLabel('Continue'), findsOneWidget);

    handle.dispose();
  });
}
