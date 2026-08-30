import 'dart:convert';

import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player_battlelog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_services.dart';

void main() {
  test('loads and merges official and historical player battles', () async {
    final api = FakeApiService();
    api.getStubs['/players/%23P1/battlelog'] = http.Response(
      jsonEncode({
        'items': [
          {
            'battleType': 'HOME_VILLAGE',
            'attack': true,
            'opponentPlayerTag': '#OPP',
            'opponentName': 'Opponent',
            'opponentTownHallLevel': 17,
            'stars': 3,
            'destructionPercentage': 100,
            'battleTimestamp': '20260816T120000.000Z',
          },
        ],
      }),
      200,
    );
    api.getStubs['/player/%23P1/battlelog/history?limit=100&days=30'] =
        http.Response(
          jsonEncode({
            'items': [
              {
                'battle_id': 'battle-1',
                'battle_type': 'farming',
                'attack': true,
                'opponent_tag': '#OPP',
                'opponent_name': 'Opponent',
                'opponent_townhall': 17,
                'stars': 3,
                'destruction_percentage': 100,
                'timestamp': '2026-08-16T12:00:00Z',
                'army_counts': {'u_5': 8},
              },
            ],
          }),
          200,
        );

    final data = await PlayerService(
      apiService: api,
    ).loadPlayerBattlelog('#P1');

    expect(data.items, hasLength(1));
    expect(data.items.single.source, PlayerBattlelogSource.history);
    expect(data.officialAvailable, isTrue);
    expect(data.historyAvailable, isTrue);
    expect(
      api.getRequiresAuthByEndpoint['/player/%23P1/battlelog/history?limit=100&days=30'],
      isTrue,
    );
  });

  test('loads troop upgrades by default from normalized history', () async {
    final api = FakeApiService();
    const endpoint = '/player/%23P1/history/changes?type=troop_level&limit=500';
    api.getStubs[endpoint] = http.Response('{"items":[]}', 200);

    final data = await PlayerService(apiService: api).loadPlayerActivity('#P1');

    expect(data.items, isEmpty);
    expect(api.getRequiresAuthByEndpoint[endpoint], isFalse);
  });

  test('loads up to 100 CWL seasons and active timers', () async {
    final api = FakeApiService();
    api.getStubs['/player/%23P1/cwl/history?limit=100'] = http.Response(
      '{"items":[]}',
      200,
    );
    api.getStubs['/player/%23P1/timers'] = http.Response('{"items":[]}', 200);
    final service = PlayerService(apiService: api);

    final firstCwlLoad = service.loadPlayerCwlHistory('#P1');
    final secondCwlLoad = service.loadPlayerCwlHistory('#P1');
    expect(secondCwlLoad, same(firstCwlLoad));
    expect((await firstCwlLoad).items, isEmpty);
    expect((await service.loadPlayerTimers('#P1')).items, isEmpty);
    expect(api.getCallCounts['/player/%23P1/cwl/history?limit=100'], 1);
    expect(api.getCallCounts['/player/%23P1/timers'], 1);
  });

  test('keeps official battles when historical data is unavailable', () async {
    final api = FakeApiService();
    api.getStubs['/players/%23P1/battlelog'] = http.Response(
      jsonEncode({
        'items': [
          {
            'battleType': 'homeVillage',
            'attack': true,
            'armyShareCode': 'u8x5-4x7s2x1',
            'opponentPlayerTag': '#OPP',
            'opponentName': 'Opponent',
            'opponentTownHallLevel': 17,
            'stars': 2,
            'destructionPercentage': 90,
            'battleTimestamp': '20260816T120000.000Z',
          },
        ],
      }),
      200,
    );
    api.getStubs['/player/%23P1/battlelog/history?limit=100&days=30'] =
        http.Response('unavailable', 503);

    final data = await PlayerService(
      apiService: api,
    ).loadPlayerBattlelog('#P1');

    expect(data.items, hasLength(1));
    expect(data.forMode(PlayerBattlelogMode.farming), hasLength(1));
    expect(data.items.single.armyCounts['u_5'], 8);
    expect(data.officialAvailable, isTrue);
    expect(data.historyAvailable, isFalse);
  });
}
