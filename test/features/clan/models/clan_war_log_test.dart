import 'package:clashkingapp/features/clan/models/clan_war_log.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _makeWarItem({
  String result = 'win',
  String endTime = '20230615T120000.000Z',
  int teamSize = 15,
  int attacksPerMember = 2,
  int clanStars = 40,
  double clanDestruction = 85.0,
  int opponentStars = 30,
  double opponentDestruction = 70.0,
}) {
  return {
    'result': result,
    'endTime': endTime,
    'teamSize': teamSize,
    'attacksPerMember': attacksPerMember,
    'clan': {
      'tag': '#CLAN',
      'name': 'My Clan',
      'badgeUrls': <String, dynamic>{},
      'clanLevel': 15,
      'attacks': teamSize * attacksPerMember,
      'stars': clanStars,
      'destructionPercentage': clanDestruction,
      'expEarned': 100,
    },
    'opponent': {
      'tag': '#OPP',
      'name': 'Opponent',
      'badgeUrls': <String, dynamic>{},
      'clanLevel': 14,
      'attacks': teamSize * attacksPerMember,
      'stars': opponentStars,
      'destructionPercentage': opponentDestruction,
      'expEarned': 80,
    },
  };
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('ClanWarLog.fromJson', () {
    test('filters out wars before 2022', () {
      final json = {
        'items': [
          _makeWarItem(endTime: '20210101T000000.000Z'), // 2021 - excluded
          _makeWarItem(endTime: '20220101T000000.000Z'), // 2022 - included
          _makeWarItem(endTime: '20230601T000000.000Z'), // 2023 - included
        ],
      };
      final log = ClanWarLog.fromJson(json, '#CLAN');
      expect(log.items, hasLength(2));
    });

    test('returns empty list when items key is absent', () {
      final log = ClanWarLog.fromJson({}, '#CLAN');
      expect(log.items, isEmpty);
    });

    test('stores clanTag', () {
      final log = ClanWarLog.fromJson({'items': []}, '#TEST');
      expect(log.clanTag, '#TEST');
    });

    test('keeps all wars from 2022 or later', () {
      final json = {
        'items': List.generate(
          5,
          (i) => _makeWarItem(endTime: '2022${(i + 1).toString().padLeft(2, '0')}01T000000.000Z'),
        ),
      };
      final log = ClanWarLog.fromJson(json, '#CLAN');
      expect(log.items, hasLength(5));
    });
  });

  group('ClanWarLog.warLogStats getter', () {
    test('returns empty/zero stats before warLogStats is set', () {
      final log = ClanWarLog(items: [], clanTag: '#CLAN');
      final stats = log.warLogStats;
      expect(stats.totalWins, 0);
      expect(stats.totalWars, 0);
      expect(stats.winPercentage, '0');
      expect(stats.averageClanDestruction, 0.0);
    });

    test('returns assigned stats after setter is called', () {
      final log = ClanWarLog(items: [], clanTag: '#CLAN');
      log.warLogStats = WarLogStats(
        totalWins: 10,
        totalLosses: 5,
        totalTies: 2,
        totalWars: 17,
        averageMembers: 15,
        averageClanDestruction: 80.0,
        averageClanStarsPerMember: 2.0,
        averageOpponentDestruction: 65.0,
        averageOpponentStarsPerMember: 1.7,
        averageAttacksPerMember: 1.9,
        winPercentage: '59',
        lossPercentage: '29',
        tiePercentage: '12',
        averageDestructionDifference: 15.0,
        averageClanStarsPercentage: 66.7,
        averageOpponentStarsPercentage: 55.6,
      );
      expect(log.warLogStats.totalWins, 10);
      expect(log.warLogStats.totalWars, 17);
      expect(log.warLogStats.winPercentage, '59');
    });
  });

  group('WarLogStatsService.analyzeWarLogs', () {
    test('returns zero stats for empty list', () async {
      final stats = await WarLogStatsService.analyzeWarLogs([]);
      expect(stats.totalWars, 0);
      expect(stats.totalWins, 0);
      expect(stats.winPercentage, '0');
      expect(stats.averageClanDestruction, 0.0);
    });

    test('counts wins, losses, and ties correctly', () async {
      final items = [
        _makeWarItem(result: 'win'),
        _makeWarItem(result: 'win'),
        _makeWarItem(result: 'lose'),
        _makeWarItem(result: 'tie'),
      ].map((j) => WarLogDetails.fromJson(j, '#CLAN')).toList();

      final stats = await WarLogStatsService.analyzeWarLogs(items);
      expect(stats.totalWars, 4);
      expect(stats.totalWins, 2);
      expect(stats.totalLosses, 1);
      expect(stats.totalTies, 1);
      expect(stats.winPercentage, '50');
      expect(stats.lossPercentage, '25');
    });

    test('ignores wars where attacksPerMember != 2', () async {
      final items = [
        _makeWarItem(result: 'win', attacksPerMember: 1), // ignored
        _makeWarItem(result: 'win', attacksPerMember: 2), // counted
      ].map((j) => WarLogDetails.fromJson(j, '#CLAN')).toList();

      final stats = await WarLogStatsService.analyzeWarLogs(items);
      expect(stats.totalWars, 1);
      expect(stats.totalWins, 1);
    });

    test('computes averages correctly for a single war', () async {
      final items = [
        _makeWarItem(
          teamSize: 10,
          clanStars: 30,
          clanDestruction: 90.0,
          opponentStars: 20,
          opponentDestruction: 60.0,
        ),
      ].map((j) => WarLogDetails.fromJson(j, '#CLAN')).toList();

      final stats = await WarLogStatsService.analyzeWarLogs(items);
      expect(stats.averageMembers, 10);
      expect(stats.averageClanDestruction, 90.0);
      expect(stats.averageOpponentDestruction, 60.0);
      expect(stats.averageDestructionDifference, 30.0);
    });

    test('computes win percentage as 0 when totalWars is 0', () async {
      // All items have attacksPerMember=1 so they are filtered out
      final items = [
        _makeWarItem(attacksPerMember: 1),
      ].map((j) => WarLogDetails.fromJson(j, '#CLAN')).toList();

      final stats = await WarLogStatsService.analyzeWarLogs(items);
      expect(stats.totalWars, 0);
      expect(stats.winPercentage, '0');
    });
  });

  group('ClanDetails.fromJson', () {
    test('parses all fields correctly', () {
      final detail = ClanDetails.fromJson({
        'tag': '#CLAN',
        'name': 'Test Clan',
        'badgeUrls': <String, dynamic>{},
        'clanLevel': 15,
        'attacks': 30,
        'stars': 45,
        'destructionPercentage': 87.5,
        'expEarned': 120,
      });
      expect(detail.tag, '#CLAN');
      expect(detail.name, 'Test Clan');
      expect(detail.attacks, 30);
      expect(detail.stars, 45);
      expect(detail.destructionPercentage, 87.5);
      expect(detail.expEarned, 120);
    });

    test('uses defaults for missing fields', () {
      final detail = ClanDetails.fromJson({'badgeUrls': <String, dynamic>{}});
      expect(detail.tag, '');
      expect(detail.attacks, 0);
      expect(detail.stars, 0);
      expect(detail.destructionPercentage, 0.0);
    });
  });
}
