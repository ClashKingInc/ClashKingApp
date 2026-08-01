import 'package:clashkingapp/features/damage_calculator/data/damage_catalog.dart';
import 'package:clashkingapp/features/damage_calculator/domain/damage_calculator_engine.dart';
import 'package:clashkingapp/features/damage_calculator/domain/damage_calculator_session.dart';
import 'package:clashkingapp/features/pages/presentation/side_tabs_pages.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts with an explicit target and attack method flow', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Calculators'), findsOneWidget);
    expect(find.text('Damage'), findsOneWidget);
    expect(find.text('Building to destroy'), findsOneWidget);
    expect(find.text('No building selected'), findsOneWidget);
    expect(find.text('Choose a building'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.byType(TabBarView), findsNothing);

    await tester.tap(find.text('Choose a building'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zap + quake'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('damage-calculator-scroll')),
      const Offset(0, -1200),
    );
    await tester.pumpAndSettle();
    expect(find.text('Zap Quake optimizer'), findsOneWidget);
  });

  testWidgets('searches and adds another building on a phone', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('choose-building')));
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

  testWidgets('allows a custom attack method', (tester) async {
    await _pump(tester);

    await tester.ensureVisible(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();

    final lightningRow = find.byKey(const ValueKey('source-lightning'));
    final earthquakeRow = find.byKey(const ValueKey('source-earthquake'));
    expect(lightningRow, findsOneWidget);
    expect(earthquakeRow, findsOneWidget);
    expect(
      find.descendant(of: lightningRow, matching: find.text('0')),
      findsOneWidget,
    );

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
  });

  testWidgets('calculates raids for a farm goal', (tester) async {
    addTearDown(() => GameDataService.loadFromBundleForTesting({}));
    GameDataService.loadFromBundleForTesting({
      'league_tiers': [
        {
          'name': 'Titan League 25',
          'rewards': [
            {
              'townhall_level': 10,
              'resources': {'gold': 350000},
            },
          ],
        },
      ],
    });
    await _pump(
      tester,
      accountPresets: const [
        DamageAccountPreset(
          tag: '#FARM',
          name: 'Farmer',
          townHall: 12,
          league: 'Titan League 25',
        ),
      ],
    );

    final modeSelector = find.byKey(const ValueKey('calculator-tabs'));
    await tester.tap(
      find.descendant(of: modeSelector, matching: find.text('Farm goal')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('farm-goal-building')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Town Hall').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('farm-goal-level')), findsOneWidget);
    expect(find.text('350000'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('farm-goal-average-loot')),
      '100',
    );
    await tester.pump();

    final result = find.byKey(const ValueKey('farm-goal-result'));
    expect(result, findsOneWidget);
    expect(
      find.descendant(of: result, matching: find.text('10')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: result, matching: find.text('Raids needed')),
      findsOneWidget,
    );
  });

  testWidgets('updates independent results from the manual stack', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Choose a building'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Zap + quake'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zap + quake'));
    await tester.pumpAndSettle();
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
      find.descendant(of: lightningRow, matching: find.text('6')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey('damage-calculator-scroll')),
      const Offset(0, 1200),
    );
    await tester.pumpAndSettle();
    expect(find.text('1,000 damage · 0 HP remaining'), findsOneWidget);
    expect(find.text('Destroyed'), findsOneWidget);
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
          league: 'Titan League 25',
          ownedLevels: {DamageSourceKind.lightning: 1},
        ),
      ],
    );

    await tester.tap(find.text('Choose a building'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Choose an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chief · TH10').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Zap + quake'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zap + quake'));
    await tester.pumpAndSettle();

    expect(find.text('800 HP'), findsOneWidget);
    expect(
      find.text('The levels used follow the selected account.'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('source-lightning')),
        matching: find.text('Level 1'),
      ),
      findsOneWidget,
    );
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
        BuildingLevelDefinition(
          level: 1,
          hitpoints: 800,
          requiredTownHall: 10,
          upgradeResource: 'Gold',
          upgradeCost: 0,
        ),
        BuildingLevelDefinition(
          level: 2,
          hitpoints: 1000,
          requiredTownHall: 12,
          upgradeResource: 'Gold',
          upgradeCost: 1000,
        ),
      ],
    ),
    BuildingDefinition(
      id: 'air-defense',
      name: 'Air Defense',
      imageName: 'Air Defense',
      zapQuakeEligible: true,
      levels: [
        BuildingLevelDefinition(
          level: 1,
          hitpoints: 600,
          requiredTownHall: 12,
          upgradeResource: 'Gold',
          upgradeCost: 2000,
        ),
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
