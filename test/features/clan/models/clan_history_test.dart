import 'package:clashkingapp/features/clan/models/clan_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses every clan leaderboard point field into one model', () {
    for (final entry in <Map<String, dynamic>>[
      {'date': '2026-08-25', 'rank': 1, 'clanPoints': 150000, 'members': 50},
      {
        'date': '2026-08-24',
        'rank': 2,
        'builderBasePoints': 44000,
        'members': 49,
      },
      {'date': '2026-08-23', 'rank': 3, 'capitalPoints': 5000, 'members': 48},
    ]) {
      final history = ClanLeaderboardHistory.fromJson({
        'items': [entry],
      });
      expect(history.items.single.points, greaterThan(0));
      expect(history.items.single.date.isUtc, isTrue);
    }
  });

  test('parses legend finishers and optional leaderboard location', () {
    final leaderboard = ClanLeaderboardHistory.fromJson({
      'items': [
        {
          'date': '2026-08-25',
          'rank': 129,
          'builderBasePoints': 44097,
          'members': 49,
          'location': {
            'id': 32000087,
            'name': 'France',
            'isCountry': true,
            'countryCode': 'FR',
          },
        },
      ],
    });
    final legends = ClanLegendHistory.fromJson({
      'items': [
        {
          'season': '2025-09',
          'tag': '#PLAYER',
          'name': 'Player',
          'expLevel': 251,
          'trophies': 5951,
          'attackWins': 242,
          'defenseWins': 2,
          'rank': 51525,
        },
      ],
    });

    expect(leaderboard.items.single.location?.countryCode, 'FR');
    expect(legends.items.single.season, '2025-09');
    expect(legends.items.single.attackWins, 242);
  });

  test('keeps record timestamps and profile change value types', () {
    final records = ClanRecords.fromJson({
      'clanPoints': {'value': 156112, 'time': '2025-10-13T06:44:43Z'},
      'warWinStreak': {'value': 4, 'time': '2025-12-30T19:46:22Z'},
    });
    final history = ClanProfileHistory.fromJson({
      'items': [
        {
          'time': '2026-07-06T07:31:37Z',
          'type': 'clanLevel',
          'previous': 31,
          'current': 32,
        },
        {
          'time': '2026-07-05T07:31:37Z',
          'type': 'description',
          'previous': 'Old',
          'current': 'New',
        },
      ],
    });

    expect(records.clanPoints?.value, 156112);
    expect(records.warWinStreak?.time.isUtc, isTrue);
    expect(history.items.first.type, ClanProfileChangeType.clanLevel);
    expect(history.items.first.current, isA<int>());
    expect(history.items.last.type, ClanProfileChangeType.description);
    expect(history.items.last.current, isA<String>());
  });
}
