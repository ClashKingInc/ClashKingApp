import 'package:clashkingapp/core/functions/war_functions.dart';
import 'package:clashkingapp/features/clan/models/clan_badge.dart';
import 'package:clashkingapp/features/clan/models/clan_war_log.dart';
import 'package:clashkingapp/features/war_cwl/models/war_attack.dart';
import 'package:clashkingapp/features/war_cwl/models/war_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war/war.dart';
import 'package:flutter_test/flutter_test.dart';

WarMember _memberWithStars(List<int> stars) {
  return WarMember(
    tag: '#TAG',
    name: 'Player',
    townhallLevel: 15,
    mapPosition: 1,
    opponentAttacks: 0,
    attacks: stars
        .asMap()
        .entries
        .map(
          (e) => WarAttack(
            attackerTag: '#TAG',
            defenderTag: '#DEF',
            stars: e.value,
            destructionPercentage: 100,
            order: e.key + 1,
          ),
        )
        .toList(),
  );
}

WarClan _clanWithMembers(List<WarMember> members) {
  return WarClan(
    tag: '#CLAN',
    name: 'Test Clan',
    badgeUrls: ClanBadgeUrls(small: '', medium: '', large: ''),
    clanLevel: 10,
    attacks: 0,
    stars: 0,
    destructionPercentage: 0.0,
    members: members,
  );
}

ClanDetails _clanDetails({int stars = 10, double dest = 80.0}) => ClanDetails(
  tag: '#CLAN',
  name: 'Test Clan',
  badgeUrls: ClanBadgeUrls(small: '', medium: '', large: ''),
  clanLevel: 10,
  attacks: 0,
  stars: stars,
  destructionPercentage: dest,
  expEarned: 0,
);

