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
      'spells': [
        {'_id': 26000001, 'name': 'Lightning Spell', 'levels': const []},
      ],
    });
  });

  test('keeps Ranked first in the battle mode order', () {
    expect(PlayerBattlelogMode.values, [
      PlayerBattlelogMode.ranked,
      PlayerBattlelogMode.farming,
    ]);
  });

  test('parses live homeVillage values and official army share codes', () {
    final battle = PlayerBattlelogEntry.fromOfficial({
      'battleType': 'homeVillage',
      'attack': true,
      'armyShareCode': 'h0p4e8_14i1x7d1x1u8x5-4x7s2x1',
      'opponentPlayerTag': '#OPP',
      'battleTimestamp': '20260817T120000.000Z',
    });

    expect(battle.mode, PlayerBattlelogMode.farming);
    expect(battle.armyCounts, {
      'i_7': 1,
      'd_1': 1,
      'u_5': 8,
      'u_7': 4,
      's_1': 2,
    });
  });

  test('parses spaced Dark Elixir resource names from official battles', () {
    final battle = PlayerBattlelogEntry.fromOfficial({
      'battleType': 'homeVillage',
      'attack': true,
      'lootedResources': [
        {'name': 'Gold', 'amount': 1000},
        {'name': 'Elixir', 'amount': 2000},
        {'name': 'Dark Elixir', 'amount': 300},
      ],
    });

    expect(battle.darkElixir, 300);
    expect(battle.totalLoot, 3300);
  });

  test('merges official and historical battles and preserves army data', () {
    final official = PlayerBattlelogEntry.fromOfficial({
      'battleType': 'homeVillage',
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
      PlayerBattlelogEntry battle(
        String id,
        Map<String, int> army, {
        bool attack = true,
      }) => PlayerBattlelogEntry(
        id: id,
        mode: PlayerBattlelogMode.farming,
        source: PlayerBattlelogSource.history,
        attack: attack,
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
          battle('A', {'u_5': 8, 'u_7': 4, 's_1': 2}),
          battle('B', {'u_5': 2}),
          battle('C', {'u_7': 3}, attack: false),
        ],
        officialAvailable: true,
        historyAvailable: true,
      );

      final popular = data.popularTroops(PlayerBattlelogMode.farming);
      expect(popular.first.item.name, 'Balloon');
      expect(popular.first.uses, 2);
      expect(popular[1].item.name, 'Wizard');
      expect(popular.map((item) => item.item.code), isNot(contains('s_1')));

      final popularDefenses = data.popularTroops(
        PlayerBattlelogMode.farming,
        attack: false,
      );
      expect(popularDefenses, hasLength(1));
      expect(popularDefenses.single.item.name, 'Wizard');
      expect(popularDefenses.single.uses, 1);
    },
  );

  test('resolves troop and spell army prefixes to ClashKing assets', () {
    final troop = PlayerBattlelogArmyCatalog.resolve('i_7');
    final spell = PlayerBattlelogArmyCatalog.resolve('s_1');

    expect(troop.name, 'Wizard');
    expect(troop.imageUrl, endsWith('/troops/wizard/icon.webp'));
    expect(spell.name, 'Lightning Spell');
    expect(spell.imageUrl, endsWith('/spells/lightning_spell.webp'));
  });
}
