import 'dart:convert';

import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads and ranks the current weekly league group', () async {
    final api = FakeApiService();
    api.getStubs['/players/%238GLYGGJQ'] = http.Response(
      jsonEncode({
        'tag': '#8GLYGGJQ',
        'name': 'Valentine',
        'townHallLevel': 18,
        'trophies': 36,
        'bestTrophies': 6085,
        'leagueTier': {
          'id': 105000030,
          'name': 'Dragon League 30',
          'iconUrls': {'small': 'small.png', 'large': 'large.png'},
        },
        'currentLeagueGroupTag': '#8PULU82',
        'currentLeagueSeasonId': 1784523600,
        'previousLeagueGroupTag': '#PREVIOUS',
        'previousLeagueSeasonId': 1783918800,
      }),
      200,
    );
    api.getStubs['/players/%238GLYGGJQ/leaguehistory'] = http.Response(
      jsonEncode({
        'items': [
          {
            'leagueSeasonId': 1783918800,
            'leagueTrophies': 332,
            'leagueTierId': 105000030,
            'placement': 94,
            'attackWins': 4,
            'attackLosses': 0,
            'attackStars': 8,
            'defenseWins': 0,
            'defenseLosses': 15,
            'defenseStars': 34,
            'maxBattles': 14,
          },
        ],
      }),
      200,
    );
    api.getStubs['/leaguetiers'] = http.Response(
      jsonEncode({
        'items': [
          {
            'id': 105000030,
            'name': 'Dragon League 30',
            'iconUrls': {'small': 'small.png', 'large': 'large.png'},
          },
        ],
      }),
      200,
    );
    api.getStubs['/leaguegroup/%238PULU82/1784523600?playerTag=%238GLYGGJQ'] =
        http.Response(
          jsonEncode({
            'members': [
              {
                'playerTag': '#OTHER',
                'playerName': 'Leader',
                'leagueTrophies': 50,
                'attackWinCount': 1,
                'attackLoseCount': 0,
                'defenseWinCount': 0,
                'defenseLoseCount': 1,
              },
              {
                'playerTag': '#8GLYGGJQ',
                'playerName': 'Valentine',
                'leagueTrophies': 36,
                'attackWinCount': 0,
                'attackLoseCount': 0,
                'defenseWinCount': 0,
                'defenseLoseCount': 2,
              },
            ],
            'attackLogs': [],
            'defenseLogs': [
              {
                'opponentPlayerTag': '#ENEMY',
                'opponentName': 'Enemy',
                'stars': 2,
                'destructionPercentage': 87.5,
                'trophies': 18,
                'creationTime': '20260720T120000.000Z',
              },
            ],
          }),
          200,
        );
    api.getStubs['/leaguegroup/%23PREVIOUS/1783918800?playerTag=%238GLYGGJQ'] =
        http.Response(
          jsonEncode({
            'members': [
              {
                'playerTag': '#8GLYGGJQ',
                'playerName': 'Valentine',
                'leagueTrophies': 332,
                'attackWinCount': 4,
                'attackLoseCount': 0,
                'defenseWinCount': 0,
                'defenseLoseCount': 15,
              },
            ],
            'attackLogs': [
              {
                'opponentPlayerTag': '#OLDENEMY',
                'opponentName': 'Old Enemy',
                'stars': 3,
                'destructionPercentage': 100,
                'trophies': 40,
                'creationTime': '20260713T120000.000Z',
              },
            ],
            'defenseLogs': <Object>[],
          }),
          200,
        );

    final data = await PlayerService(
      apiService: api,
    ).loadRankedLeagueData('#8GLYGGJQ');

    expect(data.currentTier?.name, 'Dragon League 30');
    expect(data.currentRank, 2);
    expect(data.currentMember?.leagueTrophies, 36);
    expect(data.currentMaxBattles, 14);
    expect(data.currentGroup?.defenseLogs.single.stars, 2);
    expect(data.history.single.placement, 94);
    expect(data.previousGroup?.seasonId, 1783918800);
    expect(data.previousGroup?.attackLogs.single.opponentName, 'Old Enemy');
  });

  test('keeps history available when no active group exists', () async {
    final api = FakeApiService();
    api.getStubs['/players/%23PLAYER'] = http.Response(
      jsonEncode({
        'tag': '#PLAYER',
        'name': 'Player',
        'leagueTier': {
          'id': 105000028,
          'name': 'Dragon League 28',
          'iconUrls': <String, String>{},
        },
      }),
      200,
    );
    api.getStubs['/players/%23PLAYER/leaguehistory'] = http.Response(
      jsonEncode({'items': <Object>[]}),
      200,
    );
    api.getStubs['/leaguetiers'] = http.Response(
      jsonEncode({'items': <Object>[]}),
      200,
    );

    final data = await PlayerService(
      apiService: api,
    ).loadRankedLeagueData('#PLAYER');

    expect(data.currentGroup, isNull);
    expect(data.currentRank, isNull);
    expect(data.currentTier?.name, 'Dragon League 28');
  });
}