WarLogDetails _logDetails({
  String result = 'win',
  int teamSize = 15,
  int attacksPerMember = 2,
  int clanStars = 10,
  double clanDest = 80.0,
  int oppStars = 5,
  double oppDest = 60.0,
}) => WarLogDetails(
  result: result,
  clanTag: '#CLAN',
  endTime: DateTime(2024, 1, 1),
  teamSize: teamSize,
  attacksPerMember: attacksPerMember,
  clan: _clanDetails(stars: clanStars, dest: clanDest),
  opponent: _clanDetails(stars: oppStars, dest: oppDest),
);

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('countStars', () {
    test('returns all zeros for empty member list', () {
      final result = countStars([]);
      expect(result, {0: 0, 1: 0, 2: 0, 3: 0});
    });

    test('counts stars correctly across multiple members', () {
      final members = [
        _memberWithStars([3, 2]),
        _memberWithStars([1, 0]),
        _memberWithStars([3, 3]),
      ];
      final result = countStars(members);
      expect(result[0], 1); // one 0-star
      expect(result[1], 1); // one 1-star
      expect(result[2], 1); // one 2-star
      expect(result[3], 3); // three 3-stars
    });

    test('counts a single 3-star attack', () {
      final members = [
        _memberWithStars([3]),
      ];
      final result = countStars(members);
      expect(result[3], 1);
      expect(result[0], 0);
    });

    test('ignores members with null attacks', () {
      final member = WarMember(
        tag: '#TAG',
        name: 'Player',
        townhallLevel: 15,
        mapPosition: 1,
        opponentAttacks: 0,
        attacks: null,
      );
      final result = countStars([member]);
      expect(result, {0: 0, 1: 0, 2: 0, 3: 0});
    });

    test('handles member with empty attacks list', () {
      final member = WarMember(
        tag: '#TAG',
        name: 'Player',
        townhallLevel: 15,
        mapPosition: 1,
        opponentAttacks: 0,
        attacks: [],
      );
      final result = countStars([member]);
      expect(result, {0: 0, 1: 0, 2: 0, 3: 0});
    });
  });

  group('getMemberByTag', () {
    test('returns member when tag matches', () {
      final member = WarMember(
        tag: '#PLAYER1',
        name: 'Alice',
        townhallLevel: 15,
        mapPosition: 1,
        opponentAttacks: 0,
      );
      final clan = _clanWithMembers([member]);
      final result = getMemberByTag('#PLAYER1', clan);
      expect(result, isNotNull);
      expect(result!.name, 'Alice');
    });

    test('returns null when tag not found', () {
      final clan = _clanWithMembers([]);
      expect(getMemberByTag('#UNKNOWN', clan), isNull);
    });

    test('returns null when members list is empty', () {
      final clan = _clanWithMembers([]);
      expect(getMemberByTag('#PLAYER1', clan), isNull);
    });

    test('finds correct member among multiple', () {
      final members = [
        WarMember(
          tag: '#P1',
          name: 'Alice',
          townhallLevel: 15,
          mapPosition: 1,
          opponentAttacks: 0,
        ),
        WarMember(
          tag: '#P2',
          name: 'Bob',
          townhallLevel: 14,
          mapPosition: 2,
          opponentAttacks: 0,
        ),
        WarMember(
          tag: '#P3',
          name: 'Carol',
          townhallLevel: 13,
          mapPosition: 3,
          opponentAttacks: 0,
        ),
      ];
      final clan = _clanWithMembers(members);
      expect(getMemberByTag('#P2', clan)!.name, 'Bob');
      expect(getMemberByTag('#P3', clan)!.name, 'Carol');
    });
  });

  group('getPlayerNameByTag', () {
    test('returns name when player is found', () {
      final players = [PlayerTab('#P1', 'Alice', 14, 1)];
      expect(getPlayerNameByTag('#P1', players), 'Alice');
    });

    test("returns 'Inconnu' when player is not found", () {
      final players = [PlayerTab('#P1', 'Alice', 14, 1)];
      expect(getPlayerNameByTag('#NOBODY', players), 'Inconnu');
    });

    test('returns first match when multiple players share a tag', () {
      final players = [
        PlayerTab('#P1', 'Alice', 14, 1),
        PlayerTab('#P2', 'Bob', 13, 2),
      ];
      expect(getPlayerNameByTag('#P2', players), 'Bob');
    });
  });

  group('getPlayerTownhallByTag', () {
    test('returns townhall level as string when player is found', () {
      final players = [PlayerTab('#P1', 'Alice', 15, 1)];
      expect(getPlayerTownhallByTag('#P1', players), '15');
    });

    test("returns '0' when player is not found", () {
      final players = <PlayerTab>[];
      expect(getPlayerTownhallByTag('#NOBODY', players), '0');
    });
  });

  group('getPlayerMapPositionByTag', () {
    test('returns map position as string when player is found', () {
      final players = [PlayerTab('#P1', 'Alice', 14, 5)];
      expect(getPlayerMapPositionByTag('#P1', players), '5');
    });

    test("returns '0' when player is not found", () {
      final players = <PlayerTab>[];
      expect(getPlayerMapPositionByTag('#NOBODY', players), '0');
    });
  });

  group('analyzeWarLogs', () {
    test('returns zeroes for empty list', () {
      final result = analyzeWarLogs([]);
      expect(result['totalWins'], '0');
      expect(result['totalLosses'], '0');
      expect(result['totalTies'], '0');
      expect(result['averageMembers'], '0');
    });

    test('only counts entries with attacksPerMember == 2', () {
      final logs = [
        _logDetails(result: 'win', attacksPerMember: 1),
        _logDetails(result: 'win', attacksPerMember: 2),
      ];
      final result = analyzeWarLogs(logs);
      expect(result['totalWins'], '1');
    });

    test('counts wins, losses and ties separately', () {
      final logs = [
        _logDetails(result: 'win'),
        _logDetails(result: 'win'),
        _logDetails(result: 'lose'),
        _logDetails(result: 'tie'),
      ];
      final result = analyzeWarLogs(logs);
      expect(result['totalWins'], '2');
      expect(result['totalLosses'], '1');
      expect(result['totalTies'], '1');
    });

    test('computes average destruction correctly', () {
      final logs = [_logDetails(clanDest: 80.0), _logDetails(clanDest: 60.0)];
      final result = analyzeWarLogs(logs);
      expect(result['averageClanDestruction'], '70');
    });

    test('computes clan stars per member correctly', () {
      final logs = [
        _logDetails(clanStars: 30, teamSize: 15),
        _logDetails(clanStars: 30, teamSize: 15),
      ];
      final result = analyzeWarLogs(logs);
      // 60 stars / 30 members = 2.0
      expect(result['averageClanStarsPerMember'], '2.0');
    });
  });
}
