import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameDataService static data normalization', () {
    test('prefers non-seasonal duplicate troop for the base item key', () {
      GameDataService.loadFromBundleForTesting({
        'troops': [
          {
            'name': 'Meteor Golem',
            'village': 'home',
            'is_seasonal': true,
            'levels': [
              {'level': 1},
            ],
          },
          {
            'name': 'Meteor Golem',
            'village': 'home',
            'levels': [
              {'level': 1},
            ],
          },
        ],
      });

      final troops = GameDataService.troopsData['troops'];
      expect(troops['Meteor Golem']['is_seasonal'], isNot(true));
      expect(
        troops['Meteor Golem']['url'],
        'https://assets.clashk.ing/troops/meteor_golem/icon.webp',
      );
      expect(troops['Meteor Golem 2']['is_seasonal'], isTrue);
    });
  });
}
