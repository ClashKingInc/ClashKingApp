import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/upgrade_tracker/models/upgrade_tracker_models.dart';
import 'package:clashkingapp/features/upgrade_tracker/presentation/upgrade_tracker_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates Warden follow threshold copies', () {
    expect(wardenFollowThresholdCopies(0.5), 40);
    expect(wardenFollowThresholdCopies(25), 1);
    expect(wardenFollowThresholdCopies(0), isNull);
  });

  test('formats unit movement speed as tiles per second', () {
    expect(formatUnitMovementSpeed(200), '2');
    expect(formatUnitMovementSpeed(80), '0.8');
    expect(formatUnitMovementSpeed(185), '1.9');
    expect(formatUnitMovementSpeed(195), '2');
  });

  testWidgets('shows explicit zero weights with game assets on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpDetailLauncher(
      tester,
      _item(category: UpgradeCategory.troops, wardenWeight: 0, healerWeight: 0),
    );

    expect(find.byKey(const ValueKey('warden-weight')), findsOneWidget);
    expect(find.byKey(const ValueKey('healer-weight')), findsOneWidget);
    expect(find.byKey(const ValueKey('housing-space')), findsOneWidget);
    final statsTop = tester.getTopLeft(find.text('Stats')).dy;
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('warden-weight'))).dy,
      greaterThan(statsTop),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('healer-weight'))).dy,
      greaterThan(statsTop),
    );
    expect(
      find.text('Does not contribute to follow threshold'),
      findsOneWidget,
    );
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);

    final urls = tester
        .widgetList<MobileWebImage>(find.byType(MobileWebImage))
        .map((image) => image.imageUrl);
    expect(urls, contains(ImageAssets.getHeroImage('Grand Warden')));
    expect(urls, contains(ImageAssets.getTroopImage('Healer')));
  });

  testWidgets('hides absent weights and omits troop count for a hero', (
    tester,
  ) async {
    await _pumpDetailLauncher(tester, _item(category: UpgradeCategory.heroes));

    expect(find.byKey(const ValueKey('warden-weight')), findsNothing);
    expect(find.byKey(const ValueKey('healer-weight')), findsNothing);
    expect(find.byKey(const ValueKey('housing-space')), findsNothing);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await _pumpDetailLauncher(
      tester,
      _item(category: UpgradeCategory.heroes, wardenWeight: 0.5),
    );

    expect(find.byKey(const ValueKey('warden-weight')), findsOneWidget);
    expect(find.textContaining('40 troop'), findsNothing);
  });

  testWidgets('maxed troop slider uses the selected level upgrade fields', (
    tester,
  ) async {
    await _pumpDetailLauncher(
      tester,
      _maxedItem(
        category: UpgradeCategory.darkTroops,
        levels: const [
          {'level': 8, 'upgrade_time': 914400, 'upgrade_cost': 280000},
          {'level': 9, 'upgrade_time': 0, 'upgrade_cost': 0},
        ],
      ),
    );

    tester.widget<Slider>(find.byType(Slider)).onChanged!(8);
    await tester.pump();

    expect(find.text('10d 14h'), findsOneWidget);
    expect(find.text('280.0K'), findsOneWidget);
  });

  testWidgets('building slider keeps using the destination level fields', (
    tester,
  ) async {
    await _pumpDetailLauncher(
      tester,
      _maxedItem(
        category: UpgradeCategory.defenses,
        levels: const [
          {'level': 8, 'build_time': 0, 'build_cost': 0},
          {'level': 9, 'build_time': 120, 'build_cost': 280000},
        ],
      ),
    );

    tester.widget<Slider>(find.byType(Slider)).onChanged!(8);
    await tester.pump();

    expect(find.text('2m'), findsOneWidget);
    expect(find.text('280.0K'), findsOneWidget);
  });

  testWidgets('hero attack range converts centitiles to tiles', (tester) async {
    await _pumpDetailLauncher(
      tester,
      UpgradeTrackerItem(
        id: 3,
        name: 'Grand Warden',
        imageUrl: ImageAssets.getHeroImage('Grand Warden'),
        village: UpgradeVillage.home,
        category: UpgradeCategory.heroes,
        queue: UpgradeQueue.builders,
        currentLevel: 1,
        targetLevel: 1,
        count: 1,
        steps: const [],
        completedUpgradeSeconds: 0,
        totalUpgradeSeconds: 0,
        meta: const {
          'attack_range': 700,
          'levels': [
            {'level': 1, 'hitpoints': 100},
          ],
        },
      ),
    );

    expect(find.text('7 tiles'), findsOneWidget);
    expect(find.text('0.7 tiles'), findsNothing);
  });

  testWidgets('hero movement speed converts to tiles per second', (
    tester,
  ) async {
    await _pumpDetailLauncher(
      tester,
      UpgradeTrackerItem(
        id: 5,
        name: 'Grand Warden',
        imageUrl: ImageAssets.getHeroImage('Grand Warden'),
        village: UpgradeVillage.home,
        category: UpgradeCategory.heroes,
        queue: UpgradeQueue.builders,
        currentLevel: 1,
        targetLevel: 1,
        count: 1,
        steps: const [],
        completedUpgradeSeconds: 0,
        totalUpgradeSeconds: 0,
        meta: const {
          'movement_speed': 200,
          'levels': [
            {'level': 1, 'hitpoints': 100},
          ],
        },
      ),
    );

    expect(find.text('2 tiles/sec'), findsOneWidget);
    expect(find.text('200'), findsNothing);
  });

  testWidgets('builder troop slider starts at its first real static level', (
    tester,
  ) async {
    await _pumpDetailLauncher(
      tester,
      UpgradeTrackerItem(
        id: 4,
        name: 'Boxer Giant',
        imageUrl: ImageAssets.getTroopImage('Boxer Giant'),
        village: UpgradeVillage.builderBase,
        category: UpgradeCategory.troops,
        queue: UpgradeQueue.laboratory,
        currentLevel: 3,
        targetLevel: 20,
        count: 1,
        steps: const [],
        completedUpgradeSeconds: 0,
        totalUpgradeSeconds: 0,
        meta: const {
          'housing_space': 18,
          'attack_speed': 2000,
          'attack_range': 100,
          'movement_speed': 180,
          'levels': [
            {
              'level': 3,
              'hitpoints': 2530,
              'dps': 65,
              'upgrade_time': 18000,
              'upgrade_cost': 60000,
            },
            {
              'level': 20,
              'hitpoints': 5423,
              'dps': 129,
              'upgrade_time': 0,
              'upgrade_cost': 0,
            },
          ],
        },
      ),
    );

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, 3);
    expect(slider.divisions, 17);
    expect(find.text('Level 3'), findsOneWidget);
    expect(find.text('65'), findsOneWidget);
    expect(find.text('2530'), findsOneWidget);
  });
}

