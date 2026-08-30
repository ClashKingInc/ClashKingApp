import 'dart:convert';

import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/presentation/player/player_cwl_history_tab.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../helpers/fake_services.dart';

void main() {
  testWidgets('shows every CWL season as an expandable list card', (
    tester,
  ) async {
    final api = FakeApiService();
    api.getStubs['/player/%23P1/cwl/history?limit=100'] = http.Response(
      jsonEncode({
        'items': [
          _season('2026-08-01', 'First Clan', defender: 'Defender One'),
          _season('2026-07-01', 'Second Clan'),
        ],
      }),
      200,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PlayerService(apiService: api),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: PlayerCwlHistoryTab(playerTag: '#P1', bottomPadding: 0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('First Clan'), findsOneWidget);
    expect(find.text('Second Clan'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(
      tester.widget<ExpansionTile>(find.byType(ExpansionTile).first).key,
      const PageStorageKey<String>('player-cwl-2026-08-01-#CLAN'),
    );
    expect(find.text('Defender One'), findsNothing);

    await tester.tap(find.text('First Clan'));
    await tester.pumpAndSettle();

    expect(find.text('Defender One'), findsOneWidget);
  });
}

Map<String, Object?> _season(
  String season,
  String clanName, {
  String? defender,
}) => {
  'season': season,
  'townHallLevel': 17,
  'missedAttacks': 0,
  'placement': {'clan': 2},
  'clan': {
    'tag': '#CLAN',
    'name': clanName,
    'badgeUrls': {'medium': ''},
    'warLeague': {'name': 'Champion League I'},
    'wars': {'won': 5, 'lost': 2, 'tied': 0},
    'placement': {'group': 2},
  },
  'attacks': defender == null
      ? <Object>[]
      : [
          {
            'warTag': '#WAR',
            'round': 1,
            'opponent': {'name': 'Opponent', 'tag': '#OPP'},
            'defender': {
              'name': defender,
              'tag': '#DEF',
              'townHallLevel': 17,
              'mapPosition': 1,
            },
            'stars': 3,
            'destructionPercentage': 100,
            'order': 1,
            'duration': 120,
          },
        ],
};
