import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/presentation/to_do/widget/player_to_do_body.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('wide layouts show account cards in a bounded grid', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1120, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final players = List.generate(
      3,
      (index) => Player.fromJson({
        'name': 'Account ${index + 1}',
        'tag': '#PLAYER$index',
        'townHallLevel': 18 - index,
      }),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BookmarkService()),
          ChangeNotifierProvider(create: (_) => PlayerService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PlayerToDoBody(
              players: players,
              memberPresenceMap: const {},
              emptyText: 'Empty',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final cards = find.byType(Card);
    expect(cards, findsNWidgets(3));
    expect(tester.getSize(cards.first).width, lessThan(370));
    expect(
      tester.getTopLeft(cards.at(0)).dy,
      tester.getTopLeft(cards.at(1)).dy,
    );
    expect(
      tester.getTopLeft(cards.at(1)).dy,
      tester.getTopLeft(cards.at(2)).dy,
    );
  });
}
