import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/models/clan_join_leave.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Clan.fromJson', () {
    test('uses defaults for all missing fields', () {
      final clan = Clan.fromJson({'tag': '#CLAN', 'name': 'Test'});
      expect(clan.tag, '#CLAN');
      expect(clan.name, 'Test');
      expect(clan.type, '');
      expect(clan.description, '');
      expect(clan.isFamilyFriendly, isFalse);
      expect(clan.clanLevel, 0);
      expect(clan.warFrequency, 'unknown');
      expect(clan.warWinStreak, 0);
      expect(clan.warWins, 0);
      expect(clan.warTies, 0);
      expect(clan.warLosses, 0);
      expect(clan.isWarLogPublic, isTrue);
      expect(clan.members, 0);
      expect(clan.memberList, isEmpty);
      expect(clan.labels, isEmpty);
      expect(clan.location, isNull);
      expect(clan.capitalLeague, isNull);
      expect(clan.warLeague, isNull);
      expect(clan.clanCapital, isNull);
      expect(clan.chatLanguage, isNull);
    });

    test('parses all scalar fields correctly', () {
      final clan = Clan.fromJson({
        'tag': '#ABC',
        'name': 'My Clan',
        'type': 'inviteOnly',
        'description': 'A great clan',
        'isFamilyFriendly': true,
        'clanLevel': 20,
        'clanPoints': 50000,
        'clanBuilderBasePoints': 10000,
        'clanCapitalPoints': 5000,
        'requiredTrophies': 1000,
        'warFrequency': 'always',
        'warWinStreak': 7,
        'warWins': 100,
        'warTies': 5,
        'warLosses': 10,
        'isWarLogPublic': false,
        'members': 45,
        'requiredBuilderBaseTrophies': 500,
        'requiredTownhallLevel': 12,
      });
      expect(clan.tag, '#ABC');
      expect(clan.name, 'My Clan');
      expect(clan.type, 'inviteOnly');
      expect(clan.description, 'A great clan');
      expect(clan.isFamilyFriendly, isTrue);
      expect(clan.clanLevel, 20);
      expect(clan.clanPoints, 50000);
      expect(clan.warFrequency, 'always');
      expect(clan.warWinStreak, 7);
      expect(clan.warWins, 100);
      expect(clan.warTies, 5);
      expect(clan.warLosses, 10);
      expect(clan.isWarLogPublic, isFalse);
      expect(clan.members, 45);
      expect(clan.requiredTownhallLevel, 12);
    });

    test('parses nested location correctly', () {
      final clan = Clan.fromJson({
        'tag': '#CLAN',
        'location': {
          'id': 32000006,
          'name': 'France',
          'isCountry': true,
          'countryCode': 'FR',
        },
      });
      expect(clan.location, isNotNull);
      expect(clan.location!.name, 'France');
    });

    test('parses capitalLeague and warLeague', () {
      final clan = Clan.fromJson({
        'tag': '#CLAN',
        'capitalLeague': {'id': 85000000, 'name': 'Bronze League I'},
        'warLeague': {'id': 48000000, 'name': 'Crystal League I'},
      });
      expect(clan.capitalLeague, isNotNull);
      expect(clan.capitalLeague!.name, 'Bronze League I');
      expect(clan.warLeague, isNotNull);
      expect(clan.warLeague!.name, 'Crystal League I');
    });

    test('parses chatLanguage', () {
      final clan = Clan.fromJson({
        'tag': '#CLAN',
        'chatLanguage': {'id': 75000000, 'name': 'English', 'languageCode': 'EN'},
      });
      expect(clan.chatLanguage, isNotNull);
      expect(clan.chatLanguage!.name, 'English');
    });

    test('parses memberList', () {
      final clan = Clan.fromJson({
        'tag': '#CLAN',
        'memberList': [
          {
            'tag': '#P1',
            'name': 'Alice',
            'role': 'member',
            'expLevel': 200,
            'trophies': 3000,
            'builderBaseTrophies': 0,
            'clanRank': 1,
            'previousClanRank': 2,
            'donations': 100,
            'donationsReceived': 50,
            'townHallLevel': 14,
            'builderHallLevel': 0,
            'playerHouse': null,
            'league': null,
            'builderBaseLeague': null,
          },
          {
            'tag': '#P2',
            'name': 'Bob',
            'role': 'elder',
            'expLevel': 150,
            'trophies': 2500,
            'builderBaseTrophies': 0,
            'clanRank': 2,
            'previousClanRank': 3,
            'donations': 50,
            'donationsReceived': 200,
            'townHallLevel': 13,
            'builderHallLevel': 0,
            'playerHouse': null,
            'league': null,
            'builderBaseLeague': null,
          },
        ],
      });
      expect(clan.memberList, hasLength(2));
      expect(clan.memberList.first.name, 'Alice');
      expect(clan.memberList.last.name, 'Bob');
    });

    test('parses labels list', () {
      final clan = Clan.fromJson({
        'tag': '#CLAN',
        'labels': [
          {'id': 56000000, 'name': 'Clan Wars', 'badgeUrls': null},
          {'id': 56000001, 'name': 'Friendly', 'badgeUrls': null},
        ],
      });
      expect(clan.labels, hasLength(2));
    });

    test('warCwl and joinLeave start null', () {
      final clan = Clan.fromJson({'tag': '#CLAN'});
      expect(clan.warCwl, isNull);
      expect(clan.joinLeave, isNull);
    });
  });

  group('Clan.linkWar', () {
    test('sets warCwl field', () {
      final clan = Clan.fromJson({'tag': '#CLAN', 'name': 'Test'});
      final warCwl = WarCwl(
        tag: '#CLAN',
        isInWar: false,
        isInCwl: false,
        warInfo: WarInfo(state: 'notInWar'),
        warLeagueInfos: [],
      );
      clan.linkWar(warCwl);
      expect(clan.warCwl, same(warCwl));
    });
  });

  group('Clan.linkJoinLeave', () {
    test('sets joinLeave field', () {
      final clan = Clan.fromJson({'tag': '#CLAN', 'name': 'Test'});
      final joinLeave = ClanJoinLeave.empty();
      clan.linkJoinLeave(joinLeave);
      expect(clan.joinLeave, same(joinLeave));
    });
  });
}