Future<void> _pumpDetailLauncher(
  WidgetTester tester,
  UpgradeTrackerItem item,
) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showUpgradeDetails(context, item),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

UpgradeTrackerItem _item({
  required UpgradeCategory category,
  num? wardenWeight,
  num? healerWeight,
}) => UpgradeTrackerItem(
  id: 1,
  name: category == UpgradeCategory.heroes ? 'Archer Queen' : 'Barbarian',
  imageUrl: ImageAssets.getTroopImage('Barbarian'),
  village: UpgradeVillage.home,
  category: category,
  queue: category == UpgradeCategory.heroes
      ? UpgradeQueue.builders
      : UpgradeQueue.laboratory,
  currentLevel: 1,
  targetLevel: 1,
  count: 1,
  steps: const [],
  completedUpgradeSeconds: 0,
  totalUpgradeSeconds: 0,
  meta: const {
    'housing_space': 1,
    'levels': [
      {'level': 1, 'dps': 10, 'hitpoints': 100},
    ],
  },
  wardenWeight: wardenWeight,
  healerWeight: healerWeight,
);

UpgradeTrackerItem _maxedItem({
  required UpgradeCategory category,
  required List<Map<String, dynamic>> levels,
}) => UpgradeTrackerItem(
  id: 2,
  name: category == UpgradeCategory.defenses ? 'Cannon' : 'Ice Golem',
  imageUrl: ImageAssets.getTroopImage('Ice Golem'),
  village: UpgradeVillage.home,
  category: category,
  queue: category == UpgradeCategory.defenses
      ? UpgradeQueue.builders
      : UpgradeQueue.laboratory,
  currentLevel: 9,
  targetLevel: 9,
  count: 1,
  steps: const [],
  completedUpgradeSeconds: 0,
  totalUpgradeSeconds: 0,
  meta: {'upgrade_resource': 'dark_elixir', 'levels': levels},
);
