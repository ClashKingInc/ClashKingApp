import 'package:clashkingapp/features/clan/models/clan_capital.dart';
import 'package:clashkingapp/features/clan/models/clan_chat_language.dart';
import 'package:clashkingapp/features/clan/models/clan_district.dart';
import 'package:clashkingapp/features/clan/models/clan_league.dart';
import 'package:clashkingapp/features/clan/models/clan_location.dart';
import 'package:clashkingapp/features/clan/models/clan_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClanCapital.fromJson', () {
    test('parses capitalHallLevel and districts', () {
      final capital = ClanCapital.fromJson({
        'capitalHallLevel': 5,
        'districts': [
          {'id': 1, 'name': 'Barbarian Camp', 'districtHallLevel': 3},
        ],
      });
      expect(capital.capitalHallLevel, 5);
      expect(capital.districts, hasLength(1));
      expect(capital.districts.first.name, 'Barbarian Camp');
    });

    test('uses defaults for missing fields', () {
      final capital = ClanCapital.fromJson({});
      expect(capital.capitalHallLevel, 0);
      expect(capital.districts, isEmpty);
    });
  });

  group('ClanChatLanguage.fromJson', () {
    test('parses all fields', () {
      final lang = ClanChatLanguage.fromJson({
        'id': 75000000,
        'name': 'English',
        'languageCode': 'EN',
      });
      expect(lang.id, 75000000);
      expect(lang.name, 'English');
      expect(lang.languageCode, 'EN');
    });

    test('uses defaults for missing fields', () {
      final lang = ClanChatLanguage.fromJson({});
      expect(lang.id, 0);
      expect(lang.name, '');
      expect(lang.languageCode, '');
    });
  });

  group('ClanDistrict.fromJson', () {
    test('parses id, name and districtHallLevel', () {
      final district = ClanDistrict.fromJson({
        'id': 70000000,
        'name': 'Capital Peak',
        'districtHallLevel': 10,
      });
      expect(district.id, 70000000);
      expect(district.name, 'Capital Peak');
      expect(district.districtHallLevel, 10);
    });

    test('uses defaults for missing fields', () {
      final district = ClanDistrict.fromJson({});
      expect(district.id, 0);
      expect(district.name, '');
      expect(district.districtHallLevel, 0);
    });
  });

  group('ClanLeague', () {
    test('fromJson parses all fields including iconUrls', () {
      final league = ClanLeague.fromJson({
        'id': 29000022,
        'name': 'Legend League',
        'iconUrls': {
          'small': 'https://example.com/small.png',
          'medium': 'https://example.com/medium.png',
          'tiny': 'https://example.com/tiny.png',
        },
      });
      expect(league.id, 29000022);
      expect(league.name, 'Legend League');
      expect(league.smallIconUrl, 'https://example.com/small.png');
      expect(league.mediumIconUrl, 'https://example.com/medium.png');
      expect(league.tinyIconUrl, 'https://example.com/tiny.png');
    });

    test('fromJson handles missing iconUrls', () {
      final league = ClanLeague.fromJson({'id': 1, 'name': 'Bronze I'});
      expect(league.smallIconUrl, isNull);
      expect(league.mediumIconUrl, isNull);
      expect(league.tinyIconUrl, isNull);
    });

    test('unranked factory sets id=0 and name=Unranked with null urls', () {
      final league = ClanLeague.unranked();
      expect(league.id, 0);
      expect(league.name, 'Unranked');
      expect(league.smallIconUrl, isNull);
    });
  });

  group('ClanLocation.fromJson', () {
    test('parses all fields', () {
      final location = ClanLocation.fromJson({
        'id': 32000006,
        'name': 'France',
        'isCountry': true,
        'countryCode': 'FR',
      });
      expect(location.id, 32000006);
      expect(location.name, 'France');
      expect(location.isCountry, isTrue);
      expect(location.countryCode, 'FR');
    });

    test('handles missing optional countryCode', () {
      final location = ClanLocation.fromJson({
        'id': 1,
        'name': 'International',
        'isCountry': false,
      });
      expect(location.countryCode, isNull);
      expect(location.isCountry, isFalse);
    });
  });

  group('ClanMember', () {
    test('fromJson parses all fields', () {
      final member = ClanMember.fromJson({
        'tag': '#ABC123',
        'name': 'Player One',
        'role': 'leader',
        'townHallLevel': 15,
        'expLevel': 200,
        'trophies': 5000,
        'donations': 1500,
        'donationsReceived': 800,
        'builderBaseTrophies': 4000,
        'league': {'id': 29000022, 'name': 'Legend League'},
      });
      expect(member.tag, '#ABC123');
      expect(member.name, 'Player One');
      expect(member.role, 'leader');
      expect(member.townHallLevel, 15);
      expect(member.trophies, 5000);
      expect(member.donations, 1500);
      expect(member.league.id, 29000022);
    });

    test('fromJson uses ClanLeague.unranked when league field is absent', () {
      final member = ClanMember.fromJson({
        'tag': '#AAA',
        'name': 'Test',
        'role': 'member',
        'townHallLevel': 10,
        'expLevel': 50,
        'trophies': 1000,
        'donations': 0,
        'donationsReceived': 0,
        'builderBaseTrophies': 0,
      });
      expect(member.league.id, 0);
      expect(member.league.name, 'Unranked');
    });

    test('empty factory returns zero-value member with unranked league', () {
      final member = ClanMember.empty();
      expect(member.tag, '');
      expect(member.name, '');
      expect(member.townHallLevel, 0);
      expect(member.donations, 0);
      expect(member.league.name, 'Unranked');
    });
  });
}
