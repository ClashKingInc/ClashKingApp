import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/player/models/player_battlelog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    GameDataService.loadFromBundleForTesting({
      'troops': [
        {'_id': 4000005, 'name': 'Balloon', 'levels': const []},
        {'_id': 4000007, 'name': 'Wizard', 'levels': const []},
      ],
    });
  });

  test('merges official and historical battles and preserves army data', () {
    final official = PlayerBattlelogEntry.fromOfficial({
      'battleType': 'HOME_VILLAGE',
      'attack': true,
      'opponentPlayerTag': '#OPP',
      'opponentName': 'Opponent',
      'opponentTownHallLevel': 17,
      'stars': 2,
      'destructionPercentage': 88,
      'battleTimestamp': '20260816T120000.000Z',
      'lootedResources': [
        {'name': 'Gold', 'amount': 1000000},
      ],
    });
    final history = PlayerBattlelogEntry.fromHistory({
      'battle_id': 'battle-1',
      'battle_type': 'farming',
      'attack': true,
      'opponent_tag': '#OPP',
      'opponent_name': 'Opponent',
      'opponent_townhall': 17,
      'stars': 2,
      'destruction_percentage': 88,
      'gold': 1000000,
      'timestamp': '2026-08-16T12:00:00Z',
      'army_counts': {'u_5': 8, 'u_7': 4},
    });

    final data = PlayerBattlelogData.merge(
      official: [official],
      history: [history],
      officialAvailable: true,
      historyAvailable: true,
    );

    expect(data.items, hasLength(1));
    expect(data.items.single.source, PlayerBattlelogSource.history);
    expect(data.items.single.armyCounts['u_5'], 8);
    expect(data.forMode(PlayerBattlelogMode.farming), hasLength(1));
  });

  test(
    'calculates popular troops by battle usage and resolves static names',
    () {
      PlayerBattlelogEntry battle(String id, Map<String, int> army) =>
          PlayerBattlelogEntry(
            id: id,
            mode: PlayerBattlelogMode.farming,
            source: PlayerBattlelogSource.history,
            attack: true,
            opponentTag: '#$id',
            opponentName: id,
            opponentTownHall: 17,
            stars: 3,
            destructionPercentage: 100,
            gold: 0,
            elixir: 0,
            darkElixir: 0,
            timestamp: DateTime.utc(2026, 8, 16),
            duration: 120,
            armyShareCode: '',
            armyCounts: army,
          );

      final data = PlayerBattlelogData.merge(
        official: const [],
        history: [
          battle('A', {'u_5': 8, 'u_7': 4}),
          battle('B', {'u_5': 2}),
        ],
        officialAvailable: true,
        historyAvailable: true,
      );

      final popular = data.popularTroops(PlayerBattlelogMode.farming);
      expect(popular.first.item.name, 'Balloon');
      expect(popular.first.uses, 2);
      expect(popular[1].item.name, 'Wizard');
    },
  );
}
