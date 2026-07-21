import 'package:clashkingapp/features/damage_calculator/data/damage_catalog.dart';
import 'package:clashkingapp/features/damage_calculator/domain/damage_calculator_engine.dart';
import 'package:clashkingapp/features/damage_calculator/domain/damage_calculator_session.dart';
import 'package:clashkingapp/features/pages/presentation/side_tabs_pages.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'renders one mobile-first damage calculator with static defaults',
    (tester) async {
      await _pump(tester);

      expect(
        find.text('Compare one attack stack against multiple buildings.'),
        findsOneWidget,
      );
      expect(find.text('Buildings'), findsOneWidget);
      expect(find.text('Town Hall'), findsWidgets);
      expect(find.text('1,000 HP'), findsOneWidget);
      expect(find.text('Manual attack stack'), findsOneWidget);
      expect(find.text('Lightning'), findsOneWidget);
      expect(find.text('Earthquake'), findsOneWidget);
      expect(find.byType(TabBarView), findsNothing);

      await tester.scrollUntilVisible(find.text('Zap Quake optimizer'), 400);
      expect(find.text('Zap Quake optimizer'), findsOneWidget);
    },
  );

  testWidgets('searches and adds another building on a phone', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('add-building')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('building-search')),
      'air',
    );
    await tester.pump();

    expect(find.text('Air Defense'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.text('Town Hall'),
      ),
      findsNothing,
    );

    await tester.tap(find.text('Air Defense'));
    await tester.pumpAndSettle();

    expect(find.text('Air Defense'), findsOneWidget);
    expect(find.text('600 HP'), findsOneWidget);
  });

  testWidgets('updates independent results from the manual stack', (
    tester,
  ) async {
    await _pump(tester);

    final lightningRow = find.byKey(const ValueKey('source-lightning'));
    await tester.ensureVisible(lightningRow);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: lightningRow,
        matching: find.byIcon(Icons.add_circle_outline_rounded),
      ),
    );
    await tester.pump();
    expect(
      find.descendant(of: lightningRow, matching: find.text('1')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('result-town-hall')),
      300,
    );

    expect(find.text('400 damage · 600 HP remaining'), findsOneWidget);
    expect(find.text('Survives'), findsOneWidget);
  });

  testWidgets('verified account presets remain local to the calculator', (
    tester,
  ) async {
    await _pump(
      tester,
      accountPresets: const [
        DamageAccountPreset(
          tag: '#ABC',
          name: 'Chief',
          townHall: 10,
          ownedLevels: {DamageSourceKind.lightning: 1},
        ),
      ],
    );

    await tester.tap(find.text('Verified account preset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chief · TH10').last);
    await tester.pumpAndSettle();

    expect(find.text('800 HP'), findsOneWidget);
    expect(
      find.text('Changes here do not update the player account.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('lightning-level-1')), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  List<DamageAccountPreset> accountPresets = const [],
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CalculatorsPage(catalog: _catalog, accountPresets: accountPresets),
    ),
  );
  await tester.pump();
}

const _catalog = DamageCatalog(
  maxTownHall: 12,
  buildings: [
    BuildingDefinition(
      id: 'town-hall',
      name: 'Town Hall',
      imageName: 'Town Hall',
      zapQuakeEligible: true,
      levels: [
        BuildingLevelDefinition(level: 1, hitpoints: 800, requiredTownHall: 10),
        BuildingLevelDefinition(
          level: 2,
          hitpoints: 1000,
          requiredTownHall: 12,
        ),
      ],
    ),
    BuildingDefinition(
      id: 'air-defense',
      name: 'Air Defense',
      imageName: 'Air Defense',
      zapQuakeEligible: true,
      levels: [
        BuildingLevelDefinition(level: 1, hitpoints: 600, requiredTownHall: 12),
      ],
    ),
  ],
  sources: [
    DamageSourceDefinition(
      kind: DamageSourceKind.lightning,
      name: 'Lightning Spell',
      imageUrl: '',
      levels: [DamageLevel(level: 1, requiredTownHall: 3, damage: 400)],
    ),
    DamageSourceDefinition(
      kind: DamageSourceKind.earthquake,
      name: 'Earthquake Spell',
      imageUrl: '',
      levels: [
        DamageLevel(level: 1, requiredTownHall: 8, earthquakePercent: 29),
      ],
    ),
  ],
);
