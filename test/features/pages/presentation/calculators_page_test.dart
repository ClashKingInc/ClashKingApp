import 'package:clashkingapp/features/pages/presentation/side_tabs_pages.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('calculators expose only the current damage surfaces', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CalculatorsPage(),
      ),
    );

    expect(find.text('Zap quake'), findsOneWidget);
    expect(find.text('Fireball'), findsOneWidget);
    expect(find.text('Ore'), findsNothing);

    await tester.tap(find.text('Fireball'));
    await tester.pumpAndSettle();

    expect(find.text('Fireball level'), findsOneWidget);
  });
}
