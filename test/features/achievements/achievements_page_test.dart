import 'dart:convert';
import 'dart:io';

import 'package:clashkingapp/features/achievements/models/achievement.dart';
import 'package:clashkingapp/features/achievements/presentation/achievements_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
            profileOverride: const AchievementProfile(
              name: 'Chief Test',
              avatarUrl: '',
            ),
            modelBuilder: (context, request) {
              requests.add(request);
              return ColoredBox(
                key: ValueKey(
                  '${request.achievement.id.name}-'
                  '${request.interactive}-${request.playUnlockAnimation}',
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

  testWidgets('shows the mocked profile and responsive badge states', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Chief Test'), findsOneWidget);
    expect(find.text('3/4 completed'), findsOneWidget);
    expect(find.text('Downhill 18'), findsOneWidget);
    expect(find.text('War Warrior'), findsOneWidget);
    expect(find.text('Mr. Legend'), findsOneWidget);
    expect(find.text('Defense Doesn’t Matter'), findsOneWidget);
    expect(find.text('LOCKED'), findsOneWidget);
    expect(find.text('4× · Repeatable'), findsOneWidget);
    expect(find.text('2× · Repeatable'), findsOneWidget);
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
      tester.getSize(find.byKey(const ValueKey('achievements-profile'))).width,
      1120,
    );
  });

  testWidgets('detail exposes requirement, status, count, and model controls', (
    tester,
  ) async {
    final requests = await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('achievement-warWarrior')));
    await tester.pumpAndSettle();

    expect(
      find.text('Built an elite record one war star at a time.'),
      findsOneWidget,
    );
    expect(find.text('Reach 5,000 war stars.'), findsOneWidget);
    expect(find.text('Requirement'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Earned'), findsOneWidget);
    expect(find.text('0×'), findsOneWidget);
    expect(
      requests.any(
        (request) =>
            request.achievement.id == AchievementId.warWarrior &&
            request.interactive &&
            !request.playUnlockAnimation,
      ),
      isTrue,
    );
  });

  testWidgets('unlocked detail spins once unless reduced motion is enabled', (
    tester,
  ) async {
    var requests = await pumpPage(tester);
    await tester.tap(find.byKey(const ValueKey('achievement-mrLegend')));
    await tester.pumpAndSettle();
    expect(
      requests.any(
        (request) =>
            request.achievement.id == AchievementId.mrLegend &&
            request.interactive &&
            request.playUnlockAnimation,
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
            request.playUnlockAnimation,
      ),
      isFalse,
    );
  });

  test('mock catalog keeps the requested models and mixed states', () {
    expect(mockAchievements, hasLength(4));
    expect(
      mockAchievements.map((item) => item.modelUrl),
      containsAll(<String>[
        'https://assets.clashk.ing/achievements/town-hall-18-achievement-badge.glb',
        'https://assets.clashk.ing/achievements/war-champion-achievement-badge.glb',
        'https://assets.clashk.ing/achievements/perfect-legends-day-achievement-badge.glb',
        'https://assets.clashk.ing/achievements/bad-legends-achievement-badge.glb',
      ]),
    );
    expect(mockAchievements.any((item) => item.isUnlocked), isTrue);
    expect(mockAchievements.any((item) => !item.isUnlocked), isTrue);
    expect(
      mockAchievements
          .where((item) => item.isRepeatable)
          .map((item) => item.earnedCount),
      containsAll(<int>[4, 2]),
    );
  });

  test('every ARB locale contains the complete achievement copy', () {
    const keys = <String>{
      'achievementsTitle',
      'achievementUnlocked',
      'achievementRepeatable',
      'achievementRequirementLabel',
      'achievementStatusLabel',
      'achievementEarnedLabel',
      'achievementRotateHint',
      'achievementDownhill18Name',
      'achievementDownhill18Description',
      'achievementDownhill18Requirement',
      'achievementWarWarriorName',
      'achievementWarWarriorDescription',
      'achievementWarWarriorRequirement',
      'achievementMrLegendName',
      'achievementMrLegendDescription',
      'achievementMrLegendRequirement',
      'achievementDefenseDoesntMatterName',
      'achievementDefenseDoesntMatterDescription',
      'achievementDefenseDoesntMatterRequirement',
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

  test('mobile drawer and desktop sidebar both route to Achievements', () {
    final source = File('lib/core/app/my_home_page.dart').readAsStringSync();
    expect(
      RegExp(r'const AchievementsPage\(\)').allMatches(source),
      hasLength(2),
    );
    expect(
      RegExp(r'label: l10n\.achievementsTitle').allMatches(source),
      hasLength(2),
    );
  });
}
