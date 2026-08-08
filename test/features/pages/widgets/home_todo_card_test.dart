import 'package:clashkingapp/common/widgets/home_account_rail.dart';
import 'package:clashkingapp/features/pages/widgets/home_todo_card.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('mobile layouts keep the shared account rail and pager', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final players = [
      Player.fromJson(const {
        'name': 'First account',
        'tag': '#FIRST',
        'townHallLevel': 18,
      }),
      Player.fromJson(const {
        'name': 'Second account',
        'tag': '#SECOND',
        'townHallLevel': 17,
      }),
    ];

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WarCwlService(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HomeTodoCard(players: players, allPlayers: players),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(HomeAccountRail), findsOneWidget);
    final rail = tester.widget<HomeAccountRail>(find.byType(HomeAccountRail));
    expect(
      rail.entries.map((entry) => entry.label),
      containsAll(['First account', 'Second account']),
    );
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('wide layouts show the account cards together', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final players = [
      Player.fromJson(const {
        'name': 'First account',
        'tag': '#FIRST',
        'townHallLevel': 18,
      }),
      Player.fromJson(const {
        'name': 'Second account',
        'tag': '#SECOND',
        'townHallLevel': 17,
      }),
    ];

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => WarCwlService(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HomeTodoCard(
              players: players,
              allPlayers: players,
              desktopLayoutOverride: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(HomeAccountRail), findsNothing);
    expect(find.byType(PageView), findsNothing);
    expect(find.text('First account'), findsOneWidget);
    expect(find.text('Second account'), findsOneWidget);
  });
}
