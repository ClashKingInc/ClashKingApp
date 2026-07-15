import 'package:clashkingapp/common/widgets/loading/app_loading_screen.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('startup artwork preserves bounded logo proportions', (
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
        home: AppLoadingScreen(),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('startup-mark'))),
      const Size(80, 80),
    );
    final wordmarkSize = tester.getSize(
      find.byKey(const Key('startup-wordmark')),
    );
    expect(wordmarkSize.width, closeTo(319.8, 0.01));
    expect(wordmarkSize.width / wordmarkSize.height, closeTo(3806 / 558, 0.01));

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
