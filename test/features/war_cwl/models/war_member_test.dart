import 'package:clashkingapp/features/war_cwl/models/war_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WarMember.fromJson', () {
    test('parses all basic fields', () {
      final member = WarMember.fromJson({
        'tag': '#PLAYER1',
        'name': 'Test Player',
        'townhallLevel': 15,
        'mapPosition': 3,
        'opponentAttacks': 2,
        'attacks': null,
        'bestOpponentAttack': null,
      });
      expect(member.tag, '#PLAYER1');
      expect(member.name, 'Test Player');
      expect(member.townhallLevel, 15);
      expect(member.mapPosition, 3);
      expect(member.opponentAttacks, 2);
      expect(member.attacks, isNull);
      expect(member.bestOpponentAttack, isNull);
    });

    test('parses attacks list with stars', () {
      final member = WarMember.fromJson({
        'tag': '#PLAYER1',
        'name': 'Test Player',
        'townhallLevel': 15,
        'mapPosition': 1,
        'opponentAttacks': 1,
        'attacks': [
          {
            'attackerTag': '#PLAYER1',
            'defenderTag': '#DEF',
            'stars': 3,
            'destructionPercentage': 100,
            'order': 1,
          },
        ],
      });
      expect(member.attacks, hasLength(1));
      expect(member.attacks!.first.stars, 3);
      expect(member.attacks!.first.destructionPercentage, 100);
    });

    test('parses bestOpponentAttack when present', () {
      final member = WarMember.fromJson({
        'tag': '#PLAYER1',
        'name': 'Defender',
        'townhallLevel': 14,
        'mapPosition': 2,
        'opponentAttacks': 1,
        'bestOpponentAttack': {
          'attackerTag': '#ATK',
          'defenderTag': '#PLAYER1',
          'stars': 2,
          'destructionPercentage': 75,
          'order': 5,
        },
      });
      expect(member.bestOpponentAttack, isNotNull);
      expect(member.bestOpponentAttack!.stars, 2);
    });

    test('handles null json gracefully', () {
      final member = WarMember.fromJson(null);
      expect(member.tag, '');
      expect(member.name, '');
      expect(member.townhallLevel, 0);
      expect(member.mapPosition, 0);
      expect(member.opponentAttacks, 0);
    });

    test('uses defaults for missing fields', () {
      final member = WarMember.fromJson({});
      expect(member.tag, '');
      expect(member.mapPosition, 0);
      expect(member.opponentAttacks, 0);
      expect(member.attacks, isNull);
    });
  });

  group('WarMember.empty', () {
    test('returns zero-value member with empty attacks list', () {
      final member = WarMember.empty();
      expect(member.tag, '');
      expect(member.name, '');
      expect(member.townhallLevel, 0);
      expect(member.mapPosition, 0);
      expect(member.opponentAttacks, 0);
      expect(member.attacks, isEmpty);
      expect(member.bestOpponentAttack, isNull);
    });
  });

  group('WarMember.toJson', () {
    test('serializes basic fields correctly', () {
      final member = WarMember(
        tag: '#PLAYER1',
        name: 'Test',
        townhallLevel: 14,
        mapPosition: 5,
        opponentAttacks: 1,
        attacks: [],
        bestOpponentAttack: null,
      );
      final json = member.toJson();
      expect(json['tag'], '#PLAYER1');
      expect(json['name'], 'Test');
      expect(json['townhallLevel'], 14);
      expect(json['mapPosition'], 5);
      expect(json['opponentAttacks'], 1);
      expect(json['attacks'], isEmpty);
      expect(json['bestOpponentAttack'], isNull);
    });

    test('round-trips fromJson -> toJson -> fromJson', () {
      final original = WarMember.fromJson({
        'tag': '#ROUND',
        'name': 'RoundTrip',
        'townhallLevel': 13,
        'mapPosition': 7,
        'opponentAttacks': 0,
        'attacks': [
          {
            'attackerTag': '#ROUND',
            'defenderTag': '#TARGET',
            'stars': 2,
            'destructionPercentage': 80,
            'order': 1,
          },
        ],
      });
      final json = original.toJson();
      final restored = WarMember.fromJson(json);
      expect(restored.tag, original.tag);
      expect(restored.townhallLevel, original.townhallLevel);
      expect(restored.attacks, hasLength(1));
      expect(restored.attacks!.first.stars, 2);
    });
  });
}
