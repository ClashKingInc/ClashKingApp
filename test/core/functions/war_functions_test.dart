import 'package:clashkingapp/core/functions/war_functions.dart';
import 'package:clashkingapp/features/clan/models/clan_badge.dart';
import 'package:clashkingapp/features/war_cwl/models/war_attack.dart';
import 'package:clashkingapp/features/war_cwl/models/war_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member.dart';
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
        .map((e) => WarAttack(
              attackerTag: '#TAG',
              defenderTag: '#DEF',
              stars: e.value,
              destructionPercentage: 100,
              order: e.key + 1,
            ))
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
      final members = [_memberWithStars([3])];
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
        WarMember(tag: '#P1', name: 'Alice', townhallLevel: 15, mapPosition: 1, opponentAttacks: 0),
        WarMember(tag: '#P2', name: 'Bob', townhallLevel: 14, mapPosition: 2, opponentAttacks: 0),
        WarMember(tag: '#P3', name: 'Carol', townhallLevel: 13, mapPosition: 3, opponentAttacks: 0),
      ];
      final clan = _clanWithMembers(members);
      expect(getMemberByTag('#P2', clan)!.name, 'Bob');
      expect(getMemberByTag('#P3', clan)!.name, 'Carol');
    });
  });
}
