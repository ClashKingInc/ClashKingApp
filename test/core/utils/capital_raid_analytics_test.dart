import 'package:clashkingapp/core/utils/capital_raid_analytics.dart';
import 'package:clashkingapp/features/clan/models/clan_capital_history.dart';
import 'package:flutter_test/flutter_test.dart';

District _district({
  required int id,
  required String name,
  required int districtHallLevel,
  required int destructionPercent,
  int totalLooted = 0,
  int attackCount = 0,
  List<Attack> attacks = const [],
}) {
  return District(
    id: id,
    name: name,
    districtHallLevel: districtHallLevel,
    destructionPercent: destructionPercent,
    stars: 0,
    attackCount: attackCount,
    totalLooted: totalLooted,
    attacks: attacks,
  );
}

RaidAttackLog _entry({
  required int attackCount,
  required List<District> districts,
  String opponentName = 'Opponent',
  Map<String, String> badgeUrls = const {},
}) {
  return RaidAttackLog(
    defender: RaidDefender(
      tag: '#OPP',
      name: opponentName,
      level: 1,
      badgeUrls: badgeUrls,
    ),
    attackCount: attackCount,
    districtCount: districts.length,
    districtsDestroyed: districts
        .where((d) => d.destructionPercent == 100)
        .length,
    districts: districts,
  );
}

CapitalHistoryItem _raid({
  required String state,
  required int capitalTotalLoot,
  required int totalAttacks,
  int offensiveReward = 0,
  int defensiveReward = 0,
  DateTime? startTime,
  List<RaidAttackLog>? attackLog,
  List<RaidAttackLog>? defenseLog,
}) {
  return CapitalHistoryItem(
    state: state,
    startTime: startTime ?? DateTime(2026),
    endTime: DateTime(2026, 1, 4),
    capitalTotalLoot: capitalTotalLoot,
    raidsCompleted: 0,
    totalAttacks: totalAttacks,
    enemyDistrictsDestroyed: 0,
    offensiveReward: offensiveReward,
    defensiveReward: defensiveReward,
    members: const [],
    attackLog: attackLog ?? const [],
    defenseLog: defenseLog ?? const [],
  );
}

