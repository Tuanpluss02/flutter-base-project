import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:base/generated/l10n/strings.g.dart';
import 'package:base/src/shared/widgets/app_empty_view.dart';
import 'package:base/src/shared/widgets/app_loading_view.dart';

Widget _wrap(Widget child) {
  return TranslationProvider(
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await LocaleSettings.setLocale(AppLocale.en);
  });

  testWidgets('loading announces one localized live-region label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(_wrap(const AppLoadingView()));

    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    final data = tester
        .getSemantics(find.bySemanticsLabel('Loading'))
        .getSemanticsData();
    expect(data.flagsCollection.isLiveRegion, isTrue);
    expect(data.label, 'Loading');

    handle.dispose();
  });

  testWidgets('empty announces its localized label once', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(_wrap(const AppEmptyView()));

    expect(find.bySemanticsLabel('Nothing here yet'), findsOneWidget);
    expect(find.text('Nothing here yet'), findsOneWidget);

    handle.dispose();
  });

  testWidgets('empty uses caller-provided localized copy', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppEmptyView(message: 'No saved searches')),
    );

    expect(find.text('No saved searches'), findsOneWidget);
  });
}
