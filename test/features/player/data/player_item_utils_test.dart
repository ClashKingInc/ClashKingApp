import 'package:clashkingapp/features/player/data/player_item_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('filterGameData', () {
    test('excludes seasonal static-data entries from player lists', () {
      final result = filterGameData({
        'Barbarian': {
          'type': 'troop',
        },
        'Ice Minion': {
          'type': 'troop',
          'is_seasonal': true,
        },
        'Santa\'s Surprise': {
          'type': 'spell',
          'is_seasonal': true,
        },
      }, (key, value) => value['type'] == 'troop');

      expect(result.keys, ['Barbarian']);
    });

    test('keeps regular items that match the predicate', () {
      final result = filterGameData({
        'Lightning Spell': {
          'type': 'spell',
        },
      }, (key, value) => value['type'] == 'spell');

      expect(result.keys, ['Lightning Spell']);
    });
  });
}
