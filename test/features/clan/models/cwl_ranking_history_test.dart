import 'package:clashkingapp/features/clan/models/cwl_ranking_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the war league id used for month-over-month movement', () {
    final entry = CwlRankingHistoryEntry.fromJson({
      'season': '2026-07-02',
      'warLeague': {'id': 48000015, 'name': 'Master League I'},
      'rank': 4,
      'stars': 333,
      'destruction': 95.67,
      'rounds': {'won': 5, 'tied': 0, 'lost': 2},
    });

    expect(entry.leagueId, 48000015);
    expect(entry.league, 'Master League I');
    expect(entry.roundsWon, 5);
    expect(entry.roundsTied, 0);
    expect(entry.roundsLost, 2);
  });

  test('leaves league id null when a legacy response omits it', () {
    final entry = CwlRankingHistoryEntry.fromJson({
      'season': '2026-06',
      'league': 'Master League II',
    });

    expect(entry.leagueId, isNull);
  });
}
