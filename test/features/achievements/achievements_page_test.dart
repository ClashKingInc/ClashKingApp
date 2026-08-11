import 'dart:convert';
import 'dart:io';

import 'package:clashkingapp/features/achievements/models/achievement.dart';
import 'package:clashkingapp/features/achievements/presentation/achievements_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const achievements = <Achievement>[
    Achievement(
      id: AchievementId.townhall18,
      modelUrl:
          'https://assets.clashk.ing/achievements/town-hall-18-achievement-badge.glb',
      earnedCount: 1,
      isRepeatable: true,
    ),
    Achievement(
      id: AchievementId.warWarrior,
      modelUrl:
          'https://assets.clashk.ing/achievements/war-champion-achievement-badge.glb',
      earnedCount: 0,
      isRepeatable: true,
    ),
    Achievement(
      id: AchievementId.mrLegend,
      modelUrl:
          'https://assets.clashk.ing/achievements/perfect-legends-day-achievement-badge.glb',
      earnedCount: 4,
      isRepeatable: true,
    ),
    Achievement(
      id: AchievementId.defenseDoesntMatter,
      modelUrl:
          'https://assets.clashk.ing/achievements/bad-legends-achievement-badge.glb',
      earnedCount: 2,
      isRepeatable: true,
    ),
  ];

  Future<List<AchievementModelRequest>> pumpPage(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    bool disableAnimations = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final requests = <AchievementModelRequest>[];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            disableAnimations: disableAnimations,
          ),
          child: AchievementsPage(
            achievements: achievements,
            modelBuilder: (context, request) {
              requests.add(request);
              return ColoredBox(
                key: ValueKey(
                  '${request.achievement.id.name}-'
                  '${request.interactive}-${request.enableIdleRotation}',
                ),
                color: Colors.transparent,
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    return requests;
  }

  testWidgets('shows the completion header and responsive badge states', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('3/4 completed'), findsOneWidget);
    expect(find.text('Townhall 18'), findsOneWidget);
    expect(find.text('War Warrior'), findsOneWidget);
    expect(find.text('Mr. Legend'), findsOneWidget);
    expect(find.text('Defense Doesn’t Matter'), findsOneWidget);
    expect(find.text('LOCKED'), findsOneWidget);
    expect(find.text('×1'), findsOneWidget);
    expect(find.text('×4'), findsOneWidget);
    expect(find.text('×2'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

    final mobileGrid = tester.widget<SliverGrid>(
      find.byKey(const ValueKey('achievements-grid')),
    );
    expect(
      (mobileGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      2,
    );
  });

  testWidgets('uses four columns and the 1120dp content bound on desktop', (
    tester,
  ) async {
    await pumpPage(tester, size: const Size(1600, 900));

    final desktopGrid = tester.widget<SliverGrid>(
      find.byKey(const ValueKey('achievements-grid')),
    );
    expect(
      (desktopGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      4,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('achievements-header'))).width,
      1120,
    );
  });

  testWidgets('detail uses one copy block with a plain earned count below', (
    tester,
  ) async {
    final requests = await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('achievement-warWarrior')));
    await tester.pumpAndSettle();

    expect(
      find.text('Built an elite record one war star at a time.'),
      findsNothing,
    );
    expect(find.text('Reach 5,000 war stars.'), findsOneWidget);
    expect(find.text('Requirement'), findsNothing);
    expect(find.text('Earned ×0'), findsOneWidget);
    expect(find.text('Status'), findsNothing);
    expect(find.text('Unlocked'), findsNothing);
    expect(find.text('Repeatable'), findsNothing);
    expect(find.textContaining('Drag to rotate'), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    expect(
      find.byKey(const ValueKey('achievement-detail-sheet')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('achievement-detail-sheet')),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('achievement-earned-count')),
      findsNothing,
    );
    expect(
      requests.any(
        (request) =>
            request.achievement.id == AchievementId.warWarrior &&
            request.interactive &&
            request.enableIdleRotation,
      ),
      isTrue,
    );
  });

  testWidgets('detail idle rotation respects reduced motion', (tester) async {
    var requests = await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('achievement-mrLegend')));
    await tester.pumpAndSettle();
    expect(
      find.text('Completed a flawless Legend League attack day.'),
      findsOneWidget,
    );
    expect(
      find.text('Complete a perfect +320 Legend League day.'),
      findsNothing,
    );
    expect(
      requests.any(
        (request) =>
            request.achievement.id == AchievementId.mrLegend &&
            request.interactive &&
            request.enableIdleRotation,
      ),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    requests = await pumpPage(tester, disableAnimations: true);
    await tester.tap(find.byKey(const ValueKey('achievement-mrLegend')));
    await tester.pumpAndSettle();
    expect(
      requests.any(
        (request) =>
            request.achievement.id == AchievementId.mrLegend &&
            request.interactive &&
            !request.enableIdleRotation,
      ),
      isTrue,
    );
  });

  testWidgets('defense detail keeps only its description and earned count', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(
      find.byKey(const ValueKey('achievement-defenseDoesntMatter')),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Survived a perfect Legend League defense day.'),
      findsOneWidget,
    );
    expect(
      find.text('Receive a perfect -320 Legend League defense day.'),
      findsNothing,
    );
    expect(find.text('Earned ×2'), findsOneWidget);
  });

  test('catalog fallback keeps every requested model locked', () {
    expect(achievementCatalogFallback, hasLength(4));
    expect(
      achievementCatalogFallback.map((item) => item.modelUrl),
      containsAll(<String>[
        'https://assets.clashk.ing/achievements/town-hall-18-achievement-badge.glb',
        'https://assets.clashk.ing/achievements/war-champion-achievement-badge.glb',
        'https://assets.clashk.ing/achievements/perfect-legends-day-achievement-badge.glb',
        'https://assets.clashk.ing/achievements/bad-legends-achievement-badge.glb',
      ]),
    );
    expect(achievementCatalogFallback.any((item) => item.isUnlocked), isFalse);
    expect(
      achievementCatalogFallback.every((item) => item.isRepeatable),
      isTrue,
    );
  });

  test('every ARB locale contains the complete achievement copy', () {
    const keys = <String>{
      'achievementsTitle',
      'achievementEarnedLabel',
      'achievementTownhall18Name',
      'achievementTownhall18Requirement',
      'achievementWarWarriorName',
      'achievementWarWarriorRequirement',
      'achievementMrLegendName',
      'achievementMrLegendDescription',
      'achievementDefenseDoesntMatterName',
      'achievementDefenseDoesntMatterDescription',
    };
    final localeFiles = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((file) => RegExp(r'app_[\w]+\.arb$').hasMatch(file.path))
        .toList();

    expect(localeFiles, isNotEmpty);
    for (final file in localeFiles) {
      final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final key in keys) {
        expect(
          arb[key],
          isA<String>().having(
            (value) => value.trim(),
            '${file.path}: $key',
            isNotEmpty,
          ),
        );
      }
    }
  });

  test('model interaction is transparent, horizontal, and inertial', () {
    final source = File(
      'lib/features/achievements/presentation/achievement_model_viewer.dart',
    ).readAsStringSync();
    expect(source, contains('backgroundColor: Colors.transparent'));
    expect(
      source,
      contains("minCameraOrbit: widget.interactive ? 'auto 75deg 105%'"),
    );
    expect(
      source,
      contains("maxCameraOrbit: widget.interactive ? 'auto 75deg 105%'"),
    );
    expect(
      source,
      contains('interpolationDecay: widget.interactive ? 200 : null'),
    );
    expect(source, contains('touchAction: TouchAction.none'));
    expect(source, contains('widget.interactive && widget.enableIdleRotation'));
    expect(source, contains('autoRotateDelay: 3000'));
    expect(source, contains("rotationPerSecond: '18deg'"));
    expect(source, isNot(contains('relatedJs:')));
  });

  test('Achievements uses compact actions instead of utility menu rows', () {
    final source = File('lib/core/app/my_home_page.dart').readAsStringSync();
    expect(
      RegExp(r'const AchievementsPage\(\)').allMatches(source),
      hasLength(2),
    );
    expect(RegExp(r'Icons\.stars_rounded').allMatches(source), hasLength(2));
    expect(source, contains('achievementsTooltip: l10n.achievementsTitle'));
    expect(source, contains('tooltip: l10n.achievementsTitle'));
    expect(source, isNot(contains('label: l10n.achievementsTitle')));
  });
}
