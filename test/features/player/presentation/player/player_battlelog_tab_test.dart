import 'dart:convert';

import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/player/player_battlelog_tab.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../helpers/fake_services.dart';

void main() {
  setUpAll(() {
    GameDataService.loadFromBundleForTesting({
      'troops': [
        {'_id': 4000000, 'name': 'Barbarian', 'levels': const []},
        {'_id': 4000001, 'name': 'Archer', 'levels': const []},
        {'_id': 4000002, 'name': 'Giant', 'levels': const []},
        {'_id': 4000005, 'name': 'Balloon', 'levels': const []},
        {'_id': 4000007, 'name': 'Wizard', 'levels': const []},
      ],
    });
  });

  testWidgets(
    'keeps stats flat and shows five popular troops per battle direction',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = FakeApiService();
      api.getStubs['/players/%23P1/battlelog'] = http.Response(
        jsonEncode({'items': const []}),
        200,
      );
      api.getStubs['/player/%23P1/battlelog/history?limit=100&days=30'] =
          http.Response(
            jsonEncode({
              'items': [
                _rankedBattle(
                  id: 'one',
                  opponent: '#ONE',
                  timestamp: '2026-08-17T12:00:00Z',
                  army: {'u_5': 8, 'u_7': 4, 'u_0': 2, 'u_1': 2, 'u_2': 1},
                ),
                _rankedBattle(
                  id: 'two',
                  opponent: '#TWO',
                  timestamp: '2026-08-16T12:00:00Z',
                  army: {'u_5': 6, 'u_7': 3},
                ),
                _rankedBattle(
                  id: 'three',
                  opponent: '#THREE',
                  timestamp: '2026-08-15T12:00:00Z',
                  army: {'u_5': 4},
                ),
                _rankedBattle(
                  id: 'four',
                  opponent: '#FOUR',
                  timestamp: '2026-08-14T12:00:00Z',
                  army: {'u_0': 15, 'u_1': 8, 'u_2': 5, 'u_5': 2, 'u_7': 1},
                  attack: false,
                ),
              ],
            }),
            200,
          );

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => PlayerService(apiService: api),
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: PlayerBattlelogTab(playerTag: '#P1', bottomPadding: 0),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final summary = find.byKey(const ValueKey('player-battle-summary'));
      expect(summary, findsOneWidget);
      expect(tester.getSize(summary).height, lessThan(470));
      expect(
        find.descendant(of: summary, matching: find.byType(CKStatTile)),
        findsNothing,
      );

      final popularTiles = find.byWidgetPredicate(
        (widget) =>
            widget is CKGameItemTile &&
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'popular-troop-',
            ),
      );
      expect(find.byKey(const ValueKey('player-popular-troops')), findsNothing);
      expect(popularTiles, findsNWidgets(10));
      expect(
        find.descendant(of: summary, matching: popularTiles),
        findsNWidgets(10),
      );
      final attackTop = tester.getTopLeft(popularTiles.first).dy;
      for (var index = 1; index < 5; index++) {
        expect(tester.getTopLeft(popularTiles.at(index)).dy, attackTop);
      }
      final defenseTop = tester.getTopLeft(popularTiles.at(5)).dy;
      expect(defenseTop, greaterThan(attackTop));
      for (var index = 6; index < 10; index++) {
        expect(tester.getTopLeft(popularTiles.at(index)).dy, defenseTop);
      }
      expect(find.text('×2'), findsAtLeastNWidgets(1));

      final battleRow = find.byKey(const ValueKey('player-battle-one'));
      expect(battleRow, findsOneWidget);
      expect(tester.getSize(battleRow).height, lessThan(170));
      expect(
        find.descendant(of: battleRow, matching: find.text('×8')),
        findsOneWidget,
      );

      final townHall = tester.widget<MobileWebImage>(
        find.descendant(
          of: battleRow,
          matching: find.byKey(
            const ValueKey('battle-townhall-1|#ONE|1786968000000'),
          ),
        ),
      );
      expect(townHall.imageUrl, ImageAssets.townHall(17));
      final directionIcon = tester.widget<MobileWebImage>(
        find.descendant(
          of: battleRow,
          matching: find.byKey(
            const ValueKey('battle-direction-icon-1|#ONE|1786968000000'),
          ),
        ),
      );
      expect(directionIcon.imageUrl, ImageAssets.sword);
      expect(directionIcon.width, 20);
      expect(
        tester
            .getTopLeft(
              find.byKey(
                const ValueKey('battle-direction-icon-1|#ONE|1786968000000'),
              ),
            )
            .dx,
        greaterThan(tester.getTopLeft(find.text('ONE')).dx),
      );
      expect(
        find.descendant(of: battleRow, matching: find.text('Against ONE')),
        findsNothing,
      );
      expect(
        find.descendant(of: battleRow, matching: find.text('Defense')),
        findsNothing,
      );

      final armyTile = tester.widget<CKGameItemTile>(
        find.byKey(const ValueKey('battle-army-1|#ONE|1786968000000-u_5')),
      );
      expect(armyTile.badgeDensity, CKGameItemBadgeDensity.compact);

      await tester.tap(find.byKey(const ValueKey('battle-direction-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Defenses').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('player-battle-one')), findsNothing);
      expect(find.byKey(const ValueKey('player-battle-four')), findsOneWidget);
    },
  );
}

Map<String, dynamic> _rankedBattle({
  required String id,
  required String opponent,
  required String timestamp,
  required Map<String, int> army,
  bool attack = true,
}) => {
  'battle_id': id,
  'battle_type': 'ranked',
  'attack': attack,
  'opponent_tag': opponent,
  'opponent_name': opponent.substring(1),
  'opponent_townhall': 17,
  'stars': 3,
  'destruction_percentage': 100,
  'gold': 800000,
  'elixir': 800000,
  'dark_elixir': 8000,
  'timestamp': timestamp,
  'army_counts': army,
};
