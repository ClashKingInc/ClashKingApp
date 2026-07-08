import 'package:clashkingapp/features/player/data/player_item_utils.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestItem extends PlayerItem {
  _TestItem({
    required super.name,
    required super.level,
    required super.maxLevel,
    required super.isUnlocked,
    super.meta,
    Map<String, dynamic>? rawJson,
  }) : super(type: 'troop', imageUrl: '');
}

PlayerItemFactory<_TestItem> get _factory =>
    ({
      required name,
      required level,
      required maxLevel,
      required isUnlocked,
      meta,
      rawJson,
    }) => _TestItem(
      name: name,
      level: level,
      maxLevel: maxLevel,
      isUnlocked: isUnlocked,
      meta: meta,
      rawJson: rawJson,
    );

void main() {
  group('generateCompleteItemList', () {
    test('owned item gets level/maxLevel from json and isUnlocked=true', () {
      final result = generateCompleteItemList<_TestItem>(
        jsonList: [
          {'name': 'Barbarian', 'level': 5, 'maxLevel': 10},
        ],
        gameData: {
          'Barbarian': {'maxLevel': 10},
        },
        factory: _factory,
      );

      expect(result.length, 1);
      expect(result.first.name, 'Barbarian');
      expect(result.first.level, 5);
      expect(result.first.maxLevel, 10);
      expect(result.first.isUnlocked, isTrue);
    });

    test('unowned item gets level=0, maxLevel from meta, isUnlocked=false', () {
      final result = generateCompleteItemList<_TestItem>(
        jsonList: [],
        gameData: {
          'Archer': {'maxLevel': 8},
        },
        factory: _factory,
      );

      expect(result.first.level, 0);
      expect(result.first.maxLevel, 8);
      expect(result.first.isUnlocked, isFalse);
    });

    test('null jsonList treats all items as unowned', () {
      final result = generateCompleteItemList<_TestItem>(
        jsonList: null,
        gameData: {
          'Giant': {'maxLevel': 12},
        },
        factory: _factory,
      );

      expect(result.first.isUnlocked, isFalse);
      expect(result.first.level, 0);
    });

    test('custom nameMatcher is used for lookup', () {
      final result = generateCompleteItemList<_TestItem>(
        jsonList: [
          {'name': 'barbarian', 'level': 3, 'maxLevel': 10},
        ],
        gameData: {
          'Barbarian': {'maxLevel': 10},
        },
        factory: _factory,
        nameMatcher: (name, json) =>
            name.toLowerCase() == (json['name'] as String).toLowerCase(),
      );

      expect(result.first.isUnlocked, isTrue);
      expect(result.first.level, 3);
    });

    test('maxLevel falls back to 0 when absent from both json and meta', () {
      final result = generateCompleteItemList<_TestItem>(
        jsonList: [],
        gameData: {'Goblin': <String, dynamic>{}},
        factory: _factory,
      );

      expect(result.first.maxLevel, 0);
    });

    test('uses metadata name for duplicate static-data keys', () {
      final result = generateCompleteItemList<_TestItem>(
        jsonList: [
          {'name': 'Meteor Golem', 'level': 1, 'maxLevel': 1},
        ],
        gameData: {
          'Meteor Golem 2': {'name': 'Meteor Golem', 'maxLevel': 1},
        },
        factory: _factory,
      );

      expect(result.first.name, 'Meteor Golem');
      expect(result.first.isUnlocked, isTrue);
      expect(result.first.level, 1);
    });
  });

  group('maxLevelForTH', () {
    final meta = {
      'levels': [
        {'required_townhall': 1, 'level': 1},
        {'required_townhall': 5, 'level': 5},
        {'required_townhall': 10, 'level': 10},
      ],
    };

    test('returns highest level unlockable at given TH', () {
      expect(maxLevelForTH(meta, 5), 5);
      expect(maxLevelForTH(meta, 10), 10);
      expect(maxLevelForTH(meta, 1), 1);
    });

    test('returns 0 when no level meets thLevel requirement', () {
      expect(maxLevelForTH(meta, 0), 0);
    });

    test('returns 0 for null meta', () {
      expect(maxLevelForTH(null, 10), 0);
    });

    test('returns 0 for thLevel <= 0', () {
      expect(maxLevelForTH(meta, 0), 0);
      expect(maxLevelForTH(meta, -1), 0);
    });

    test('returns 0 when levels key is missing', () {
      expect(maxLevelForTH({}, 10), 0);
    });

    test('returns 0 when levels is empty', () {
      expect(maxLevelForTH({'levels': []}, 10), 0);
    });

    test('returns 0 when levels is not a list', () {
      expect(maxLevelForTH({'levels': 'invalid'}, 10), 0);
    });

    test('skips entries missing required_townhall or level keys', () {
      final incompleteMeta = {
        'levels': [
          {'required_townhall': 5},
          {'level': 3},
          {'required_townhall': 2, 'level': 2},
        ],
      };
      expect(maxLevelForTH(incompleteMeta, 10), 2);
    });
  });

  group('filterGameData', () {
    test('excludes seasonal static-data entries from player lists', () {
      final result = filterGameData({
        'Barbarian': {'type': 'troop'},
        'Ice Minion': {'type': 'troop', 'is_seasonal': true},
        'Santa\'s Surprise': {'type': 'spell', 'is_seasonal': true},
      }, (key, value) => value['type'] == 'troop');

      expect(result.keys, ['Barbarian']);
    });

    test('keeps regular items that match the predicate', () {
      final result = filterGameData({
        'Lightning Spell': {'type': 'spell'},
      }, (key, value) => value['type'] == 'spell');

      expect(result.keys, ['Lightning Spell']);
    });

    test('returns empty map for null data', () {
      expect(filterGameData(null, (_, _) => true), isEmpty);
    });

    test('skips non-Map values', () {
      final result = filterGameData({
        'valid': {'type': 'troop'},
        'invalid': 'not a map',
      }, (_, _) => true);

      expect(result.keys, ['valid']);
    });

    test('excludes items where predicate returns false', () {
      final result = filterGameData({
        'Barbarian': {'type': 'troop'},
        'Lightning Spell': {'type': 'spell'},
      }, (key, value) => value['type'] == 'troop');

      expect(result.keys, ['Barbarian']);
      expect(result.containsKey('Lightning Spell'), isFalse);
    });
  });

  group('filterSpellGameData', () {
    test('excludes seasonal spell entries from player spell lists', () {
      final result = filterSpellGameData({
        'Lightning Spell': {'type': 'spell'},
        'Santa\'s Surprise': {'type': 'spell', 'is_seasonal': true},
      });

      expect(result.keys, ['Lightning Spell']);
    });
  });
}
