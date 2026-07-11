import 'package:clashkingapp/features/war_cwl/models/war_attack.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _miniMemberJson({
  String tag = '#ATTACKER',
  String name = 'Hero',
  int townhallLevel = 15,
  int mapPosition = 1,
  int? opponentAttacks,
}) => <String, dynamic>{
  'tag': tag,
  'name': name,
  'townhallLevel': townhallLevel,
  'mapPosition': mapPosition,
  'opponentAttacks': ?opponentAttacks,
};

Map<String, dynamic> _warAttackJson({
  String attackerTag = '#ATTACKER',
  String defenderTag = '#DEFENDER',
  int stars = 3,
  int destructionPercentage = 100,
  int order = 1,
  int? duration,
  Map<String, dynamic>? defender,
  Map<String, dynamic>? attacker,
}) => <String, dynamic>{
  'attackerTag': attackerTag,
  'defenderTag': defenderTag,
  'stars': stars,
  'destructionPercentage': destructionPercentage,
  'order': order,
  'duration': ?duration,
  'defender': ?defender,
  'attacker': ?attacker,
};

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  // ---------------------------------------------------------------------------
  // MiniMember.fromJson — all fields present
  // ---------------------------------------------------------------------------

  group('MiniMember.fromJson — all fields present', () {
    test('parses tag correctly', () {
      final member = MiniMember.fromJson(_miniMemberJson(tag: '#TEST1'));
      expect(member.tag, '#TEST1');
    });

    test('parses name correctly', () {
      final member = MiniMember.fromJson(_miniMemberJson(name: 'Warrior'));
      expect(member.name, 'Warrior');
    });

    test('parses townhallLevel correctly', () {
      final member = MiniMember.fromJson(_miniMemberJson(townhallLevel: 16));
      expect(member.townhallLevel, 16);
    });

    test('parses mapPosition correctly', () {
      final member = MiniMember.fromJson(_miniMemberJson(mapPosition: 5));
      expect(member.mapPosition, 5);
    });

    test('parses opponentAttacks correctly when present', () {
      final member = MiniMember.fromJson(_miniMemberJson(opponentAttacks: 2));
      expect(member.opponentAttacks, 2);
    });

    test('opponentAttacks is null when missing from json', () {
      final member = MiniMember.fromJson(_miniMemberJson());
      expect(member.opponentAttacks, isNull);
    });

    test('full round-trip preserves all fields', () {
      final json = _miniMemberJson(
        tag: '#HERO1',
        name: 'Legend',
        townhallLevel: 14,
        mapPosition: 3,
        opponentAttacks: 1,
      );
      final member = MiniMember.fromJson(json);
      expect(member.tag, '#HERO1');
      expect(member.name, 'Legend');
      expect(member.townhallLevel, 14);
      expect(member.mapPosition, 3);
      expect(member.opponentAttacks, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // WarAttack.fromJson — all fields present
  // ---------------------------------------------------------------------------

  group('WarAttack.fromJson — all fields present', () {
    test('parses attackerTag correctly', () {
      final attack = WarAttack.fromJson(_warAttackJson(attackerTag: '#ATK1'));
      expect(attack.attackerTag, '#ATK1');
    });

    test('parses defenderTag correctly', () {
      final attack = WarAttack.fromJson(_warAttackJson(defenderTag: '#DEF1'));
      expect(attack.defenderTag, '#DEF1');
    });

    test('parses stars correctly', () {
      final attack = WarAttack.fromJson(_warAttackJson(stars: 2));
      expect(attack.stars, 2);
    });

    test('parses destructionPercentage correctly', () {
      final attack = WarAttack.fromJson(
        _warAttackJson(destructionPercentage: 85),
      );
      expect(attack.destructionPercentage, 85);
    });

    test('parses order correctly', () {
      final attack = WarAttack.fromJson(_warAttackJson(order: 7));
      expect(attack.order, 7);
    });

    test('parses duration when present', () {
      final attack = WarAttack.fromJson(_warAttackJson(duration: 180));
      expect(attack.duration, 180);
    });

    test('duration is null when missing', () {
      final attack = WarAttack.fromJson(_warAttackJson());
      expect(attack.duration, isNull);
    });

    test('parses nested defender MiniMember', () {
      final attack = WarAttack.fromJson(
        _warAttackJson(
          defender: _miniMemberJson(tag: '#DEF1', name: 'Defender'),
        ),
      );
      expect(attack.defender, isNotNull);
      expect(attack.defender!.tag, '#DEF1');
      expect(attack.defender!.name, 'Defender');
    });

    test('parses nested attacker MiniMember', () {
      final attack = WarAttack.fromJson(
        _warAttackJson(
          attacker: _miniMemberJson(tag: '#ATK1', name: 'Attacker'),
        ),
      );
      expect(attack.attacker, isNotNull);
      expect(attack.attacker!.tag, '#ATK1');
    });

    test('defender is null when not in json', () {
      final attack = WarAttack.fromJson(_warAttackJson());
      expect(attack.defender, isNull);
    });

    test('attacker is null when not in json', () {
      final attack = WarAttack.fromJson(_warAttackJson());
      expect(attack.attacker, isNull);
    });

    test('full round-trip with all fields', () {
      final json = _warAttackJson(
        attackerTag: '#A',
        defenderTag: '#D',
        stars: 3,
        destructionPercentage: 100,
        order: 5,
        duration: 200,
        defender: _miniMemberJson(tag: '#D', name: 'D1'),
        attacker: _miniMemberJson(tag: '#A', name: 'A1'),
      );
      final attack = WarAttack.fromJson(json);
      expect(attack.attackerTag, '#A');
      expect(attack.defenderTag, '#D');
      expect(attack.stars, 3);
      expect(attack.destructionPercentage, 100);
      expect(attack.order, 5);
      expect(attack.duration, 200);
      expect(attack.defender!.name, 'D1');
      expect(attack.attacker!.name, 'A1');
    });

    test('both defender and attacker are null when absent from json', () {
      final attack = WarAttack.fromJson(_warAttackJson());
      expect(attack.defender, isNull);
      expect(attack.attacker, isNull);
    });

    test('defender is non-null when json has defender key', () {
      final attack = WarAttack.fromJson(
        _warAttackJson(defender: _miniMemberJson()),
      );
      expect(attack.defender, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // WarAttack.fromJson — zero star attack
  // ---------------------------------------------------------------------------

  group('WarAttack.fromJson — zero-value attack', () {
    test('zero stars parsed correctly', () {
      final attack = WarAttack.fromJson(_warAttackJson(stars: 0));
      expect(attack.stars, 0);
    });

    test('zero destructionPercentage parsed correctly', () {
      final attack = WarAttack.fromJson(
        _warAttackJson(destructionPercentage: 0),
      );
      expect(attack.destructionPercentage, 0);
    });

    test('first order attack (order = 1) parsed correctly', () {
      final attack = WarAttack.fromJson(_warAttackJson(order: 1));
      expect(attack.order, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // WarAttack.toJson
  // ---------------------------------------------------------------------------

  group('WarAttack.toJson', () {
    test('serialises attackerTag', () {
      final attack = WarAttack.fromJson(_warAttackJson(attackerTag: '#X'));
      expect(attack.toJson()['attackerTag'], '#X');
    });

    test('serialises defenderTag', () {
      final attack = WarAttack.fromJson(_warAttackJson(defenderTag: '#Y'));
      expect(attack.toJson()['defenderTag'], '#Y');
    });

    test('serialises stars', () {
      final attack = WarAttack.fromJson(_warAttackJson(stars: 1));
      expect(attack.toJson()['stars'], 1);
    });

    test('serialises destructionPercentage', () {
      final attack = WarAttack.fromJson(
        _warAttackJson(destructionPercentage: 73),
      );
      expect(attack.toJson()['destructionPercentage'], 73);
    });

    test('serialises order', () {
      final attack = WarAttack.fromJson(_warAttackJson(order: 9));
      expect(attack.toJson()['order'], 9);
    });

    test('serialises duration as null when absent', () {
      final attack = WarAttack.fromJson(_warAttackJson());
      expect(attack.toJson()['duration'], isNull);
    });

    test('serialises duration value when present', () {
      final attack = WarAttack.fromJson(_warAttackJson(duration: 120));
      expect(attack.toJson()['duration'], 120);
    });

    test('toJson round-trip preserves all values', () {
      final original = _warAttackJson(
        attackerTag: '#ROUND',
        defenderTag: '#TRIP',
        stars: 2,
        destructionPercentage: 65,
        order: 3,
        duration: 155,
      );
      final attack = WarAttack.fromJson(original);
      final json = attack.toJson();
      expect(json['attackerTag'], '#ROUND');
      expect(json['defenderTag'], '#TRIP');
      expect(json['stars'], 2);
      expect(json['destructionPercentage'], 65);
      expect(json['order'], 3);
      expect(json['duration'], 155);
    });
  });
}
