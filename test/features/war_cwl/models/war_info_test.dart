import 'package:clashkingapp/features/clan/models/clan_badge.dart';
import 'package:clashkingapp/features/war_cwl/models/war_attack.dart';
import 'package:clashkingapp/features/war_cwl/models/war_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member.dart';
import 'package:flutter_test/flutter_test.dart';

WarMember _makeMember(
  String tag, {
  String name = 'Player',
  int th = 14,
  int pos = 1,
  List<WarAttack>? attacks,
}) {
  return WarMember(
    tag: tag,
    name: name,
    townhallLevel: th,
    mapPosition: pos,
    opponentAttacks: 0,
    attacks: attacks,
  );
}

WarClan _makeClan(
  String tag, {
  List<WarMember> members = const [],
  int stars = 0,
  double dest = 0.0,
}) {
  return WarClan(
    tag: tag,
    name: 'Clan $tag',
    badgeUrls: ClanBadgeUrls(small: '', medium: '', large: ''),
    clanLevel: 10,
    attacks: 0,
    stars: stars,
    destructionPercentage: dest,
    members: members,
  );
}

WarAttack _makeAttack({int stars = 3, int dest = 100}) => WarAttack(
      attackerTag: '#ATK',
      defenderTag: '#DEF',
      stars: stars,
      destructionPercentage: dest,
      order: 1,
    );