void main() {
  group('projectedTotalLoot', () {
    test('extrapolates current loot/attack rate to 300 attacks', () {
      final raid = _raid(
        state: 'ongoing',
        capitalTotalLoot: 50000,
        totalAttacks: 10,
      );
      expect(CapitalRaidAnalytics.projectedTotalLoot(raid), 1500000);
    });

    test('returns null once the raid has ended', () {
      final raid = _raid(
        state: 'ended',
        capitalTotalLoot: 50000,
        totalAttacks: 10,
      );
      expect(CapitalRaidAnalytics.projectedTotalLoot(raid), isNull);
    });

    test('returns null before any attack has been made', () {
      final raid = _raid(
        state: 'ongoing',
        capitalTotalLoot: 0,
        totalAttacks: 0,
      );
      expect(CapitalRaidAnalytics.projectedTotalLoot(raid), isNull);
    });
  });

  group('predictTrophyChange', () {
    test(
      'matches a hand-computed value for an ended raid with no defense log',
      () {
        // avgLoot = 100000/200 = 500; skill = 500 (no defense data) is inside
        // the +-664 threshold band, so perf = loot^0.6 + skill + 34.
        // 100000^0.6 = 10^3 = 1000 exactly -> perf = 1000 + 500 + 34 = 1534.
        // predicted = 3000*0.8 + 1534*0.2 = 2400 + 306.8 = 2706.8 -> 2707.
        final raid = _raid(
          state: 'ended',
          capitalTotalLoot: 100000,
          totalAttacks: 200,
        );
        final result = CapitalRaidAnalytics.predictTrophyChange(raid, 3000);
        expect(result.predictedPoints, 2707);
        expect(result.change, -293);
      },
    );
  });

  group('districtStats', () {
    test('aggregates fully-destroyed districts by id across opponents', () {
      final log = [
        _entry(
          attackCount: 3,
          districts: [
            _district(
              id: 70000001,
              name: 'Barbarian Camp',
              districtHallLevel: 2,
              destructionPercent: 100,
              totalLooted: 1000,
              attackCount: 2,
            ),
            _district(
              id: 70000002,
              name: 'Wizard Valley',
              districtHallLevel: 1,
              destructionPercent: 80,
              totalLooted: 500,
              attackCount: 1,
            ),
          ],
        ),
        _entry(
          attackCount: 2,
          districts: [
            _district(
              id: 70000001,
              name: 'Barbarian Camp',
              districtHallLevel: 2,
              destructionPercent: 100,
              totalLooted: 900,
              attackCount: 1,
            ),
          ],
        ),
      ];

      final stats = CapitalRaidAnalytics.districtStats(log);

      expect(stats.length, 1);
      expect(stats.single.name, 'Barbarian Camp');
      expect(stats.single.destroyedCount, 2);
      expect(stats.single.attacks, 3);
      expect(stats.single.loot, 1900);
    });
  });

  group('opponentStats', () {
    test('ranks opponents by loot descending', () {
      final log = [
        _entry(
          attackCount: 2,
          opponentName: 'Low Loot Clan',
          districts: [
            _district(
              id: 70000001,
              name: 'Barbarian Camp',
              districtHallLevel: 2,
              destructionPercent: 100,
              totalLooted: 100,
            ),
          ],
        ),
        _entry(
          attackCount: 3,
          opponentName: 'High Loot Clan',
          districts: [
            _district(
              id: 70000001,
              name: 'Barbarian Camp',
              districtHallLevel: 2,
              destructionPercent: 100,
              totalLooted: 900,
            ),
          ],
        ),
      ];

      final stats = CapitalRaidAnalytics.opponentStats(log);

      expect(stats.map((s) => s.clan.name), [
        'High Loot Clan',
        'Low Loot Clan',
      ]);
    });
  });

  group('attackEfficiency', () {
    test('counts one-shots and fails', () {
      final log = [
        _entry(
          attackCount: 4,
          districts: [
            _district(
              id: 70000001,
              name: 'District',
              districtHallLevel: 1,
              destructionPercent: 100,
              attackCount: 1, // one-shot
            ),
            _district(
              id: 70000002,
              name: 'District',
              districtHallLevel: 1,
              destructionPercent: 100,
              attackCount: 3, // regular district fail (>2)
            ),
            _district(
              id: 70000000,
              name: 'Capital Peak',
              districtHallLevel: 5,
              destructionPercent: 100,
              attackCount: 4, // capital peak fail (>3)
            ),
          ],
        ),
      ];

      final efficiency = CapitalRaidAnalytics.attackEfficiency(log);

      expect(efficiency.oneshots, 1);
      expect(efficiency.fails, 2);
    });
  });

  group('playerAttackStats', () {
    test('aggregates attackers, detects perfect hits, and sorts by hits', () {
      final log = [
        _entry(
          attackCount: 4,
          districts: [
            _district(
              id: 1,
              name: 'District One',
              districtHallLevel: 1,
              destructionPercent: 100,
              attacks: [
                Attack(
                  tag: '#ONE',
                  name: 'One',
                  destructionPercent: 100,
                  stars: 2,
                ),
                Attack(
                  tag: '#ONE',
                  name: 'One',
                  destructionPercent: 70,
                  stars: 3,
                ),
                Attack(
                  tag: '',
                  name: 'No Tag',
                  destructionPercent: 60,
                  stars: 1,
                ),
              ],
            ),
          ],
        ),
      ];

      final stats = CapitalRaidAnalytics.playerAttackStats(log);

      expect(stats.map((stat) => stat.name), ['One', 'No Tag']);
      expect(stats.first.attacks, 2);
      expect(stats.first.stars, 5);
      expect(stats.first.perfectHits, 2);
      expect(stats.first.avgStars, 2.5);
      expect(stats.first.avgDestruction, 85);
      expect(stats.last.perfectHits, 0);
    });

    test('returns an empty list when districts contain no attacks', () {
      final log = [
        _entry(
          attackCount: 0,
          districts: [
            _district(
              id: 1,
              name: 'Empty',
              districtHallLevel: 1,
              destructionPercent: 0,
            ),
          ],
        ),
      ];

      expect(CapitalRaidAnalytics.playerAttackStats(log), isEmpty);
    });
  });

  group('districtDefenseStats', () {
    test('aggregates districts and prioritizes defenses that held', () {
      final log = [
        _entry(
          attackCount: 5,
          districts: [
            _district(
              id: 1,
              name: 'Strong District',
              districtHallLevel: 2,
              destructionPercent: 70,
              totalLooted: 400,
              attackCount: 2,
            ),
            _district(
              id: 2,
              name: 'Destroyed District',
              districtHallLevel: 2,
              destructionPercent: 100,
              totalLooted: 800,
              attackCount: 3,
            ),
          ],
        ),
        _entry(
          attackCount: 1,
          districts: [
            _district(
              id: 1,
              name: 'Strong District',
              districtHallLevel: 2,
              destructionPercent: 50,
              totalLooted: 200,
              attackCount: 1,
            ),
          ],
        ),
      ];

      final stats = CapitalRaidAnalytics.districtDefenseStats(log);

      expect(stats.map((stat) => stat.name), [
        'Strong District',
        'Destroyed District',
      ]);
      expect(stats.first.defenses, 2);
      expect(stats.first.held, 2);
      expect(stats.first.destroyed, 0);
      expect(stats.first.attacksTaken, 3);
      expect(stats.first.lootLost, 600);
      expect(stats.first.avgAttacksTaken, 1.5);
      expect(stats.first.avgDestruction, 60);
      expect(stats.last.destroyed, 1);
    });
  });

  group('summarizeHistory', () {
    test('returns an empty summary when no raid has ended', () {
      final raids = [
        _raid(state: 'ongoing', capitalTotalLoot: 1000, totalAttacks: 10),
      ];
      final summary = CapitalRaidAnalytics.summarizeHistory(raids);
      expect(summary.weeksCounted, 0);
      expect(summary.bestRaid, isNull);
      expect(summary.worstRaid, isNull);
    });

    test('excludes the ongoing week and picks best/worst by reward', () {
      final low = _raid(
        state: 'ended',
        capitalTotalLoot: 10000,
        totalAttacks: 100,
        offensiveReward: 100,
        defensiveReward: 50,
        startTime: DateTime(2026, 1, 1),
      );
      final high = _raid(
        state: 'ended',
        capitalTotalLoot: 50000,
        totalAttacks: 100,
        offensiveReward: 300,
        defensiveReward: 100,
        startTime: DateTime(2026, 1, 8),
      );
      final ongoing = _raid(
        state: 'ongoing',
        capitalTotalLoot: 999999,
        totalAttacks: 5,
        startTime: DateTime(2026, 1, 15),
      );

      final summary = CapitalRaidAnalytics.summarizeHistory([
        ongoing,
        high,
        low,
      ]);

      expect(summary.weeksCounted, 2);
      expect(summary.totalLoot, 60000);
      expect(summary.avgLootPerWeek, 30000);
      expect(summary.bestRaid, same(high));
      expect(summary.worstRaid, same(low));
    });
  });
}
