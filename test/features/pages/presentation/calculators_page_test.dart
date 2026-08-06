import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/damage_calculator/data/damage_catalog.dart';
import 'package:clashkingapp/features/damage_calculator/domain/damage_calculator_engine.dart';
import 'package:clashkingapp/features/damage_calculator/domain/damage_calculator_session.dart';
import 'package:clashkingapp/features/pages/presentation/side_page_components.dart';
import 'package:clashkingapp/features/pages/presentation/side_tabs_pages.dart';
import 'package:clashkingapp/features/upgrade_tracker/data/upgrade_tracker_repository.dart';
import 'package:clashkingapp/features/upgrade_tracker/models/upgrade_tracker_models.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('starts with an explicit target and attack method flow', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Calculators'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('calculator-tabs')),
        matching: find.text('Damage'),
      ),
      findsOneWidget,
    );
    expect(find.text('Building to destroy'), findsOneWidget);
    expect(find.text('No building selected'), findsOneWidget);
    expect(find.text('Choose a building'), findsOneWidget);
    final sectionTitles = tester
        .widgetList<SidePageSectionHeader>(find.byType(SidePageSectionHeader))
        .map((header) => header.title)
        .toList(growable: false);
    expect(sectionTitles.take(3), [
      'Account',
      'Building to destroy',
      'Manual attack stack',
    ]);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('calculator-quick-setups')),
        matching: find.text('Custom'),
      ),
      findsOneWidget,
    );
    expect(find.byType(TabBarView), findsNothing);

    await tester.tap(find.text('Choose a building'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Zap + quake'),
      300,
      scrollable: _damageScrollable,
    );
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

    await tester.tap(find.text('Air Defense').first);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('target-air-defense')),
        matching: find.text('Air Defense'),
      ),
      findsOneWidget,
    );
    expect(find.text('600 HP'), findsOneWidget);
  });

  testWidgets('allows a custom attack method', (tester) async {
    await _pump(tester);

    await tester.ensureVisible(
      find.descendant(
        of: find.byKey(const ValueKey('calculator-quick-setups')),
        matching: find.text('Custom'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('calculator-quick-setups')),
        matching: find.text('Custom'),
      ),
    );
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

  testWidgets('remains stable at 200 percent text scale', (tester) async {
    await _pump(tester, textScaler: const TextScaler.linear(2));

    expect(find.text('Calculators'), findsOneWidget);
    expect(find.text('Building to destroy'), findsOneWidget);
    final artwork = tester.getRect(
      find.byKey(const ValueKey('calculator-hero-artwork')),
    );
    final title = tester.getRect(find.text('Calculators'));
    expect(artwork.width, 112);
    expect(artwork.bottom, lessThan(title.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the centered utility identity on a narrow phone', (
    tester,
  ) async {
    await _pump(tester);

    final artwork = tester.getRect(
      find.byKey(const ValueKey('calculator-hero-artwork')),
    );
    final title = tester.getRect(find.text('Calculators'));
    expect(artwork.center.dx, closeTo(195, 1));
    expect(artwork.bottom, lessThan(title.top));
  });

  testWidgets('uses localized calculator copy on a narrow French phone', (
    tester,
  ) async {
    await _pump(tester, locale: const Locale('fr'));

    expect(
      find.text("Compare une composition d'attaque à plusieurs bâtiments."),
      findsOneWidget,
    );
    expect(find.text("Composition d'attaque manuelle"), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('damage-calculator-scroll')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(find.text('Foudre'), findsOneWidget);
    expect(find.text('400 dégâts par utilisation'), findsOneWidget);
    expect(find.text('Manual attack stack'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calculates attacks for a farm goal', (tester) async {
    addTearDown(() => GameDataService.loadFromBundleForTesting({}));
    GameDataService.loadFromBundleForTesting({
      'league_tiers': [
        {
          'name': 'Titan League 25',
          'rewards': [
            {
              'townhall_level': 10,
              'resources': {'gold': 350000},
              'star_bonus': {'gold': 900000},
            },
          ],
        },
      ],
    });
    expect(
      (GameDataService.playerLeagueData['leagues'] as Map)['Titan League 25'],
      isNotNull,
    );
    expect(
      ((GameDataService.playerLeagueData['leagues'] as Map)['Titan League 25']
          as Map)['rewards'][0]['star_bonus'],
      isNotNull,
    );
    await _pump(
      tester,
      catalog: _farmGoalCatalog,
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

    expect(
      tester
          .widgetList<MobileWebImage>(find.byType(MobileWebImage))
          .where((image) => image.imageUrl == ImageAssets.lootCart),
      hasLength(2),
    );

    expect(find.text('No building selected'), findsOneWidget);
    expect(find.text('Choose a building'), findsOneWidget);
    expect(find.text('Upgrade Tracker data needed'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('farm-goal-open-upgrade-tracker')),
      findsOneWidget,
    );
    expect(
      tester.widget(
        find.byKey(const ValueKey('farm-goal-open-upgrade-tracker')),
      ),
      isA<OutlinedButton>(),
    );
    expect(find.text('1013000'), findsOneWidget);
    expect(find.text('Gold'), findsOneWidget);
    expect(
      find.textContaining('Titan League 25 league bonus: 350,000 Gold'),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey('farm-goal-scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('farm-goal-building')));
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    await tester.tap(find.text('Town Hall').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('farm-goal-level')), findsOneWidget);
    expect(find.text('Change building'), findsOneWidget);
    expect(find.text('1013000'), findsOneWidget);
    expect(
      find.textContaining('Titan League 25 league bonus: 350,000 Gold'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Star bonus: 900,000 Gold after 5 stars'),
      findsOneWidget,
    );
    expect(find.text('1,363,000 Gold / attack'), findsOneWidget);

    final result = find.byKey(const ValueKey('farm-goal-result'));
    expect(result, findsOneWidget);
    expect(
      find.descendant(
        of: result,
        matching: find.text('1,363,000 Gold / attack'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: result, matching: find.text('19')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: result, matching: find.text('23')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: result, matching: find.text('31')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: result, matching: find.text('Attacks needed')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<MobileWebImage>(
            find.byKey(const ValueKey('farm-goal-attacks-icon')),
          )
          .imageUrl,
      ImageAssets.sword,
    );
  });

  testWidgets('shows the next Upgrade Tracker plan item in the farm picker', (
    tester,
  ) async {
    final snapshot = UpgradeTrackerSnapshot(
      tag: '#FARM',
      name: 'Farmer',
      townHallLevel: 12,
      builderHallLevel: 0,
      homeBuilderCount: 5,
      builderBaseBuilderCount: 0,
      items: const [
        UpgradeTrackerItem(
          id: 1,
          name: 'Town Hall',
          imageUrl: '',
          village: UpgradeVillage.home,
          category: UpgradeCategory.defenses,
          queue: UpgradeQueue.builders,
          currentLevel: 2,
          targetLevel: 3,
          count: 1,
          steps: [
            UpgradeStep(
              targetLevel: 3,
              costs: [UpgradeCost('Gold', 25000000)],
              seconds: 86400,
            ),
          ],
          completedUpgradeSeconds: 0,
          totalUpgradeSeconds: 86400,
        ),
      ],
      collections: const [],
      boosts: const UpgradeBoosts(),
      events: const [],
      capturedAt: DateTime.now(),
    );
    await _pump(
      tester,
      catalog: _farmGoalCatalog,
      accountPresets: const [
        DamageAccountPreset(
          tag: '#FARM',
          name: 'Farmer',
          townHall: 12,
          league: 'Titan League 25',
        ),
      ],
      initialTrackerSnapshot: snapshot,
    );

    await tester.tap(find.text('Farm goal'));
    await tester.pumpAndSettle();
    expect(find.text('Upgrade Tracker data needed'), findsNothing);
    expect(find.byType(CKUpgradeRow), findsOneWidget);
    expect(
      tester.widget<CKUpgradeRow>(find.byType(CKUpgradeRow)).accentColor,
      Colors.transparent,
    );
    expect(find.text('Use building'), findsNothing);
    final colorScheme = Theme.of(
      tester.element(find.byKey(const ValueKey('farm-goal-target'))),
    ).colorScheme;
    await tester.drag(
      find.byKey(const ValueKey('farm-goal-scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('farm-goal-building')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.text('Next in Upgrade Tracker plan'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(DraggableScrollableSheet),
        matching: find.text('Level 2 → Level 3 · 25,000,000 Gold'),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('farm-goal-tracker-picker-item')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Town Hall · Level 3'), findsOneWidget);
    expect(find.text('Upgrade cost: 25,000,000 Gold'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('farm-goal-tracker-suggestion')),
      findsNothing,
    );
    final changeBuildingButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Change building'),
    );
    expect(
      changeBuildingButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      colorScheme.onSurface,
    );
  });

  testWidgets('shows a tracker target when it is the only picker choice', (
    tester,
  ) async {
    final snapshot = UpgradeTrackerSnapshot(
      tag: '#FARM',
      name: 'Farmer',
      townHallLevel: 12,
      builderHallLevel: 0,
      homeBuilderCount: 5,
      builderBaseBuilderCount: 0,
      items: const [
        UpgradeTrackerItem(
          id: 1,
          name: 'Town Hall',
          imageUrl: '',
          village: UpgradeVillage.home,
          category: UpgradeCategory.defenses,
          queue: UpgradeQueue.builders,
          currentLevel: 1,
          targetLevel: 2,
          count: 1,
          steps: [
            UpgradeStep(
              targetLevel: 2,
              costs: [UpgradeCost('Gold', 1000)],
              seconds: 86400,
            ),
          ],
          completedUpgradeSeconds: 0,
          totalUpgradeSeconds: 86400,
        ),
      ],
      collections: const [],
      boosts: const UpgradeBoosts(),
      events: const [],
      capturedAt: DateTime.now(),
    );
    await _pump(
      tester,
      catalog: _trackerOnlyCatalog,
      accountPresets: const [
        DamageAccountPreset(
          tag: '#FARM',
          name: 'Farmer',
          townHall: 12,
          league: 'Titan League 25',
        ),
      ],
      initialTrackerSnapshot: snapshot,
    );

    await tester.tap(find.text('Farm goal'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('farm-goal-scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('farm-goal-building')));
    await tester.pumpAndSettle();

    expect(find.text('No buildings found'), findsNothing);
    expect(
      find.byKey(const ValueKey('farm-goal-tracker-picker-item')),
      findsOneWidget,
    );
  });

  testWidgets('does not suggest a building already maxed in Upgrade Tracker', (
    tester,
  ) async {
    final snapshot = UpgradeTrackerSnapshot(
      tag: '#FARM',
      name: 'Farmer',
      townHallLevel: 12,
      builderHallLevel: 0,
      homeBuilderCount: 5,
      builderBaseBuilderCount: 0,
      items: const [
        UpgradeTrackerItem(
          id: 2,
          name: 'Air Defense',
          imageUrl: '',
          village: UpgradeVillage.home,
          category: UpgradeCategory.defenses,
          queue: UpgradeQueue.builders,
          currentLevel: 1,
          targetLevel: 1,
          count: 1,
          steps: [],
          completedUpgradeSeconds: 0,
          totalUpgradeSeconds: 0,
        ),
      ],
      collections: const [],
      boosts: const UpgradeBoosts(),
      events: const [],
      capturedAt: DateTime.now(),
    );
    await _pump(
      tester,
      catalog: _farmGoalCatalog,
      accountPresets: const [
        DamageAccountPreset(
          tag: '#FARM',
          name: 'Farmer',
          townHall: 12,
          league: 'Titan League 25',
        ),
      ],
      initialTrackerSnapshot: snapshot,
    );

    await tester.tap(find.text('Farm goal'));
    await tester.pumpAndSettle();

    expect(find.byType(CKUpgradeRow), findsNothing);
    expect(
      find.text(
        'No remaining building upgrades were found in Upgrade Tracker. '
        'You can still choose a building manually.',
      ),
      findsOneWidget,
    );
    expect(find.text('Choose a building'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('farm-goal-scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('farm-goal-building')));
    await tester.pumpAndSettle();
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.text('Air Defense'), findsNothing);
  });

  testWidgets('clears a selected building when tracker data marks it maxed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    UpgradeTrackerRepository.shared.clearCache();
    addTearDown(UpgradeTrackerRepository.shared.clearCache);
    const presets = [
      DamageAccountPreset(
        tag: '#FARM',
        name: 'Farmer',
        townHall: 12,
        league: 'Titan League 25',
      ),
    ];
    await _pump(tester, catalog: _farmGoalCatalog, accountPresets: presets);

    await tester.tap(find.text('Farm goal'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('farm-goal-scroll')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('farm-goal-building')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Air Defense').last);
    await tester.pumpAndSettle();
    expect(find.text('Air Defense · Level 1'), findsOneWidget);

    final snapshot = UpgradeTrackerSnapshot(
      tag: '#FARM',
      name: 'Farmer',
      townHallLevel: 12,
      builderHallLevel: 0,
      homeBuilderCount: 5,
      builderBaseBuilderCount: 0,
      items: const [
        UpgradeTrackerItem(
          id: 2,
          name: 'Air Defense',
          imageUrl: '',
          village: UpgradeVillage.home,
          category: UpgradeCategory.defenses,
          queue: UpgradeQueue.builders,
          currentLevel: 1,
          targetLevel: 1,
          count: 1,
          steps: [],
          completedUpgradeSeconds: 0,
          totalUpgradeSeconds: 0,
        ),
      ],
      collections: const [],
      boosts: const UpgradeBoosts(),
      events: const [],
      capturedAt: DateTime.now(),
    );
    await UpgradeTrackerRepository.shared.saveRawSnapshot('#FARM', const {
      'tag': '#FARM',
      'name': 'Farmer',
    }, parsedSnapshot: snapshot);

    await _pump(
      tester,
      catalog: _farmGoalCatalog,
      accountPresets: presets,
      locale: const Locale('en', 'US'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Air Defense · Level 1'), findsNothing);
    expect(find.text('No building selected'), findsOneWidget);
    expect(find.byKey(const ValueKey('farm-goal-result')), findsNothing);
  });

  testWidgets('updates independent results from the manual stack', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Choose a building'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Zap + quake'),
      300,
      scrollable: _damageScrollable,
    );
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

  testWidgets('both modes default to the first verified account preset', (
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

    expect(find.text('Chief'), findsOneWidget);
    expect(find.text('#ABC · TH10'), findsOneWidget);
    expect(find.text('Choose an account'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('calculator-account-selector')));
    await tester.pumpAndSettle();
    final colorScheme = Theme.of(
      tester.element(find.text('Chief · TH10')),
    ).colorScheme;
    expect(
      tester.widget<Text>(find.text('Chief · TH10')).style?.color,
      colorScheme.onSurface,
    );
    expect(
      tester.widget<Text>(find.text('#ABC · Titan League 25')).style?.color,
      colorScheme.onSurfaceVariant,
    );
    await tester.tap(find.text('Chief · TH10'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Farm goal'));
    await tester.pumpAndSettle();
    expect(find.text('Chief'), findsOneWidget);
    expect(find.text('#ABC · TH10'), findsOneWidget);

    await tester.tap(find.text('Damage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose a building'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Zap + quake'),
      300,
      scrollable: _damageScrollable,
    );
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

final Finder _damageScrollable = find.descendant(
  of: find.byKey(const ValueKey('damage-calculator-scroll')),
  matching: find.byType(Scrollable),
);

Future<void> _pump(
  WidgetTester tester, {
  DamageCatalog catalog = _catalog,
  List<DamageAccountPreset> accountPresets = const [],
  UpgradeTrackerSnapshot? initialTrackerSnapshot,
  TextScaler textScaler = TextScaler.noScaling,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: CalculatorsPage(
        catalog: catalog,
        accountPresets: accountPresets,
        initialTrackerSnapshot: initialTrackerSnapshot,
      ),
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

const _farmGoalCatalog = DamageCatalog(
  maxTownHall: 13,
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
        BuildingLevelDefinition(
          level: 3,
          hitpoints: 1200,
          requiredTownHall: 13,
          upgradeResource: 'Gold',
          upgradeCost: 25000000,
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

const _trackerOnlyCatalog = DamageCatalog(
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
  ],
  sources: [],
);