void main() {
  group('WarInfo.fromJson', () {
    test('returns unknown state for null input', () {
      final info = WarInfo.fromJson(null);
      expect(info.state, 'unknown');
      expect(info.clan, isNull);
    });

    test('returns unknown state for empty map', () {
      final info = WarInfo.fromJson({});
      expect(info.state, 'unknown');
    });

    test('parses all scalar fields', () {
      final info = WarInfo.fromJson({
        'war_tag': '#WAR1',
        'state': 'inWar',
        'teamSize': 15,
        'attacksPerMember': 2,
        'startTime': '20230601T120000.000Z',
        'endTime': '20230602T120000.000Z',
        'preparationStartTime': '20230531T120000.000Z',
        'warType': 'classic',
        'clan': {'tag': '#CLAN', 'name': 'My Clan', 'members': []},
        'opponent': {'tag': '#OPP', 'name': 'Enemy', 'members': []},
      });
      expect(info.tag, '#WAR1');
      expect(info.state, 'inWar');
      expect(info.teamSize, 15);
      expect(info.attacksPerMember, 2);
      expect(info.warType, 'classic');
      expect(info.startTime, isNotNull);
      expect(info.endTime, isNotNull);
      expect(info.preparationStartTime, isNotNull);
      expect(info.clan?.tag, '#CLAN');
      expect(info.opponent?.tag, '#OPP');
    });

    test('falls back to type field for warType when warType absent', () {
      final info = WarInfo.fromJson({'state': 'inWar', 'type': 'cwl'});
      expect(info.warType, 'cwl');
    });

    test('returns unknown warType when both warType and type are absent', () {
      final info = WarInfo.fromJson({'state': 'inWar'});
      expect(info.warType, 'unknown');
    });
  });

  group('WarInfo.empty', () {
    test('creates with unknown state and empty clan/opponent', () {
      final info = WarInfo.empty();
      expect(info.state, 'unknown');
      expect(info.clan, isNotNull);
      expect(info.opponent, isNotNull);
      expect(info.clan!.members, isEmpty);
      expect(info.opponent!.members, isEmpty);
    });
  });

  group('WarInfo.getMemberByTag', () {
    test('finds member in clan', () {
      final member = _makeMember('#P1', name: 'Alice');
      final info = WarInfo(
        state: 'inWar',
        clan: _makeClan('#CLAN', members: [member]),
        opponent: _makeClan('#OPP'),
      );
      expect(info.getMemberByTag('#P1')?.name, 'Alice');
    });

    test('finds member in opponent', () {
      final member = _makeMember('#P2', name: 'Bob');
      final info = WarInfo(
        state: 'inWar',
        clan: _makeClan('#CLAN'),
        opponent: _makeClan('#OPP', members: [member]),
      );
      expect(info.getMemberByTag('#P2')?.name, 'Bob');
    });

    test('returns null when not found in either side', () {
      final info = WarInfo(
        state: 'inWar',
        clan: _makeClan('#CLAN'),
        opponent: _makeClan('#OPP'),
      );
      expect(info.getMemberByTag('#NOBODY'), isNull);
    });
  });

  group('WarInfo tag helpers', () {
    late WarInfo info;

    setUp(() {
      info = WarInfo(
        state: 'inWar',
        clan: _makeClan('#CLAN', members: [
          _makeMember('#P1', name: 'Charlie', th: 15, pos: 3),
        ]),
        opponent: _makeClan('#OPP'),
      );
    });

    test('getTownhallLevelByTag returns correct level', () {
      expect(info.getTownhallLevelByTag('#P1'), 15);
    });

    test('getTownhallLevelByTag returns null for unknown tag', () {
      expect(info.getTownhallLevelByTag('#NOBODY'), isNull);
    });

    test('getMapPositionByTag returns correct position', () {
      expect(info.getMapPositionByTag('#P1'), 3);
    });

    test('getMapPositionByTag returns null for unknown tag', () {
      expect(info.getMapPositionByTag('#NOBODY'), isNull);
    });

    test('getNameByTag returns correct name', () {
      expect(info.getNameByTag('#P1'), 'Charlie');
    });

    test('getNameByTag returns null for unknown tag', () {
      expect(info.getNameByTag('#NOBODY'), isNull);
    });
  });

  group('WarInfo.getAttacksDoneByPlayer', () {
    late WarInfo info;

    setUp(() {
      info = WarInfo(
        state: 'inWar',
        clan: _makeClan('#CLAN', members: [
          _makeMember('#P1', attacks: [_makeAttack(), _makeAttack()]),
        ]),
        opponent: _makeClan('#OPP', members: [
          _makeMember('#P2', attacks: [_makeAttack()]),
        ]),
      );
    });

    test('returns attack count for clan member', () {
      expect(info.getAttacksDoneByPlayer('#P1', '#CLAN'), 2);
    });

    test('returns attack count for opponent member', () {
      expect(info.getAttacksDoneByPlayer('#P2', '#OPP'), 1);
    });

    test('returns 0 for unknown clan tag', () {
      expect(info.getAttacksDoneByPlayer('#P1', '#UNKNOWN'), 0);
    });

    test('returns 0 for unknown player in known clan', () {
      expect(info.getAttacksDoneByPlayer('#NOBODY', '#CLAN'), 0);
    });
  });

  group('WarInfo.isPlayerInWar', () {
    late WarInfo info;

    setUp(() {
      info = WarInfo(
        state: 'inWar',
        clan: _makeClan('#CLAN', members: [_makeMember('#P1')]),
        opponent: _makeClan('#OPP', members: [_makeMember('#P2')]),
      );
    });

    test('returns true for member in clan', () {
      expect(info.isPlayerInWar('#P1', '#CLAN'), isTrue);
    });

    test('returns true for member in opponent', () {
      expect(info.isPlayerInWar('#P2', '#OPP'), isTrue);
    });

    test('returns false for unknown player in known clan', () {
      expect(info.isPlayerInWar('#NOBODY', '#CLAN'), isFalse);
    });

    test('returns false when clan tag does not match either side', () {
      expect(info.isPlayerInWar('#P1', '#UNKNOWN'), isFalse);
    });
  });

  group('WarInfo.getWarResult', () {
    test('returns unknown when clan tag matches neither side', () {
      final info = WarInfo(
        state: 'warEnded',
        clan: _makeClan('#A', stars: 10, dest: 80.0),
        opponent: _makeClan('#B', stars: 5, dest: 60.0),
      );
      expect(info.getWarResult('#OTHER'), 'unknown');
    });

    test('returns inWar when state is not warEnded', () {
      final info = WarInfo(
        state: 'inWar',
        clan: _makeClan('#A', stars: 10),
        opponent: _makeClan('#B', stars: 5),
      );
      expect(info.getWarResult('#A'), 'inWar');
    });

    test('clan wins by stars', () {
      final info = WarInfo(
        state: 'warEnded',
        clan: _makeClan('#A', stars: 10, dest: 80.0),
        opponent: _makeClan('#B', stars: 5, dest: 60.0),
      );
      expect(info.getWarResult('#A'), 'won');
    });

    test('clan loses by stars', () {
      final info = WarInfo(
        state: 'warEnded',
        clan: _makeClan('#A', stars: 5, dest: 60.0),
        opponent: _makeClan('#B', stars: 10, dest: 80.0),
      );
      expect(info.getWarResult('#A'), 'lost');
    });

    test('clan wins by destruction when stars are tied', () {
      final info = WarInfo(
        state: 'warEnded',
        clan: _makeClan('#A', stars: 10, dest: 90.0),
        opponent: _makeClan('#B', stars: 10, dest: 70.0),
      );
      expect(info.getWarResult('#A'), 'won');
    });

    test('clan loses by destruction when stars are tied', () {
      final info = WarInfo(
        state: 'warEnded',
        clan: _makeClan('#A', stars: 10, dest: 60.0),
        opponent: _makeClan('#B', stars: 10, dest: 80.0),
      );
      expect(info.getWarResult('#A'), 'lost');
    });

    test('returns tie when stars and destruction are equal', () {
      final info = WarInfo(
        state: 'warEnded',
        clan: _makeClan('#A', stars: 10, dest: 80.0),
        opponent: _makeClan('#B', stars: 10, dest: 80.0),
      );
      expect(info.getWarResult('#A'), 'tie');
    });

    test('returns perfectWar when both sides have 100% destruction', () {
      final info = WarInfo(
        state: 'warEnded',
        clan: _makeClan('#A', stars: 30, dest: 100.0),
        opponent: _makeClan('#B', stars: 25, dest: 100.0),
      );
      expect(info.getWarResult('#A'), 'perfectWar');
    });

    test('opponent perspective: wins by stars', () {
      final info = WarInfo(
        state: 'warEnded',
        clan: _makeClan('#A', stars: 5, dest: 60.0),
        opponent: _makeClan('#B', stars: 10, dest: 80.0),
      );
      expect(info.getWarResult('#B'), 'won');
    });

    test('opponent perspective: loses by stars', () {
      final info = WarInfo(
        state: 'warEnded',
        clan: _makeClan('#A', stars: 10, dest: 80.0),
        opponent: _makeClan('#B', stars: 5, dest: 60.0),
      );
      expect(info.getWarResult('#B'), 'lost');
    });

    test('opponent perspective: wins by destruction on tie', () {
      final info = WarInfo(
        state: 'warEnded',
        clan: _makeClan('#A', stars: 10, dest: 60.0),
        opponent: _makeClan('#B', stars: 10, dest: 80.0),
      );
      expect(info.getWarResult('#B'), 'won');
    });
  });

  group('WarInfo.reorderForUser', () {
    test('returns same when user is already in clan position', () {
      final member = _makeMember('#P1');
      final info = WarInfo(
        state: 'inWar',
        clan: _makeClan('#CLAN', members: [member]),
        opponent: _makeClan('#OPP'),
      );
      final result = info.reorderForUser('#P1');
      expect(result.clan!.tag, '#CLAN');
      expect(result.opponent!.tag, '#OPP');
    });

    test('swaps clan and opponent when user is in opponent position', () {
      final member = _makeMember('#P2');
      final info = WarInfo(
        state: 'inWar',
        clan: _makeClan('#CLAN'),
        opponent: _makeClan('#OPP', members: [member]),
      );
      final result = info.reorderForUser('#P2');
      expect(result.clan!.tag, '#OPP');
      expect(result.opponent!.tag, '#CLAN');
    });

    test('returns same when user is not found in either side', () {
      final info = WarInfo(
        state: 'inWar',
        clan: _makeClan('#CLAN'),
        opponent: _makeClan('#OPP'),
      );
      final result = info.reorderForUser('#NOBODY');
      expect(result.clan!.tag, '#CLAN');
      expect(result.opponent!.tag, '#OPP');
    });
  });

  group('WarInfo.reorderForClan', () {
    test('returns same when clan is already in clan position', () {
      final info = WarInfo(
        state: 'inWar',
        clan: _makeClan('#CLAN'),
        opponent: _makeClan('#OPP'),
      );
      final result = info.reorderForClan('#CLAN');
      expect(result.clan!.tag, '#CLAN');
      expect(result.opponent!.tag, '#OPP');
    });

    test('swaps when target clan is in opponent position', () {
      final info = WarInfo(
        state: 'inWar',
        clan: _makeClan('#CLAN'),
        opponent: _makeClan('#OPP'),
      );
      final result = info.reorderForClan('#OPP');
      expect(result.clan!.tag, '#OPP');
      expect(result.opponent!.tag, '#CLAN');
    });

    test('normalizes # prefix when searching by tag without #', () {
      final info = WarInfo(
        state: 'inWar',
        clan: _makeClan('#CLAN'),
        opponent: _makeClan('#OPP'),
      );
      final result = info.reorderForClan('OPP');
      expect(result.clan!.tag, '#OPP');
      expect(result.opponent!.tag, '#CLAN');
    });

    test('returns same when target clan not found in either position', () {
      final info = WarInfo(
        state: 'inWar',
        clan: _makeClan('#CLAN'),
        opponent: _makeClan('#OPP'),
      );
      final result = info.reorderForClan('#OTHER');
      expect(result.clan!.tag, '#CLAN');
      expect(result.opponent!.tag, '#OPP');
    });
  });
}
