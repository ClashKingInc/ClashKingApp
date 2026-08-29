import 'package:clashkingapp/features/player/models/player_cwl_history.dart';
import 'package:clashkingapp/features/player/models/player_timer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses player CWL seasons and round attacks', () {
    final history = PlayerCwlHistory.fromJson({
      'items': [
        {
          'season': '2026-08-02',
          'townHallLevel': 18,
          'teamSize': 15,
          'clan': {
            'tag': '#CLAN',
            'name': 'Clan',
            'badgeUrls': {'medium': 'badge'},
            'warLeague': {'name': 'Master League I'},
            'wars': {'won': 5, 'lost': 2, 'tied': 0},
            'totalStars': 333,
            'placement': {'group': 4},
          },
          'attacks': [
            {
              'warTag': '#WAR',
              'round': 1,
              'opponent': {'tag': '#OTHER', 'name': 'Other'},
              'defender': {
                'tag': '#PLAYER',
                'name': 'Defender',
                'townHallLevel': 18,
                'mapPosition': 10,
              },
              'stars': 3,
              'destructionPercentage': 100,
              'order': 1,
              'duration': 120,
            },
          ],
          'placement': {'clan': 8, 'group': 33},
          'missedAttacks': 0,
        },
      ],
    });

    final season = history.items.single;
    expect(season.stars, 3);
    expect(season.clan.leagueName, 'Master League I');
    expect(season.attacks.single.round, 1);
  });

  test('parses all supported to-do timer types', () {
    final timers = PlayerTimers.fromJson({
      'items': [
        {
          'type': 'war',
          'expiresAt': '2026-08-30T20:00:00Z',
          'clans': ['#CLAN', '#OTHER'],
          'warTag': '#WAR',
        },
        {
          'type': 'cwl',
          'expiresAt': '2026-09-01T20:00:00Z',
          'clans': ['#CLAN'],
        },
        {
          'type': 'capital',
          'expiresAt': '2026-09-02T20:00:00Z',
          'clans': ['#CLAN'],
        },
      ],
    });

    expect(timers.items.map((timer) => timer.type), [
      PlayerTimerType.war,
      PlayerTimerType.cwl,
      PlayerTimerType.capital,
    ]);
    expect(timers.items.first.warTag, '#WAR');
  });
}
